#!/bin/bash
# ============================================================
# AuraKit Installer v2.0
# One-line install: bash install.sh
# ============================================================

set -euo pipefail

AURAKIT_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
SETTINGS_FILE="$HOME/.claude/settings.json"
HP="~/.claude/skills/aurakit/hooks"   # hooks path in settings (tilde-form)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[AuraKit]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# Optional: --lang=ko,en,jp,zh,es,fr,de,it (default: all)
LANG_FILTER=""
for arg in "$@"; do
  case "$arg" in --lang=*) LANG_FILTER="${arg#--lang=}" ;; esac
done

should_install_lang() {
  [ -z "$LANG_FILTER" ] && return 0
  echo ",$LANG_FILTER," | grep -qi ",${1}," && return 0
  return 1
}

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     AuraKit Installer v2.0           ║"
echo "  ║  8-Lang · 6-Layer Security · 75% opt ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ════════════════════════════════════════════════════════════
# 0. Claude Code 확인
# ════════════════════════════════════════════════════════════
command -v claude &>/dev/null || error "Claude Code not found. Install from https://claude.ai/code"
info "Claude Code: $(claude --version 2>/dev/null | head -1 || echo 'detected')"

# ════════════════════════════════════════════════════════════
# 0.5. 의존성 확인 및 자동 설치
# ════════════════════════════════════════════════════════════
info "Checking dependencies..."

# ── Node.js (필수 — JS 훅 실행) ────────────────────────────
if command -v node &>/dev/null && node -e "process.exit(0)" >/dev/null 2>&1; then
  success "Node.js: $(node --version)"
else
  error "Node.js not found (required for hooks). Install from https://nodejs.org"
fi

# ── Python (필수 — statusline JSON 파싱) ────────────────────
PYTHON_BIN=""
for bin in python python3; do
  if command -v "$bin" &>/dev/null && "$bin" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
    PYTHON_BIN="$bin"
    break
  fi
done

if [ -n "$PYTHON_BIN" ]; then
  success "Python: $("$PYTHON_BIN" --version 2>&1 | head -1)"
else
  warn "Python not found — statusline will show basic mode"
  warn "Install from https://python.org (optional but recommended)"
fi

# ── jq (선택 — 없어도 Python fallback으로 정상 작동) ──────────
JQ_INSTALLED=false
if command -v jq &>/dev/null; then
  success "jq: $(jq --version)"
  JQ_INSTALLED=true
else
  warn "jq not installed — auto-installing..."
  OS_TYPE="$(uname -s 2>/dev/null || echo 'unknown')"

  case "$OS_TYPE" in
    Darwin)
      if command -v brew &>/dev/null; then
        brew install jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via Homebrew"
      fi ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via apt"
      elif command -v yum &>/dev/null; then
        sudo yum install -y jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via yum"
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via pacman"
      elif command -v apk &>/dev/null; then
        sudo apk add jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via apk"
      fi ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows (Git Bash / MSYS2)
      if command -v winget &>/dev/null; then
        winget install jqlang.jq --silent --accept-package-agreements >/dev/null 2>&1 \
          && JQ_INSTALLED=true && success "jq installed via winget"
      elif command -v choco &>/dev/null; then
        choco install jq -y >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via Chocolatey"
      elif command -v scoop &>/dev/null; then
        scoop install jq >/dev/null 2>&1 && JQ_INSTALLED=true && success "jq installed via Scoop"
      fi ;;
  esac

  if ! $JQ_INSTALLED; then
    warn "jq auto-install skipped — Python fallback active (all features work without jq)"
  fi
fi

# ── git (필수 — 훅 내 git 명령) ────────────────────────────
if command -v git &>/dev/null; then
  success "git: $(git --version)"
else
  warn "git not found — git-related features will be limited"
fi

echo ""

# ════════════════════════════════════════════════════════════
# 1. 디렉토리 생성
# ════════════════════════════════════════════════════════════
info "Creating directories..."
mkdir -p "$SKILLS_DIR" "$HOME/.claude/projects" "$HOME/.claude/rules"
success "~/.claude/ structure ready"

# ════════════════════════════════════════════════════════════
# 2. 스킬 파일 복사
# ════════════════════════════════════════════════════════════
info "Installing skills (8 languages, 56+ commands)..."

cp -r "$AURAKIT_REPO/skills/aura"         "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-compact" "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-guard"   "$SKILLS_DIR/" 2>/dev/null || true

