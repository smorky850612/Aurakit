#!/bin/bash
# AuraKit - 자동 설치 스크립트
# 실행: bash init.sh
# 향후: npx aurakit init

set -euo pipefail

# ── 색상 출력 ─────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[AuraKit]${NC} $*"; }
log_success() { echo -e "${GREEN}[AuraKit]${NC} ✅ $*"; }
log_warn()    { echo -e "${YELLOW}[AuraKit]${NC} ⚠️  $*"; }
log_error()   { echo -e "${RED}[AuraKit]${NC} ❌ $*"; }
log_step()    { echo -e "${CYAN}${BOLD}[Step $1]${NC} $2"; }

# ── 헤더 ──────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        AuraKit Installer v1.0          ║${NC}"
echo -e "${BOLD}║  One Command. Full Stack. Zero Risk.   ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════╝${NC}"
echo ""

# ── 설정 ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "${SCRIPT_DIR}")"  # aurakit/ 루트
AURA_DIR="${HOME}/.claude/skills/aurakit"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

# ── Step 1: 디렉토리 구조 생성 ────────────────────────────────────────
log_step 1 "디렉토리 구조 생성"

mkdir -p "${AURA_DIR}/skills/aura/resources"
mkdir -p "${AURA_DIR}/skills/aura-compact"
mkdir -p "${AURA_DIR}/skills/aura-guard"
mkdir -p "${AURA_DIR}/agents"
mkdir -p "${AURA_DIR}/hooks"
mkdir -p "${AURA_DIR}/templates"
mkdir -p "${AURA_DIR}/scripts"
mkdir -p "${AURA_DIR}/landing"
mkdir -p "${CLAUDE_DIR}"

log_success "디렉토리 구조 생성 완료: ${AURA_DIR}"

# ── Step 2: 파일 복사 ─────────────────────────────────────────────────
log_step 2 "파일 복사"

if [ ! -d "${SOURCE_DIR}" ]; then
  log_error "소스 디렉토리를 찾을 수 없습니다: ${SOURCE_DIR}"
  log_error "aurakit/ 디렉토리 내에서 실행하세요: bash scripts/init.sh"
  exit 1
fi

# 전체 복사
cp -r "${SOURCE_DIR}/." "${AURA_DIR}/"

log_success "파일 복사 완료"

# ── Step 3: 실행 권한 설정 ────────────────────────────────────────────
log_step 3 "훅 스크립트 실행 권한 설정"

HOOKS=(
  "pre-session.sh"
  "security-scan.sh"
  "build-verify.sh"
  "bloat-check.sh"
  "migration-guard.sh"
  "output-filter.sh"
  "pre-compact-snapshot.sh"
  "post-compact-restore.sh"
)

for hook in "${HOOKS[@]}"; do
  HOOK_PATH="${AURA_DIR}/hooks/${hook}"
  if [ -f "${HOOK_PATH}" ]; then
    chmod +x "${HOOK_PATH}"
    log_success "chmod +x ${hook}"
  else
    log_warn "${hook} 파일을 찾을 수 없습니다"
  fi
done

# ── Step 4: settings.json 설정 ────────────────────────────────────────
log_step 4 "Claude Code hooks 설정"

# 기존 settings.json 백업
if [ -f "${SETTINGS_FILE}" ]; then
  BACKUP_FILE="${SETTINGS_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
  cp "${SETTINGS_FILE}" "${BACKUP_FILE}"
  log_info "기존 settings.json 백업: ${BACKUP_FILE}"
fi

# jq가 있는지 확인
if ! command -v jq &>/dev/null; then
  log_warn "jq가 설치되지 않았습니다. settings.json을 수동으로 설정하세요."
  log_warn "수동 설정 방법은 README.md의 'hooks settings.json 예시' 참조"
  MANUAL_HOOKS=true
else
  MANUAL_HOOKS=false
fi

