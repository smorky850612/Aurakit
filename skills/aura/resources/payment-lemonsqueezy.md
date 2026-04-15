# AuraKit — Lemon Squeezy 결제 파이프라인

> PAYMENT 모드에서 Lemon Squeezy 선택 시 로딩. 공통 스키마 → payment-pipeline.md 참조.

---

## Lemon Squeezy

> SaaS·디지털 제품에 최적. 세금 자동 처리 (MoR). 설정 가장 단순.

### .env.example
```
LEMONSQUEEZY_API_KEY=eyJhbGciOiJxxxxxxxxxx
LEMONSQUEEZY_STORE_ID=12345
LEMONSQUEEZY_WEBHOOK_SECRET=your-webhook-secret
NEXT_PUBLIC_URL=https://your-app.com
```

### 설치 + 초기화
```bash
npm install @lemonsqueezy/lemonsqueezy.js
```

```typescript
import { lemonSqueezySetup, createCheckout } from '@lemonsqueezy/lemonsqueezy.js';
lemonSqueezySetup({ apiKey: process.env.LEMONSQUEEZY_API_KEY! });
```

### 체크아웃 생성
```typescript
const { data } = await createCheckout(
  process.env.LEMONSQUEEZY_STORE_ID!,
  variantId,
  {
    checkoutData: {
      email: user.email,
      custom: { user_id: user.id },
    },
    productOptions: {
      redirectUrl: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=true`,
    },
  }
);
return data?.data.attributes.url;
```

### 웹훅 핸들러 (`/api/webhooks/lemonsqueezy`)
```typescript
import crypto from 'crypto';

export async function POST(req: Request) {
  const body = await req.text();
  const sig = req.headers.get('x-signature') ?? '';
  const hmac = crypto
    .createHmac('sha256', process.env.LEMONSQUEEZY_WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');

  // 명시적 hex 버퍼 비교 — 인코딩 불일치 방지 (SEC-015 수정)
  // sig가 유효한 hex가 아니면 Buffer.from('', 'hex')은 빈 버퍼 → 길이 불일치로 차단
  const hmacBuf = Buffer.from(hmac, 'hex');
  const sigBuf  = Buffer.from(sig,  'hex');
  if (sigBuf.length === 0 || sigBuf.length !== hmacBuf.length ||
      !crypto.timingSafeEqual(hmacBuf, sigBuf)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);
  const eventName: string = payload.meta.event_name;
  const sub = payload.data.attributes;
  const eventId = String(payload.meta.event_id || payload.data.id + '_' + eventName);

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['lemonsqueezy', eventId, eventName, JSON.stringify(payload)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    switch (eventName) {
      case 'subscription_created':
      case 'subscription_updated': {
        // custom_data.user_id 검증 (SEC-014 수정)
        const userId = payload.meta.custom_data?.user_id;
        if (!userId || typeof userId !== 'string') {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Missing user_id in custom_data' }, { status: 400 });
        }

        // renews_at/ends_at 둘 다 null이면 epoch 방지 (EDGE-003 수정)
        const periodEnd = sub.renews_at ?? sub.ends_at;
        if (!periodEnd) {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Missing subscription end date' }, { status: 400 });
        }

        await upsertSubscription({
          provider: 'lemonsqueezy',
          providerSubscriptionId: String(payload.data.id),
          providerPriceId: String(sub.variant_id),
          userId,
          status: sub.status,
          currentPeriodStart: new Date(sub.updated_at),
          currentPeriodEnd: new Date(periodEnd),
          trialEnd: sub.trial_ends_at ? new Date(sub.trial_ends_at) : null,
        }, client);
        break;
      }
      case 'subscription_payment_failed':
        // 결제 실패 → past_due + 던닝 (이메일)
        await client.query(
          "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider_subscription_id=$1",
          [String(payload.data.id)]
        );
        break;
      case 'subscription_cancelled':
      case 'subscription_expired':
        await client.query(
          "UPDATE subscriptions SET status='canceled', canceled_at=now(), updated_at=now() WHERE provider_subscription_id=$1",
          [String(payload.data.id)]
        );
        break;
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['lemonsqueezy', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[lemonsqueezy-webhook] processing error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  } finally {
    client.release();
  }

  return NextResponse.json({ ok: true });
}
```

### Billing Portal (LemonSqueezy)
```typescript
// POST /api/subscriptions/ls-portal
import { getSubscription } from '@lemonsqueezy/lemonsqueezy.js';

export async function POST(req: Request) {
  const session = await getServerSession();
  if (!session?.user?.id) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  // DB에서 LS 구독 ID 조회
  const sub = await db.query(
    "SELECT provider_subscription_id FROM subscriptions WHERE user_id=$1 AND provider='lemonsqueezy' AND status='active' LIMIT 1",
    [session.user.id]
  );
  if (!sub.rows.length) return NextResponse.json({ error: 'No active subscription' }, { status: 404 });

  const { data } = await getSubscription(sub.rows[0].provider_subscription_id);
  // data.data.attributes.urls.customer_portal — LemonSqueezy 제공 포털 URL
  return NextResponse.json({ url: data?.data.attributes.urls?.customer_portal });
}
```

---

