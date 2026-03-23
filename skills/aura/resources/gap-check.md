# AuraKit — Gap Check (설계 vs 구현 비교)

> REVIEW 모드 또는 `/aura gap:` 명령에서 로딩. 독립 실행 가능.

---

## 목적

설계 문서(Plan/Spec)와 실제 구현 코드 사이의 격차를 정량적으로 측정한다.
Match Rate를 0~100%로 표시하고 미구현 항목과 초과 구현 항목을 분류한다.

---

## 실행 순서

### Step 1: 설계 문서 위치 감지

```
우선순위:
1. 사용자가 명시한 경로
2. .aura/plan.md
3. .aura/design.md
4. docs/PLAN.md, docs/DESIGN.md, docs/SPEC.md
5. README.md (기능 목록 섹션)
→ 없으면: "설계 문서를 찾을 수 없습니다. 경로를 지정해주세요." 안내
```

### Step 2: 구현 파일 탐색 (Scout, model: haiku/sonnet(MAX))

```bash
# 주요 소스 파일 탐색
find src -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.go" \) \
  | grep -v node_modules | grep -v .test.

# API 엔드포인트 추출
grep -rn "app\.\(get\|post\|put\|delete\|patch\)" src/
grep -rn "router\.\|route(" src/
grep -rn "export async function\|export function" src/app/api/

# 컴포넌트 목록 추출
find src -name "*.tsx" -o -name "*.jsx" | grep -v test

# 함수/클래스 목록 추출
grep -rn "^export\|^class\|^function\|^const " src/ | head -100
```

### Step 3: 설계 항목 추출

설계 문서에서 구현 요구사항 파싱:
- `[ ]` / `[x]` 체크박스 → 기능 목록
- `## Features` / `## 기능` 섹션 → 기능 목록
- API 엔드포인트 목록 (`GET /api/...`, `POST /api/...`)
- 컴포넌트 목록 (`<ComponentName>`)
- 함수/서비스 목록 (`functionName()`, `ServiceName`)

### Step 4: 매핑 분석

```
설계 항목 → 구현 코드 1:1 매핑:

✅ 구현됨   — 설계 항목이 코드에 존재
❌ 미구현   — 설계에 있지만 코드에 없음
⚠️ 부분구현 — 함수는 있지만 비어 있거나 TODO 상태
🆕 초과구현 — 설계에 없지만 코드에 추가됨
```

### Step 5: Match Rate 계산

```
Match Rate = (구현됨 + 부분구현 * 0.5) / 전체 설계 항목 * 100

기준:
≥ 90% → ✅ 설계 충실 (배포 가능)
70~89% → ⚠️ 부분 구현 (우선순위 보완 필요)
50~69% → ❌ 미흡 (추가 구현 필요)
< 50%  → 🔴 초기 단계 (대부분 미구현)
```

---

## 출력 포맷

```markdown
# AuraKit Gap Check Report
분석 시각: [ISO 8601]
설계 문서: [경로]
분석 범위: [파일 수]개 소스 파일

---

## 📊 Match Rate: [N]%

| 상태 | 항목 수 | 비율 |
|------|---------|------|
| ✅ 구현됨 | N | N% |
| ⚠️ 부분구현 | N | N% |
| ❌ 미구현 | N | N% |
| 🆕 초과구현 | N | — |

---

## ❌ 미구현 항목 ([N]개)

1. `[기능명]` — 설계: [설명] | 위치: 미생성
2. `GET /api/[endpoint]` — 라우트 핸들러 없음
...

## ⚠️ 부분구현 항목 ([N]개)

1. `[기능명]` @ `[파일:라인]` — TODO 주석 또는 빈 함수
...

## 🆕 설계 외 추가 항목 ([N]개)

1. `[기능명]` @ `[파일]` — 설계서에 미포함
...

---

## 🔧 권장 액션

Match Rate [N]%:
→ [다음 단계 제안]
→ `/aura build:[미구현 항목]` 으로 보완 가능
```

---

## 빠른 실행 명령

```
/aura gap:               → .aura/plan.md 자동 탐색
/aura gap:docs/SPEC.md   → 특정 문서 지정
/aura review:gap         → REVIEW 모드 내 gap check
```

---

*Gap Check — Match Rate 90% 이상이면 배포 준비 완료*
