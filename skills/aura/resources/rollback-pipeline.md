# ROLLBACK 모드 — 안전한 변경사항 되돌리기

> BUILD/FIX가 잘못됐을 때 빠르고 안전하게 되돌리는 모드.

## 트리거
```bash
/aura rollback:              # 현재 변경사항 모두 되돌리기
/aura rollback: src/auth/    # 특정 디렉토리만
/aura rollback: last-commit  # 마지막 커밋 되돌리기
```

## 파이프라인

1. **현재 상태 파악**
   - `git status` — 수정된 파일 목록
   - `git diff --stat` — 변경 규모
   - `.aura/snapshots/current.md` — 마지막 작업 내용

2. **되돌리기 옵션 제시** (사용자 선택)
   - **A. Staged 변경사항만**: `git restore --staged .`
   - **B. 전체 되돌리기**: `git checkout .`
   - **C. 마지막 커밋 취소**: `git reset HEAD~1 --soft`
   - **D. 특정 파일만**: `git checkout -- [파일]`

3. **확인 후 실행** — 항상 확인 받고 실행 (자동 실행 금지)

4. **스냅샷 업데이트** — rollback 완료 기록

## 안전 규칙
- ⚠️ `git reset --hard` 는 사용자 명시적 요청 시만
- 원격 push된 커밋 되돌리기는 반드시 경고 후 진행
- BATCH 작업 rollback → `/aura batch:recover` 사용 권장

## 다음 추천
- 되돌린 후 다시 시도 → `/aura build:` 또는 `/aura fix:`
- 원인 파악 필요 → `/aura debug:`
