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
| Billing Portal | ✅ | ✅ | ✅ | ❌ (직접 구현) | ❌ |
| 최소 설정 복잡도 | 보통 | **쉬움** | 쉬움 | 보통 | 보통 |
| 추천 용도 | 글로벌 SaaS | 디지털 제품 | 오픈소스 | 국내 서비스 | 한국 BNPL |

---

## 공통 파이프라인

1. **Discovery** — 구독 플랜 수 / 트라이얼 여부 / 업그레이드·다운그레이드 필요 여부 확인
2. **DB 설계** — `subscription_plans`, `subscriptions`, `webhook_events` 테이블
3. **제공자 설정** — API 키, 웹훅 엔드포인트 등록, `.env.example` 생성
4. **결제 플로우 구현** — 체크아웃 세션 → 구독 생성 → 포털
5. **웹훅 핸들러** — 서명 검증 → 멱등성 체크 → DB 동기화
6. **접근 제어** — 미들웨어로 구독 상태 확인
7. **3중 검증** — V1 빌드 + V2 Reviewer + V3 E2E 결제 플로우 테스트

---

## 공통 DB 스키마

```sql
-- 구독 플랜 정의
CREATE TABLE subscription_plans (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(100) NOT NULL,
  provider_plan_id VARCHAR(200) NOT NULL,   -- stripe price_id, LS variant_id 등
  price_cents   INTEGER NOT NULL,
  currency      VARCHAR(3) DEFAULT 'USD',
  interval      VARCHAR(20) NOT NULL,       -- 'month' | 'year'
  features      JSONB DEFAULT '[]',
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- 사용자 구독
CREATE TABLE subscriptions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id                UUID NOT NULL REFERENCES subscription_plans(id),
  provider               VARCHAR(50) NOT NULL,  -- 'stripe'|'lemonsqueezy'|'polar'|'toss'|'steppay'
  provider_subscription_id VARCHAR(200) UNIQUE NOT NULL,
  provider_customer_id   VARCHAR(200),
  status                 VARCHAR(50) NOT NULL,  -- 'active'|'past_due'|'canceled'|'trialing'|'paused'
  trial_ends_at          TIMESTAMPTZ,
  current_period_start   TIMESTAMPTZ NOT NULL,
  current_period_end     TIMESTAMPTZ NOT NULL,
  canceled_at            TIMESTAMPTZ,
  created_at             TIMESTAMPTZ DEFAULT now(),
  updated_at             TIMESTAMPTZ DEFAULT now()
);

-- 웹훅 이벤트 (멱등성 보장)
CREATE TABLE webhook_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider    VARCHAR(50) NOT NULL,
  event_id    VARCHAR(200) NOT NULL,  -- provider 이벤트 ID
  event_type  VARCHAR(100) NOT NULL,
  payload     JSONB NOT NULL,
  processed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(provider, event_id)         -- 중복 처리 완전 차단
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id, status);
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
      trial_period_days: 14,  // 트라이얼 (필요 시 제거)
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

  // 멱등성 보장
  const existing = await db.query(
    'SELECT id FROM webhook_events WHERE provider=$1 AND event_id=$2',
    ['stripe', event.id]
  );
  if (existing.rows.length > 0) return NextResponse.json({ ok: true });

  await db.query(
    'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4)',
    ['stripe', event.id, event.type, JSON.stringify(event.data)]
  );

  switch (event.type) {
    case 'customer.subscription.created':
    case 'customer.subscription.updated': {
      const sub = event.data.object as Stripe.Subscription;
      await upsertSubscription({
        provider: 'stripe',
        providerSubscriptionId: sub.id,
        userId: sub.metadata.userId,
        status: sub.status,
        currentPeriodStart: new Date(sub.current_period_start * 1000),
        currentPeriodEnd: new Date(sub.current_period_end * 1000),
        trialEnd: sub.trial_end ? new Date(sub.trial_end * 1000) : null,
      });
      break;
    }
    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription;
      await cancelSubscription('stripe', sub.id);
      break;
    }
    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice;
      await handlePaymentFailed(invoice.subscription as string);
      break;
    }
  }

  await db.query(
    'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
    ['stripe', event.id]
  );
  return NextResponse.json({ ok: true });
}
```

