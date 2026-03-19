#!/bin/bash
# AuraKit - 파일 크기(줄 수) 모니터링 및 블로트 경고
# Hook: PostToolUse (matcher: Write|Edit)
# stdin: JSON (tool_result + tool_input)
# exit 0 (경고만, 블로킹 아님)

set -euo pipefail

# ── 설정 ───────────────────────────────────────────────────────────────
WARN_LINES=250      # 경고 임계값
CRITICAL_LINES=400  # 심각 경고 임계값

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

# file_path 추출
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "${INPUT}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
else
  FILE_PATH=$(echo "${INPUT}" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"$//' || echo "")
fi

# 파일 경로가 없거나 존재하지 않으면 스킵
if [ -z "${FILE_PATH}" ] || [ ! -f "${FILE_PATH}" ]; then
  exit 0
fi

# ── 검사 대상 파일 필터링 ─────────────────────────────────────────────
EXTENSION="${FILE_PATH##*.}"

# 소스 코드 파일만 검사
case "${EXTENSION}" in
  ts|tsx|js|jsx|py|go|rs|java|kt|swift|rb|php|vue|svelte|astro)
    # 검사 대상
    ;;
  *)
    # 설정 파일, 마크다운, JSON 등은 스킵
    exit 0
    ;;
esac

# 생성된 파일 / 노드 모듈 제외
if echo "${FILE_PATH}" | grep -qE "node_modules|\.next|dist|build|__pycache__|\.pyc$|vendor"; then
  exit 0
fi

# ── 줄 수 카운트 ──────────────────────────────────────────────────────
if command -v wc &>/dev/null; then
  LINE_COUNT=$(wc -l < "${FILE_PATH}" 2>/dev/null || echo "0")
else
  LINE_COUNT=$(grep -c "" "${FILE_PATH}" 2>/dev/null || echo "0")
fi

# ── 결과 출력 ─────────────────────────────────────────────────────────
FILE_BASENAME=$(basename "${FILE_PATH}")

if [ "${LINE_COUNT}" -ge "${CRITICAL_LINES}" ] 2>/dev/null; then
  echo ""
  echo "🚨 AuraKit Bloat Warning [CRITICAL]: ${FILE_PATH}"
  echo "   현재 줄 수: ${LINE_COUNT}줄 (임계값: ${WARN_LINES}줄)"
  echo ""
  echo "   분할 권장:"
  case "${EXTENSION}" in
    tsx|jsx)
      echo "   → 서브 컴포넌트로 분리 ([Name]Item.tsx, [Name]List.tsx)"
      echo "   → 커스텀 훅 추출 (use[Name].ts)"
      echo "   → 타입 분리 ([name].types.ts)"
      ;;
    ts|js)
      if echo "${FILE_PATH}" | grep -qi "route\|controller\|handler"; then
        echo "   → 서비스 레이어 추출 ([name].service.ts)"
        echo "   → 리포지토리 레이어 추출 ([name].repository.ts)"
        echo "   → 스키마 분리 ([name].schema.ts)"
      else
        echo "   → 도메인별 유틸리티 분리 ([domain].utils.ts)"
        echo "   → 상수 분리 ([name].constants.ts)"
      fi
      ;;
    py)
      echo "   → 모듈로 분리 (services/, repositories/, schemas/)"
      echo "   → 믹스인 추출"
      ;;
  esac
  echo ""
  echo "   /aura 분할 리팩토링 해줘 — 로 자동 분할 요청 가능"

elif [ "${LINE_COUNT}" -ge "${WARN_LINES}" ] 2>/dev/null; then
  echo ""
  echo "⚠️  AuraKit Bloat Warning: ${FILE_PATH}"
  echo "   현재 줄 수: ${LINE_COUNT}줄 (권장 최대: ${WARN_LINES}줄)"
  echo "   250줄 이내로 분할을 권장합니다."
  echo "   /aura ${FILE_BASENAME} 분할해줘 — 로 자동 분할 가능"
fi

# 경고는 출력하되 항상 exit 0 (블로킹 없음)
exit 0
