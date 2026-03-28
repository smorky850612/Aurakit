import json, sys, shlex, os, re

try:
    raw = sys.stdin.read()
    d = json.loads(raw)
except Exception:
    raw = ''
    d = {}

# Debug: save JSON structure once so we can inspect actual fields
try:
    dbg_path = os.path.join(os.path.expanduser('~'), '.claude', '.statusline-debug.json')
    if not os.path.isfile(dbg_path) and d:
        import copy
        rl_dbg = d.get('rate_limits') or {}
        with open(dbg_path, 'w') as f:
            json.dump({
                'top_keys': sorted(d.keys()),
                'rate_limit_keys': sorted(rl_dbg.keys()),
                'five_hour': dict(rl_dbg.get('five_hour') or {}),
                'seven_day': dict(rl_dbg.get('seven_day') or {}),
                'monthly': dict(rl_dbg.get('monthly') or {}),
                'model_keys': sorted((d.get('model') or {}).keys()),
                'context_window_keys': sorted((d.get('context_window') or {}).keys()),
                'cost': dict(d.get('cost') or {}),
                'cost_keys': sorted((d.get('cost') or {}).keys()),
                'scalars': {k: v for k, v in d.items()
                            if not isinstance(v, (dict, list)) and k not in ('transcript_path',)},
            }, f, indent=2)
except Exception:
    pass

def g(obj, *keys, default=''):
    for k in keys:
        if isinstance(obj, dict):
            obj = obj.get(k)
            if obj is None:
                return default
        else:
            return default
    return str(obj) if obj is not None else default

m  = d.get('model', {}) or {}
cw = d.get('context_window', {}) or {}
cu = cw.get('current_usage', {}) or {}
rl = d.get('rate_limits', {}) or {}
fh = rl.get('five_hour', {}) or {}
sd = rl.get('seven_day', {}) or {}
ss = rl.get('seven_day_sonnet', {}) or {}
mo = rl.get('monthly', {}) or {}
co = d.get('cost', {}) or {}

cwd_val = d.get('cwd') or (d.get('workspace') or {}).get('current_dir', '') or ''
transcript_path = d.get('transcript_path', '')

# Subscription vs API detection
five_pct_val    = fh.get('used_percentage')
seven_pct_val   = sd.get('used_percentage')
monthly_pct_val = mo.get('used_percentage')
is_subscription = '1' if (five_pct_val is not None or seven_pct_val is not None or monthly_pct_val is not None) else '0'

# Rate limit absolute values (seconds for time-based, or token count)
# five_hour default = 5h = 18000s
five_limit_val    = fh.get('limit', 18000)
seven_limit_val   = sd.get('limit', 0)
monthly_limit_val = mo.get('limit', 0)

# Plan name: manual override file > JSON field > rate_limits inference
plan_override_file = os.path.join(os.path.expanduser('~'), '.claude', '.aura-plan')
raw_plan = ''
if os.path.isfile(plan_override_file):
    try:
        with open(plan_override_file, 'r') as f:
            raw_plan = f.read().strip()
    except Exception:
        pass
if not raw_plan:
    raw_plan = (d.get('plan_name') or d.get('plan') or
                d.get('subscription_plan') or d.get('claude_plan') or '')
if not raw_plan and is_subscription == '1':
    if monthly_pct_val is not None:
        raw_plan = 'Max'
    elif five_limit_val and int(str(five_limit_val)) > 18000:
        # Limit larger than standard Pro 5h (18000s) → Max
        raw_plan = 'Max'
    elif seven_pct_val is not None:
        raw_plan = 'Pro'
    else:
        raw_plan = 'Free'
# Sanitize: alphanumeric + space/dash only
plan_name = re.sub(r'[^A-Za-z0-9 _\-]', '', str(raw_plan))[:16].strip()

# Terminal width from Claude Code JSON (may or may not be present)
terminal_width_val = (d.get('terminal_width') or d.get('columns') or
                      d.get('screen_width') or d.get('terminalWidth') or 0)

# Read first timestamp from transcript (JSONL format)
first_ts = ''
if transcript_path and os.path.isfile(transcript_path):
    try:
        with open(transcript_path, 'r', encoding='utf-8', errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    ts = obj.get('timestamp', '')
                    if ts:
                        first_ts = ts
                        break
                except Exception:
                    pass
    except Exception:
        pass

fields = [
    ('model_name',      g(m,  'display_name', default='Unknown')),
    ('model_id',        g(m,  'id')),
    ('session_id',      d.get('session_id', '')),
    ('cwd',             cwd_val),
    ('transcript',      transcript_path),
    ('first_ts',        first_ts),
    ('used_pct',        g(cw, 'used_percentage')),
    ('total_input',     str(cw.get('total_input_tokens', 0))),
    ('total_output',    str(cw.get('total_output_tokens', 0))),
    ('ctx_size',        str(cw.get('context_window_size', 200000))),
    ('cur_input',       str(cu.get('input_tokens', 0))),
    ('five_pct',        '' if five_pct_val is None else str(five_pct_val)),
    ('five_reset',      g(fh, 'resets_at')),
    ('five_limit',      str(five_limit_val)),
    ('seven_pct',       '' if seven_pct_val is None else str(seven_pct_val)),
    ('seven_reset',     g(sd, 'resets_at')),
    ('seven_limit',     str(seven_limit_val)),
    ('seven_s_pct',     g(ss, 'used_percentage')),
    ('monthly_pct',     '' if monthly_pct_val is None else str(monthly_pct_val)),
    ('monthly_reset',   g(mo, 'resets_at')),
    ('monthly_limit',   str(monthly_limit_val)),
    ('is_subscription', is_subscription),
    ('plan_name',       plan_name),
    ('terminal_width',  str(int(terminal_width_val) if terminal_width_val else 0)),
    ('cost_usd',        str(co.get('total_cost_usd', ''))),
    ('lines_added',     str(int(co.get('total_lines_added', 0) or 0))),
    ('lines_removed',   str(int(co.get('total_lines_removed', 0) or 0))),
    ('duration_ms',     str(int(co.get('total_duration_ms', 0) or 0))),
    ('api_duration_ms', str(int(co.get('total_api_duration_ms', 0) or 0))),
]

for k, v in fields:
    print(k + '=' + shlex.quote(str(v)))
