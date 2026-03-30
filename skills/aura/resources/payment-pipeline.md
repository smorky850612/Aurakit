# AuraKit — Payment Pipeline

> `/aura payment:` 호출 시 로딩. 구독 결제 완성까지 자동.
> **기본 티어: PRO** (결제는 비즈니스 크리티컬 — Opus 모델 사용)

---

## 결제 제공자 선택 가이드

| 기준 | Stripe | LemonSqueezy | Polar | TossPayments | StepPay |
|------|--------|--------------|-------|--------------|---------|
| 대상 시장 | 글로벌 | 글로벌/SaaS | 오픈소스 | **한국** | **한국** |
| 구독 지원 | ✅ 완전 | ✅ 완전 | ✅ | ✅ 정기결제 | ✅ |
| 세금 자동 처리 | ❌ | ✅ (MoR) | ✅ (MoR) | ❌ | ❌ |
| 수수료 | 2.9%+30¢ | 5%+50¢ | 5% | 2.2~3.3% | varies |
| Billing Portal | ✅ | ✅ (API) | ✅ (API) | ❌ (직접 구현) | ❌ |
| 최소 설정 복잡도 | 보통 | **쉬움** | 쉬움 | 보통 | 보통 |
| 추천 용도 | 글로벌 SaaS | 디지털 제품 | 오픈소스 | 국내 서비스 | 한국 BNPL |

---

## 공통 파이프라인

1. **Discovery** — 구독 플랜 수 / 트라이얼 여부 / 업그레이드·다운그레이드 필요 여부 확인
2. **DB 설계** — `subscription_plans`, `subscriptions`, `webhook_events` 테이블
3. **제공자 설정** — API 키, 웹훅 엔드포인트 등록, `.env.example` 생성
4. **결제 플로우 구현** — 체크아웃 세션 → 구독 생성 → 포털
5. **웹훅 핸들러** — 서명 검증 → 원자적 멱등성 (`INSERT ON CONFLICT`) → 트랜잭션 DB 동기화
6. **접근 제어** — 미들웨어로 구독 상태 확인
7. **3중 검증** — V1 빌드 + V2 Reviewer + V3 E2E 결제 플로우 테스트

---

## 공통 DB 스키마

```sql
-- 구독 플랜 정의
CREATE TABLE subscription_plans (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(100) NOT NULL,
  provider_plan_id VARCHAR(200) NOT NULL,   -- stripe price_id, LS variant_id 등
  price_cents      INTEGER NOT NULL,
  currency         VARCHAR(3) DEFAULT 'USD',
  interval         VARCHAR(20) NOT NULL,    -- 'month' | 'year'
  features         JSONB DEFAULT '[]',
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- 사용자 구독
CREATE TABLE subscriptions (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id                  UUID NOT NULL REFERENCES subscription_plans(id),
  provider                 VARCHAR(50) NOT NULL,
  provider_subscription_id VARCHAR(200) UNIQUE NOT NULL,
  provider_customer_id     VARCHAR(200),
  status                   VARCHAR(50) NOT NULL,  -- 'active'|'past_due'|'canceled'|'trialing'|'paused'
  trial_ends_at            TIMESTAMPTZ,
  current_period_start     TIMESTAMPTZ NOT NULL,
  current_period_end       TIMESTAMPTZ NOT NULL,
  canceled_at              TIMESTAMPTZ,
  created_at               TIMESTAMPTZ DEFAULT now(),
  updated_at               TIMESTAMPTZ DEFAULT now()
);

-- 웹훅 이벤트 (멱등성 보장)
CREATE TABLE webhook_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider     VARCHAR(50) NOT NULL,
  event_id     VARCHAR(200) NOT NULL,
  event_type   VARCHAR(100) NOT NULL,
  payload      JSONB NOT NULL,
  processed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(provider, event_id)
);

CREATE INDEX idx_subscriptions_user     ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_provider ON subscriptions(provider, provider_subscription_id);
```

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

## TossPayments

> 한국 시장 표준. 카드·계좌이체·가상계좌·휴대폰·BNPL 지원.

### .env.example
```
TOSS_CLIENT_KEY=test_ck_xxxxxxxxxx
TOSS_SECRET_KEY=test_sk_xxxxxxxxxx
TOSS_WEBHOOK_SECRET=your-toss-webhook-secret
NEXT_PUBLIC_TOSS_CLIENT_KEY=test_ck_xxxxxxxxxx
NEXT_PUBLIC_URL=https://your-app.com
```

### 설치
```bash
npm install @tosspayments/tosspayments-sdk
```

### 정기결제 플로우 (빌링키 방식)

