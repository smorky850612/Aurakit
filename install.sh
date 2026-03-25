#!/bin/bash
# ============================================================
# AuraKit Installer v1.0
# One-line install: bash install.sh
# ============================================================

set -euo pipefail

AURAKIT_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
HOOKS_DIR="$HOME/.claude"
SETTINGS_FILE="$HOME/.claude/settings.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[AuraKit]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

# Optional: --lang=ko,en,jp,zh,es,fr,de,it (default: all)
LANG_FILTER=""
for arg in "$@"; do
  case "$arg" in
    --lang=*) LANG_FILTER="${arg#--lang=}" ;;
  esac
done

should_install_lang() {
  [ -z "$LANG_FILTER" ] && return 0
  echo ",$LANG_FILTER," | grep -qi ",${1}," && return 0
  return 1
}

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     AuraKit Installer v1.0           ║"
echo "  ║  8-Lang · 6-Layer Security · 75% opt ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── 0. Prerequisites ────────────────────────────────────────
command -v claude &>/dev/null || error "Claude Code not found. Install from https://claude.ai/code"
info "Claude Code detected"

# ── 1. Create directories ──────────────────────────────────
info "Creating directories..."
mkdir -p "$SKILLS_DIR"
mkdir -p "$HOME/.claude/projects"
success "~/.claude/skills/ ready"

# ── 2. Copy core skills ────────────────────────────────────
info "Installing skill files..."

# aura (main engine)
cp -r "$AURAKIT_REPO/skills/aura"         "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-compact" "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-guard"   "$SKILLS_DIR/" 2>/dev/null || true

# Korean (KR)
if should_install_lang "kr"; then
  for skill in 아우라 아우라빌드 아우라수정 아우라정리 아우라배포 아우라리뷰 아우라컴팩트; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Japanese (JP)
if should_install_lang "jp"; then
  for skill in オーラ オーラビルド "オーラ修正" "オーラ整理" オーラデプロイ オーラレビュー オーラコンパクト; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Chinese (ZH)
if should_install_lang "zh"; then
  for skill in 奥拉 奥拉构建 奥拉修复 奥拉清理 奥拉部署 奥拉审查 奥拉压缩; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Spanish (ES)
if should_install_lang "es"; then
  for skill in aura-es aura-construir aura-arreglar aura-limpiar aura-desplegar aura-revisar aura-compactar; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# French (FR)
if should_install_lang "fr"; then
  for skill in aura-fr aura-construire aura-corriger aura-nettoyer aura-deployer aura-reviser aura-compresser; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# German (DE)
if should_install_lang "de"; then
  for skill in aura-de aura-bauen aura-beheben aura-aufraeumen aura-deployen aura-pruefen aura-komprimieren; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Italian (IT)
if should_install_lang "it"; then
  for skill in aura-it aura-costruire aura-correggere aura-pulire aura-distribuire aura-rivedere aura-compattare; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

success "Skills installed (8 languages, 56+ commands)"

