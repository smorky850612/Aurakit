#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════╗
# ║  AuraKit Nexus — Status Bar v2.4                ║
# ║  Responsive · Plan badge · Real usage display   ║
# ╚══════════════════════════════════════════════════╝

input=$(cat)

# ── JSON 파싱 (Python) — TERM_W보다 먼저 실행 ─────
PARSER="$HOME/.claude/statusline-parser.py"
PYTHON_BIN=""
for bin in python python3; do
  if "$bin" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
    PYTHON_BIN="$bin"
    break
  fi
done

if [ -n "$PYTHON_BIN" ] && [ -f "$PARSER" ]; then
  eval "$(echo "$input" | "$PYTHON_BIN" "$PARSER" 2>/dev/null)"
else
  model_name="Unknown"; model_id=""; session_id=""
  cwd=""; transcript=""; first_ts=""; used_pct=""; total_input=0; total_output=0
  ctx_size=200000; cur_input=0
  five_pct=""; five_reset=""; five_limit=18000
  seven_pct=""; seven_reset=""; seven_limit=0; seven_s_pct=""
  monthly_pct=""; monthly_reset=""; monthly_limit=0
  is_subscription="0"; plan_name=""; terminal_width=0; cost_usd=""
  lines_added=0; lines_removed=0; duration_ms=0; api_duration_ms=0
fi

# ── 터미널 폭 감지 (JSON → stty → COLUMNS 순서) ──
TERM_W=0
[ -n "$terminal_width" ] && [ "$terminal_width" -gt 0 ] && TERM_W=$terminal_width
if [ "$TERM_W" -eq 0 ]; then
  stty_w=$(stty size 2>/dev/null | awk '{print $2}')
  [ -n "$stty_w" ] && [ "$stty_w" -gt 0 ] && TERM_W=$stty_w
fi
if [ "$TERM_W" -eq 0 ]; then
  tput_w=$(tput cols 2>/dev/null)
  [ -n "$tput_w" ] && [ "$tput_w" -gt 0 ] && TERM_W=$tput_w
fi
[ "$TERM_W" -eq 0 ] && TERM_W=${COLUMNS:-80}

# ── UI 언어 감지 ──────────────────────────────────
LANG_FILE="$HOME/.claude/.aura-lang"
UI_LANG=$(cat "$LANG_FILE" 2>/dev/null | tr -d '[:space:]')
[ -z "$UI_LANG" ] && UI_LANG="en"

case "$UI_LANG" in
  ko) L_H="시간"; L_M="분"; L_NA="—"
      L_DAY="일"; L_WEEK="주"; L_MON="월"; L_BYPASS="바이패스" ;;
  ja) L_H="時"; L_M="分"; L_NA="—"
      L_DAY="日"; L_WEEK="週"; L_MON="月"; L_BYPASS="バイパス" ;;
  zh) L_H="时"; L_M="分"; L_NA="—"
      L_DAY="日"; L_WEEK="周"; L_MON="月"; L_BYPASS="绕过" ;;
  *)  L_H="h"; L_M="m"; L_NA="—"
      L_DAY="5h"; L_WEEK="7d"; L_MON="mo"; L_BYPASS="bypass" ;;
esac

# ── 컬러 팔레트 (256색 ANSI) ──────────────────────
RS=$'\033[0m'
BD=$'\033[1m'
DM=$'\033[2m'

AURA=$'\033[38;5;51m'
AURA2=$'\033[38;5;45m'

C_OPUS=$'\033[38;5;213m'
C_SONNET=$'\033[38;5;141m'
C_HAIKU=$'\033[38;5;117m'

C_BAR_HI=$'\033[38;5;46m'
C_BAR_MD=$'\033[38;5;43m'
C_BAR_LO=$'\033[38;5;238m'
C_PCT=$'\033[38;5;226m'
C_COST=$'\033[38;5;220m'
C_PLAN=$'\033[38;5;214m'
C_TOK=$'\033[38;5;252m'
C_REM=$'\033[38;5;82m'

C_PROJ=$'\033[38;5;117m'
C_BRANCH=$'\033[38;5;81m'
C_ID=$'\033[38;5;242m'
C_TIME=$'\033[38;5;250m'