**Step 1: 카드 등록 — 빌링키 발급 요청 (Frontend)**
```typescript
import { loadTossPayments } from '@tosspayments/tosspayments-sdk';

const toss = await loadTossPayments(process.env.NEXT_PUBLIC_TOSS_CLIENT_KEY!);
await toss.requestBillingAuth({
  method: '카드',
  customerKey: user.id,
  successUrl: `${window.location.origin}/api/toss/billing-auth`,  // userId URL 노출 금지
  failUrl: `${window.location.origin}/payment-fail`,
});
```

**Step 2: 빌링키 저장 (API Route)**
```typescript
// GET /api/toss/billing-auth?authKey=...&customerKey=...
import crypto from 'crypto';

export async function GET(req: Request) {
  // customerKey는 서버 세션 기준 — URL 파라미터 변조 방지 (VULN-004 수정)
  const session = await getServerSession();
  if (!session?.user?.id) {
    return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/payment-fail`);
  }

  const { searchParams } = new URL(req.url);
  const authKey = searchParams.get('authKey');

  // authKey 포맷 검증 (SEC-019 수정: 빈 값·CSRF 방지)
  if (!authKey || !/^[a-zA-Z0-9_-]+$/.test(authKey)) {
    return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/payment-fail`);
  }

  const customerKey = session.user.id;  // URL param 무시

  const response = await fetch('https://api.tosspayments.com/v1/billing/authorizations/issue', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(process.env.TOSS_SECRET_KEY! + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ authKey, customerKey }),
  });

  if (!response.ok) {
    return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/payment-fail`);
  }

  const { billingKey } = await response.json();
  await saveBillingKey(customerKey, billingKey);  // AES-256 또는 KMS 암호화 필수

  return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/dashboard`);
}
```

**Step 3: 정기 결제 실행 (서버 배치 또는 요청 시)**
```typescript
import crypto from 'crypto';

export async function chargeSubscription(userId: string, planId: string) {
  // 빌링키 null 체크 — 카드 미등록 방어 (EDGE-006 수정)
  const encryptedBillingKey = await getBillingKey(userId);
  if (!encryptedBillingKey) throw new Error('BILLING_KEY_NOT_FOUND');
  const billingKey = await decryptBillingKey(encryptedBillingKey);  // 복호화 필수 (SEC-020)

  // 서버에서 실제 플랜 금액 조회 — 클라이언트 전달 금액 절대 신뢰 금지 (VULN-005 수정)
  const planResult = await db.query<{ price_cents: number; name: string }>(
    'SELECT price_cents, name FROM subscription_plans WHERE id = $1 AND is_active = true',
    [planId]
  );
  if (!planResult.rows.length) throw new Error('PLAN_NOT_FOUND');
  const amountKRW = planResult.rows[0].price_cents;
  const orderName = planResult.rows[0].name;

  const response = await fetch(`https://api.tosspayments.com/v1/billing/${billingKey}`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(process.env.TOSS_SECRET_KEY! + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      customerKey: userId,
      amount: amountKRW,
      orderId: `order_${crypto.randomUUID()}`,  // Date.now() 충돌 방지 (VULN-010 수정)
      orderName,
      customerEmail: await getUserEmail(userId),
    }),
  });

  if (!response.ok) throw new Error('PAYMENT_FAILED');  // 내부 메시지 노출 금지 (VULN-011)
  return await response.json();  // { paymentKey, orderId, status: 'DONE' }
}
```

### 웹훅 핸들러 (`/api/webhooks/tosspayments`) — GAP-011 수정: 완전 신규 추가
```typescript
import crypto from 'crypto';

