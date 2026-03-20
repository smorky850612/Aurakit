#!/bin/bash
# AuraKit — Token Usage Tracker
# Hook: Stop
# stdin: JSON (session_id, transcript_path, stop_reason)
# 역할: 매 응답 완료 시 API 토큰 사용량을 .aura/token-stats.json에 누적

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
[ -z "$PYTHON" ] && exit 0
"$PYTHON" "${SCRIPT_DIR}/token-tracker.py" 2>/dev/null || true
exit 0
