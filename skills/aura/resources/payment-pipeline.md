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

## 결제 제공자별 파일 (Progressive Load)

| 제공자 | 파일 | 대상 시장 | 줄 수 |
|--------|------|----------|-------|
| Stripe | `payment-stripe.md` | 글로벌 | 202 |
| Lemon Squeezy | `payment-lemonsqueezy.md` | 글로벌/SaaS | 171 |
| Polar | `payment-polar.md` | 오픈소스 | 116 |
| TossPayments | `payment-toss.md` | 한국 | 205 |
| StepPay | `payment-steppay.md` | 한국 BNPL | 142 |

선택한 제공자 파일만 로딩 → 불필요한 1,043줄 전체 로딩 방지.

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
