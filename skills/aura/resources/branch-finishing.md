# AuraKit — Branch Finishing (G17)

> 이 파일은 `/aura finish:` 또는 BUILD Step 6 완료 후 자동 로딩된다.

---

## Branch Finishing 개요

기능 구현 완료 후 브랜치를 정리하고 main에 안전하게 병합한다.
"구현 완료"와 "브랜치 정리"를 명확히 분리.

```bash
/aura finish:로그인 기능    # 특정 브랜치 마무리
/aura finish:               # 현재 브랜치 마무리
```

---

## 실행 순서

### Step 1 — 현재 상태 확인

```bash
CURRENT_BRANCH=$(git branch --show-current)
BASE_BRANCH="main"

echo "브랜치: ${CURRENT_BRANCH}"
echo "베이스: ${BASE_BRANCH}"

# 미커밋 변경사항 확인
DIRTY=$(git status --porcelain)
if [ -n "$DIRTY" ]; then
  echo "⚠️  미커밋 변경사항 있음:"
  git status --short
  echo "→ 먼저 커밋 또는 stash 필요"
  exit 1
fi
```

### Step 2 — 최종 검증 (3중)

```bash
# V1: 빌드 검증
npx tsc --noEmit 2>&1 | tail -5
echo "V1: $([ $? -eq 0 ] && echo '✅' || echo '❌')"

# V2: 린트
npx eslint . --max-warnings=0 2>&1 | tail -3
echo "V2: $([ $? -eq 0 ] && echo '✅' || echo '❌')"

# V3: 테스트 (있으면)
if [ -f "package.json" ] && grep -q '"test"' package.json; then
  npm test -- --passWithNoTests 2>&1 | tail -5
  echo "V3: $([ $? -eq 0 ] && echo '✅' || echo '❌')"
fi
```

### Step 3 — 브랜치 히스토리 정리

```bash
# 커밋 목록 확인
echo "변경 커밋:"
git log --oneline "${BASE_BRANCH}..${CURRENT_BRANCH}"

# 커밋 수 계산
COMMIT_COUNT=$(git rev-list --count "${BASE_BRANCH}..${CURRENT_BRANCH}")

if [ "$COMMIT_COUNT" -gt 5 ]; then
  echo "💡 커밋 $COMMIT_COUNT 개 — squash 권장:"
  echo "  git rebase -i ${BASE_BRANCH}"
fi
```

### Step 4 — Squash & Merge (권장)

```bash
# main 최신화
git fetch origin main
git checkout main
git pull origin main

# Squash merge (히스토리 깔끔)
git merge --squash "${CURRENT_BRANCH}"

# 커밋 메시지 작성 (기능명 + 주요 변경사항)
FEATURE_NAME=$(echo "${CURRENT_BRANCH}" | sed 's/aura\///')
git commit -m "feat(${FEATURE_NAME}): squash merge from ${CURRENT_BRANCH}

$(git log --oneline origin/main..HEAD 2>/dev/null | head -10)"
```

### Step 5 — 브랜치 정리

```bash
# 로컬 브랜치 삭제
git branch -d "${CURRENT_BRANCH}"
echo "✅ 로컬 브랜치 삭제: ${CURRENT_BRANCH}"

# 원격 브랜치 삭제 (있으면)
if git ls-remote --exit-code --heads origin "${CURRENT_BRANCH}" &>/dev/null; then
  git push origin --delete "${CURRENT_BRANCH}"
  echo "✅ 원격 브랜치 삭제: origin/${CURRENT_BRANCH}"
fi

# Worktree 정리 (있으면)
WORKTREE_PATH=".aura/worktree/$(echo "${CURRENT_BRANCH}" | sed 's/aura\///')"
if [ -d "$WORKTREE_PATH" ]; then
  git worktree remove "$WORKTREE_PATH" --force
  echo "✅ Worktree 정리: ${WORKTREE_PATH}"
fi

# 좀비 Worktree 정리
git worktree prune
```

### Step 6 — 스냅샷 아카이브

```bash
# current.md → archived.md 이동
ARCHIVE_DATE=$(date +%Y%m%d)
FEATURE_NAME=$(echo "${CURRENT_BRANCH}" | sed 's/aura\///')

if [ -f ".aura/snapshots/current.md" ]; then
  mkdir -p ".aura/archive/${FEATURE_NAME}"
  cp ".aura/snapshots/current.md" ".aura/archive/${FEATURE_NAME}/snapshot-${ARCHIVE_DATE}.md"

  # current.md 초기화
  cat > ".aura/snapshots/current.md" << EOF
# AuraKit Snapshot
- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Mode: 대기
- Original Request: (없음)

## Completed
- ${FEATURE_NAME} ✅ ($(date +%Y-%m-%d))

## Remaining
(없음)

## Next Action
새 작업 시작: /aura [기능명]
EOF
  echo "✅ 스냅샷 아카이브: .aura/archive/${FEATURE_NAME}/"
fi
```

### Step 7 — 완료 리포트

```
✅ BRANCH FINISHING 완료 — [기능명]
──────────────────────────────────────
브랜치:   [feature-branch] → main (merged)
커밋:     [N]개 → squash 1개
V1: ✅ | V2: ✅ | V3: ✅
스냅샷:   아카이브됨
──────────────────────────────────────
다음 작업: /aura [다음 기능]
```

---

## 빠른 참조

```bash
# 현재 브랜치 → main 병합 (대화형)
git fetch origin main
git rebase origin/main      # 또는 merge
git push origin main

# 브랜치 목록 확인
git branch -a | grep "aura/"

# 오래된 브랜치 일괄 정리
git branch --merged main | grep "aura/" | xargs git branch -d
```

---

## AuraKit Branch Finishing 규칙

```
BRANCH FINISHING 규칙:
  main 직접 커밋 금지 — 반드시 기능 브랜치 경유
  Squash merge 권장 — 히스토리 오염 방지
  병합 전 V1 검증 필수 (빌드 실패 상태로 main 병합 금지)
  Worktree 사용 후 반드시 remove (git worktree prune)
  브랜치 삭제 전 스냅샷 아카이브
```
