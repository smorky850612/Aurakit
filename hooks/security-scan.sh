#!/bin/bash
# AuraKit - 시크릿 패턴 감지 (보안 L4 Pre-commit 검사)
# Hook: PreToolUse (matcher: Write|Edit)
# stdin: JSON (tool_input)
# 차단 시 exit 2

set -euo pipefail

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

# jq가 없으면 grep 폴백
if ! command -v jq &>/dev/null; then
  # jq 없이 기본 패턴 체크
  CONTENT=$(echo "${INPUT}" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' || echo "")
  FILE_PATH=$(echo "${INPUT}" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"$//' || echo "")
else
  # tool_input에서 content 또는 new_string 추출
  CONTENT=$(echo "${INPUT}" | jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null || echo "")
  FILE_PATH=$(echo "${INPUT}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
fi

# 내용이 없으면 통과
if [ -z "${CONTENT}" ]; then
  exit 0
fi

# ── .env 템플릿 파일 제외 (커밋용 예시 파일, 실제 시크릿 아님) ───────────
if echo "${FILE_PATH}" | grep -qiE "\.env\.(example|sample|template|defaults|test|ci|development)$"; then
  exit 0
fi

# ── .env 파일 쓰기 보안 검사 ──────────────────────────────────────────
if echo "${FILE_PATH}" | grep -qE "^\.env$|/\.env$|\.env\.local$|\.env\.production$"; then
  # .env 파일에 실제 시크릿 값이 포함되어 있는지 확인
  # (플레이스홀더나 주석만 있는 경우는 통과)
  if echo "${CONTENT}" | grep -qE "^[A-Z_]+=.{8,}" 2>/dev/null; then
    # .gitignore 확인
    if [ -f ".gitignore" ]; then
      if ! grep -qE "^\.env$|^\.env\b" .gitignore 2>/dev/null; then
        echo "⚠️  AuraKit Security L4: .env 파일이 .gitignore에 없습니다." >&2
        echo "   .gitignore에 먼저 .env를 추가하세요." >&2
        exit 2
      fi
    fi
  fi
fi

# ── 시크릿 패턴 검사 ───────────────────────────────────────────────────
FOUND_SECRETS=()

# 패턴 1: 하드코딩된 키=값 패턴 (변수 할당)
if echo "${CONTENT}" | grep -qEi \
  '(API_KEY|SECRET_KEY|PRIVATE_KEY|ACCESS_KEY|AUTH_TOKEN|DATABASE_URL|DB_PASSWORD)\s*=\s*["\x27][^"\x27]{8,}' \
  2>/dev/null; then
  FOUND_SECRETS+=("하드코딩된 환경변수 값")
fi

# 패턴 2: OpenAI API 키
if echo "${CONTENT}" | grep -qE 'sk-[a-zA-Z0-9]{20,}' 2>/dev/null; then
  FOUND_SECRETS+=("OpenAI API 키 패턴 (sk-...)")
fi

# 패턴 3: Stripe 키
if echo "${CONTENT}" | grep -qE 'sk_live_[a-zA-Z0-9]{24,}|pk_live_[a-zA-Z0-9]{24,}' 2>/dev/null; then
  FOUND_SECRETS+=("Stripe API 키 패턴")
fi

# 패턴 4: GitHub Personal Access Token
if echo "${CONTENT}" | grep -qE 'ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{82}' 2>/dev/null; then
  FOUND_SECRETS+=("GitHub Personal Access Token 패턴 (ghp_...)")
fi

# 패턴 5: AWS 액세스 키
if echo "${CONTENT}" | grep -qE 'AKIA[0-9A-Z]{16}' 2>/dev/null; then
  FOUND_SECRETS+=("AWS Access Key ID 패턴 (AKIA...)")
fi

# 패턴 6: AWS 시크릿 액세스 키
if echo "${CONTENT}" | grep -qE 'aws_secret_access_key\s*=\s*[a-zA-Z0-9/+=]{40}' 2>/dev/null; then
  FOUND_SECRETS+=("AWS Secret Access Key 패턴")
fi

# 패턴 7: 하드코딩된 비밀번호
if echo "${CONTENT}" | grep -qEi \
  'password\s*[=:]\s*["\x27][^"\x27]{8,}["\x27]' \
  2>/dev/null; then
  # 예시/테스트 케이스 제외 (your-password, example, test 등)
  if ! echo "${CONTENT}" | grep -qEi \
    'password\s*[=:]\s*["\x27](your-|my-|example|test|change-me|placeholder|xxx)' \
    2>/dev/null; then
    FOUND_SECRETS+=("하드코딩된 비밀번호")
  fi
fi

# 패턴 8: JWT 시크릿 (충분히 긴 경우)
if echo "${CONTENT}" | grep -qEi \
  'jwt_secret\s*=\s*["\x27][^"\x27]{32,}["\x27]' \
  2>/dev/null; then
  FOUND_SECRETS+=("JWT 시크릿 하드코딩")
fi

# 패턴 9: Webhook 시크릿
if echo "${CONTENT}" | grep -qE 'whsec_[a-zA-Z0-9]{32,}' 2>/dev/null; then
  FOUND_SECRETS+=("Webhook 시크릿 패턴 (whsec_...)")
fi

# ── 결과 처리 ──────────────────────────────────────────────────────────
if [ ${#FOUND_SECRETS[@]} -gt 0 ]; then
  echo "" >&2
  echo "🚨 AuraKit Security L4: 하드코딩된 시크릿이 감지되었습니다!" >&2
  echo "" >&2
  echo "감지된 패턴:" >&2
  for secret in "${FOUND_SECRETS[@]}"; do
    echo "  - ${secret}" >&2
  done
  echo "" >&2
  echo "해결 방법:" >&2
  echo "  1. 값을 .env 파일로 이동하세요" >&2
  echo "  2. 코드에서는 process.env.VARIABLE_NAME 으로 참조하세요" >&2
  echo "  3. .env를 .gitignore에 추가하세요" >&2
  echo "" >&2
  echo "예시:" >&2
  echo "  ❌ const apiKey = 'sk-abc123...'" >&2
  echo "  ✅ const apiKey = process.env.OPENAI_API_KEY" >&2
  exit 2
fi

exit 0
