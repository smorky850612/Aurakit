#!/bin/bash
# AuraKit - 세션 시작 시 프로젝트 환경 초기화 및 상태 확인
# Hook: SessionStart (matcher: startup|resume)
# 토큰 비용: 0 (stdout 출력만)
cat > /dev/null 2>&1 || true

set -euo pipefail

AURA_DIR=".aura"
SNAPSHOTS_DIR="${AURA_DIR}/snapshots"
PROFILE_FILE="${AURA_DIR}/project-profile.md"
SNAPSHOT_FILE="${SNAPSHOTS_DIR}/current.md"

# ── 1. .aura/ 디렉토리 초기화 ─────────────────────────────────────────
if [ ! -d "${AURA_DIR}" ]; then
  mkdir -p "${SNAPSHOTS_DIR}"
  echo "AuraKit: .aura/ 디렉토리를 초기화했습니다."
fi

if [ ! -d "${SNAPSHOTS_DIR}" ]; then
  mkdir -p "${SNAPSHOTS_DIR}"
fi

# ── 1.5. 패키지 매니저 자동 감지 ──────────────────────────────────────
PKG_MGR=""
PKG_MGR_CMD=""

if [ -f "package.json" ]; then
  if [ -f "pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"; PKG_MGR_CMD="pnpm"
  elif [ -f "yarn.lock" ]; then
    PKG_MGR="yarn"; PKG_MGR_CMD="yarn"
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    PKG_MGR="bun"; PKG_MGR_CMD="bun"
  else
    PKG_MGR="npm"; PKG_MGR_CMD="npm"
  fi
elif [ -f "go.mod" ]; then
  PKG_MGR="go"; PKG_MGR_CMD="go"
elif [ -f "Cargo.toml" ]; then
  PKG_MGR="cargo"; PKG_MGR_CMD="cargo"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  if command -v uv &>/dev/null; then
    PKG_MGR="uv"; PKG_MGR_CMD="uv"
  elif command -v poetry &>/dev/null && [ -f "pyproject.toml" ]; then
    PKG_MGR="poetry"; PKG_MGR_CMD="poetry"
  else
    PKG_MGR="pip"; PKG_MGR_CMD="pip"
  fi
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  PKG_MGR="gradle"; PKG_MGR_CMD="./gradlew"
elif [ -f "pom.xml" ]; then
  PKG_MGR="maven"; PKG_MGR_CMD="mvn"
elif [ -f "composer.json" ]; then
  PKG_MGR="composer"; PKG_MGR_CMD="composer"
fi

if [ -n "${PKG_MGR}" ]; then
  echo "📦 AuraKit: 패키지 매니저 → ${PKG_MGR}"
  if [ -d "${AURA_DIR}" ]; then
    mkdir -p "${AURA_DIR}/runtime"
    echo "{\"pkg\":\"${PKG_MGR}\",\"cmd\":\"${PKG_MGR_CMD}\",\"ts\":$(date +%s 2>/dev/null || echo 0)}" \
      > "${AURA_DIR}/runtime/pkg-manager.json" 2>/dev/null || true
  fi
fi

# ── 2. .env 보안 검사 ─────────────────────────────────────────────────
ENV_ISSUE=false

if [ -f ".env" ]; then
  # .gitignore에 .env 포함 여부 확인
  if [ -f ".gitignore" ]; then
    if ! grep -qE "^\.env$|^\.env\b" .gitignore 2>/dev/null; then
      echo "⚠️  AuraKit Security L1: .env 파일이 .gitignore에 없습니다."
      echo "   즉시 .gitignore에 .env를 추가하세요:"
      echo "   echo '.env' >> .gitignore"
      ENV_ISSUE=true
    fi
  else
    echo "⚠️  AuraKit Security L1: .gitignore 파일이 없습니다."
    echo "   .gitignore를 생성하고 .env를 추가하세요."
    ENV_ISSUE=true
  fi

  # git에 .env가 추적되고 있는지 확인
  if command -v git &>/dev/null && git rev-parse --git-dir &>/dev/null 2>&1; then
    if git ls-files --error-unmatch .env &>/dev/null 2>&1; then
      echo "🚨 AuraKit Security L1 [CRITICAL]: .env 파일이 git에 추적되고 있습니다!"
      echo "   즉시 다음 명령을 실행하세요:"
      echo "   git rm --cached .env && git commit -m 'security: remove .env from tracking'"
      ENV_ISSUE=true
    fi
  fi
fi

if [ "${ENV_ISSUE}" = false ] && [ -f ".env" ]; then
  echo "✅ AuraKit Security L1: .env 보안 검사 통과"
fi

# ── 3. 프로젝트 프로필 상태 확인 ───────────────────────────────────────
if [ ! -f "${PROFILE_FILE}" ]; then
  echo ""
  echo "📋 AuraKit: 프로젝트 프로필이 없습니다."
  echo "   /aura 실행 시 Scout 에이전트가 자동으로 프로젝트를 스캔합니다."
  echo "   (첫 실행에만 필요, 이후 캐시 사용)"
else
  # 프로필 마지막 업데이트 날짜 확인 (7일 이상 오래됐으면 갱신 제안)
  if command -v stat &>/dev/null; then
    PROFILE_AGE=$(( ($(date +%s) - $(stat -c %Y "${PROFILE_FILE}" 2>/dev/null || echo 0)) / 86400 ))
    if [ "${PROFILE_AGE}" -gt 7 ] 2>/dev/null; then
      echo "💡 AuraKit: 프로젝트 프로필이 ${PROFILE_AGE}일 전에 생성되었습니다."
      echo "   /aura 실행 시 자동으로 최신 상태를 확인합니다."
    fi
  fi
fi

# ── 4. 이전 스냅샷 확인 ────────────────────────────────────────────────
if [ -f "${SNAPSHOT_FILE}" ]; then
  echo ""
  echo "🔄 AuraKit: 이전 작업 스냅샷이 발견되었습니다."

  # 스냅샷에서 모드와 원래 요청 추출
  MODE=$(grep -m1 "^- Mode:" "${SNAPSHOT_FILE}" 2>/dev/null | sed 's/- Mode: //' || echo "Unknown")
  REQUEST=$(grep -m1 "^- Original Request:" "${SNAPSHOT_FILE}" 2>/dev/null | sed 's/- Original Request: //' | cut -c1-60 || echo "")

  if [ -n "${MODE}" ] && [ "${MODE}" != "Unknown" ]; then
    echo "   모드: ${MODE}"
  fi
  if [ -n "${REQUEST}" ]; then
    echo "   요청: ${REQUEST}..."
  fi

  echo "   /aura 실행 시 자동으로 이어서 작업합니다."
fi

# ── 5. 백업 스냅샷 개수 확인 (정리 제안) ──────────────────────────────
if [ -d "${SNAPSHOTS_DIR}" ]; then
  SNAPSHOT_COUNT=$(ls "${SNAPSHOTS_DIR}"/SNAPSHOT-*.md 2>/dev/null | wc -l)
  if [ "${SNAPSHOT_COUNT}" -gt 10 ] 2>/dev/null; then
    echo ""
    echo "💡 AuraKit: 오래된 스냅샷 ${SNAPSHOT_COUNT}개가 있습니다."
    echo "   ls .aura/snapshots/ 로 확인하고 불필요한 파일을 정리하세요."
  fi
fi

exit 0
