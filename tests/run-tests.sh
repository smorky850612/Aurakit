#!/usr/bin/env bash
# AuraKit Test Runner v2.0 — Automated (40/40 AuraScore)
# Usage: bash tests/run-tests.sh
# No manual /aura execution required — all tests run automatically.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="${REPO}/hooks"
RESULTS_DIR="${REPO}/tests/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="${RESULTS_DIR}/result-${TIMESTAMP}.md"

mkdir -p "$RESULTS_DIR"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; FAIL=0; TOTAL=0

_pass() { local pts=${2:-2}; echo -e "  ${GREEN}✓${NC} $1 (+${pts}pts)"; PASS=$((PASS + pts)); TOTAL=$((TOTAL + pts)); }
_fail() { local pts=${2:-2}; echo -e "  ${RED}✗${NC} $1 (-${pts}pts)"; FAIL=$((FAIL + pts)); TOTAL=$((TOTAL + pts)); }
_section() { echo -e "\n${BLUE}[$1]${NC} $2"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   AuraKit Test Runner v2.0           ║"
echo "  ║   Automated · AuraScore /40          ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ════════════════════════════════════════════════════════════
# 1. STRUCTURE TESTS (16 pts)
# ════════════════════════════════════════════════════════════
_section "1/4" "Structure Tests (16 pts)"

# S-1: SKILL.md exists
if [[ -f "${REPO}/skills/aura/SKILL.md" ]]; then _pass "SKILL.md exists"; else _fail "SKILL.md missing"; fi

# S-2: hooks directory has JS hooks
js_count=$(ls "${HOOKS}"/*.js 2>/dev/null | wc -l)
if [[ $js_count -ge 5 ]]; then _pass "JS hooks: ${js_count} found"; else _fail "JS hooks: expected ≥5, got ${js_count}"; fi

# S-3: hooks/lib/common.js exists
if [[ -f "${HOOKS}/lib/common.js" ]]; then _pass "hooks/lib/common.js exists"; else _fail "hooks/lib/common.js missing"; fi

# S-4: install.sh exists
if [[ -f "${REPO}/install.sh" ]]; then _pass "install.sh exists"; else _fail "install.sh missing"; fi

# S-5: package.json is valid JSON (cat→stdin avoids Windows path issues)
if cat "${REPO}/package.json" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{try{JSON.parse(s);process.exit(0)}catch{process.exit(1)}})" 2>/dev/null; then _pass "package.json valid JSON"; else _fail "package.json invalid JSON"; fi

# S-6: rules/aurakit-security.md exists
if [[ -f "${REPO}/rules/aurakit-security.md" ]]; then _pass "security rules exist"; else _fail "security rules missing"; fi

# S-7: benchmarks directory has 5 tasks
task_count=$(ls "${REPO}/benchmarks/tasks/"*.md 2>/dev/null | wc -l)
if [[ $task_count -ge 5 ]]; then _pass "benchmarks: ${task_count} tasks"; else _fail "benchmarks: expected ≥5 tasks, got ${task_count}"; fi

# S-8: Formula/aurakit.rb exists
if [[ -f "${REPO}/Formula/aurakit.rb" ]]; then _pass "Homebrew formula exists"; else _fail "Homebrew formula missing"; fi

# ════════════════════════════════════════════════════════════
# 2. HOOK UNIT TESTS (16 pts)
# ════════════════════════════════════════════════════════════
_section "2/4" "Hook Unit Tests (16 pts)"

# H-1: bash-guard blocks force push to main
input='{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}'
if echo "$input" | node "${HOOKS}/bash-guard.js" 2>/dev/null; then
  _fail "bash-guard: should block 'git push --force origin main'" 4
else
  _pass "bash-guard: blocks force push to main" 4
fi

# H-2: bash-guard blocks git clean -f
input='{"tool_name":"Bash","tool_input":{"command":"git clean -fd ."}}'
if echo "$input" | node "${HOOKS}/bash-guard.js" 2>/dev/null; then
  _fail "bash-guard: should block 'git clean -fd'" 4
else
  _pass "bash-guard: blocks git clean -fd" 4
fi

# H-3: bash-guard allows safe command
input='{"tool_name":"Bash","tool_input":{"command":"git status"}}'
if echo "$input" | node "${HOOKS}/bash-guard.js" 2>/dev/null; then
  _pass "bash-guard: allows safe command (git status)" 4
else
  _fail "bash-guard: incorrectly blocked safe command" 4
fi

# H-4: bash-guard.js has valid Node syntax
if node --check "${HOOKS}/bash-guard.js" 2>/dev/null; then _pass "bash-guard.js syntax valid" 4; else _fail "bash-guard.js syntax error" 4; fi

# ════════════════════════════════════════════════════════════
# 3. INSTALL SCRIPT TESTS (8 pts)
# ════════════════════════════════════════════════════════════
_section "3/4" "Install Script Tests (8 pts)"

# I-1: install.sh has --auto flag support
if grep -q 'AUTO_MODE' "${REPO}/install.sh"; then _pass "install.sh: --auto flag implemented" 4; else _fail "install.sh: --auto flag missing" 4; fi

# I-2: install.sh bash syntax valid
if bash -n "${REPO}/install.sh" 2>/dev/null; then _pass "install.sh: bash syntax valid" 4; else _fail "install.sh: bash syntax error" 4; fi

# ════════════════════════════════════════════════════════════
# 4. SETTINGS.JSON TESTS (0 pts — optional, user-specific)
# ════════════════════════════════════════════════════════════
_section "4/4" "Settings.json (info only — user-specific)"

SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  if node -e "const s=require('$SETTINGS'); process.exit(s.hooks ? 0 : 1)" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} hooks registered in settings.json"
  else
    echo -e "  ${YELLOW}!${NC} hooks not found in settings.json (run: bash install.sh)"
  fi
  if node -e "const s=require('$SETTINGS'); process.exit(s.statusLine ? 0 : 1)" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} statusLine configured"
  else
    echo -e "  ${YELLOW}!${NC} statusLine not configured"
  fi
else
  echo -e "  ${YELLOW}!${NC} ~/.claude/settings.json not found (run: bash install.sh)"
fi

# ════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════
SCORE=$PASS
echo ""
echo "  ══════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}AuraScore: ${SCORE}/40 — ALL PASS ✓${NC}"
else
  echo -e "  ${YELLOW}AuraScore: ${SCORE}/40${NC} (${FAIL} pts failed)"
fi
echo "  ══════════════════════════════════════"
echo ""

# Write result
cat > "$RESULT_FILE" << EOF
# AuraKit Test Results — $TIMESTAMP
- AuraScore: ${SCORE}/40
- Pass: ${PASS}pts  Fail: ${FAIL}pts
- Version: $(node -e "console.log(require('${REPO}/package.json').version)" 2>/dev/null)
EOF
echo "Results: ${RESULT_FILE}"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
