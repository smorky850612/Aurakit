# AuraKit — Batch Pipeline (G16)

> 이 파일은 `/aura batch:` 명시 시 로딩된다.

---

## Batch 모드 개요

여러 기능을 병렬로 또는 순차적으로 처리한다.
각 기능은 독립된 Git Worktree에서 실행되어 충돌 없이 동시 진행 가능.

```bash
/aura batch:로그인,회원가입,프로필    # 3개 기능 병렬 처리
/aura batch:sequential:A,B,C         # 순차 처리 (A완료 후 B)
/aura batch:status                   # 현재 배치 상태 확인
/aura batch:cancel                   # 배치 중단
```

---

## 실행 순서

### Step 1 — 배치 목록 파싱

```javascript
// 입력: "로그인,회원가입,프로필"
const features = input.split(',').map(f => f.trim()).filter(Boolean);
const mode = input.startsWith('sequential:') ? 'sequential' : 'parallel';

console.log(`BATCH: ${features.length}개 기능 (${mode} 모드)`);
features.forEach((f, i) => console.log(`  ${i+1}. ${f}`));
```

### Step 2 — 배치 상태 파일 생성

```json
// .aura/batch/current.json
{
  "id": "batch-20250315-001",
  "mode": "parallel",
  "createdAt": "2025-03-15T10:00:00Z",
  "features": [
    { "name": "로그인", "status": "pending", "worktree": null, "startedAt": null },
    { "name": "회원가입", "status": "pending", "worktree": null, "startedAt": null },
    { "name": "프로필", "status": "pending", "worktree": null, "startedAt": null }
  ],
  "completed": 0,
  "failed": 0
}
```

### Step 3 — 병렬 실행 (Parallel Mode)

각 기능을 독립된 Worktree에서 에이전트가 처리:

```bash
# Worktree 생성 (기능별)
for FEATURE in "${features[@]}"; do
  SAFE_NAME=$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  git worktree add ".aura/worktree/batch-${SAFE_NAME}" -b "aura/batch-${SAFE_NAME}" 2>/dev/null || true
done
```

```
[병렬 에이전트 실행]
Builder-A (model: [tier]) → 로그인 기능     → aura/batch-로그인
Builder-B (model: [tier]) → 회원가입 기능   → aura/batch-회원가입
Builder-C (model: [tier]) → 프로필 기능     → aura/batch-프로필
```

**에이전트 실행 규칙**:
- 각 에이전트는 해당 Worktree 내에서만 작업
- B-1~B-4 공통 프로토콜 각각 실행
- 완료 시 상태 파일 업데이트

### Step 4 — 순차 실행 (Sequential Mode)

```
[순차 에이전트 실행]
Builder (model: [tier])
  → 로그인 완료 → 상태: completed
  → 회원가입 시작 → ...
  → 프로필 시작 → ...
```

### Step 5 — 상태 모니터링

```bash
# .aura/batch/current.json 읽기
TOTAL=$(jq '.features | length' .aura/batch/current.json)
DONE=$(jq '.completed' .aura/batch/current.json)
FAILED=$(jq '.failed' .aura/batch/current.json)

echo "📊 BATCH 진행: ${DONE}/${TOTAL} 완료, ${FAILED} 실패"
jq -r '.features[] | "  \(.status == "completed" | if . then "✅" else if (.status == "running") then "⏳" else "⏸️" end end) \(.name)"' .aura/batch/current.json
```

### Step 6 — 완료 및 병합

```bash
# 각 Worktree 검증 후 main에 병합
for FEATURE in "${completed_features[@]}"; do
  SAFE_NAME=$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

  # 검증 (V1)
  cd ".aura/worktree/batch-${SAFE_NAME}"
  npx tsc --noEmit 2>&1 | tail -3

  # 병합
  cd -
  git merge --squash "aura/batch-${SAFE_NAME}"
  git commit -m "feat(batch): ${FEATURE}"

  # Worktree 정리
  git worktree remove ".aura/worktree/batch-${SAFE_NAME}" --force
done
```

### Step 7 — 배치 리포트

```
📊 BATCH COMPLETE — [N]개 기능
──────────────────────────────
✅ 로그인      — 3파일, feat(auth): login flow
✅ 회원가입    — 4파일, feat(auth): signup flow
✅ 프로필      — 2파일, feat(user): profile CRUD
──────────────────────────────
총: [N]개 파일 생성 | 소요: [T]초
실패: 0개
💰 [티어: ECO] | 다음: /aura review: 배치 결과 검토
```

---

## batch:status

```bash
# 현재 배치 상태 출력
if [ ! -f ".aura/batch/current.json" ]; then
  echo "⏸️  진행 중인 배치 없음"
else
  cat .aura/batch/current.json | jq '{
    id, mode,
    progress: "\(.completed)/\(.features|length)",
    features: [.features[] | {name, status}]
  }'
fi
```

---

## batch:cancel

```bash
# 실행 중인 Worktree 정리
git worktree list | grep "batch-" | awk '{print $1}' | xargs -I{} git worktree remove {} --force 2>/dev/null

# 상태 파일 삭제
rm -f .aura/batch/current.json

echo "✅ 배치 취소 완료"
```

---

## AuraKit Batch 규칙

```
BATCH 규칙:
  병렬 최대: 5개 기능 동시 처리 (초과 시 순차 전환)
  Worktree 네이밍: aura/batch-[기능명-kebab]
  충돌 파일: 배치 시작 전 공유 파일(types.ts, globals.css) 확인
  실패 기능: 나머지 완료 후 개별 FIX 모드로 처리
  배치 완료 후: git worktree prune 실행 (좀비 Worktree 방지)
  토큰: PRO/MAX 티어는 기능당 에이전트 비용 × 기능 수 고려
```
