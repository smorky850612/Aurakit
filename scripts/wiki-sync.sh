#!/usr/bin/env bash
# AuraKit Wiki Sync v1.0
# Syncs wiki/ directory → GitHub Wiki remote
#
# Usage:
#   bash scripts/wiki-sync.sh
#   bash scripts/wiki-sync.sh --dry-run    # Preview only, no push
#
# Prerequisites:
#   git remote add wiki https://github.com/smorky850612/Aurakit.wiki.git
#   GitHub wiki must be initialized (create at least one page on GitHub first)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WIKI_SRC="${REPO_ROOT}/wiki"
WIKI_REMOTE="wiki"
WIKI_REMOTE_URL="https://github.com/smorky850612/Aurakit.wiki.git"
DRY_RUN=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

echo "🔄 AuraKit Wiki Sync"
echo "   Source: ${WIKI_SRC}"
echo "   Target: ${WIKI_REMOTE_URL}"
[[ "$DRY_RUN" == true ]] && echo "   Mode: DRY RUN (no push)"
echo ""

# Check wiki source exists
if [[ ! -d "$WIKI_SRC" ]]; then
  echo "❌ wiki/ directory not found. Run from repo root."
  exit 1
fi

# Check wiki remote
cd "$REPO_ROOT"
if ! git remote | grep -q "^${WIKI_REMOTE}$"; then
  echo "⚙️  Adding wiki remote..."
  git remote add "$WIKI_REMOTE" "$WIKI_REMOTE_URL"
  echo "   ✅ Added: ${WIKI_REMOTE} → ${WIKI_REMOTE_URL}"
else
  echo "   ✅ Wiki remote already set."
fi

# Create temp dir for wiki clone
TMPDIR=$(mktemp -d)
trap "rm -rf ${TMPDIR}" EXIT

echo ""
echo "📥 Cloning GitHub Wiki..."
if ! git clone "${WIKI_REMOTE_URL}" "${TMPDIR}/wiki" 2>&1; then
  echo ""
  echo "❌ Wiki clone failed. Possible causes:"
  echo "   1. GitHub wiki not initialized — go to github.com/smorky850612/Aurakit/wiki"
  echo "      and create the first page manually, then retry."
  echo "   2. Authentication issue — configure git credentials:"
  echo "      gh auth login   # or set GITHUB_TOKEN"
  echo "   3. No push access to the repository."
  exit 1
fi

echo ""
echo "📋 Copying wiki files..."
# Copy all .md files and SVG assets
find "${WIKI_SRC}" -maxdepth 1 -name "*.md" -o -name "*.svg" | while read -r f; do
  fname=$(basename "$f")
  cp "$f" "${TMPDIR}/wiki/${fname}"
  echo "   ✅ ${fname}"
done

# Commit changes
cd "${TMPDIR}/wiki"
git add -A

if git diff --cached --quiet; then
  echo ""
  echo "✅ Wiki is already up to date. Nothing to push."
  exit 0
fi

CHANGED=$(git diff --cached --stat | tail -1)
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

git commit -m "docs(wiki): sync from main repo — ${TIMESTAMP}"

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 DRY RUN — would push:"
  git log --oneline -1
  echo "   Files: ${CHANGED}"
else
  echo "🚀 Pushing to GitHub Wiki..."
  git push origin master 2>&1 || git push origin main 2>&1
  echo ""
  echo "✅ Wiki synced successfully!"
  echo "   View: https://github.com/smorky850612/Aurakit/wiki"
fi
