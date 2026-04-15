# AuraKit — StepPay 결제 파이프라인

> PAYMENT 모드에서 StepPay 선택 시 로딩. 공통 스키마 → payment-pipeline.md 참조.

---

## StepPay

> 한국 BNPL/후불결제. 무이자 할부, 소상공인 타겟.

### .env.example
```
STEPPAY_SECRET_KEY=your-steppay-secret-key
STEPPAY_STORE_ID=your-store-id
NEXT_PUBLIC_URL=https://your-app.com
```

### 구독 주문 생성
```typescript
const response = await fetch('https://api.steppay.kr/api/v1/orders', {
  method: 'POST',
  headers: {
    'Secret-Token': process.env.STEPPAY_SECRET_KEY!,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    customerId: user.steppayCustomerId,
    items: [{ priceId: planPriceId, quantity: 1 }],
    successUrl: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=true`,
    cancelUrl: `${process.env.NEXT_PUBLIC_URL}/pricing`,
  }),
});

const { orderUid, url } = await response.json();
// url로 redirect → 결제 페이지
```

### 웹훅 핸들러 (`/api/webhooks/steppay`)
```typescript
import crypto from 'crypto';

export async function POST(req: Request) {
  const body = await req.text();
  const sig      = req.headers.get('x-steppay-signature') ?? '';
  const expected = crypto.createHmac('sha256', process.env.STEPPAY_SECRET_KEY!).update(body).digest('hex');

  // 명시적 hex 버퍼 비교 — timingSafeEqual 길이 오류 방지
  const expectedBuf = Buffer.from(expected, 'hex');
  const sigBuf      = Buffer.from(sig, 'hex');
  if (sigBuf.length === 0 || sigBuf.length !== expectedBuf.length ||
      !crypto.timingSafeEqual(expectedBuf, sigBuf)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);

  // eventId 결정 — timestamp 없으면 에러로 차단 (SEC-022 수정: 빈 timestamp로 인한 idempotency 파괴 방지)
  let eventId: string;
  if (payload.eventId) {
    eventId = String(payload.eventId);
  } else if (payload.subscriptionId && payload.type && payload.timestamp) {
    eventId = `${payload.subscriptionId}_${payload.type}_${payload.timestamp}`;
  } else {
    return NextResponse.json({ error: 'Cannot derive stable event ID' }, { status: 400 });
  }

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['steppay', eventId, payload.type, JSON.stringify(payload)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    switch (payload.type) {
      case 'subscription.active': {
        // nextBillingDate null 방어 (EDGE-005 수정)
        if (!payload.nextBillingDate) {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Missing nextBillingDate' }, { status: 400 });
        }
        await upsertSubscription({
          provider: 'steppay',
          providerSubscriptionId: payload.subscriptionId,
          providerPriceId: String(payload.priceId),
          userId: payload.customerId,
          status: 'active',
          currentPeriodStart: new Date(payload.startDate),
          currentPeriodEnd: new Date(payload.nextBillingDate),
          trialEnd: null,
        }, client);
        break;
      }
      case 'subscription.updated': {
        if (!payload.nextBillingDate) {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Missing nextBillingDate' }, { status: 400 });
        }
        await client.query(
          "UPDATE subscriptions SET status=$1, current_period_end=$2, updated_at=now() WHERE provider_subscription_id=$3",
          [payload.status ?? 'active', new Date(payload.nextBillingDate), payload.subscriptionId]
        );
        break;
      }
      case 'subscription.canceled':
        await client.query(
          "UPDATE subscriptions SET status='canceled', canceled_at=now(), updated_at=now() WHERE provider_subscription_id=$1",
          [payload.subscriptionId]
        );
        break;
      case 'subscription.payment_failed':
        await client.query(
          "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider_subscription_id=$1",
          [payload.subscriptionId]
        );
        break;
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['steppay', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[steppay-webhook] processing error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  } finally {
    client.release();
  }

  return NextResponse.json({ ok: true });
}
```

---