### Billing Portal (구독 관리 UI)
```typescript
// POST /api/subscriptions/portal
export async function POST(req: Request) {
  const session = await getServerSession();
  const customerId = await getUserStripeCustomerId(session!.user.id);

  const portal = await stripe.billingPortal.sessions.create({
    customer: customerId!,
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
  variantId,  // LemonSqueezy Variant ID
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
  const sig = req.headers.get('x-signature')!;
  const hmac = crypto
    .createHmac('sha256', process.env.LEMONSQUEEZY_WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');

  if (!crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(sig))) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);
  const eventName: string = payload.meta.event_name;
  const sub = payload.data.attributes;
  const eventId = String(payload.meta.event_id || payload.data.id + '_' + eventName);

  // 멱등성 보장
  const existing = await db.query(
    'SELECT id FROM webhook_events WHERE provider=$1 AND event_id=$2',
    ['lemonsqueezy', eventId]
  );
  if (existing.rows.length > 0) return NextResponse.json({ ok: true });

  await db.query(
    'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4)',
    ['lemonsqueezy', eventId, eventName, JSON.stringify(payload)]
  );

  switch (eventName) {
    case 'subscription_created':
    case 'subscription_updated':
      await upsertSubscription({
        provider: 'lemonsqueezy',
        providerSubscriptionId: String(payload.data.id),
        userId: payload.meta.custom_data?.user_id,
        status: sub.status,  // 'active'|'paused'|'cancelled'|'expired'|'past_due'
        currentPeriodStart: new Date(sub.updated_at),
        currentPeriodEnd: new Date(sub.renews_at || sub.ends_at),
        trialEnd: sub.trial_ends_at ? new Date(sub.trial_ends_at) : null,
      });
      break;
    case 'subscription_cancelled':
    case 'subscription_expired':
      await cancelSubscription('lemonsqueezy', String(payload.data.id));
      break;
  }

  await db.query(
    'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
    ['lemonsqueezy', eventId]
  );
  return NextResponse.json({ ok: true });
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
  try {
    const event = validateEvent(body, req.headers, process.env.POLAR_WEBHOOK_SECRET!);
    const eventId = event.id;

    const existing = await db.query(
      'SELECT id FROM webhook_events WHERE provider=$1 AND event_id=$2',
      ['polar', eventId]
    );
    if (existing.rows.length > 0) return NextResponse.json({ ok: true });

    if (event.type === 'subscription.created' || event.type === 'subscription.updated') {
      const sub = event.data;
      await upsertSubscription({
        provider: 'polar',
        providerSubscriptionId: sub.id,
        userId: String(sub.metadata?.userId),
        status: sub.status,
        currentPeriodStart: new Date(sub.currentPeriodStart),
        currentPeriodEnd: new Date(sub.currentPeriodEnd),
        trialEnd: null,
      });
    }
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof WebhookVerificationError) {
      return NextResponse.json({ error: 'Invalid' }, { status: 403 });
    }
    throw err;
  }
}
```

---

## TossPayments

> 한국 시장 표준. 카드·계좌이체·가상계좌·휴대폰·BNPL 지원.

### .env.example
```
TOSS_CLIENT_KEY=test_ck_xxxxxxxxxx
TOSS_SECRET_KEY=test_sk_xxxxxxxxxx
NEXT_PUBLIC_TOSS_CLIENT_KEY=test_ck_xxxxxxxxxx
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
  successUrl: `${window.location.origin}/api/toss/billing-auth?userId=${user.id}`,
  failUrl: `${window.location.origin}/payment-fail`,
});
```