// ⚠️ TossPayments 웹훅 시그니처 헤더명은 콘솔에서 확인 필요
// 일반적으로 'webhook-signature' 또는 'toss-signature' 사용
export async function POST(req: Request) {
  const body = await req.text();
  const sig  = req.headers.get('webhook-signature') ?? '';

  const expected    = crypto.createHmac('sha256', process.env.TOSS_WEBHOOK_SECRET!).update(body).digest('hex');
  const expectedBuf = Buffer.from(expected, 'hex');
  const sigBuf      = Buffer.from(sig, 'hex');

  if (sigBuf.length === 0 || sigBuf.length !== expectedBuf.length ||
      !crypto.timingSafeEqual(expectedBuf, sigBuf)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);
  // TossPayments 웹훅 구조: { eventType, eventId?, data: { orderId?, paymentKey?, status, ... } }
  const eventId = payload.eventId
    || `${payload.data?.paymentKey ?? payload.data?.orderId}_${payload.eventType}`;

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['toss', eventId, payload.eventType, JSON.stringify(payload)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    switch (payload.eventType) {
      case 'PAYMENT_STATUS_CHANGED': {
        const { orderId, status } = payload.data;
        if (status === 'DONE') {
          await client.query(
            "UPDATE subscriptions SET status='active', updated_at=now() WHERE provider='toss' AND provider_subscription_id=$1",
            [orderId]
          );
        } else if (status === 'CANCELED' || status === 'ABORTED') {
          await client.query(
            "UPDATE subscriptions SET status='canceled', canceled_at=now(), updated_at=now() WHERE provider='toss' AND provider_subscription_id=$1",
            [orderId]
          );
        }
        break;
      }
      case 'BILLING_STATUS_CHANGED': {
        // 빌링키 무효화 (카드 만료·한도 초과)
        const { customerKey, status } = payload.data;
        if (status === 'INVALID') {
          await client.query(
            "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider='toss' AND provider_subscription_id=$1",
            [customerKey]
          );
        }
        break;
      }
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['toss', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[tosspayments-webhook] processing error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  } finally {
    client.release();
  }

  return NextResponse.json({ ok: true });
}
```

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

## 공통 패턴

### 구독 접근 제어 미들웨어
```typescript
// lib/subscription.ts
// 'paused' 포함 — LemonSqueezy 일시정지 사용자 차단 방지 (GAP-009 수정)
export async function requireSubscription(userId: string, requiredPlan?: string) {
  const result = await db.query<{ status: string; plan_name: string }>(
    `SELECT s.status, p.name AS plan_name
     FROM subscriptions s JOIN subscription_plans p ON s.plan_id = p.id
     WHERE s.user_id = $1 AND s.status IN ('active', 'trialing', 'paused')
     ORDER BY s.created_at DESC LIMIT 1`,
    [userId]
  );

  if (!result.rows.length) throw new Error('SUBSCRIPTION_REQUIRED');
  if (requiredPlan && result.rows[0].plan_name !== requiredPlan) {
    throw new Error('PLAN_UPGRADE_REQUIRED');
  }
  return result.rows[0];
}
```

### 플랜 변경 — Stripe 업그레이드/다운그레이드
```typescript
// ℹ️ LemonSqueezy: updateSubscription() 사용 | Polar: subscription update API 사용
// ℹ️ TossPayments/StepPay: 플랜 변경 시 새 결제 흐름 필요 (mid-cycle 변경 미지원)
export async function changePlan(stripeSubscriptionId: string, newPriceId: string) {
  const sub = await stripe.subscriptions.retrieve(stripeSubscriptionId);

  await stripe.subscriptions.update(stripeSubscriptionId, {
    items: [{ id: sub.items.data[0].id, price: newPriceId }],
    proration_behavior: 'create_prorations',
  });
}
```

### upsertSubscription 공통 헬퍼
```typescript
import { PoolClient } from 'pg';

interface SubscriptionData {
  provider: string;
  providerSubscriptionId: string;
  providerPriceId: string;          // subscription_plans.provider_plan_id 매핑용
  userId: string;
  status: string;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  trialEnd: Date | null;
}

export async function upsertSubscription(data: SubscriptionData, client?: PoolClient) {
  const db_ = client ?? db;

  // userId 기본 검증 (SEC-025 수정)
  if (!data.userId || typeof data.userId !== 'string' || !data.userId.trim()) {
    throw new Error('Invalid userId: must be non-empty string');
  }

  // providerPriceId → plan_id 조회 (VULN-008 수정)
  // 플랜 미존재는 설정 오류 — 500 throw 대신 명시적 에러로 호출자가 처리
  const planResult = await db_.query<{ id: string }>(
    'SELECT id FROM subscription_plans WHERE provider_plan_id = $1 AND is_active = true',
    [data.providerPriceId]
  );
  if (!planResult.rows.length) {
    throw new Error(`PLAN_NOT_FOUND:${data.providerPriceId}`);
  }
  const planId = planResult.rows[0].id;

  await db_.query(
    `INSERT INTO subscriptions
       (provider, provider_subscription_id, user_id, plan_id, status,
        current_period_start, current_period_end, trial_ends_at, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,now())
     ON CONFLICT (provider_subscription_id)
     DO UPDATE SET
       plan_id=$4, status=$5, current_period_start=$6, current_period_end=$7,
       trial_ends_at=$8, updated_at=now()`,
    [
      data.provider, data.providerSubscriptionId, data.userId, planId, data.status,
      data.currentPeriodStart, data.currentPeriodEnd, data.trialEnd,
    ]
  );
}
```

> **⚠️ PLAN_NOT_FOUND 처리 전략**: 플랜이 존재하지 않는 경우 (잘못된 설정 또는 삭제된 플랜)
> 웹훅 핸들러에서 이 에러를 catch하여:
> - **500** → 제공자가 재시도 (DB 일시 장애 등 transient 오류)
> - **200 OK + 로그** → 재시도 없음 (플랜 설정 오류 등 permanent 오류)
>
> 현재 구현: 500 반환 (catch → `return NextResponse.json({error:'Internal error'},{status:500})`)
> 프로덕션 권장: PLAN_NOT_FOUND는 200 OK로 처리하고 알림 발송

---

## 보안 체크리스트

### 웹훅 보안 (Critical)
- [ ] 서명 검증 필수 (`constructEvent` / HMAC-SHA256) — 모든 제공자
- [ ] HMAC 비교: 명시적 hex 버퍼 (`Buffer.from(x, 'hex')`) + `timingSafeEqual` + 길이 0 체크
- [ ] **Raw body 보존**: `req.text()` → 서명 검증 → `JSON.parse()` 순서 엄수
- [ ] **TOCTOU 방지**: `INSERT ON CONFLICT DO NOTHING` + `rowCount === 0` 조기 리턴
- [ ] **원자성**: 웹훅 이벤트 INSERT + 구독 upsert = 단일 트랜잭션
- [ ] 에러 핸들링: `throw err` 대신 `NextResponse.json({error:'Internal error'},{status:500})` 반환

### 결제 데이터 보안 (Critical)
- [ ] 금액 서버 검증: 클라이언트 전달 금액 신뢰 금지 → DB `price_cents` 조회
- [ ] 결제 완료 확인: 웹훅으로만 확인 (`success_url` 리다이렉트 신뢰 금지)
- [ ] TossPayments `customerKey`: URL 파라미터 대신 `session.user.id` 사용
- [ ] TossPayments 빌링키: AES-256 또는 KMS 암호화 저장 + 사용 전 복호화
- [ ] TossPayments `orderId`: `crypto.randomUUID()` 사용 (`Date.now()` 충돌 가능)
- [ ] TossPayments `authKey`: 포맷 검증 (`/^[a-zA-Z0-9_-]+$/`) 필수

### 입력 검증 (High)
- [ ] Stripe/LemonSqueezy: `metadata.userId` / `custom_data.user_id` null 체크 후 사용
- [ ] Stripe: `sub.items.data.length > 0` 확인 후 `data[0]` 접근
- [ ] Stripe: `invoice.subscription` 타입 체크 (`typeof === 'string'` 조건 분기)
- [ ] LemonSqueezy: `renews_at ?? ends_at` 둘 다 null이면 400 반환
- [ ] StepPay: `eventId` 또는 `(subscriptionId + type + timestamp)` 모두 있어야 처리
- [ ] StepPay: `nextBillingDate` null 검증
- [ ] TossPayments: `getBillingKey()` null 체크 후 API 호출

### 인증 / API 보안 (High)
- [ ] 보호 라우트 전체: `session?.user?.id` null 체크 + 401 반환
- [ ] `upsertSubscription`: userId 비어있으면 throw
- [ ] 에러 응답: 결제 API 내부 메시지 클라이언트 노출 금지

### DB / 스키마 보안 (High)
- [ ] `upsertSubscription`에 `providerPriceId` → `subscription_plans` 조회 (plan_id NOT NULL 보장)
- [ ] `webhook_events.UNIQUE(provider, event_id)` 인덱스 확인
- [ ] `requireSubscription`: `'paused'` 상태 포함 여부 비즈니스 정책 결정

### 운영 보안 (Medium)
- [ ] 웹훅 엔드포인트 Rate Limiting 권장 (Upstash Ratelimit 등) — DoS 방어
- [ ] `PLAN_NOT_FOUND` 오류: 200 OK + 운영 알림 전략 결정
- [ ] `.env.example`에 `NEXT_PUBLIC_URL` 포함 — 모든 제공자 공통 필수
- [ ] `.env`는 `.gitignore` 등록 확인, `.env.example`은 커밋 권장

---

## 커맨드 예시

```bash
/aura payment: Stripe 구독 기능 추가해줘
/aura payment: LemonSqueezy로 월간/연간 플랜 구현해줘
/aura payment: TossPayments 정기결제 빌링키 방식 구현
/aura payment: Stripe + 업그레이드/다운그레이드 + 프로레이션 처리
/aura pro payment: Polar 오픈소스 구독 + 스폰서 플랜
/aura max payment: 멀티 제공자 (Stripe + TossPayments) 구독 아키텍처
```
