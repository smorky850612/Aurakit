# AuraKit — QA Pipeline (G7)

> 이 파일은 `/aura qa:` 모드 또는 `/aura review:` 완료 후 QA 단계에서 로딩된다.

---

## 개요: Zero-Script QA + Log-Based Testing

테스트 스크립트 없이 실제 실행 로그로 검증하는 방법.
Docker 로그, API 응답, 브라우저 콘솔을 활용한 구조화된 QA.

```bash
# QA 모드 진입
/aura qa:                      → 현재 변경사항 전체 QA
/aura qa:api                   → API 엔드포인트 집중 QA
/aura qa:ui                    → UI 컴포넌트 QA
/aura qa:security              → 보안 취약점 QA
/aura qa:performance           → 성능 QA
/aura qa:e2e                   → E2E 테스트 (Playwright)
/aura qa:e2e:setup             → playwright.config.ts + 시나리오 자동 생성
/aura qa:e2e:ci                → GitHub Actions E2E 워크플로우 생성
```

---

## Step 1: QA 범위 결정

```bash
# 변경된 파일 감지
git diff --name-only HEAD~1 HEAD

# 파일 유형별 QA 전략:
*.ts / *.tsx → TypeScript + 단위 테스트
*api*        → API 엔드포인트 테스트 (curl)
*component*  → 컴포넌트 렌더링 + 접근성
*service*    → 비즈니스 로직 단위 테스트
*.sql        → 쿼리 결과 검증
Dockerfile   → 컨테이너 빌드 + 실행 테스트
```

---

## Step 2: 빠른 자동 검증 (항상 실행)

### 2.1 빌드 검증 (V1)

```bash
# TypeScript
npx tsc --noEmit

# Python
python -m py_compile **/*.py

# Go
go build ./...
```

### 2.2 린트 + 포맷

```bash
# Node.js
npx eslint . --ext .ts,.tsx --max-warnings 0
npx prettier --check .

# Python
ruff check .

# 실패 시: 자동 FIX 모드 전환
```

### 2.3 단위 테스트 (V3)

```bash
# Node.js
npx vitest run --reporter=verbose
# 또는
npx jest --ci

# Python
pytest --tb=short -v

# Go
go test ./... -v

# 결과 파싱:
# [N] tests passed, [N] failed, [N] skipped
# coverage: [N]%
```

---

## Step 3: Zero-Script QA (API)

테스트 코드 없이 실제 API 호출로 검증.

### 3.1 서버 기동

```bash
# 개발 서버 백그라운드 시작
npm run dev &
DEV_PID=$!

# 준비 대기 (최대 30초)
for i in $(seq 1 30); do
  curl -s http://localhost:3000/health && break
  sleep 1
done
```

### 3.2 API 엔드포인트 체크리스트

```bash
BASE="http://localhost:3000/api"

# 인증 없이 보호된 라우트 → 401 확인
curl -s -o /dev/null -w "%{http_code}" $BASE/users
# 기대: 401

# 잘못된 입력 → 400 확인
curl -s -X POST $BASE/users \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid"}' | jq .
# 기대: {"success":false,"error":"validation_failed"}

# 정상 흐름 → 200 확인
TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test1234"}' | jq -r .token)

curl -s $BASE/users \
  -H "Authorization: Bearer $TOKEN" | jq .
# 기대: {"success":true,"data":[...]}
```

### 3.3 응답 포맷 검증

```bash
# 표준 응답 포맷 검사 (AuraKit 규칙)
RESPONSE=$(curl -s $BASE/users -H "Authorization: Bearer $TOKEN")

echo $RESPONSE | jq 'has("success")' # true 확인
echo $RESPONSE | jq '.success'        # true/false
echo $RESPONSE | jq 'has("data")'    # true 확인
```

---

## Step 3.5: E2E 테스트 (Playwright)

> `/aura qa:e2e` 입력 시 → `resources/e2e-pipeline.md` 로딩 → Playwright 자동 실행.

```bash
/aura qa:e2e:setup            # playwright.config.ts + 시나리오 생성
/aura qa:e2e                  # 전체 E2E 스위트 실행
/aura qa:e2e:auth             # 인증 플로우만 실행
/aura qa:e2e:[url]            # 특정 URL 집중 테스트
```

### 자동 생성 시나리오

```
1. 인증: 회원가입 → 로그인 → 로그아웃
2. CRUD: 생성 → 조회 → 수정 → 삭제
3. 반응형: mobile(375px) · tablet(768px) · desktop(1440px)
4. 보안: 비인증 → 보호 라우트 → 리다이렉트 확인
```

### 실패 분석 패턴

```
TimeoutError: 셀렉터 없음 → locator 수정 또는 대기 조건 추가
NetworkError: baseURL 확인 → NEXT_PUBLIC_URL 환경변수 점검
AssertionError: URL 불일치 → 리다이렉트 로직 점검
```

상세 → `resources/e2e-pipeline.md`

---

## Step 4: Docker Log-Based QA

### 4.1 컨테이너 실행 + 로그 모니터링

```bash
# 컨테이너 빌드 + 실행
docker compose up -d

# 실시간 로그 구조화 출력
docker compose logs -f --tail=100 | jq -R '
  . as $line |
  if test("^{") then fromjson
  else {"raw": $line}
  end
' 2>/dev/null || docker compose logs -f --tail=100
```

### 4.2 구조화 로그 포맷 (AuraKit 표준)