**Step 2: 빌링키 저장 (API Route)**
```typescript
// GET /api/toss/billing-auth?authKey=...&customerKey=...
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const authKey = searchParams.get('authKey')!;
  const customerKey = searchParams.get('customerKey')!;

  const response = await fetch('https://api.tosspayments.com/v1/billing/authorizations/issue', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(process.env.TOSS_SECRET_KEY! + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ authKey, customerKey }),
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.message);
  }

  const { billingKey } = await response.json();
  await saveBillingKey(customerKey, billingKey);  // DB 암호화 저장 권장

  return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/dashboard`);
}
```

**Step 3: 정기 결제 실행 (서버 배치 또는 요청 시)**
```typescript
export async function chargeSubscription(userId: string, amountKRW: number) {
  const billingKey = await getBillingKey(userId);

  const response = await fetch(`https://api.tosspayments.com/v1/billing/${billingKey}`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(process.env.TOSS_SECRET_KEY! + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      customerKey: userId,
      amount: amountKRW,
      orderId: `order_${Date.now()}_${userId.slice(0, 8)}`,
      orderName: '월간 구독',
      customerEmail: await getUserEmail(userId),
    }),
  });

  const result = await response.json();
  if (!response.ok) throw new Error(result.message);
  return result;  // { paymentKey, orderId, status: 'DONE' }
}
```

---

## StepPay

> 한국 BNPL/후불결제. 무이자 할부, 소상공인 타겟.

### .env.example
```
STEPPAY_SECRET_KEY=your-steppay-secret-key
STEPPAY_STORE_ID=your-store-id
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
export async function POST(req: Request) {
  const payload = await req.json();
  // StepPay는 HMAC-SHA256 서명 헤더 사용
  const sig = req.headers.get('x-steppay-signature')!;
  const expected = crypto
    .createHmac('sha256', process.env.STEPPAY_SECRET_KEY!)
    .update(JSON.stringify(payload))
    .digest('hex');

  if (sig !== expected) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  if (payload.type === 'subscription.active') {
    await upsertSubscription({
      provider: 'steppay',
      providerSubscriptionId: payload.subscriptionId,
      userId: payload.customerId,
      status: 'active',
      currentPeriodStart: new Date(payload.startDate),
      currentPeriodEnd: new Date(payload.nextBillingDate),
      trialEnd: null,
    });
  }

  return NextResponse.json({ ok: true });
}
```

---

## 공통 패턴

### 구독 접근 제어 미들웨어
```typescript
// lib/subscription.ts
export async function requireSubscription(userId: string, requiredPlan?: string) {
  const result = await db.query<{ status: string; plan_name: string }>(
    `SELECT s.status, p.name AS plan_name
     FROM subscriptions s JOIN subscription_plans p ON s.plan_id = p.id
     WHERE s.user_id = $1 AND s.status IN ('active', 'trialing')
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
export async function changePlan(stripeSubscriptionId: string, newPriceId: string) {
  const sub = await stripe.subscriptions.retrieve(stripeSubscriptionId);

  await stripe.subscriptions.update(stripeSubscriptionId, {
    items: [{ id: sub.items.data[0].id, price: newPriceId }],
    proration_behavior: 'create_prorations',  // 일할 계산 자동
  });
}
```

### 던닝 (결제 실패 → 상태 업데이트 + 이메일)
```typescript
export async function handlePaymentFailed(providerSubscriptionId: string) {
  await db.query(
    "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider_subscription_id=$1",
    [providerSubscriptionId]
  );
  const ownerEmail = await getSubscriptionOwnerEmail(providerSubscriptionId);
  await sendPaymentFailedEmail(ownerEmail);  // 이메일 서비스 연동
}
```

### upsertSubscription 공통 헬퍼
```typescript
interface SubscriptionData {
  provider: string;
  providerSubscriptionId: string;
  userId: string;
  status: string;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  trialEnd: Date | null;
}

export async function upsertSubscription(data: SubscriptionData) {
  await db.query(
    `INSERT INTO subscriptions
       (provider, provider_subscription_id, user_id, status,
        current_period_start, current_period_end, trial_ends_at, updated_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7,now())
     ON CONFLICT (provider_subscription_id)
     DO UPDATE SET
       status=$4, current_period_start=$5, current_period_end=$6,
       trial_ends_at=$7, updated_at=now()`,
    [
      data.provider, data.providerSubscriptionId, data.userId, data.status,
      data.currentPeriodStart, data.currentPeriodEnd, data.trialEnd,
    ]
  );
}
```

---

## 보안 체크리스트

- [ ] 웹훅 서명 검증 (`stripe.webhooks.constructEvent` / HMAC)
- [ ] 웹훅 멱등성 보장 (`webhook_events` 테이블에 `event_id` UNIQUE)
- [ ] 클라이언트가 금액·플랜 직접 전달 금지 (서버에서 DB로 검증)
- [ ] 결제 완료는 웹훅으로만 확인 (`success_url` 리다이렉트만으로 충분하지 않음)
- [ ] TossPayments 빌링키 암호화 저장 (`AES-256` 또는 KMS)
- [ ] API 키 서버 전용 (`NEXT_PUBLIC_` 접두사는 Public Key만)
- [ ] `.env.example`을 커밋해 팀 설정 문서화 (실제 `.env`는 gitignore)

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
