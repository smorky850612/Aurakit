# AuraKit — FIX Pipeline (상세)

> 이 파일은 FIX 모드에서만 로딩된다. (Progressive Disclosure)

---

## 원칙

- **최소 변경**: 버그를 수정하되 사이드 이펙트 최소화
- **근본 원인**: 증상이 아닌 원인 수정
- **테스트 우선**: 수정 후 반드시 검증

---

## Step 1: 에러 분석

### 에러 메시지 파싱

```
입력 유형:
  A. 에러 메시지 직접 입력
     예: "TypeError: Cannot read properties of undefined (reading 'map')"
  B. 스택 트레이스
     예: "at UserList (src/components/UserList.tsx:45:12)"
  C. 현상 설명
     예: "로그인 버튼 눌러도 아무것도 안 됨"

A/B의 경우:
  - 에러 타입 분류 (TypeError, ReferenceError, NetworkError, etc.)
  - 파일:라인 추출
  - 연관 파일 추론

C의 경우:
  - Scout 에이전트로 관련 파일 탐색 후 에러 추론
```

### 에러 유형별 빠른 진단

| 에러 | 의심 원인 | 확인 파일 |
|------|----------|----------|
| `Cannot read properties of undefined` | null check 누락, 비동기 타이밍 | 해당 컴포넌트 |
| `fetch failed` / `ECONNREFUSED` | API URL 오류, 서버 미실행 | .env, API 라우트 |
| `Hydration failed` | 서버/클라이언트 렌더 불일치 | 'use client' 누락, window 직접 접근 |
| `prisma.X is not a function` | Prisma 클라이언트 미초기화 | lib/prisma.ts |
| `401 Unauthorized` | 토큰 만료, 미들웨어 설정 | middleware.ts, cookie |
| `CORS error` | Origin 미허용 | API CORS 설정 |
| `Module not found` | import 경로 오류, 패키지 미설치 | tsconfig paths, package.json |

---

## Step 2: Scout 에이전트로 파일 탐색 [ECO/PRO: Haiku 위임 필수]

```
Agent(model="haiku") 실행:  ← ECO/PRO 티어 필수, Sonnet 직접 탐색 금지
  목적: 에러 관련 파일 탐색
  탐색 대상:
    - 에러 스택에서 언급된 파일
    - import 체인으로 연결된 파일
    - 동일 기능 관련 API/컴포넌트
  출력:
    - 관련 파일 목록
    - 의심 코드 블록
    - 유사 패턴 파일 (참조용)
  형식: Fail-Only (탐색 결과만 반환, 불필요한 설명 생략)
```

---

## Step 3: 근본 원인 파악 + 최소 수정

### 수정 원칙

```
❌ 나쁜 수정 — 증상 회피
  // 에러가 발생하는 배열을 || [] 로 덮어버림
  const items = data?.items || []
  // 실제 문제: API가 items를 반환하지 않는 이유를 모름

✅ 좋은 수정 — 근본 원인
  // API가 빈 배열 대신 null을 반환하는 버그 수정
  // server: return { items: results ?? [] }
  // client: const items = data.items (이제 항상 배열)
```

### 수정 범위 제한

```
변경 금지:
  - 버그와 무관한 리팩토링
  - 기능 추가
  - 성능 최적화 (별도 CLEAN 모드)

변경 허용:
  - 버그 유발 코드 수정
  - 수정에 필요한 최소 의존성
  - 수정된 코드의 타입 수정
```

### 일반적인 수정 패턴

```typescript
// 패턴 1: null/undefined 체크
// Before
const name = user.profile.name
// After
const name = user?.profile?.name ?? '알 수 없음'

// 패턴 2: 비동기 에러 처리
// Before
const data = await fetchData()
setData(data)
// After
try {
  const data = await fetchData()
  setData(data)
} catch (error) {
  setError(error instanceof Error ? error.message : '데이터 로딩 실패')
}

// 패턴 3: 조건부 렌더링
// Before
return <div>{items.map(...)}</div>
// After
if (!items?.length) return <EmptyState />
return <div>{items.map(...)}</div>

// 패턴 4: 환경변수 누락
// Before
const url = process.env.API_URL
fetch(url + '/endpoint')  // url이 undefined일 수 있음
// After
const url = process.env.API_URL
if (!url) throw new Error('API_URL 환경변수가 설정되지 않았습니다')
fetch(url + '/endpoint')
```

---

## Step 4: 스냅샷 업데이트

`.aura/snapshots/current.md` 업데이트:

```markdown
# AuraKit Snapshot
- Timestamp: 2025-01-15T15:00:00Z
- Mode: FIX
- Original Request: TypeError: Cannot read properties of undefined (reading 'map') at UserList.tsx:45

## Completed
- [x] src/components/UserList.tsx (null check 추가)
- [x] src/app/api/users/route.ts (빈 배열 반환 보장)

## Remaining
- (없음)

## Last Verification
- Build: Pass
- Security: Pass
- Tests: 3/3 Pass

## Key Decisions
- API 응답에 users 필드 항상 포함하도록 수정
- 컴포넌트에 loading/error 상태 추가

## Next Action
- /aura review 로 전체 코드 점검 권장
```

---

## Step 5: 3중 검증

BUILD 모드 §4와 동일:

```
V1: build-verify.js (tsc --noEmit / py_compile)
V2: Worker → 코드 리뷰 + 보안 스캔 (격리 서브에이전트)
V3: Worker → 테스트 실행 (격리 서브에이전트)
```

수정 후 원래 버그가 재현되지 않는지 특별 확인:
```
V3 테스트 시 명시적으로 버그 시나리오 포함 요청
```

---

## Step 6: Conventional Commit

```bash
git add [수정된 파일들]
git commit -m "fix(scope): 버그 설명"

# 예시
git commit -m "fix(ui): add null check in UserList to prevent crash"
git commit -m "fix(api): ensure users array is always returned"
git commit -m "fix(auth): handle expired token redirect properly"
```

---

## Step 7: 수정 리포트

```
🔧 FIX 완료

원인: UserList.tsx:45 — API 응답의 users가 null일 때 .map() 호출
수정:
  ~ src/components/UserList.tsx (users?.length 체크 추가)
  ~ src/app/api/users/route.ts (users: result ?? [] 보장)

검증:
  V1 Build:    ✅ Pass
  V2 Security: ✅ Pass
  V3 Tests:    ✅ 3/3 Pass (버그 시나리오 포함)

재발 방지:
  → API 응답 타입에 required 필드 명시 권장
  → /aura review 로 유사 패턴 전체 점검 권장
```