애플리케이션에서 이 포맷으로 로그를 출력해야 Zero-Script QA 가능:

```json
{"level":"info","event":"request","method":"POST","path":"/api/users","status":201,"ms":23}
{"level":"error","event":"validation","field":"email","message":"invalid format"}
{"level":"warn","event":"auth","message":"invalid token","ip":"::1"}
```

```bash
# 에러 로그만 필터링
docker compose logs | grep '"level":"error"' | jq .

# 느린 요청 감지 (200ms 이상)
docker compose logs | jq -R '
  if test("^{") then fromjson | select(.ms > 200)
  else empty end
' 2>/dev/null
```

### 4.3 로그 기반 테스트 시나리오

```bash
# 시나리오 실행 + 로그 캡처
docker compose logs -f > /tmp/qa-log.txt &
LOG_PID=$!

# 시나리오 1: 회원가입 → 로그인 → 데이터 조회
curl -s -X POST http://localhost:3000/api/auth/signup \
  -d '{"email":"qa@test.com","password":"qa123456"}'

sleep 2
kill $LOG_PID

# 로그 분석
grep -c '"event":"request"' /tmp/qa-log.txt   # 요청 수
grep '"level":"error"' /tmp/qa-log.txt         # 에러 있으면 실패
```

---

## Step 5: UI QA 체크리스트

### 5.1 접근성 (WCAG 2.1 AA)

```
□ 모든 이미지에 alt 속성
□ 폼 입력에 htmlFor / aria-label
□ 버튼에 aria-label (아이콘만 있을 때)
□ 키보드 탭 순서 논리적
□ 색상 대비 4.5:1 이상
□ Focus visible 스타일 존재
```

### 5.2 반응형 체크포인트

```
□ 320px (모바일 최소)
□ 768px (태블릿)
□ 1024px (데스크톱 작은)
□ 1440px (데스크톱 큰)
```

### 5.3 브라우저 콘솔 에러

```javascript
// 브라우저 콘솔에서 실행
const errors = [];
const originalError = console.error;
console.error = (...args) => { errors.push(args); originalError(...args); };

// 페이지 조작 후
console.log('에러 수:', errors.length);
// 0이어야 통과
```

---

## Step 6: 보안 QA (L3)

```
□ 인증 없이 보호 라우트 접근 → 401 반환 확인
□ 다른 사용자 리소스 접근 → 403 반환 확인
□ SQL Injection 입력 → 에러 노출 없이 400 반환
□ XSS 입력 ("<script>") → HTML 이스케이프 확인
□ CSRF 토큰 검증 (상태 변경 요청)
□ Rate Limiting 동작 확인 (429 반환)
□ 에러 응답에 스택 트레이스 미포함 확인
```

---

## Step 7: 성능 QA

```bash
# API 응답시간 측정
time curl -s $BASE/users -H "Authorization: Bearer $TOKEN" > /dev/null

# 기준:
# < 100ms → A (우수)
# < 300ms → B (양호)
# < 1000ms → C (개선 권장)
# > 1000ms → D (필수 개선)

# 번들 사이즈 (Next.js)
npx next build 2>&1 | grep "First Load JS"

# 기준:
# < 100KB → A
# < 200KB → B
# < 400KB → C
# > 400KB → D
```

---

## QA 에이전트 배분

```
QA-Coordinator (sonnet/opus(MAX)):
  → QA 범위 결정
  → 체크리스트 생성

동시 실행:
  QA-API (haiku/sonnet(MAX)):      → API 엔드포인트 테스트
  QA-UI (haiku/sonnet(MAX)):       → 접근성 + 반응형 검사
  QA-Security (sonnet/opus(MAX)):  → 보안 L3 검사
  QA-Performance (haiku/sonnet(MAX)): → 성능 측정

QA-Monitor (haiku):
  → Docker 로그 실시간 분석
  → 이상 패턴 감지

E2E-Worker (haiku/sonnet(MAX)):
  → /aura qa:e2e 실행 시 활성화
  → playwright 시나리오 실행 + 실패 스크린샷 분석

종합자 (sonnet/opus(MAX)):
  → 결과 통합
  → QA 리포트 생성
```

---

## QA 리포트 포맷

```markdown
# AuraKit QA Report
생성: [타임스탬프]
범위: [N]개 파일 / [N]개 엔드포인트

## 자동 검증
V1 (빌드): ✅ Pass
V3 (테스트): ✅ [N/N Pass] | 커버리지: [N]%

## API QA
✅ POST /api/auth/login → 200 (23ms)
✅ GET /api/users (인증 없음) → 401
❌ DELETE /api/users/:id → 500 (에러 노출)

## E2E
✅ 인증 플로우: 회원가입 → 로그인 → 로그아웃 (2.3s)
✅ 반응형: mobile · tablet · desktop Pass
⚠️ CRUD 삭제 버튼: locator 타임아웃 → 수동 확인 필요

## 접근성
⚠️ src/components/UserAvatar.tsx:12 — img에 alt 없음

## 보안
✅ SQL Injection → 안전
✅ XSS → 이스케이프 확인
⚠️ Rate Limiting 미구현

## 성능
API 평균 응답시간: 87ms (A)
번들 사이즈: 156KB (B)

## 결론
등급: B | 주요 이슈: 2개 (에러 노출, Rate Limiting)
권장: /aura fix:API 500 에러 수정
```
