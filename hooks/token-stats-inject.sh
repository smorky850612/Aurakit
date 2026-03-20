#!/bin/bash
# AuraKit — Token Stats Injector
# Hook: UserPromptSubmit
# stdin: UserPromptSubmit hook JSON
# 역할: .aura/token-stats.json 읽어 오늘/주간 사용량을 additionalContext에 주입

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
[ -z "$PYTHON" ] && exit 0
"$PYTHON" "${SCRIPT_DIR}/token-stats-inject.py" 2>/dev/null || true
exit 0
