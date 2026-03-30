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
5. **웹훅 핸들러** — 서명 검증 → 원자적 멱등성 체크 → 트랜잭션 내 DB 동기화
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

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // 멱등성 + 원자성: INSERT ON CONFLICT DO NOTHING으로 TOCTOU 레이스 컨디션 방지
    // SELECT → INSERT 패턴 대신 단일 원자 연산으로 중복 처리 완전 차단
    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['stripe', event.id, event.type, JSON.stringify(event.data)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true }); // 이미 처리된 이벤트
    }

    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        await upsertSubscription({
          provider: 'stripe',
          providerSubscriptionId: sub.id,
          providerPriceId: sub.items.data[0].price.id,
          userId: sub.metadata.userId,
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
      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice;
        await client.query(
          "UPDATE subscriptions SET status='past_due', updated_at=now() WHERE provider_subscription_id=$1",
          [invoice.subscription as string]
        );
        const ownerEmail = await getSubscriptionOwnerEmail(invoice.subscription as string);
        await sendPaymentFailedEmail(ownerEmail);
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
    throw err;
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
  // non-null assertion(!) 대신 명시적 401 가드 (VULN-009 수정)
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

  // 길이 불일치 시 timingSafeEqual은 throw — 사전 체크 필수
  if (hmac.length !== sig.length || !crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(sig))) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);
  const eventName: string = payload.meta.event_name;
  const sub = payload.data.attributes;
  const eventId = String(payload.meta.event_id || payload.data.id + '_' + eventName);

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // 멱등성 + 원자성: TOCTOU 레이스 컨디션 방지
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
      case 'subscription_updated':
        await upsertSubscription({
          provider: 'lemonsqueezy',
          providerSubscriptionId: String(payload.data.id),
          providerPriceId: String(sub.variant_id),  // LS variant_id → subscription_plans 매핑
          userId: payload.meta.custom_data?.user_id,
          status: sub.status,  // 'active'|'paused'|'cancelled'|'expired'|'past_due'
          currentPeriodStart: new Date(sub.updated_at),
          currentPeriodEnd: new Date(sub.renews_at || sub.ends_at),
          trialEnd: sub.trial_ends_at ? new Date(sub.trial_ends_at) : null,
        }, client);
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
    throw err;
  } finally {
    client.release();
  }

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
  let event: ReturnType<typeof validateEvent>;
  try {
    event = validateEvent(body, req.headers, process.env.POLAR_WEBHOOK_SECRET!);
  } catch (err) {
    if (err instanceof WebhookVerificationError) {
      return NextResponse.json({ error: 'Invalid' }, { status: 403 });
    }
    throw err;
  }

  const eventId = event.id;
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // 멱등성 + 원자성: TOCTOU 방지 + 누락된 webhook_events INSERT 추가 (VULN-006 수정)
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

      // metadata.userId 검증 — undefined면 "undefined" 문자열로 저장되는 버그 방지 (VULN-007 수정)
      const userId = sub.metadata?.userId;
      if (!userId || typeof userId !== 'string') {
        await client.query('ROLLBACK');
        return NextResponse.json({ error: 'Missing or invalid userId in metadata' }, { status: 400 });
      }

      await upsertSubscription({
        provider: 'polar',
        providerSubscriptionId: sub.id,
        providerPriceId: sub.productPriceId,  // Polar product price ID
        userId,
        status: sub.status,
        currentPeriodStart: new Date(sub.currentPeriodStart),
        currentPeriodEnd: new Date(sub.currentPeriodEnd),
        trialEnd: null,
      }, client);
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['polar', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
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
  customerKey: user.id,  // 서버 세션 userId와 동일 — URL에 userId 파라미터 노출 금지
  successUrl: `${window.location.origin}/api/toss/billing-auth`,
  failUrl: `${window.location.origin}/payment-fail`,
});
```

**Step 2: 빌링키 저장 (API Route)**
```typescript
// GET /api/toss/billing-auth?authKey=...&customerKey=...
export async function GET(req: Request) {
  // customerKey는 서버 세션에서만 가져옴 — URL 파라미터 변조 방지 (VULN-004 수정)
  const session = await getServerSession();
  if (!session?.user?.id) {
    return NextResponse.redirect(`${process.env.NEXT_PUBLIC_URL}/payment-fail`);
  }

  const { searchParams } = new URL(req.url);
  const authKey = searchParams.get('authKey')!;
  const customerKey = session.user.id;  // URL param customerKey 무시, 세션 기준

  const response = await fetch('https://api.tosspayments.com/v1/billing/authorizations/issue', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(process.env.TOSS_SECRET_KEY! + ':').toString('base64')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ authKey, customerKey }),
  });

  if (!response.ok) {
    // 내부 Toss 오류 메시지 클라이언트 노출 금지 (VULN-011 수정)
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

// amountKRW 파라미터 제거 — 서버에서 DB 조회 (클라이언트 전달 금액 절대 신뢰 금지)
export async function chargeSubscription(userId: string, planId: string) {
  const billingKey = await getBillingKey(userId);

  // VULN-005 수정: 서버에서 실제 플랜 금액 조회
  const planResult = await db.query<{ price_cents: number; name: string }>(
    'SELECT price_cents, name FROM subscription_plans WHERE id = $1 AND is_active = true',
    [planId]
  );
  if (!planResult.rows.length) throw new Error('PLAN_NOT_FOUND');
  const amountKRW = planResult.rows[0].price_cents;  // KRW: 원 단위 (cents 없음)
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
      orderId: `order_${crypto.randomUUID()}`,  // VULN-010 수정: Date.now() 충돌 → randomUUID
      orderName,
      customerEmail: await getUserEmail(userId),
    }),
  });

  if (!response.ok) throw new Error('PAYMENT_FAILED');  // VULN-011 수정: 내부 메시지 노출 금지
  return await response.json();  // { paymentKey, orderId, status: 'DONE' }
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
import crypto from 'crypto';

