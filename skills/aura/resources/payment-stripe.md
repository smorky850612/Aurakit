# AuraKit — Stripe 결제 파이프라인

> PAYMENT 모드에서 Stripe 선택 시 로딩. 공통 스키마 → payment-pipeline.md 참조.

---

## Stripe

### .env.example
```
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxx
NEXT_PUBLIC_URL=https://your-app.com
```

### 설치
```bash
npm install stripe @stripe/stripe-js @stripe/react-stripe-js
```

### 초기화 (`lib/stripe.ts`)
```typescript
import Stripe from 'stripe';
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
  typescript: true,
});
```

### 체크아웃 세션 생성 (API Route)
```typescript
// POST /api/subscriptions/checkout
export async function POST(req: Request) {
  const session = await getServerSession();
  if (!session?.user?.id) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { priceId } = await req.json();

  let customerId = await getUserStripeCustomerId(session.user.id);
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: session.user.email!,
      metadata: { userId: session.user.id },
    });
    customerId = customer.id;
    await saveStripeCustomerId(session.user.id, customerId);
  }

  const checkoutSession = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_URL}/dashboard?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_URL}/pricing`,
    subscription_data: {
      trial_period_days: 14,
      metadata: { userId: session.user.id },
    },
  });

  return NextResponse.json({ url: checkoutSession.url });
}
```

### 웹훅 핸들러 (`/api/webhooks/stripe`)
```typescript
export async function POST(req: Request) {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['stripe', event.id, event.type, JSON.stringify(event.data)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;

        // metadata.userId 검증 — Stripe 대시보드에서 수동 생성된 구독은 metadata 없을 수 있음
        const userId = sub.metadata?.userId;
        if (!userId || typeof userId !== 'string') {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Missing userId in subscription metadata' }, { status: 400 });
        }

        // 구독에 item이 없는 경우 방어 (EDGE-001)
        if (!sub.items.data.length) {
          await client.query('ROLLBACK');
          return NextResponse.json({ error: 'Subscription has no items' }, { status: 400 });
        }

        await upsertSubscription({
          provider: 'stripe',
          providerSubscriptionId: sub.id,
          providerPriceId: sub.items.data[0].price.id,
          userId,
          status: sub.status,
          currentPeriodStart: new Date(sub.current_period_start * 1000),
          currentPeriodEnd: new Date(sub.current_period_end * 1000),
          trialEnd: sub.trial_end ? new Date(sub.trial_end * 1000) : null,
        }, client);
        break;
      }
      case 'customer.subscription.deleted': {
        const sub = event.data.object as Stripe.Subscription;
        await client.query(
          "UPDATE subscriptions SET status='canceled', canceled_at=now(), updated_at=now() WHERE provider_subscription_id=$1",
          [sub.id]
        );
        break;
      }
      case 'invoice.payment_succeeded': {
        // 반복 청구 성공 → past_due → active 복구 (SEC-016 추가)
        const invoice = event.data.object as Stripe.Invoice;
        // invoice.subscription은 string 또는 Subscription 객체일 수 있음 (SEC-013 수정)
        const subId = typeof invoice.subscription === 'string'
          ? invoice.subscription
          : (invoice.subscription as Stripe.Subscription | null)?.id;
        if (subId) {
          await client.query(
            "UPDATE subscriptions SET status='active', updated_at=now() WHERE provider='stripe' AND provider_subscription_id=$1",
            [subId]
          );
        }
        break;
      }
      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;
        const subId = typeof invoice.subscription === 'string'
          ? invoice.subscription
          : (invoice.subscription as Stripe.Subscription | null)?.id;
        if (subId) {
          await client.query(
            "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider='stripe' AND provider_subscription_id=$1",
            [subId]
          );
          const ownerEmail = await getSubscriptionOwnerEmail(subId);
          await sendPaymentFailedEmail(ownerEmail);
        }
        break;
      }
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['stripe', event.id]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    // re-throw 대신 구조화된 500 반환 — 스택 트레이스 클라이언트 노출 방지 (SEC-023)
    console.error('[stripe-webhook] processing error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  } finally {
    client.release();
  }

  return NextResponse.json({ ok: true });
}
```

### Billing Portal (구독 관리 UI)
```typescript
// POST /api/subscriptions/portal
export async function POST(req: Request) {
  const session = await getServerSession();
  if (!session?.user?.id) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const customerId = await getUserStripeCustomerId(session.user.id);
  if (!customerId) return NextResponse.json({ error: 'No subscription found' }, { status: 404 });

  const portal = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: `${process.env.NEXT_PUBLIC_URL}/dashboard`,
  });

  return NextResponse.json({ url: portal.url });
}
```

---

