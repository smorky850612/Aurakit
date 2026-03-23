#!/bin/bash
# AuraKit — Convention Check (v4.0)
# grep-based 컨벤션 검사. 0 LLM 토큰.
# build-verify.sh V1 단계에서 자동 실행.
#
# 종료 코드:
#   0 = 위반 없음 (또는 MEDIUM만 있음)
#   1 = HIGH 위반 존재 -> 커밋 차단

set -euo pipefail

TARGET_DIRS="${CONVENTION_DIRS:-src lib app components pages api}"
STAGED_ONLY="${STAGED_ONLY:-false}"
OUTPUT_FILE=".aura/agent-memory/convention.json"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

VIOLATIONS_HIGH=0
VIOLATIONS_MEDIUM=0
VIOLATIONS_TOTAL=0

# 검사 대상 파일 결정
if [ "$STAGED_ONLY" = "true" ]; then
  FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | \
    grep -E '\.(ts|tsx|js|jsx|py|go|sql)$' | head -50 || true)
elif [ $# -gt 0 ]; then
  FILES="$*"
else
  FILES=$(find $TARGET_DIRS -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.go" 2>/dev/null | \
    grep -v node_modules | grep -v ".next" | grep -v ".aura" | head -200 || true)
fi

if [ -z "$FILES" ]; then
  echo -e "${GREEN}CONV: 검사 대상 없음${NC}"
  exit 0
fi

report_violation() {
  local level="$1"
  local code="$2"
  local file="$3"
  local line="$4"
  local desc="$5"

  VIOLATIONS_TOTAL=$((VIOLATIONS_TOTAL + 1))
  if [ "$level" = "HIGH" ]; then
    VIOLATIONS_HIGH=$((VIOLATIONS_HIGH + 1))
    echo -e "${RED}[${code}][${level}]${NC} ${file}:${line} -- ${desc}"
  else
    VIOLATIONS_MEDIUM=$((VIOLATIONS_MEDIUM + 1))
    echo -e "${YELLOW}[${code}][${level}]${NC} ${file}:${line} -- ${desc}"
  fi
}

# CONV-001: SQL 문자열 보간 검사 [HIGH]
# SQL 쿼리에 변수를 직접 삽입하면 인젝션 취약점 발생
check_conv001() {
  local file="$1"
  local hits
  hits=$(grep -nE "query|execute|SELECT|INSERT|UPDATE|DELETE" "$file" 2>/dev/null | \
    grep '\$[{`]' | grep -vE "//|#|parameterized|placeholder" | head -5 || true)
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local linenum
    linenum=$(echo "$hit" | cut -d: -f1)
    report_violation "HIGH" "CONV-001" "$file" "$linenum" "SQL 직접 보간 금지 -- Parameterized query 사용 필수"
  done <<< "$hits"
}

# CONV-002: HttpOnly 없는 쿠키 [HIGH]
# 민감 정보를 담은 쿠키에 HttpOnly 플래그 누락 시 XSS 취약
check_conv002() {
  local file="$1"
  local hits
  hits=$(grep -nE "Set-Cookie|setCookie" "$file" 2>/dev/null | \
    grep -ivE "httponly|http-only" | \
    grep -ivE "//|#" | head -5 || true)
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local linenum
    linenum=$(echo "$hit" | cut -d: -f1)
    report_violation "HIGH" "CONV-002" "$file" "$linenum" "HttpOnly 플래그 누락 -- XSS 취약점"
  done <<< "$hits"
}

# CONV-003: 하드코딩된 자격증명 패턴 [HIGH]
# 환경변수 대신 코드에 직접 삽입된 인증 정보
check_conv003() {
  local file="$1"
  # 패턴 문자열을 변수로 분리하여 스캐너 오탐 방지
  local cred_names="sk-|ghp_|aws_access_key_id"
  local hits
  hits=$(grep -nE "(${cred_names})[a-zA-Z0-9_\-]{20,}" "$file" 2>/dev/null | \
    grep -vE "process\.env|os\.environ|example|placeholder" | \
    grep -v "^[[:space:]]*//" | head -5 || true)
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local linenum
    linenum=$(echo "$hit" | cut -d: -f1)
    report_violation "HIGH" "CONV-003" "$file" "$linenum" "하드코딩 자격증명 -- process.env 또는 Secrets Manager 사용"
  done <<< "$hits"
}

# CONV-004: CSS 하드코딩 색상값 [MEDIUM]
# 디자인 시스템 토큰(var(--color-xxx)) 대신 직접 색상 코드 사용
check_conv004() {
  local file="$1"
  if ! echo "$file" | grep -qE '\.(css|scss|sass|less|tsx|jsx)$'; then
    return
  fi
  local hits
  hits=$(grep -nE "color:|background:|border-color:|fill:|stroke:" "$file" 2>/dev/null | \
    grep -E "#[0-9a-fA-F]{3,8}" | \
    grep -vE "var\(--|//|/\*" | head -5 || true)
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local linenum
    linenum=$(echo "$hit" | cut -d: -f1)
    report_violation "MEDIUM" "CONV-004" "$file" "$linenum" "하드코딩 색상값 -- var(--color-xxx) 디자인 시스템 토큰 사용"
  done <<< "$hits"
}

# CONV-005: 로그에 민감 정보 출력 [MEDIUM]
# 개발용 로그가 프로덕션에서 민감 정보를 노출할 수 있음
check_conv005() {
  local file="$1"
  local hits
  hits=$(grep -nE "console\.(log|error|warn|info)" "$file" 2>/dev/null | \
    grep -iE "password|credential|private" | \
    grep -vE "//|process\.env" | head -5 || true)
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    local linenum
    linenum=$(echo "$hit" | cut -d: -f1)
    report_violation "MEDIUM" "CONV-005" "$file" "$linenum" "로그 민감정보 출력 -- 프로덕션 배포 전 제거 필요"
  done <<< "$hits"
}

# 메인 실행
echo "Convention Check 실행중..."
echo ""

for file in $FILES; do
  [ -f "$file" ] || continue
  check_conv001 "$file"
  check_conv002 "$file"
  check_conv003 "$file"
  check_conv004 "$file"
  check_conv005 "$file"
done

echo ""

SCORE=$((100 - (VIOLATIONS_HIGH * 20) - (VIOLATIONS_MEDIUM * 5)))
[ $SCORE -lt 0 ] && SCORE=0

mkdir -p ".aura/agent-memory"
cat > "$OUTPUT_FILE" << JSONEOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "violations": $VIOLATIONS_TOTAL,
  "high": $VIOLATIONS_HIGH,
  "medium": $VIOLATIONS_MEDIUM,
  "score": $SCORE,
  "status": "$([ $VIOLATIONS_HIGH -eq 0 ] && echo 'pass' || echo 'fail')"
}
JSONEOF

if [ $VIOLATIONS_TOTAL -eq 0 ]; then
  echo -e "${GREEN}CONV Pass: 0개 위반, 스코어 100/100${NC}"
  exit 0
elif [ $VIOLATIONS_HIGH -eq 0 ]; then
  echo -e "${YELLOW}CONV Warning: MEDIUM ${VIOLATIONS_MEDIUM}개 | 스코어 ${SCORE}/100 | 커밋 허용${NC}"
  exit 0
else
  echo -e "${RED}CONV FAIL: HIGH ${VIOLATIONS_HIGH}개 | 스코어 ${SCORE}/100 | 커밋 차단${NC}"
  exit 1
fi
