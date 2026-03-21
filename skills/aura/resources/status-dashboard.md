# AuraKit — Status Dashboard (상태 대시보드)

> `/aura status` 호출 시 로딩.
> 프로젝트 헬스 지표 종합 표시 + 다음 단계 추천.

---

## 데이터 수집 (0 LLM 토큰, bash 기반)

### 1. Match Rate

```bash
# 최근 report 파일에서 추출
REPORT=$(ls -t .aura/docs/report-*.md 2>/dev/null | head -1)
if [ -f "$REPORT" ]; then
  MATCH_RATE=$(grep "Match Rate" "$REPORT" | awk -F'|' '{print $3}' | tr -d ' %')
else
  MATCH_RATE="N/A"
fi
```

### 2. 보안 스코어

```bash
# agent-memory에서 최근 보안 스캔 결과
SECURITY_FILE=".aura/agent-memory/security.json"
if [ -f "$SECURITY_FILE" ]; then
  SECURITY_GRADE=$(jq -r '.grade // "N/A"' "$SECURITY_FILE")
  VULN_COUNT=$(jq -r '.vulnerabilities // 0' "$SECURITY_FILE")
else
  SECURITY_GRADE="N/A"
  VULN_COUNT="N/A"
fi
```

### 3. 테스트 커버리지

```bash
# TestRunner 결과
TEST_FILE=".aura/agent-memory/test-runner.json"
if [ -f "$TEST_FILE" ]; then
  TESTS_PASS=$(jq -r '.passed // 0' "$TEST_FILE")
  TESTS_TOTAL=$(jq -r '.total // 0' "$TEST_FILE")
  COVERAGE=$(jq -r '.coverage // "N/A"' "$TEST_FILE")
else
  TESTS_PASS="?"
  TESTS_TOTAL="?"
  COVERAGE="N/A"
fi
```

### 4. 기술 부채 (Bloat)

```bash
# 200줄 초과 파일 감지
BLOAT_COUNT=$(find . -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" 2>/dev/null \
  | grep -v node_modules | grep -v ".aura" \
  | xargs wc -l 2>/dev/null \
  | awk '$1 > 200 {print $2}' | wc -l)
```

### 5. 컨벤션 준수율

```bash
# scripts/convention-check.sh 결과 캐시 (build-verify.js가 호출)
CONV_FILE=".aura/agent-memory/convention.json"
if [ -f "$CONV_FILE" ]; then
  CONV_VIOLATIONS=$(jq -r '.violations // 0' "$CONV_FILE")
  CONV_SCORE=$(jq -r '.score // "N/A"' "$CONV_FILE")
else
  CONV_VIOLATIONS="N/A"
  CONV_SCORE="N/A"
fi
```

---

## 출력 포맷

```
📊 AuraKit Health Dashboard — [프로젝트명]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Match Rate:    [N]%  [████████░░] → 설계 vs 구현 일치율
🔒 보안:          [A~F] 등급 | 취약점 [N]개
🧪 테스트:        [N]/[N] Pass | 커버리지 [N]%
🗂️  기술 부채:    200줄 초과 파일 [N]개
📋 컨벤션:        위반 [N]건 | 스코어 [N]/100

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 문서 현황 (.aura/docs/index.md):
  Plan:   [N]개 | Design: [N]개 | Report: [N]개

⚡ 현재 작업:
  [current.md에서 추출한 상태]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 다음 추천:
  [아래 로직에 따른 추천]
```

---

## 다음 단계 추천 로직

```
Match Rate 조건:
  N/A         → /aura review: 실행 (첫 갭 분석)
  < 70%       → /aura iterate: (자동 수정 5회)
  70% ~ 89%   → /aura iterate: (수동 확인 후)
  90% ~ 99%   → /aura report: (완료 보고서)
  100%        → /aura deploy: (배포 준비)

보안 조건:
  취약점 > 0  → /aura review:보안 점검 먼저
  등급 D/F    → /aura fix: 즉시 수정

테스트 조건:
  커버리지 < 80% → /aura tdd: 테스트 추가
  실패 있음      → /aura fix: 테스트 수정

기술 부채 조건:
  200줄 초과 > 5개 → /aura clean: 리팩토링
```

---

## 문서 라이프사이클 인덱스 (Doc Lifecycle)

### .aura/docs/index.md 자동 생성

각 PLAN/DESIGN/REPORT 문서 저장 시 자동 업데이트:

```markdown
# AuraKit Docs Index
업데이트: [timestamp]

## 활성 기능
| 기능 | Plan | Design | Report | Match Rate |
|------|------|--------|--------|------------|
| 로그인 | ✅ | ✅ | ✅ | 95% |
| 결제 | ✅ | ✅ | - | 진행중 |
| 프로필 | ✅ | - | - | 계획중 |

## 최근 완료
- 로그인 (2025-03-15) — Match Rate 95%
- 회원가입 (2025-03-10) — Match Rate 98%
```

### 인덱스 업데이트 규칙

```bash
# PLAN 저장 시
FEATURE=$(basename "$DOC_PATH" | sed 's/plan-//;s/\.md//')
update_index "$FEATURE" "plan" "✅"

# DESIGN 저장 시
update_index "$FEATURE" "design" "✅"

# REPORT 저장 시 + Match Rate
update_index "$FEATURE" "report" "✅" "$MATCH_RATE"
```

---

## /aura next 로직

```
현재 스냅샷 (.aura/snapshots/current.md) 분석:
  Mode: BUILD → 완료 후 REVIEW 추천
  Mode: REVIEW → Gap Rate 확인 후 ITERATE 또는 REPORT
  Mode: ITERATE → 90% 달성 여부 → REPORT 또는 계속
  스냅샷 없음 → PIPELINE 또는 새 BUILD 제안

파이프라인 단계 (.aura/pipeline-state.md):
  Phase 1~3 → 다음 단계 안내
  Phase 9 완료 → 유지보수 모드
```

---

## /aura status:pipeline

```
🗺️ 개발 파이프라인 상태
━━━━━━━━━━━━━━━━━━━━━
Phase 1: PM 분석           [✅/⏳/-]
Phase 2: 컨벤션 정의       [✅/⏳/-]
Phase 3: 목업              [✅/⏳/-]
Phase 4: API 구현          [✅/⏳/-]
Phase 5: 디자인 시스템     [✅/⏳/-]
Phase 6: UI 통합           [✅/⏳/-]
Phase 7: SEO/보안          [✅/⏳/-]
Phase 8: 코드 리뷰         [✅/⏳/-]
Phase 9: 배포              [✅/⏳/-]
━━━━━━━━━━━━━━━━━━━━━
현재: Phase [N] → 다음: [안내]
```

---

*AuraKit Status Dashboard — 헬스 KPI · Doc Lifecycle · 다음 단계 추천 · 0 LLM 토큰*