C_OK=$'\033[38;5;82m'
C_BYPASS=$'\033[38;5;204m'
C_DOT=$'\033[38;5;240m'
C_MD=$'\033[38;5;255m'

D=" ${C_DOT}·${RS} "

# ── 모델 감지 ─────────────────────────────────────
case "$model_id" in
  *opus*)
    M_ICON="⬡"; M_COLOR="$C_OPUS"
    M_SHORT=$(echo "$model_name" | sed 's/Claude //;s/ Opus.*//' | tr '[:lower:]' '[:upper:]')
    M_MINI=$(echo "$model_name" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "OP")
    ;;
  *sonnet*)
    M_ICON="◈"; M_COLOR="$C_SONNET"
    M_SHORT=$(echo "$model_name" | sed 's/Claude //;s/ Sonnet.*//' | tr '[:lower:]' '[:upper:]')
    M_MINI=$(echo "$model_name" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "SN")
    ;;
  *haiku*)
    M_ICON="◉"; M_COLOR="$C_HAIKU"
    M_SHORT=$(echo "$model_name" | sed 's/Claude //;s/ Haiku.*//' | tr '[:lower:]' '[:upper:]')
    M_MINI=$(echo "$model_name" | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "HK")
    ;;
  *)
    M_ICON="○"; M_COLOR="$C_TOK"; M_SHORT="$model_name"; M_MINI="?" ;;
esac

# ── 그라디언트 진행바 ─────────────────────────────
build_bar() {
  local slots=$1
  local bfilled bbar bempty_cnt
  if [ -n "$used_pct" ]; then
    bfilled=$(echo "$used_pct $slots" | awk '{n=int($1*$2/100); if(n>$2)n=$2; print n}')
    bempty_cnt=$(($slots - bfilled))
    bbar=""
    for i in $(seq 1 "$bfilled"); do bbar="${bbar}${C_BAR_HI}█"; done
    if [ "$bempty_cnt" -gt 0 ]; then
      bbar="${bbar}${C_BAR_MD}▌"
      bempty_cnt=$((bempty_cnt - 1))
    fi
    for i in $(seq 1 "$bempty_cnt"); do bbar="${bbar}${C_BAR_LO}░"; done
    pct_n=$(printf "%.0f" "$used_pct")
    echo "${DM}▕${RS}${bbar}${RS}${DM}▏${RS} ${C_PCT}${pct_n}%${RS}"
  else
    local empty_bar=""
    for i in $(seq 1 "$slots"); do empty_bar="${empty_bar}${C_BAR_LO}░"; done
    echo "${DM}▕${RS}${empty_bar}${RS}${DM}▏${RS} ${DM}—%${RS}"
  fi
}

BAR_FULL=$(build_bar 16)
BAR_MED=$(build_bar 8)
BAR_NANO=$(build_bar 6)

# ── 토큰 (FULL 레이아웃용) ────────────────────────
cur_k=$(echo "$cur_input" | awk '{printf "%dK", $1/1000}')
ctx_k=$(echo "$ctx_size"  | awk '{printf "%dK", $1/1000}')
TOKENS="${C_TOK}${cur_k}${DM}/${RS}${C_TOK}${ctx_k}${RS}"

# ── 플랜 뱃지 / API 비용 ─────────────────────────
# 구독자: 플랜 이름 표시 (Max / Pro / Free)
# API 키: $비용 표시
if [ "$is_subscription" = "1" ]; then
  _pname="${plan_name:-Sub}"
  PLAN_OR_COST="${C_PLAN}${BD}${_pname}${RS}"
else
  if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ] && [ "$cost_usd" != "0.0" ]; then
    cost=$(echo "$cost_usd" | awk '{
      c=$1+0
      if (c >= 0.01) printf "$%.2f", c
      else printf "$%.4f", c
    }')
  else
    cost=$(echo "$total_input $total_output $model_id" | awk '{
      inp=$1; out=$2; id=$3
      if      (id~/opus/)   { ri=15;   ro=75   }
      else if (id~/sonnet/) { ri=3;    ro=15   }
      else                  { ri=0.25; ro=1.25 }
      c=(inp*ri + out*ro)/1000000
      if (c >= 0.01) printf "$%.2f", c
      else printf "$%.4f", c
    }')
  fi
  PLAN_OR_COST="${C_COST}${BD}${cost}${RS}"
fi

