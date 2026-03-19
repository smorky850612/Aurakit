# AuraKit — REVIEW Pipeline (상세)

> 이 파일은 REVIEW 모드에서만 로딩된다. (Progressive Disclosure)

---

## 원칙

- **객관적 측정**: 점수 기반 리포트 (A~F)
- **실행 가능한 피드백**: 파일:라인 + 수정 제안
- **토큰 효율**: Worker 에이전트 3개 병렬 실행 (context:fork)

---

## Step 1: 변경 파일 감지

```bash
# 커밋되지 않은 변경 파일
git diff --name-only

# 마지막 커밋의 변경 파일
git diff --name-only HEAD~1 HEAD

# 특정 브랜치와 비교
git diff --name-only main...feature/my-branch
```

사용자가 특정 파일/디렉토리를 지정한 경우 해당 범위만 리뷰.
지정하지 않은 경우: `git diff --name-only` 결과 사용.

---

## Step 2~4: Worker 에이전트 3개 병렬 실행

```
Worker-A: 코드 리뷰 (context:fork)
Worker-B: 보안 L3 스캔 (context:fork)
Worker-C: 테스트 실행 (context:fork)

→ 3개 동시 실행, 결과 취합
```

### Worker-A: 코드 리뷰 체크리스트

```
코드 품질:
  □ 에러 핸들링 — try-catch, error boundary
  □ 입력 검증 — 모든 사용자 입력 검증 여부
  □ 타입 안정성 — any 타입, 타입 캐스팅 남용
  □ 네이밍 — 의미있는 이름, 일관성
  □ 중복 코드 — DRY 원칙
  □ 컴포넌트 크기 — 200줄 이내
  □ 단일 책임 — 함수/컴포넌트가 한 가지 일만
  □ loading/error 상태 — UI 처리
  □ 접근성 — alt, label, ARIA

성능:
  □ 불필요한 리렌더링 — React.memo, useMemo, useCallback
  □ N+1 쿼리 패턴 — DB 쿼리 최적화 필요 여부
  □ 번들 사이즈 — 불필요한 import
```

### Worker-B: 보안 L3 스캔 체크리스트

```
인젝션:
  □ SQL Injection — parameterized query 사용 여부
  □ XSS — dangerouslySetInnerHTML, innerHTML 사용 여부
  □ Command Injection — exec(), spawn() 입력 검증
  □ Path Traversal — 파일 경로 검증

인증/인가:
  □ 인증 미들웨어 — 보호 라우트 커버리지
  □ 토큰 저장 — localStorage 저장 여부
  □ CSRF 보호 — 상태 변경 요청
  □ 권한 검사 — 리소스 소유권 확인

시크릿:
  □ 하드코딩된 시크릿 — API_KEY, SECRET 패턴
  □ 클라이언트 노출 — NEXT_PUBLIC_ 시크릿
  □ 로그 노출 — console.log(sensitiveData)

네트워크:
  □ CORS 설정 — 와일드카드 *
  □ Rate Limiting — 구현 여부
  □ 보안 헤더 — CSP, X-Frame-Options
```

### Worker-C: 테스트 실행

```bash
# Node.js
npm test
# 또는
npx vitest run
npx jest --ci

# Python
pytest --tb=short

# 결과:
# N tests passed, N failed, N skipped
# coverage: N%
```

---

## Step 5: bloat-check.sh 실행

```bash
# 250줄 초과 파일 감지
find src -name "*.ts" -o -name "*.tsx" -o -name "*.py" | \
  xargs wc -l | sort -rn | awk '$1 > 250 {print $1, $2}'
```

---

## Step 6: 통합 리포트 생성

### 리포트 포맷

```markdown
# AuraKit Review Report
생성 시각: 2025-01-15T17:00:00Z
리뷰 범위: git diff HEAD~1 HEAD (4 files)

---

## 🔴 보안 이슈

### VULN-001 [HIGH] SQL Injection 취약점
- 위치: `src/app/api/search/route.ts:34`
- 심각도: HIGH
- 설명: 사용자 입력이 SQL 쿼리에 직접 삽입됨
- 현재 코드:
  ```typescript
  const results = await db.query(`SELECT * FROM products WHERE name = '${query}'`)
  ```
- 수정 제안:
  ```typescript
  const results = await db.query('SELECT * FROM products WHERE name = $1', [query])
  ```

### VULN-002 [MEDIUM] 인증 토큰 localStorage 저장
- 위치: `src/lib/auth.ts:78`
- 심각도: MEDIUM
- 설명: JWT 토큰을 localStorage에 저장하여 XSS 취약점 노출
- 수정 제안: httpOnly cookie 사용

---

## 🟡 코드 품질 이슈

### WARN-001 에러 핸들링 누락
- 위치: `src/components/UserList.tsx:45`
- 설명: async 함수에 try-catch 없음
- 수정 제안: ErrorBoundary로 감싸거나 try-catch 추가

### WARN-002 컴포넌트 크기 초과
- 위치: `src/components/Dashboard.tsx` (342줄)
- 설명: 250줄 초과
- 수정 제안: DashboardStats, DashboardChart로 분할

### WARN-003 미사용 import
- 위치: `src/lib/utils.ts:3`
- 설명: `import { debounce } from 'lodash'` — 미사용
- 수정 제안: 해당 import 제거

---

## 🟢 테스트 결과

총 24개 테스트:
- ✅ 22 Passed
- ❌ 2 Failed:
  - `UserService > createUser > should validate email format` (src/services/user.service.test.ts:45)
  - `AuthController > login > should reject invalid password` (src/controllers/auth.test.ts:89)

커버리지: 67.3% (목표: 80%)

---

## 📏 블로트 경고

| 파일 | 줄 수 | 권장 |
|------|-------|------|
| src/components/Dashboard.tsx | 342 | 분할 |
| src/app/api/users/route.ts | 289 | 분할 |

---

## 📊 전체 점수

| 항목 | 점수 |
|------|------|
| 보안 | D (HIGH 취약점 1개) |
| 코드 품질 | C (이슈 3개) |
| 테스트 | C (2 Failed, 커버리지 67%) |
| 블로트 | B (2개 파일 초과) |

**전체: C (수정 권장)**

---

## 🔧 권장 액션

우선순위 순:
1. `VULN-001` 즉시 수정 필요 — `/aura VULN-001 수정해줘`
2. `VULN-002` 수정 필요 — `/aura 토큰 저장 방식 수정해줘`
3. 실패한 테스트 수정 — `/aura 실패한 테스트 수정해줘`
4. Dashboard.tsx 분할 — `/aura Dashboard 컴포넌트 분할해줘`
```

---

## 점수 산정 기준

| 등급 | 보안 | 품질 | 테스트 |
|------|------|------|--------|
| A | 이슈 없음 | 이슈 없음 | 100% + 80%+ 커버리지 |
| B | LOW 이슈만 | 1~2개 | 98%+ Pass |
| C | MEDIUM 이슈 | 3~5개 | 90%+ Pass |
| D | HIGH 이슈 | 6~10개 | 80%+ Pass |
| F | CRITICAL 이슈 | 10개 초과 | 80% 미만 |
