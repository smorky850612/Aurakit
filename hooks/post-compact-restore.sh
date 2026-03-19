#!/bin/bash
# AuraKit - 컴팩트 후 스냅샷 복구 및 컨텍스트 주입
# Hook: PostCompact (matcher: auto)
# stdout: Claude 컨텍스트에 자동 주입됨
cat > /dev/null 2>&1 || true

set -euo pipefail

AURA_DIR=".aura"
SNAPSHOTS_DIR="${AURA_DIR}/snapshots"
CURRENT_SNAPSHOT="${SNAPSHOTS_DIR}/current.md"

# ── 스냅샷 존재 확인 ──────────────────────────────────────────────────
if [ ! -f "${CURRENT_SNAPSHOT}" ]; then
  echo "=== AuraKit Context Recovery ==="
  echo ""
  echo "AuraKit: 복구할 스냅샷이 없습니다."
  echo ""
  echo "새 작업을 시작하려면: /aura [작업 설명]"
  echo "예시: /aura 로그인 기능 만들어줘"
  echo ""
  echo "=== AuraKit Context Recovery End ==="
  exit 0
fi

# ── 스냅샷 내용 읽기 ──────────────────────────────────────────────────
SNAPSHOT_CONTENT=$(cat "${CURRENT_SNAPSHOT}" 2>/dev/null || echo "")

if [ -z "${SNAPSHOT_CONTENT}" ]; then
  echo "=== AuraKit Context Recovery ==="
  echo "AuraKit: 스냅샷 파일이 비어 있습니다. /aura 로 새 작업을 시작하세요."
  echo "=== AuraKit Context Recovery End ==="
  exit 0
fi

# ── 컨텍스트 주입 ─────────────────────────────────────────────────────
echo "=== AuraKit Context Recovery ==="
echo ""
echo "⚡ 이전 작업 상태가 복구되었습니다. 아래 스냅샷을 참고하여 작업을 이어서 진행하세요."
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "${SNAPSHOT_CONTENT}"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""

# 남은 작업이 있는지 확인
HAS_REMAINING=$(echo "${SNAPSHOT_CONTENT}" | grep -c "^- \[ \]" 2>/dev/null || echo "0")
NEXT_ACTION=$(echo "${SNAPSHOT_CONTENT}" | \
  awk '/^## Next Action/{found=1; next} found && /^-/{print; exit}' | \
  sed 's/^- //' || echo "")

if [ "${HAS_REMAINING}" -gt 0 ] 2>/dev/null; then
  echo "📋 남은 작업: ${HAS_REMAINING}개 항목"
fi

if [ -n "${NEXT_ACTION}" ]; then
  echo "▶️  다음 액션: ${NEXT_ACTION}"
  echo ""
fi

echo "=== 위 스냅샷을 참고하여 남은 작업을 이어서 진행하세요 ==="
echo ""
echo "명령어:"
echo "  /aura          — 남은 작업 자동 이어서 진행"
echo "  /aura-compact  — 수동 스냅샷 저장"

exit 0