if [ "${MANUAL_HOOKS}" = false ]; then
  # 기존 settings.json 읽기 또는 새로 생성
  if [ -f "${SETTINGS_FILE}" ]; then
    CURRENT_SETTINGS=$(cat "${SETTINGS_FILE}")
  else
    CURRENT_SETTINGS='{}'
  fi

  # hooks 설정 생성
  HOOKS_CONFIG=$(cat << 'HOOKS_EOF'
{
  "SessionStart": [
    {
      "matcher": "startup|resume",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/pre-session.sh\""
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/security-scan.sh\""
        },
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/migration-guard.sh\""
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/build-verify.sh\""
        },
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/bloat-check.sh\""
        }
      ]
    },
    {
      "matcher": "Agent",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/output-filter.sh\""
        }
      ]
    }
  ],
  "PreCompact": [
    {
      "matcher": "auto",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/pre-compact-snapshot.sh\""
        }
      ]
    }
  ],
  "PostCompact": [
    {
      "matcher": "auto",
      "hooks": [
        {
          "type": "command",
          "command": "\"$HOME/.claude/skills/aurakit/hooks/post-compact-restore.sh\""
        }
      ]
    }
  ]
}
HOOKS_EOF
)

  # 기존 hooks와 이벤트 단위 append 병합 (기존 hooks 보존)
  NEW_SETTINGS=$(echo "${CURRENT_SETTINGS}" | \
    jq --argjson hooks "${HOOKS_CONFIG}" '
      .hooks.SessionStart = ((.hooks.SessionStart // []) + $hooks.SessionStart) |
      .hooks.PreToolUse   = ((.hooks.PreToolUse   // []) + $hooks.PreToolUse)   |
      .hooks.PostToolUse  = ((.hooks.PostToolUse  // []) + $hooks.PostToolUse)  |
      .hooks.PreCompact   = ((.hooks.PreCompact   // []) + $hooks.PreCompact)   |
      .hooks.PostCompact  = ((.hooks.PostCompact  // []) + $hooks.PostCompact)
    ' 2>/dev/null || \
    echo "${CURRENT_SETTINGS}")

  echo "${NEW_SETTINGS}" | jq . > "${SETTINGS_FILE}"
  log_success "settings.json 업데이트 완료"
fi

# ── Step 5: 환경변수 설정 ─────────────────────────────────────────────
log_step 5 "환경변수 설정 (CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65)"

SHELL_PROFILE=""
ENV_VAR_LINE='export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65'
ENV_VAR_COMMENT='# AuraKit: 컨텍스트 65%에서 자동 컴팩트 트리거'

# 쉘 프로필 감지
if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ] || [ -f "${HOME}/.zshrc" ]; then
  SHELL_PROFILE="${HOME}/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/bash" ] || [ -f "${HOME}/.bashrc" ]; then
  SHELL_PROFILE="${HOME}/.bashrc"
else
  SHELL_PROFILE="${HOME}/.profile"
fi

# 이미 설정되어 있는지 확인
if [ -f "${SHELL_PROFILE}" ] && grep -q "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "${SHELL_PROFILE}" 2>/dev/null; then
  log_warn "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE 이미 설정됨 (${SHELL_PROFILE})"
else
  echo "" >> "${SHELL_PROFILE}"
  echo "${ENV_VAR_COMMENT}" >> "${SHELL_PROFILE}"
  echo "${ENV_VAR_LINE}" >> "${SHELL_PROFILE}"
  log_success "환경변수 추가: ${SHELL_PROFILE}"
fi

# 현재 세션에도 적용
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65

# ── Step 6: 검증 ──────────────────────────────────────────────────────
log_step 6 "설치 검증"

ERRORS=0

# 필수 파일 확인
REQUIRED_FILES=(
  "skills/aura/SKILL.md"
  "skills/aura-compact/SKILL.md"
  "skills/aura-guard/SKILL.md"
  "agents/scout.md"
  "agents/worker.md"
  "hooks/pre-session.sh"
  "hooks/security-scan.sh"
  "hooks/build-verify.sh"
  "hooks/bloat-check.sh"
  "hooks/migration-guard.sh"
  "hooks/output-filter.sh"
  "hooks/pre-compact-snapshot.sh"
  "hooks/post-compact-restore.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "${AURA_DIR}/${file}" ]; then
    log_success "${file}"
  else
    log_error "${file} — 파일 없음"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "${ERRORS}" -gt 0 ]; then
  log_error "설치 중 ${ERRORS}개 오류 발생"
  exit 1
fi

# ── 완료 메시지 ───────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║       AuraKit 설치 완료! 🎉                    ║${NC}"
echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}빠른 시작:${NC}"
echo ""
echo -e "  ${CYAN}/aura 로그인 기능 만들어줘${NC}     (BUILD 모드)"
echo -e "  ${CYAN}/aura 에러 수정해줘${NC}             (FIX 모드)"
echo -e "  ${CYAN}/aura 코드 정리해줘${NC}             (CLEAN 모드)"
echo -e "  ${CYAN}/aura 배포 설정해줘${NC}             (DEPLOY 모드)"
echo -e "  ${CYAN}/aura 코드 리뷰해줘${NC}             (REVIEW 모드)"
echo ""
echo -e "${BOLD}설치 위치:${NC} ${AURA_DIR}"
echo -e "${BOLD}설정 파일:${NC} ${SETTINGS_FILE}"
echo ""
echo -e "${YELLOW}⚠️  새 쉘을 열거나 'source ${SHELL_PROFILE}' 를 실행하세요.${NC}"
echo ""
echo -e "Claude는 완벽하지 않습니다. 중요한 결정은 항상 확인하세요."
echo ""