# ── 사용량 표시 헬퍼: 남은 시간 계산 ─────────────
# 인수: used_pct, limit_sec → 남은 시간 문자열 반환
rem_time_str() {
  local pct=$1 limit=$2
  if [ "$limit" -gt 0 ]; then
    local rem_s
    rem_s=$(echo "$pct $limit" | awk '{printf "%d", $2*(100-$1)/100}')
    if [ "$rem_s" -ge 3600 ]; then
      echo "$(echo "$rem_s" | awk '{printf "%.1f", $1/3600}')${L_H}"
    else
      echo "$((rem_s/60))${L_M}"
    fi
  else
    echo "$(echo "$pct" | awk '{printf "%d", 100-$1}')%"
  fi
}

# 총 한도 문자열
total_time_str() {
  local limit=$1
  [ "$limit" -gt 0 ] && echo "$(echo "$limit" | awk '{printf "%.0f", $1/3600}')${L_H}" || echo ""
}

# ── 리셋 타이머 계산 ─────────────────────────────
now_s=$(date +%s 2>/dev/null || echo 0)

reset_timer() {
  local reset_ts=$1
  [ -z "$reset_ts" ] && echo "" && return
  local diff_s=$((reset_ts - now_s))
  [ "$diff_s" -le 0 ] && echo "" && return
  local days=$((diff_s / 86400))
  local hrs=$(( (diff_s % 86400) / 3600 ))
  local mins=$((diff_s / 60))
  if [ "$days" -gt 0 ]; then
    echo "(${days}일)"
  elif [ "$hrs" -gt 0 ]; then
    echo "(${hrs}${L_H})"
  elif [ "$mins" -gt 0 ]; then
    echo "(${mins}${L_M})"
  else
    echo ""
  fi
}

# ── 구독 사용량 한도 ─────────────────────────────
LIMITS_L2=""

if [ "$is_subscription" = "1" ]; then
  # 일 한도 (five_hour) — 남은 % + 남은 시간/총 한도
  if [ -n "$five_pct" ]; then
    _rem_pct=$(echo "$five_pct" | awk '{printf "%d", 100-$1}')
    _rem=$(rem_time_str "$five_pct" "$five_limit")
    _tot=$(total_time_str "$five_limit")
    _tmr=$(reset_timer "$five_reset")
    if [ -n "$_tot" ]; then
      LIMITS_L2="${C_REM}${L_DAY} ${_rem_pct}% ${_rem}/${_tot}${_tmr}${RS}"
    else
      LIMITS_L2="${C_REM}${L_DAY} ${_rem_pct}%${_tmr}${RS}"
    fi
  fi

  # 주간 한도 (seven_day)
  if [ -n "$seven_pct" ]; then
    _rem=$(rem_time_str "$seven_pct" "$seven_limit")
    _tot=$(total_time_str "$seven_limit")
    _tmr=$(reset_timer "$seven_reset")
    [ -n "$LIMITS_L2" ] && LIMITS_L2="${LIMITS_L2}${D}"
    if [ -n "$_tot" ]; then
      LIMITS_L2="${LIMITS_L2}${C_REM}${L_WEEK} ${_rem}/${_tot}${_tmr}${RS}"
    else
      LIMITS_L2="${LIMITS_L2}${C_REM}${L_WEEK} ${_rem}${_tmr}${RS}"
    fi
  fi

  # 월간 한도 (monthly, Max 플랜)
  if [ -n "$monthly_pct" ]; then
    _rem=$(rem_time_str "$monthly_pct" "$monthly_limit")
    _tot=$(total_time_str "$monthly_limit")
    _tmr=$(reset_timer "$monthly_reset")
    [ -n "$LIMITS_L2" ] && LIMITS_L2="${LIMITS_L2}${D}"
    if [ -n "$_tot" ]; then
      LIMITS_L2="${LIMITS_L2}${C_REM}${L_MON} ${_rem}/${_tot}${_tmr}${RS}"
    else
      LIMITS_L2="${LIMITS_L2}${C_REM}${L_MON} ${_rem}${_tmr}${RS}"
    fi
  fi
fi

