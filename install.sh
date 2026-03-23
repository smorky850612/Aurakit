#!/bin/bash
# ============================================================
# AuraKit Installer v1.0
# 한 줄로 설치: bash <(curl -fsSL https://raw.githubusercontent.com/.../install.sh)
# ============================================================

set -euo pipefail

AURAKIT_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"
HOOKS_DIR="$HOME/.claude"
SETTINGS_FILE="$HOME/.claude/settings.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[AuraKit]${NC} $*"; }
success() { echo -e "${GREEN}[✅]${NC} $*"; }
warn()    { echo -e "${YELLOW}[⚠️]${NC} $*"; }
error()   { echo -e "${RED}[❌]${NC} $*"; exit 1; }

# Optional: --lang=ko,en,jp,zh,es,fr,de,it (default: all)
LANG_FILTER=""
for arg in "$@"; do
  case "$arg" in
    --lang=*) LANG_FILTER="${arg#--lang=}" ;;
  esac
done

# 언어 필터 함수 (비어있으면 전체 설치)
should_install_lang() {
  [ -z "$LANG_FILTER" ] && return 0
  echo ",$LANG_FILTER," | grep -qi ",${1}," && return 0
  return 1
}

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     AuraKit Installer v1.0           ║"
echo "  ║  8-Lang · 6-Layer Security · ~55% 절감  ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── 0. 사전 확인 ──────────────────────────────────────────────
command -v claude &>/dev/null || error "Claude Code가 설치되어 있지 않습니다. https://claude.ai/code"
info "Claude Code 감지됨 ✓"

# ── 1. 디렉토리 생성 ──────────────────────────────────────────
info "디렉토리 생성 중..."
mkdir -p "$SKILLS_DIR"
mkdir -p "$HOME/.claude/projects"
success "~/.claude/skills/ 준비 완료"

# ── 2. 핵심 스킬 복사 ─────────────────────────────────────────
info "스킬 파일 설치 중..."

# aura (메인 엔진)
cp -r "$AURAKIT_REPO/skills/aura"         "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-compact" "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-guard"   "$SKILLS_DIR/" 2>/dev/null || true

# 한국어 (KR) — 7개
if should_install_lang "kr"; then
  for skill in 아우라 아우라빌드 아우라수정 아우라정리 아우라배포 아우라리뷰 아우라컴팩트; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# 日本語 (JP) — 7개
if should_install_lang "jp"; then
  for skill in オーラ オーラビルド "オーラ修正" "オーラ整理" オーラデプロイ オーラレビュー オーラコンパクト; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# 中文 (ZH) — 7개
if should_install_lang "zh"; then
  for skill in 奥拉 奥拉构建 奥拉修复 奥拉清理 奥拉部署 奥拉审查 奥拉压缩; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Español (ES) — 7개
if should_install_lang "es"; then
  for skill in aura-es aura-construir aura-arreglar aura-limpiar aura-desplegar aura-revisar aura-compactar; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Français (FR) — 7개
if should_install_lang "fr"; then
  for skill in aura-fr aura-construire aura-corriger aura-nettoyer aura-deployer aura-reviser aura-compresser; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Deutsch (DE) — 7개
if should_install_lang "de"; then
  for skill in aura-de aura-bauen aura-beheben aura-aufraeumen aura-deployen aura-pruefen aura-komprimieren; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

# Italiano (IT) — 7개
if should_install_lang "it"; then
  for skill in aura-it aura-costruire aura-correggere aura-pulire aura-distribuire aura-rivedere aura-compattare; do
    cp -r "$AURAKIT_REPO/skills/$skill" "$SKILLS_DIR/" 2>/dev/null || true
  done
fi

success "스킬 설치 완료 (8개 언어, 56개 명령어)"

