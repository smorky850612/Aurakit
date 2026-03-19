#!/bin/bash
# AuraKit - 에이전트 출력 필터 (성공 시 억제, 실패 시 통과)
# Hook: PostToolUse (matcher: Agent)
# stdin: JSON (tool_result)
# Fail-Only Output 원칙 구현

set -euo pipefail

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

# tool_output 추출
if command -v jq &>/dev/null; then
  AGENT_OUTPUT=$(echo "${INPUT}" | jq -r '.tool_response // .tool_output // ""' 2>/dev/null || echo "")
else
  # jq 없는 경우 전체 내용으로 패턴 검사
  AGENT_OUTPUT="${INPUT}"
fi

# 출력이 없으면 통과
if [ -z "${AGENT_OUTPUT}" ]; then
  exit 0
fi

# ── 실패 키워드 검사 ──────────────────────────────────────────────────
# 이 키워드가 있으면 출력을 그대로 통과시킴 (사용자가 봐야 함)
FAILURE_KEYWORDS=(
  "VULN-"
  "WARN:"
  "Failed"
  "failed"
  "Error"
  "error"
  "실패"
  "오류"
  "취약점"
  "경고"
  "issues found"
  "issue found"
  "이슈"
  "문제"
  "TypeScript"
  "SyntaxError"
  "TypeError"
  "CRITICAL"
  "HIGH"
  "MEDIUM"
)

HAS_FAILURE=false

for keyword in "${FAILURE_KEYWORDS[@]}"; do
  if echo "${AGENT_OUTPUT}" | grep -q "${keyword}" 2>/dev/null; then
    HAS_FAILURE=true
    break
  fi
done

# ── 결과 처리 ─────────────────────────────────────────────────────────
if [ "${HAS_FAILURE}" = false ]; then
  # 성공: 출력 억제하고 "Pass" 한 줄만 표시
  # Claude Code의 suppressOutput 기능 활용
  if command -v jq &>/dev/null; then
    # JSON 형태로 suppressOutput 신호 출력
    echo '{"suppressOutput": true}' | jq .
  fi

  # stdout에 Pass 출력 (사용자에게 간단히 알림)
  echo "✅ AuraKit: 에이전트 검증 통과 (Pass)"
  exit 0
else
  # 실패: 그대로 통과 (Claude가 전체 출력을 표시)
  # 추가 포맷 없이 원본 출력 유지
  exit 0
fi
