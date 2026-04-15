# AuraKit — Polar 결제 파이프라인

> PAYMENT 모드에서 Polar 선택 시 로딩. 공통 스키마 → payment-pipeline.md 참조.

---

## Polar

> 오픈소스 프로젝트에 최적. GitHub 스폰서 대체. MoR 지원.

### .env.example
```
POLAR_ACCESS_TOKEN=polar_pat_xxxxxxxxxx
POLAR_ORGANIZATION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
POLAR_WEBHOOK_SECRET=your-webhook-secret
NEXT_PUBLIC_URL=https://your-app.com
```

### 설치 + 초기화
```bash
npm install @polar-sh/sdk
```

```typescript
import { Polar } from '@polar-sh/sdk';
export const polar = new Polar({ accessToken: process.env.POLAR_ACCESS_TOKEN! });
```

### 체크아웃 + 웹훅
```typescript
// 체크아웃 세션 생성
const result = await polar.checkouts.custom.create({
  productPriceId: priceId,
  successUrl: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=true`,
  customerEmail: user.email,
  metadata: { userId: user.id },
});
return result.url;

// 웹훅 검증
import { validateEvent, WebhookVerificationError } from '@polar-sh/sdk/webhooks';

export async function POST(req: Request) {
  const body = await req.text();
  let event: ReturnType<typeof validateEvent>;
  try {
    event = validateEvent(body, req.headers, process.env.POLAR_WEBHOOK_SECRET!);
  } catch (err) {
    if (err instanceof WebhookVerificationError) {
      return NextResponse.json({ error: 'Invalid' }, { status: 403 });
    }
    // 예기치 않은 SDK 오류 — 스택 트레이스 클라이언트 노출 방지 (SEC-024)
    console.error('[polar-webhook] signature validation error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }

  const eventId = event.id;
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['polar', eventId, event.type, JSON.stringify(event.data)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    if (event.type === 'subscription.created' || event.type === 'subscription.updated') {
      const sub = event.data;

      const userId = sub.metadata?.userId;
      if (!userId || typeof userId !== 'string') {
        await client.query('ROLLBACK');
        return NextResponse.json({ error: 'Missing or invalid userId in metadata' }, { status: 400 });
      }

      await upsertSubscription({
        provider: 'polar',
        providerSubscriptionId: sub.id,
        providerPriceId: sub.productPriceId,
        userId,
        status: sub.status,
        currentPeriodStart: new Date(sub.currentPeriodStart),
        currentPeriodEnd: new Date(sub.currentPeriodEnd),
        trialEnd: null,
      }, client);
    } else if (event.type === 'subscription.canceled' || event.type === 'subscription.revoked') {
      const sub = event.data;
      await client.query(
        "UPDATE subscriptions SET status='canceled', canceled_at=now(), updated_at=now() WHERE provider_subscription_id=$1",
        [sub.id]
      );
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['polar', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[polar-webhook] processing error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  } finally {
    client.release();
  }

  return NextResponse.json({ ok: true });
}
```

---

