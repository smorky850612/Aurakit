# AuraKit — TossPayments 결제 파이프라인

> PAYMENT 모드에서 TossPayments 선택 시 로딩. 공통 스키마 → payment-pipeline.md 참조.

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