# ── 3. Install hooks ───────────────────────────────────────
info "Installing hooks..."
HOOKS_SRC="$AURAKIT_REPO/hooks"
HOOKS_DEST="$HOME/.claude/skills/aurakit/hooks"
mkdir -p "$HOOKS_DEST/lib"
cp "$HOOKS_SRC"/*.sh  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC"/*.py  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC"/*.js  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC/lib"/*.js "$HOOKS_DEST/lib/" 2>/dev/null || true
chmod +x "$HOOKS_DEST"/*.sh 2>/dev/null || true
success "13 hooks + lib installed"

# ── 3.5. Global security rules (~/.claude/rules/) ─────────
info "Installing global security rules..."
RULES_DIR="$HOME/.claude/rules"
mkdir -p "$RULES_DIR"
if [ -f "$AURAKIT_REPO/rules/aurakit-security.md" ]; then
  cp "$AURAKIT_REPO/rules/aurakit-security.md" "$RULES_DIR/"
  success "~/.claude/rules/aurakit-security.md installed (always-active)"
else
  warn "rules/aurakit-security.md not found — skipped"
fi

# ── 4. Update settings.json ────────────────────────────────
info "Configuring settings.json..."

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

if command -v jq &>/dev/null; then
  HOOKS_PATH="$HOME/.claude/skills/aurakit/hooks"
  if command -v cygpath &>/dev/null; then
    HOOKS_PATH_WIN=$(cygpath -w "$HOOKS_PATH")
  else
    HOOKS_PATH_WIN="$HOOKS_PATH"
  fi

  CURRENT=$(cat "$SETTINGS_FILE")
  UPDATED=$(echo "$CURRENT" | jq \
    --arg ss "$HOOKS_PATH_WIN\\pre-session.sh" \
    --arg kc "node $HOOKS_PATH_WIN\\korean-command.js" \
    --arg bv "$HOOKS_PATH_WIN\\build-verify.sh" \
    --arg bc "$HOOKS_PATH_WIN\\bloat-check.sh" \
    --arg sc "$HOOKS_PATH_WIN\\security-scan.sh" \
    --arg pre "$HOOKS_PATH_WIN\\pre-compact-snapshot.sh" \
    --arg post "$HOOKS_PATH_WIN\\post-compact-restore.sh" \
    --arg ia "node $HOOKS_PATH_WIN\\instinct-auto-save.js" \
    --arg ptf "node $HOOKS_PATH_WIN\\post-tool-failure.js" \
    --arg stp "node $HOOKS_PATH_WIN\\session-stop.js" \
    --arg af "node $HOOKS_PATH_WIN\\auto-format.js" \
    --arg gc "node $HOOKS_PATH_WIN\\governance-capture.js" \
    --arg bg "node $HOOKS_PATH_WIN\\bash-guard.js" \
    '.hooks = {
      "SessionStart": [{"type": "command", "command": $ss}],
      "UserPromptSubmit": [{"type": "command", "command": $kc}],
      "PostToolUse": [
        {"type": "command", "command": $bv},
        {"type": "command", "command": $bc},
        {"type": "command", "command": $ia},
        {"type": "command", "command": $af},
        {"type": "command", "command": $gc}
      ],
      "PostToolUseFailure": [{"type": "command", "command": $ptf}],
      "PreToolUse": [
        {"type": "command", "command": $sc},
        {"type": "command", "command": $bg}
      ],
      "Stop": [{"type": "command", "command": $stp}],
      "PreCompact": [{"type": "command", "command": $pre}],
      "PostCompact": [{"type": "command", "command": $post}]
    }')
  echo "$UPDATED" > "$SETTINGS_FILE"
  success "settings.json updated (hooks registered)"
else
  warn "jq not found — manual setup required."
  warn "Add the following hooks to your settings.json:"
  echo ""
  echo '  "hooks": {'
  echo '    "SessionStart":        [{"type":"command","command":"~/.claude/skills/aurakit/hooks/pre-session.sh"}],'
  echo '    "UserPromptSubmit":    [{"type":"command","command":"node ~/.claude/skills/aurakit/hooks/korean-command.js"}],'
  echo '    "PreToolUse":         ['
  echo '      {"type":"command","command":"~/.claude/skills/aurakit/hooks/security-scan.sh"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/bash-guard.js"}'
  echo '    ],'
  echo '    "PostToolUse":        ['
  echo '      {"type":"command","command":"~/.claude/skills/aurakit/hooks/build-verify.sh"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/bloat-check.js"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/instinct-auto-save.js"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/auto-format.js"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/governance-capture.js"}'
  echo '    ],'
  echo '    "PostToolUseFailure": [{"type":"command","command":"node ~/.claude/skills/aurakit/hooks/post-tool-failure.js"}],'
  echo '    "Stop":               [{"type":"command","command":"node ~/.claude/skills/aurakit/hooks/session-stop.js"}],'
  echo '    "PreCompact":         [{"type":"command","command":"~/.claude/skills/aurakit/hooks/pre-compact-snapshot.sh"}],'
  echo '    "PostCompact":        [{"type":"command","command":"~/.claude/skills/aurakit/hooks/post-compact-restore.sh"}]'
  echo '  }'
fi

# ── 5. Environment variable ────────────────────────────────
info "Setting compact threshold..."
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "$SHELL_RC" 2>/dev/null; then
  echo 'export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65' >> "$SHELL_RC"
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 added to $SHELL_RC"
else
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE already set"
fi

# ── 6. Done ────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║      Installation complete!          ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  Usage:"
echo "    /aura build: login with JWT    # BUILD"
echo "    /aura fix: TypeError           # FIX"
echo "    /aura review:                  # REVIEW"
echo "    /aura deploy: vercel           # DEPLOY"
echo "    /aura! change button color     # QUICK"
echo ""
echo "  Restart Claude Code to activate."
echo ""
