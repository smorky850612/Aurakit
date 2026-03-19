#!/bin/bash
# AuraKit - 컴팩트 전 작업 상태 스냅샷 저장
# Hook: PreCompact (matcher: auto)
# stdin: JSON (session_id, transcript_path)
# Disk > Memory 원칙 구현

set -euo pipefail

AURA_DIR=".aura"
SNAPSHOTS_DIR="${AURA_DIR}/snapshots"
CURRENT_SNAPSHOT="${SNAPSHOTS_DIR}/current.md"
TIMESTAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || date +%Y%m%d)

# ── 디렉토리 확인 ─────────────────────────────────────────────────────
mkdir -p "${SNAPSHOTS_DIR}"

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "${INPUT}" | jq -r '.session_id // ""' 2>/dev/null || echo "")
  TRANSCRIPT_PATH=$(echo "${INPUT}" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")
else
  SESSION_ID=$(echo "${INPUT}" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"//;s/"$//' || echo "")
  TRANSCRIPT_PATH=$(echo "${INPUT}" | grep -o '"transcript_path":"[^"]*"' | sed 's/"transcript_path":"//;s/"$//' || echo "")
fi

# ── 기존 스냅샷 백업 ──────────────────────────────────────────────────
if [ -f "${CURRENT_SNAPSHOT}" ]; then
  BACKUP_FILE="${SNAPSHOTS_DIR}/SNAPSHOT-${TIMESTAMP}.md"
  cp "${CURRENT_SNAPSHOT}" "${BACKUP_FILE}"
  echo "AuraKit: 기존 스냅샷 백업 완료 → ${BACKUP_FILE}"
fi

# ── transcript 기반 요약 생성 ─────────────────────────────────────────
SUMMARY_GENERATED=false

if [ -n "${TRANSCRIPT_PATH}" ] && [ -f "${TRANSCRIPT_PATH}" ]; then
  # 트랜스크립트 크기 확인
  TRANSCRIPT_SIZE=$(wc -c < "${TRANSCRIPT_PATH}" 2>/dev/null || echo "0")

  # claude CLI가 있는지 확인
  if command -v claude &>/dev/null; then
    echo "AuraKit: 트랜스크립트 요약 생성 중..."

    # 파일이 50KB 초과이면 마지막 50KB만 사용
    if [ "${TRANSCRIPT_SIZE}" -gt 51200 ] 2>/dev/null; then
      TRANSCRIPT_CONTENT=$(tail -c 50000 "${TRANSCRIPT_PATH}" 2>/dev/null || cat "${TRANSCRIPT_PATH}")
    else
      TRANSCRIPT_CONTENT=$(cat "${TRANSCRIPT_PATH}" 2>/dev/null || echo "")
    fi

    # claude -p 로 요약 요청
    SUMMARY_PROMPT="아래 대화 내용에서 현재 작업 상태를 요약해줘.

반드시 아래 마크다운 포맷으로 작성해줘 (200줄 이내):

# AuraKit Snapshot
- Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)
- Mode: [BUILD/FIX/CLEAN/DEPLOY/REVIEW 중 하나]
- Original Request: [사용자의 원래 요청]
- Plan: [총 N개 파일]
- Session ID: ${SESSION_ID}

## Completed
- [x] [완료된 파일/작업 목록]

## Remaining
- [ ] [아직 완료하지 못한 파일/작업]

## Last Verification
- Build: [Pass/Fail]
- Security: [Pass/Fail]
- Tests: [N/N Pass]

## Key Decisions
- [중요한 아키텍처/기술 결정 사항]

## Next Action
- [다음에 바로 해야 할 구체적인 작업]

=== 대화 내용 ===
${TRANSCRIPT_CONTENT}"

    SUMMARY=$(echo "${SUMMARY_PROMPT}" | claude -p 2>/dev/null || echo "")

    if [ -n "${SUMMARY}" ]; then
      echo "${SUMMARY}" > "${CURRENT_SNAPSHOT}"
      SUMMARY_GENERATED=true
      echo "AuraKit: 스냅샷 생성 완료 → ${CURRENT_SNAPSHOT}"
    fi
  fi
fi

# ── 요약 생성 실패 시 기본 스냅샷 생성 ───────────────────────────────
if [ "${SUMMARY_GENERATED}" = false ]; then
  # 기존 스냅샷이 있으면 타임스탬프만 업데이트
  if [ -f "${CURRENT_SNAPSHOT}" ]; then
    echo "AuraKit: claude CLI 없음 — 기존 스냅샷 유지 (타임스탬프 업데이트)"
    # 타임스탬프 라인 업데이트
    if command -v sed &>/dev/null; then
      NEW_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)
      sed -i "s/- Timestamp:.*/- Timestamp: ${NEW_TIMESTAMP} (compact backup)/" \
        "${CURRENT_SNAPSHOT}" 2>/dev/null || true
    fi
  else
    # 스냅샷이 없으면 기본 템플릿 생성
    cat > "${CURRENT_SNAPSHOT}" << EOF
# AuraKit Snapshot
- Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)
- Mode: UNKNOWN (auto-compact triggered)
- Original Request: (트랜스크립트 요약 불가 — claude CLI 미설치)
- Session ID: ${SESSION_ID}
- Plan: Unknown

## Completed
- (compact 전 상태 미기록)

## Remaining
- (compact 전 상태 미기록)

## Last Verification
- Build: Unknown
- Security: Unknown
- Tests: Unknown

## Key Decisions
- (compact 전 상태 미기록)

## Next Action
- /aura 를 실행하여 작업 상태를 확인하고 이어서 진행하세요
- 이전 대화를 참고하여 작업을 재개하세요

## Note
이 스냅샷은 claude CLI 없이 생성되었습니다.
claude CLI를 설치하면 자동 요약이 활성화됩니다.
EOF
    echo "AuraKit: 기본 스냅샷 템플릿 생성 완료"
  fi
fi

# ── 오래된 백업 스냅샷 정리 (20개 초과 시 가장 오래된 것 삭제) ──────
BACKUP_COUNT=$(ls "${SNAPSHOTS_DIR}"/SNAPSHOT-*.md 2>/dev/null | wc -l || echo "0")
if [ "${BACKUP_COUNT}" -gt 20 ] 2>/dev/null; then
  OLDEST=$(ls -t "${SNAPSHOTS_DIR}"/SNAPSHOT-*.md 2>/dev/null | tail -5)
  if [ -n "${OLDEST}" ]; then
    echo "${OLDEST}" | xargs rm -f 2>/dev/null || true
    echo "AuraKit: 오래된 스냅샷 5개 정리 완료"
  fi
fi

exit 0
