#!/usr/bin/env python3
"""
AuraKit Token Stats Injector — UserPromptSubmit Hook
.aura/token-stats.json 를 읽어 오늘/주간 사용량을 컨텍스트에 주입.
한도는 .aura/token-limits.json 에서 로드 (없으면 무제한).
stdin: UserPromptSubmit hook JSON
stdout: {"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "..."}}
"""
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path

# stdin은 소비하되 실패해도 계속
try:
    json.load(sys.stdin)
except Exception:
    pass

stats_file = Path('.aura/token-stats.json')
if not stats_file.exists():
    sys.exit(0)

try:
    stats = json.loads(stats_file.read_text(encoding='utf-8'))
except Exception:
    sys.exit(0)

today      = datetime.now().strftime('%Y-%m-%d')
week_start = (datetime.now() - timedelta(days=datetime.now().weekday())).strftime('%Y-%m-%d')

def K(n: int) -> str:
    if n >= 1_000_000:
        return f"{n/1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n/1_000:.1f}K"
    return str(n)

def limit_str(used: int, limit) -> str:
    if limit:
        pct = min(used * 100 // limit, 999)
        return f"{K(used)}/{K(limit)} ({pct}%)"
    return K(used)

today_data   = stats.get(today, {})
today_in     = today_data.get('input', 0)
today_out    = today_data.get('output', 0)
today_cache  = today_data.get('cache_read', 0)
today_calls  = today_data.get('calls', 0)
today_total  = today_in + today_out

weekly_in    = sum(v.get('input', 0)  for k, v in stats.items() if k >= week_start)
weekly_out   = sum(v.get('output', 0) for k, v in stats.items() if k >= week_start)
weekly_calls = sum(v.get('calls', 0)  for k, v in stats.items() if k >= week_start)
weekly_total = weekly_in + weekly_out

# 사용자 한도 설정 (없으면 None)
daily_limit = weekly_limit = None
config_file = Path('.aura/token-limits.json')
if config_file.exists():
    try:
        cfg = json.loads(config_file.read_text())
        daily_limit  = cfg.get('daily')
        weekly_limit = cfg.get('weekly')
    except Exception:
        pass

parts = [f"[AuraKit 토큰] 오늘({today}): ↑{K(today_in)} ↓{K(today_out)} = {limit_str(today_total, daily_limit)} ({today_calls}회)"]
parts.append(f"주간: {limit_str(weekly_total, weekly_limit)} ({weekly_calls}회)")
if today_cache:
    parts.append(f"캐시절약: {K(today_cache)}")

context = " | ".join(parts)

print(json.dumps({
    "continue": True,
    "additionalContext": context
}))
