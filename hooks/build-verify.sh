#!/bin/bash
# AuraKit - 파일 저장 후 빌드 타입 검증 (V1 검증)
# Hook: PostToolUse (matcher: Write|Edit)
# stdin: JSON (tool_result + tool_input)
# 실패 시 exit 2

set -euo pipefail

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

# file_path 추출
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "${INPUT}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
else
  FILE_PATH=$(echo "${INPUT}" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"$//' || echo "")
fi

# 파일 경로가 없으면 스킵 (Edit 도구 등)
if [ -z "${FILE_PATH}" ]; then
  exit 0
fi

# 파일이 존재하지 않으면 스킵
if [ ! -f "${FILE_PATH}" ]; then
  exit 0
fi

# ── 파일 확장자에 따른 검증 ────────────────────────────────────────────
EXTENSION="${FILE_PATH##*.}"
FILE_BASENAME=$(basename "${FILE_PATH}")

case "${EXTENSION}" in
  # ── TypeScript 파일 ──
  ts|tsx)
    # tsconfig.json이 있는지 확인
    if [ ! -f "tsconfig.json" ] && [ ! -f "tsconfig.base.json" ]; then
      # tsconfig 없으면 단순 구문 검사만
      if command -v node &>/dev/null; then
        # ts-node로 기본 구문 확인 (빠름)
        if command -v npx &>/dev/null; then
          ERROR_OUTPUT=$(npx --no-install tsc --noEmit --allowJs 2>&1) || {
            echo "" >&2
            echo "❌ AuraKit V1 Build Error: TypeScript 오류 발견" >&2
            echo "파일: ${FILE_PATH}" >&2
            echo "" >&2
            echo "${ERROR_OUTPUT}" | head -20 >&2
            exit 2
          }
        fi
      fi
      exit 0
    fi

    # tsconfig.json이 있으면 전체 타입 체크
    echo "🔍 AuraKit V1: TypeScript 타입 검사 중... (${FILE_BASENAME})" >&2

    if command -v npx &>/dev/null; then
      ERROR_OUTPUT=$(npx --no-install tsc --noEmit 2>&1) && {
        echo "✅ AuraKit V1: TypeScript 타입 검사 통과" >&2
      } || {
        echo "" >&2
        echo "❌ AuraKit V1 Build Error: TypeScript 타입 오류" >&2
        echo "파일: ${FILE_PATH}" >&2
        echo "" >&2
        # 오류가 많으면 처음 30줄만 표시
        echo "${ERROR_OUTPUT}" | head -30 >&2
        ERROR_COUNT=$(echo "${ERROR_OUTPUT}" | grep -c "error TS" 2>/dev/null || echo "?")
        echo "" >&2
        echo "총 ${ERROR_COUNT}개 오류. /aura FIX 모드로 수정하거나 수동으로 수정하세요." >&2
        exit 2
      }
    elif command -v tsc &>/dev/null; then
      ERROR_OUTPUT=$(tsc --noEmit 2>&1) && {
        echo "✅ AuraKit V1: TypeScript 타입 검사 통과" >&2
      } || {
        echo "" >&2
        echo "❌ AuraKit V1 Build Error: TypeScript 타입 오류" >&2
        echo "${ERROR_OUTPUT}" | head -30 >&2
        exit 2
      }
    fi
    ;;

  # ── Python 파일 ──
  py)
    echo "🔍 AuraKit V1: Python 구문 검사 중... (${FILE_BASENAME})" >&2

    # python3 실제 동작 여부 확인 (Windows Python Launcher 오탐 방지)
    PYTHON_BIN=""
    if command -v python3 &>/dev/null && python3 -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
      PYTHON_BIN="python3"
    elif command -v python &>/dev/null && python -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
      PYTHON_BIN="python"
    fi

    if [ -n "${PYTHON_BIN}" ]; then
      ERROR_OUTPUT=$("${PYTHON_BIN}" -m py_compile "${FILE_PATH}" 2>&1) && {
        echo "✅ AuraKit V1: Python 구문 검사 통과" >&2
      } || {
        echo "" >&2
        echo "❌ AuraKit V1 Build Error: Python 구문 오류" >&2
        echo "파일: ${FILE_PATH}" >&2
        echo "" >&2
        echo "${ERROR_OUTPUT}" >&2
        exit 2
      }
    fi
    ;;

  # ── JSON 파일 ──
  json)
    # package.json, tsconfig.json 등 중요 JSON 파일만 검사
    IMPORTANT_JSON=(
      "package.json" "tsconfig.json" "tsconfig.base.json"
      "vercel.json" "next.config.json" ".eslintrc.json"
    )
    IS_IMPORTANT=false
    for important in "${IMPORTANT_JSON[@]}"; do
      if [ "${FILE_BASENAME}" = "${important}" ]; then
        IS_IMPORTANT=true
        break
      fi
    done

    if [ "${IS_IMPORTANT}" = true ]; then
      echo "🔍 AuraKit V1: JSON 구문 검사 중... (${FILE_BASENAME})" >&2
      if command -v python3 &>/dev/null; then
        ERROR_OUTPUT=$(python3 -c "import json; json.load(open('${FILE_PATH}'))" 2>&1) && {
          echo "✅ AuraKit V1: JSON 구문 검사 통과" >&2
        } || {
          echo "" >&2
          echo "❌ AuraKit V1 Build Error: JSON 구문 오류" >&2
          echo "파일: ${FILE_PATH}" >&2
          echo "${ERROR_OUTPUT}" >&2
          exit 2
        }
      elif command -v jq &>/dev/null; then
        if ! jq . "${FILE_PATH}" > /dev/null 2>&1; then
          echo "" >&2
          echo "❌ AuraKit V1 Build Error: JSON 구문 오류 (${FILE_PATH})" >&2
          exit 2
        fi
        echo "✅ AuraKit V1: JSON 구문 검사 통과" >&2
      fi
    fi
    ;;

  # ── 기타 파일 ── 스킵
  *)
    exit 0
    ;;
esac

exit 0