export async function POST(req: Request) {
  // VULN-003 수정: req.text()로 원본 바이트 보존 후 HMAC 계산, 이후 JSON 파싱
  // req.json() 선파싱 → JSON.stringify() 패턴은 원본 바이트와 불일치 위험
  const body = await req.text();
  const sig = req.headers.get('x-steppay-signature')!;
  const expected = crypto
    .createHmac('sha256', process.env.STEPPAY_SECRET_KEY!)
    .update(body)
    .digest('hex');

  // 길이 불일치 시 timingSafeEqual throw 방지 + 타이밍 공격 방지
  if (expected.length !== sig.length || !crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(sig))) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const payload = JSON.parse(body);
  // StepPay eventId — provider 문서에 따라 조정 (고유성 보장 필요)
  const eventId = String(
    payload.eventId || `${payload.subscriptionId}_${payload.type}_${payload.timestamp || ''}`
  );

  const client = await db.connect();
  try {
    await client.query('BEGIN');

    // VULN-012 수정: 멱등성 + 원자성 추가 (기존에 없었음)
    const inserted = await client.query(
      'INSERT INTO webhook_events (provider, event_id, event_type, payload) VALUES ($1,$2,$3,$4) ON CONFLICT (provider, event_id) DO NOTHING',
      ['steppay', eventId, payload.type, JSON.stringify(payload)]
    );
    if (inserted.rowCount === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ ok: true });
    }

    if (payload.type === 'subscription.active') {
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
    }

    await client.query(
      'UPDATE webhook_events SET processed_at=now() WHERE provider=$1 AND event_id=$2',
      ['steppay', eventId]
    );
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
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

### upsertSubscription 공통 헬퍼
```typescript
import { PoolClient } from 'pg';

interface SubscriptionData {
  provider: string;
  providerSubscriptionId: string;
  providerPriceId: string;          // subscription_plans.provider_plan_id 매핑용 (VULN-008 수정)
  userId: string;
  status: string;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  trialEnd: Date | null;
}

// VULN-008 수정: plan_id NOT NULL 제약 위반 방지
// providerPriceId → subscription_plans 조회 → plan_id 확보 후 INSERT
export async function upsertSubscription(data: SubscriptionData, client?: PoolClient) {
  const db_ = client ?? db;

  const planResult = await db_.query<{ id: string }>(
    'SELECT id FROM subscription_plans WHERE provider_plan_id = $1 AND is_active = true',
    [data.providerPriceId]
  );
  if (!planResult.rows.length) {
    throw new Error(`Plan not found for provider_plan_id: ${data.providerPriceId}`);
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

---

## 보안 체크리스트

### 웹훅 보안 (Critical)
- [ ] 서명 검증 필수 (`stripe.webhooks.constructEvent` / HMAC-SHA256) — 미검증 시 가짜 이벤트 주입 가능
- [ ] 서명 비교 → `crypto.timingSafeEqual()` 사용 (타이밍 공격 방지) + 길이 일치 사전 확인
- [ ] **Raw body 보존**: `req.text()` 먼저 읽고 이후 `JSON.parse()` — `req.json()` 선파싱 후 재직렬화하면 서명 불일치
- [ ] **TOCTOU 방지**: `SELECT → INSERT` 대신 `INSERT ON CONFLICT DO NOTHING` + `rowCount === 0` 조기 리턴
- [ ] **원자성**: 웹훅 이벤트 INSERT와 구독 upsert를 단일 DB 트랜잭션으로 묶기 — 중간 크래시 시 불일치 방지

### 결제 데이터 보안 (Critical)
- [ ] **금액 서버 검증**: 클라이언트 전달 금액 절대 신뢰 금지 → `subscription_plans.price_cents` DB 조회
- [ ] **결제 완료는 웹훅으로만 확인** (`success_url` 리다이렉트는 UI 힌트일 뿐 — 위조 가능)
- [ ] TossPayments `customerKey`: URL 파라미터 대신 `getServerSession().user.id` 사용 — 파라미터 변조로 타인 계정에 빌링키 연결 가능
- [ ] TossPayments 빌링키: AES-256 또는 KMS 암호화 저장 (평문 DB 저장 금지)
- [ ] TossPayments `orderId`: `crypto.randomUUID()` 사용 — `Date.now()` 동시 요청 충돌 가능

### 인증 / API 보안 (High)
- [ ] 모든 보호 라우트: `session?.user?.id` null 체크 + 401 반환 — non-null assertion(`!`) 사용 금지
- [ ] Polar `metadata.userId`: 존재 여부 + `typeof === 'string'` 검증 — undefined 저장 방지
- [ ] 에러 응답: 결제 API 내부 오류 메시지 클라이언트 노출 금지 (`throw new Error('PAYMENT_FAILED')`)
- [ ] API 키: 서버 전용 (`NEXT_PUBLIC_` 접두사는 Public Key만 허용)

### DB / 스키마 보안 (High)
- [ ] `upsertSubscription`에 `providerPriceId` 전달 → `subscription_plans` 조회 → `plan_id` 확보 (NOT NULL 제약 보장)
- [ ] `webhook_events` 테이블 `UNIQUE(provider, event_id)` 인덱스 존재 확인
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