# COMPACT용 첫 번째 한도
USAGE_COMPACT="$PLAN_OR_COST"
if [ "$is_subscription" = "1" ] && [ -n "$LIMITS_L2" ]; then
  first_limit=""
  if [ -n "$five_pct" ]; then
    _rp=$(echo "$five_pct" | awk '{printf "%d", 100-$1}')
    _r=$(rem_time_str "$five_pct" "$five_limit")
    first_limit="${C_REM}${L_DAY} ${_rp}% ${_r}${RS}"
  elif [ -n "$seven_pct" ]; then
    _r=$(rem_time_str "$seven_pct" "$seven_limit")
    first_limit="${C_REM}${L_WEEK} ${_r}${RS}"
  fi
  [ -n "$first_limit" ] && USAGE_COMPACT="$first_limit"
fi

# ── Git 브랜치 ────────────────────────────────────
git_tag=""; git_tag_short=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  [ -n "$dirty" ] && branch="${branch}*"
  if [ -n "$branch" ]; then
    git_tag=" ${C_BRANCH}(${branch})${RS}"
    git_tag_short="${C_BRANCH}*${RS}"
    [ -z "$dirty" ] && git_tag_short="${C_BRANCH}${branch}${RS}"
  fi
fi

# ── 경과 시간 ─────────────────────────────────────
elapsed="—"
if [ -n "$first_ts" ]; then
  epoch=$(date -d "$first_ts" +%s 2>/dev/null \
       || date -j -f "%Y-%m-%dT%H:%M:%S" "${first_ts%%.*}" +%s 2>/dev/null)
  if [ -n "$epoch" ]; then
    now=$(date +%s); diff=$((now - epoch))
    h=$((diff / 3600)); m=$(( (diff % 3600) / 60 ))
    [ "$h" -gt 0 ] && elapsed="${h}${L_H}${m}${L_M}" || elapsed="${m}${L_M}"
  fi
fi

# ── CLAUDE.md 개수 ────────────────────────────────
md_count=0
[ -n "$cwd" ] && md_count=$(find "$cwd" -maxdepth 3 -name "CLAUDE.md" 2>/dev/null | wc -l | tr -d ' ')

proj=$(basename "$cwd" 2>/dev/null); [ -z "$proj" ] && proj="—"
short_id="${session_id:0:8}"
[ -n "$short_id" ] && short_id="#${short_id}" || short_id="#—"

# ── AuraKit 레인보우 파도 애니메이션 ──────────────
# 각 글자가 다른 레인보우 색 → 매초 1칸씩 좌측으로 이동 → 반짝이는 효과
# 색상 파동: 빨강→주황→노랑→초록→시안→파랑→보라
_AK="AuraKit"
_shift=$((now_s % 7))
BRAND_ANIM="${BD}⬡ "
for _ai in 0 1 2 3 4 5 6; do
  case "$(( (_ai + _shift) % 7 ))" in
    0) _rc=196 ;;  # 빨강
    1) _rc=208 ;;  # 주황
    2) _rc=226 ;;  # 노랑
    3) _rc=82  ;;  # 초록
    4) _rc=51  ;;  # 시안
    5) _rc=33  ;;  # 파랑
    6) _rc=93  ;;  # 보라
  esac
  BRAND_ANIM="${BRAND_ANIM}$(printf '\033[1m\033[38;5;%dm' "$_rc")${_AK:$_ai:1}"
done
BRAND_ANIM="${BRAND_ANIM}${RS}"