if should_install_lang "kr"; then
  for skill in 아우라 아우라빌드 아우라수정 아우라정리 아우라배포 아우라리뷰 아우라컴팩트; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "jp"; then
  for skill in オーラ オーラビルド "オーラ修正" "オーラ整理" オーラデプロイ オーラレビュー オーラコンパクト; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "zh"; then
  for skill in 奥拉 奥拉构建 奥拉修复 奥拉清理 奥拉部署 奥拉审查 奥拉压缩; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "es"; then
  for skill in aura-es aura-construir aura-arreglar aura-limpiar aura-desplegar aura-revisar aura-compactar; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "fr"; then
  for skill in aura-fr aura-construire aura-corriger aura-nettoyer aura-deployer aura-reviser aura-compresser; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "de"; then
  for skill in aura-de aura-bauen aura-beheben aura-aufraeumen aura-deployen aura-pruefen aura-komprimieren; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi
if should_install_lang "it"; then
  for skill in aura-it aura-costruire aura-correggere aura-pulire aura-distribuire aura-rivedere aura-compattare; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

success "Skills installed"

# ════════════════════════════════════════════════════════════
# 3. 훅 설치
# ════════════════════════════════════════════════════════════
info "Installing hooks..."
HOOKS_DEST="$HOME/.claude/skills/aurakit/hooks"
mkdir -p "$HOOKS_DEST/lib"
cp "$AURAKIT_REPO/hooks/"*.sh  "$HOOKS_DEST/" 2>/dev/null || true
cp "$AURAKIT_REPO/hooks/"*.py  "$HOOKS_DEST/" 2>/dev/null || true
cp "$AURAKIT_REPO/hooks/"*.js  "$HOOKS_DEST/" 2>/dev/null || true
cp "$AURAKIT_REPO/hooks/lib/"*.js "$HOOKS_DEST/lib/" 2>/dev/null || true
chmod +x "$HOOKS_DEST"/*.sh 2>/dev/null || true
success "Hooks installed"

# ════════════════════════════════════════════════════════════
# 3.5. 보안 규칙 설치
# ════════════════════════════════════════════════════════════
if [ -f "$AURAKIT_REPO/rules/aurakit-security.md" ]; then
  cp "$AURAKIT_REPO/rules/aurakit-security.md" "$HOME/.claude/rules/"
  success "Security rules installed (~/.claude/rules/)"
else
  warn "rules/aurakit-security.md not found — skipped"
fi

# ════════════════════════════════════════════════════════════
# 3.7. 상태바 설치 (AuraKit Nexus Status Bar)
# ════════════════════════════════════════════════════════════
info "Installing AuraKit Nexus status bar..."
if [ -d "$AURAKIT_REPO/statusline" ]; then
  cp "$AURAKIT_REPO/statusline/statusline-command.sh" "$HOME/.claude/"
  cp "$AURAKIT_REPO/statusline/statusline-parser.py"  "$HOME/.claude/"
  chmod +x "$HOME/.claude/statusline-command.sh"
  success "Status bar installed (responsive · subscription/API auto-detect)"
else
  warn "statusline/ directory not found — status bar not installed"
fi

# ════════════════════════════════════════════════════════════
# 4. settings.json 업데이트 (Python 우선, jq 폴백)
# ════════════════════════════════════════════════════════════
info "Configuring ~/.claude/settings.json..."

[ ! -f "$SETTINGS_FILE" ] && echo '{}' > "$SETTINGS_FILE"

_update_settings_python() {
  "$PYTHON_BIN" - "$SETTINGS_FILE" "$HP" << 'PYEOF'
import json, sys

sf = sys.argv[1]
hp = sys.argv[2]

try:
    with open(sf, 'r', encoding='utf-8') as f:
        d = json.load(f)
except Exception:
    d = {}

d['hooks'] = {
    'SessionStart': [
        {'type': 'command', 'command': f'{hp}/pre-session.sh'}
    ],
    'UserPromptSubmit': [
        {'type': 'command', 'command': f'node {hp}/korean-command.js'}
    ],
    'PreToolUse': [
        {'type': 'command', 'command': f'{hp}/security-scan.sh'},
        {'type': 'command', 'command': f'node {hp}/bash-guard.js'}
    ],
    'PostToolUse': [
        {'type': 'command', 'command': f'{hp}/build-verify.sh'},
        {'type': 'command', 'command': f'{hp}/bloat-check.sh'},
        {'type': 'command', 'command': f'node {hp}/instinct-auto-save.js'},
        {'type': 'command', 'command': f'node {hp}/auto-format.js'},
        {'type': 'command', 'command': f'node {hp}/governance-capture.js'}
    ],
    'PostToolUseFailure': [
        {'type': 'command', 'command': f'node {hp}/post-tool-failure.js'}
    ],
    'Stop': [
        {'type': 'command', 'command': f'node {hp}/session-stop.js'}
    ],
    'PreCompact': [
        {'type': 'command', 'command': f'{hp}/pre-compact-snapshot.sh'}
    ],
    'PostCompact': [
        {'type': 'command', 'command': f'{hp}/post-compact-restore.sh'}
    ]
}
d['statusLine'] = {
    'type': 'command',
    'command': 'bash ~/.claude/statusline-command.sh'
}

with open(sf, 'w', encoding='utf-8') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
print('OK')
PYEOF
}

_update_settings_jq() {
  local HOOKS_PATH="$HOME/.claude/skills/aurakit/hooks"
  if command -v cygpath &>/dev/null; then
    HOOKS_PATH=$(cygpath -w "$HOOKS_PATH")
  fi
  UPDATED=$(cat "$SETTINGS_FILE" | jq \
    --arg ss "${HOOKS_PATH}/pre-session.sh" \
    --arg kc "node ${HOOKS_PATH}/korean-command.js" \
    --arg bv "${HOOKS_PATH}/build-verify.sh" \
    --arg bc "${HOOKS_PATH}/bloat-check.sh" \
    --arg sc "${HOOKS_PATH}/security-scan.sh" \
    --arg pre "${HOOKS_PATH}/pre-compact-snapshot.sh" \
    --arg post "${HOOKS_PATH}/post-compact-restore.sh" \
    --arg ia "node ${HOOKS_PATH}/instinct-auto-save.js" \
    --arg ptf "node ${HOOKS_PATH}/post-tool-failure.js" \
    --arg stp "node ${HOOKS_PATH}/session-stop.js" \
    --arg af "node ${HOOKS_PATH}/auto-format.js" \
    --arg gc "node ${HOOKS_PATH}/governance-capture.js" \
    --arg bg "node ${HOOKS_PATH}/bash-guard.js" \
    '.hooks = {
      "SessionStart": [{"type":"command","command":$ss}],
      "UserPromptSubmit": [{"type":"command","command":$kc}],
      "PreToolUse": [{"type":"command","command":$sc},{"type":"command","command":$bg}],
      "PostToolUse": [{"type":"command","command":$bv},{"type":"command","command":$bc},{"type":"command","command":$ia},{"type":"command","command":$af},{"type":"command","command":$gc}],
      "PostToolUseFailure": [{"type":"command","command":$ptf}],
      "Stop": [{"type":"command","command":$stp}],
      "PreCompact": [{"type":"command","command":$pre}],
      "PostCompact": [{"type":"command","command":$post}]
    } | .statusLine = {"type":"command","command":"bash ~/.claude/statusline-command.sh"}')
  echo "$UPDATED" > "$SETTINGS_FILE"
}

if [ -n "$PYTHON_BIN" ]; then
  _update_settings_python && success "settings.json updated via Python (hooks + statusLine)"
elif $JQ_INSTALLED; then
  _update_settings_jq && success "settings.json updated via jq (hooks + statusLine)"
else
  warn "Neither Python nor jq available — cannot auto-update settings.json"
  warn "Please add manually. See: https://github.com/smorky85/aurakit#manual-setup"
fi

# ════════════════════════════════════════════════════════════
# 5. 환경 변수 (.bashrc / .zshrc)
# ════════════════════════════════════════════════════════════
info "Setting compact threshold..."
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "$SHELL_RC" 2>/dev/null; then
  echo 'export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65' >> "$SHELL_RC"
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 → $SHELL_RC"
else
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE already set"
fi

# ════════════════════════════════════════════════════════════
# 6. 완료
# ════════════════════════════════════════════════════════════
echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║        AuraKit v2.0 — Installation complete!     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
echo "  Installed:"
echo "    ✓ 56+ skill commands (8 languages)"
echo "    ✓ 13 security & automation hooks"
echo "    ✓ AuraKit Nexus status bar (responsive · subscription/API)"
echo "    ✓ Always-active security rules"
echo ""
echo "  Status bar features:"
echo "    • Subscription users → daily/weekly remaining % (일↓88% 주↓92%)"
echo "    • API users         → actual cost display (\$0.23)"
echo "    • Auto-resizes: 3-line (≥80 cols) · 2-line · 1-line (<55 cols)"
echo "    • Language auto-detect: 한국어/日本語/中文/English/..."
echo ""
echo "  Quick start:"
echo "    /aura build: login with JWT    # BUILD"
echo "    /aura fix: TypeError           # FIX"
echo "    /aura review:                  # REVIEW"
echo "    /aura deploy: vercel           # DEPLOY"
echo "    /aura! change button color     # QUICK"
echo ""
echo "  ▶ Restart Claude Code to activate."
echo ""
