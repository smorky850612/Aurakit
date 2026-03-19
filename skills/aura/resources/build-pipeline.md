# AuraKit — BUILD Pipeline (상세)

> 이 파일은 BUILD 모드에서만 로딩된다. (Progressive Disclosure)

---

## Step 1: 마이크로 플랜 (200 토큰 이내)

### 출력 포맷

```
📋 BUILD PLAN — [기능명]

파일 목록 (의존성 순서):
1. [파일경로] — [역할 1줄]
2. [파일경로] — [역할 1줄]
3. [파일경로] — [역할 1줄]

의존성:
- [파일A] → [파일B] (파일B가 파일A에 의존)

예상 소요: [N]개 파일
```

### 플랜 생성 규칙
- 최소 파일로 최대 기능 구현 (YAGNI 원칙)
- 의존성 없는 파일은 독립 배치 (병렬 구현 가능)
- 각 파일 역할은 1줄 이내로 명확하게

---

## Step 2: 파일별 구현 규칙

### 2-1. API 엔드포인트 (Node.js / Next.js)

```typescript
// ✅ 올바른 패턴
export async function POST(req: Request) {
  try {
    const body = await req.json()

    // 입력 검증 (zod)
    const schema = z.object({
      email: z.string().email().max(255),
      password: z.string().min(8).max(128),
    })
    const parsed = schema.safeParse(body)
    if (!parsed.success) {
      return Response.json(
        { success: false, error: 'VALIDATION_ERROR', message: parsed.error.message },
        { status: 400 }
      )
    }

    // 비즈니스 로직
    const result = await doSomething(parsed.data)

    return Response.json({ success: true, data: result })
  } catch (error) {
    console.error('[API Error]:', error)
    return Response.json(
      { success: false, error: 'INTERNAL_ERROR', message: 'Something went wrong' },
      { status: 500 }
    )
  }
}

// ❌ 금지 패턴
// - try-catch 없음
// - 입력 검증 없음
// - 에러 정보 전체 노출
```

### 2-2. SQL 쿼리

```typescript
// ✅ Parameterized query
const result = await db.query(
  'SELECT * FROM users WHERE email = $1 AND active = $2',
  [email, true]
)

// ✅ Prisma (자동 parameterized)
const user = await prisma.user.findUnique({
  where: { email }
})

// ❌ 절대 금지 — SQL Injection 취약점
const result = await db.query(
  `SELECT * FROM users WHERE email = '${email}'`
)
```

### 2-3. React 컴포넌트

```typescript
// ✅ 올바른 패턴
'use client'

import { useState } from 'react'
import type { FC } from 'react'

interface Props {
  title: string
  onSubmit: (data: FormData) => Promise<void>
}

const MyForm: FC<Props> = ({ title, onSubmit }) => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setIsLoading(true)
    setError(null)
    try {
      const formData = new FormData(e.currentTarget)
      await onSubmit(formData)
    } catch (err) {
      setError(err instanceof Error ? err.message : '오류가 발생했습니다')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h2>{title}</h2>
      {/* 접근성: label + htmlFor */}
      <label htmlFor="email">이메일</label>
      <input
        id="email"
        name="email"
        type="email"
        required
        aria-required="true"
        tabIndex={0}
      />
      {error && <p role="alert" aria-live="polite">{error}</p>}
      <button type="submit" disabled={isLoading}>
        {isLoading ? '처리 중...' : '제출'}
      </button>
    </form>
  )
}

export default MyForm
```

### 2-4. 이미지 접근성

```tsx
// ✅ alt 필수
<img src={product.imageUrl} alt={`${product.name} 제품 이미지`} />

// ✅ 장식용 이미지
<img src="/decoration.png" alt="" role="presentation" />

// ❌ 금지
<img src={url} />  // alt 없음
```

### 2-5. 인증 토큰 저장

```typescript
// ✅ httpOnly cookie (서버사이드)
res.setHeader('Set-Cookie', [
  `token=${jwt}; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=86400`
])

// ❌ 절대 금지 — XSS 취약점
localStorage.setItem('token', jwt)
sessionStorage.setItem('token', jwt)
```

### 2-6. CORS 설정

```typescript
// ✅ 화이트리스트
const ALLOWED_ORIGINS = [
  'https://myapp.com',
  'https://staging.myapp.com',
  process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : '',
].filter(Boolean)

// ❌ 절대 금지
Access-Control-Allow-Origin: *
```