# ── 서브에이전트 카운트 ──────────────────────────
# .aura/agent-memory/active.json → running 에이전트 수 → ●●(*Sub)
_AGENTS=""
_AGENTS_LABEL=""
if [ -n "$cwd" ] && [ -f "${cwd}/.aura/agent-memory/active.json" ]; then
  _agent_cnt=$(grep -o '"status": "running"' \
    "${cwd}/.aura/agent-memory/active.json" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${_agent_cnt:-0}" -gt 0 ]; then
    _dots=""
    for _di in $(seq 1 "$_agent_cnt"); do _dots="${_dots}●"; done
    _AGENTS="${C_HAIKU}${_dots}(*Sub)${RS}"
    _AGENTS_LABEL="${C_HAIKU}AGENTS ${_agent_cnt}개${RS}"
  fi
fi

# ── 세션 통계 ─────────────────────────────────────
# 1) +N −N 코드 줄 변화 (0이면 표시 안 함)
LINES_LABEL=""
_la="${lines_added:-0}"; _lr="${lines_removed:-0}"
if [ "$_la" -gt 0 ] || [ "$_lr" -gt 0 ]; then
  LINES_LABEL="${C_OK}+${_la}${RS} ${C_BYPASS}−${_lr}${RS}"
fi

# 2) ⏱ Nm 세션 시간 (total_duration_ms → 분/시간)
SESSION_DUR=""
if [ "${duration_ms:-0}" -gt 0 ]; then
  _dur_m=$(echo "$duration_ms" | awk '{printf "%d", $1/60000}')
  _dur_h=$(echo "$_dur_m" | awk '{printf "%d", $1/60}')
  if [ "${_dur_h:-0}" -gt 0 ]; then
    _dur_rm=$(echo "$_dur_m $_dur_h" | awk '{printf "%d", $1-$2*60}')
    SESSION_DUR="${C_TIME}⏱ ${_dur_h}${L_H}${_dur_rm}${L_M}${RS}"
  elif [ "${_dur_m:-0}" -gt 0 ]; then
    SESSION_DUR="${C_TIME}⏱ ${_dur_m}${L_M}${RS}"
  fi
fi

# 3) API N% 효율 — API 키 사용자 전용
API_EFF=""
if [ "$is_subscription" != "1" ] && [ "${api_duration_ms:-0}" -gt 0 ] && [ "${duration_ms:-0}" -gt 0 ]; then
  _api_pct=$(echo "$api_duration_ms $duration_ms" | awk '{p=int($1*100/$2); if(p>99)p=99; printf "%d", p}')
  API_EFF="${C_TOK}API ${_api_pct}%${RS}"
fi

# ═══════════════════════════════════════════════════
# 반응형 레이아웃 (터미널 폭 기준)
# ═══════════════════════════════════════════════════

if [ "$TERM_W" -ge 80 ]; then
  # ── FULL (3줄, ≥80 cols) ─────────────────────────
  # L1: AuraKit 혜성 애니메이션 (독립 라인)
  L1=" ${BRAND_ANIM}"

  # L2: 모델 아이콘+이름 · 플랜 [· AGENTS N개] 컨텍스트바+%
  MODEL="${M_COLOR}${BD}${M_ICON} ${M_SHORT}${RS}"
  L2=" ${MODEL}${D}${PLAN_OR_COST}"
  [ -n "$_AGENTS_LABEL" ] && L2="${L2}${D}${_AGENTS_LABEL}"
  L2="${L2} ${BAR_MED}"

  # L3: 사용량 한도 + 세션 통계
  L3=" ${C_ID}${proj}${git_tag}${RS}"
  [ -n "$LIMITS_L2" ] && L3=" ${LIMITS_L2}"
  [ -n "$LINES_LABEL" ] && L3="${L3}${D}${LINES_LABEL}"
  [ -n "$SESSION_DUR" ] && L3="${L3}${D}${SESSION_DUR}"
  [ -n "$API_EFF" ]     && L3="${L3}${D}${API_EFF}"
  printf '%s\n%s\n%s\n' "$L1" "$L2" "$L3"

elif [ "$TERM_W" -ge 55 ]; then
  # ── MEDIUM (2줄, 55-79 cols) ─────────────────────
  MODEL="${M_COLOR}${BD}${M_ICON} ${M_SHORT}${RS}"

  # L1: AuraKit(애니) · 모델 · 플랜 [· AGENTS N개]
  L1=" ${BRAND_ANIM}${D}${MODEL}${D}${PLAN_OR_COST}"
  [ -n "$_AGENTS_LABEL" ] && L1="${L1}${D}${_AGENTS_LABEL}"

  # L2: 바+% · 일/주 사용량
  L2=" ${BAR_MED}${D}${TOKENS}"
  [ -n "$LIMITS_L2" ] && L2="${L2}${D}${LIMITS_L2}"
  printf '%s\n%s\n' "$L1" "$L2"

else
  # ── COMPACT (1줄, <72 cols) ──────────────────────
  MODEL_C="${M_COLOR}${M_ICON} ${M_MINI}${RS}"

  printf ' %s%s%s%s%s%s%s\n' \
    "$BRAND_ANIM" "$D" "$MODEL_C" "$D" "$BAR_NANO" "$D" "$USAGE_COMPACT"
fi
