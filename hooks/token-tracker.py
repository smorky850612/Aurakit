#!/usr/bin/env python3
"""
AuraKit Token Tracker — Stop Hook
매 응답 완료 시 API 토큰 사용량을 .aura/token-stats.json에 누적 저장.
stdin: {"session_id": "...", "transcript_path": "...", "stop_reason": "..."}
"""
import json
import sys
import os
from datetime import datetime
from pathlib import Path

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

transcript_path = data.get('transcript_path', '')
if not transcript_path or not os.path.exists(transcript_path):
    sys.exit(0)

# 트랜스크립트에서 마지막 어시스턴트 응답의 usage 추출
input_tokens = output_tokens = cache_read = cache_write = 0
try:
    with open(transcript_path, encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    for line in reversed(lines):
        try:
            entry = json.loads(line.strip())
            if entry.get('type') == 'assistant':
                usage = entry.get('message', {}).get('usage', {})
                if usage.get('input_tokens') or usage.get('output_tokens'):
                    input_tokens  = usage.get('input_tokens', 0)
                    output_tokens = usage.get('output_tokens', 0)
                    cache_read    = usage.get('cache_read_input_tokens', 0)
                    cache_write   = usage.get('cache_write_input_tokens', 0)
                    break
        except Exception:
            continue
except Exception:
    sys.exit(0)

if not (input_tokens or output_tokens):
    sys.exit(0)

# .aura/token-stats.json 에 누적
stats_file = Path('.aura/token-stats.json')
stats_file.parent.mkdir(exist_ok=True)
today = datetime.now().strftime('%Y-%m-%d')

stats = {}
if stats_file.exists():
    try:
        stats = json.loads(stats_file.read_text(encoding='utf-8'))
    except Exception:
        pass

if today not in stats:
    stats[today] = {'input': 0, 'output': 0, 'cache_read': 0, 'cache_write': 0, 'calls': 0}

d = stats[today]
d['input']       += input_tokens
d['output']      += output_tokens
d['cache_read']  += cache_read
d['cache_write'] += cache_write
d['calls']       += 1

stats_file.write_text(json.dumps(stats, indent=2), encoding='utf-8')