### 2-7. CSS 디자인 시스템 토큰

```css
/* ✅ 토큰 사용 */
.button-primary {
  background-color: var(--color-primary);
  color: var(--color-bg);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
}

/* ❌ 하드코딩 금지 */
.button-primary {
  background-color: #2563eb;
}
```

### 2-8. 에러 바운더리

```typescript
// 모든 페이지/주요 컴포넌트에 에러 바운더리 적용
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback?: React.ReactNode },
  { hasError: boolean; error?: Error }
> {
  state = { hasError: false }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[ErrorBoundary]:', error, info)
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div role="alert">
          <h2>오류가 발생했습니다</h2>
          <button onClick={() => this.setState({ hasError: false })}>
            다시 시도
          </button>
        </div>
      )
    }
    return this.props.children
  }
}
```

### 2-9. 컴포넌트 분할 기준

```
파일이 200줄 초과 시:
  → 커스텀 훅 분리: use[Name].ts
  → 서브 컴포넌트 분리: [Name]Item.tsx, [Name]List.tsx
  → 유틸리티 분리: [name].utils.ts
  → 타입 분리: [name].types.ts
```

---

## Step 3: 진행 상태 기록

파일 하나 완료마다 `.aura/snapshots/current.md` 업데이트:

```markdown
# AuraKit Snapshot
- Timestamp: 2025-01-15T14:30:00Z
- Mode: BUILD
- Original Request: 로그인 기능 만들어줘
- Plan: 4 files total

## Completed
- [x] src/app/api/auth/login/route.ts
- [x] src/components/LoginForm.tsx

## Remaining
- [ ] src/lib/auth.ts
- [ ] src/middleware.ts

## Last Verification
- Build: Pass (tsc --noEmit)
- Security: Pass
- Tests: 2/2 Pass

## Key Decisions
- JWT → httpOnly cookie 저장 방식 채택
- zod로 입력 검증

## Next Action
- src/lib/auth.ts 구현 시작
```

---

## Step 4: 3중 검증

### V1 — 빌드 검증 (Hook 자동)
```bash
# TypeScript
npx tsc --noEmit

# Python
python -m py_compile [file_path]
```
에러 시: 빌드 중단, 에러 출력 후 FIX 모드 제안

### V2 — 코드리뷰 + 보안 L3 (Worker 에이전트, context:fork)
```
Worker 에이전트 실행 (context:fork):
  입력: 변경된 파일 목록
  체크: 에러 핸들링, 입력 검증, SQL injection, XSS, 하드코딩 시크릿
  출력: "Pass" 또는 "VULN-001: [설명] 파일:라인"
```

### V3 — 테스트 실행 (Worker 에이전트, context:fork)
```
Worker 에이전트 실행 (context:fork):
  입력: 테스트 파일 목록
  실행: npm test / pytest
  출력: "N/N Pass" 또는 "N Failed: [테스트명]"
```

V2 + V3 병렬 실행 (독립적이므로):
```
Agent(V2, context:fork) ─┐
                           ├→ 결과 취합 → 이슈 있으면 수정
Agent(V3, context:fork) ─┘
```

---

## Step 5: Pre-commit 보안 L4

security-scan.sh가 staged 파일에서 자동 실행:
```bash
# 시크릿 패턴 검사
grep -rn "API_KEY=\|SECRET=\|PASSWORD=\|TOKEN=\|sk-\|ghp_\|aws_access_key" [staged_files]

# 의존성 취약점 검사
npm audit --audit-level=high
# 또는
pip audit
```

---

## Step 6: Conventional Commit

```bash
git add [변경된 파일들]
git commit -m "feat(scope): 기능 설명"

# 예시
git commit -m "feat(auth): add JWT login with httpOnly cookie"
git commit -m "feat(ui): add LoginForm with accessibility support"
git commit -m "feat(api): add /api/auth/login endpoint with zod validation"
```

---

## Step 7: 완료 리포트 (100 토큰 이내)

```
✅ BUILD 완료 — [기능명]

생성 파일:
  + src/app/api/auth/login/route.ts
  + src/components/LoginForm.tsx
  + src/lib/auth.ts
  + src/middleware.ts

검증:
  V1 Build:    ✅ Pass
  V2 Security: ✅ Pass
  V3 Tests:    ✅ 4/4 Pass

다음 단계:
  → /aura 배포 설정 추가 (vercel)
  → /aura 리뷰 실행 (전체 코드 점검)
```