# ── 3. hooks 설정 ─────────────────────────────────────────────
info "Hooks 설정 중..."
HOOKS_SRC="$AURAKIT_REPO/hooks"
HOOKS_DEST="$HOME/.claude/skills/aurakit/hooks"
mkdir -p "$HOOKS_DEST/lib"
cp "$HOOKS_SRC"/*.sh  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC"/*.py  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC"/*.js  "$HOOKS_DEST/" 2>/dev/null || true
cp "$HOOKS_SRC/lib"/*.js "$HOOKS_DEST/lib/" 2>/dev/null || true
chmod +x "$HOOKS_DEST"/*.sh 2>/dev/null || true
success "Hooks 설치 완료 (sh/py/js + lib/)"

# ── 3.5. 글로벌 규칙 설치 (~/.claude/rules/) ──────────────────────────
info "글로벌 보안 규칙 설치 중 (~/.claude/rules/)..."
RULES_DIR="$HOME/.claude/rules"
mkdir -p "$RULES_DIR"
if [ -f "$AURAKIT_REPO/rules/aurakit-security.md" ]; then
  cp "$AURAKIT_REPO/rules/aurakit-security.md" "$RULES_DIR/"
  success "~/.claude/rules/aurakit-security.md 설치 완료 (항상-활성 보안 규칙)"
else
  warn "rules/aurakit-security.md 없음 — 건너뜀 (기능 영향 없음)"
fi

# ── 4. settings.json 업데이트 ────────────────────────────────
info "settings.json 설정 중..."

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# jq 있으면 정밀 업데이트, 없으면 안내
if command -v jq &>/dev/null; then
  HOOKS_PATH="$HOME/.claude/skills/aurakit/hooks"
  # Windows 경로 변환 (Git Bash)
  if command -v cygpath &>/dev/null; then
    HOOKS_PATH_WIN=$(cygpath -w "$HOOKS_PATH")
  else
    HOOKS_PATH_WIN="$HOOKS_PATH"
  fi

  CURRENT=$(cat "$SETTINGS_FILE")
  UPDATED=$(echo "$CURRENT" | jq \
    --arg ss "$HOOKS_PATH_WIN\\pre-session.sh" \
    --arg kc "$HOOKS_PATH_WIN\\korean-command.sh" \
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
      "PreToolUse": [{"type": "command", "command": $sc}],
      "Stop": [{"type": "command", "command": $stp}],
      "PreCompact": [{"type": "command", "command": $pre}],
      "PostCompact": [{"type": "command", "command": $post}]
    }')
  echo "$UPDATED" > "$SETTINGS_FILE"
  success "settings.json 업데이트 완료 (hooks 자동 설정)"
else
  warn "jq가 없어 settings.json을 수동으로 설정해야 합니다."
  warn "다음 hooks를 settings.json에 추가하세요:"
  echo ""
  echo '  "hooks": {'
  echo '    "SessionStart":        [{"type":"command","command":"~/.claude/skills/aurakit/hooks/pre-session.sh"}],'
  echo '    "UserPromptSubmit":    [{"type":"command","command":"~/.claude/skills/aurakit/hooks/korean-command.sh"}],'
  echo '    "PreToolUse":         [{"type":"command","command":"~/.claude/skills/aurakit/hooks/security-scan.sh"}],'
  echo '    "PostToolUse":        ['
  echo '      {"type":"command","command":"~/.claude/skills/aurakit/hooks/build-verify.sh"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/auto-format.js"},'
  echo '      {"type":"command","command":"node ~/.claude/skills/aurakit/hooks/governance-capture.js"}'
  echo '    ],'
  echo '    "PostToolUseFailure": [{"type":"command","command":"node ~/.claude/skills/aurakit/hooks/post-tool-failure.js"}],'
  echo '    "Stop":               [{"type":"command","command":"node ~/.claude/skills/aurakit/hooks/session-stop.js"}],'
  echo '    "PreCompact":         [{"type":"command","command":"~/.claude/skills/aurakit/hooks/pre-compact-snapshot.sh"}],'
  echo '    "PostCompact":        [{"type":"command","command":"~/.claude/skills/aurakit/hooks/post-compact-restore.sh"}]'
  echo '  }'
fi

# ── 5. 환경변수 설정 ──────────────────────────────────────────
info "자동 compact 임계값 설정 중..."
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "$SHELL_RC" 2>/dev/null; then
  echo 'export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65' >> "$SHELL_RC"
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 추가됨 ($SHELL_RC)"
else
  success "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE 이미 설정됨"
fi

# ── 6. 설치 확인 ──────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║        설치 완료! 🎉                  ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  사용법:"
echo "    /aura 기능 만들어줘          # BUILD"
echo "    /아우라 버그 수정해줘         # KR"
echo "    /オーラビルド 機能を追加       # JP"
echo "    /奥拉构建 实现登录功能         # ZH"
echo "    /aura-construir función login # ES"
echo "    /aura! 버튼 색상 변경         # QUICK"
echo ""
echo "  Claude Code 재시작 후 활성화됩니다."
echo ""
