---
name: aura-compact
description: "컨텍스트 창 수동 압축. 현재 진행 상황을 초경량 스냅샷으로 저장 후 /compact 실행. Use when context window is filling up or user wants to save progress."
disable-model-invocation: true
allowed-tools: Read, Write, Bash
---

# AuraKit Compact — /aura-compact

> 컨텍스트 창이 가득 찰 때 진행 상황을 보존하고 압축하는 수동 트리거.

---

## 실행 흐름

### Step 1 — 현재 작업 상태 수집

아래 정보를 수집하여 `.aura/snapshots/current.md`에 저장한다.

```markdown
# AuraKit Snapshot
- Timestamp: [현재 ISO 8601 타임스탬프]
- Mode: [현재 모드: BUILD/FIX/CLEAN/DEPLOY/REVIEW]
- Original Request: [사용자의 원래 요청 전문]
- Plan: [총 N개 파일]

## Completed
- [x] 완료된 파일 1
- [x] 완료된 파일 2

## Remaining
- [ ] 남은 파일 1
- [ ] 남은 파일 2

## Last Verification
- Build: [Pass / Fail — 에러 내용]
- Security: [Pass / VULN-001: 설명]
- Tests: [N/N Pass]

## Key Decisions
- [아키텍처 결정 사항 1]
- [기술 선택 이유 1]

## Next Action
- [다음에 바로 해야 할 일]
```

### Step 2 — 스냅샷 저장

```bash
mkdir -p .aura/snapshots
# 기존 스냅샷 백업
if [ -f .aura/snapshots/current.md ]; then
  cp .aura/snapshots/current.md \
     .aura/snapshots/SNAPSHOT-$(date +%Y%m%d-%H%M%S).md
fi
# 새 스냅샷 저장 (Write 도구로)
```

### Step 3 — 사용자 안내

저장 완료 후 다음 메시지를 출력한다:

```
✅ AuraKit 스냅샷 저장 완료

저장 위치: .aura/snapshots/current.md

이제 /compact 를 실행하세요:
  1. /compact 입력 → 컨텍스트 압축 실행
  2. 압축 완료 후 /aura 입력
  3. AuraKit이 자동으로 스냅샷을 복구하고 이어서 작업합니다

⚡ post-compact-restore.sh가 자동으로 컨텍스트를 복원합니다.
```

---

## 자동 컴팩트 흐름 (참고)

```
컨텍스트 65% 도달
  → CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 트리거
  → pre-compact-snapshot.sh 자동 실행 (PreCompact hook)
  → /compact 자동 실행
  → post-compact-restore.sh 자동 실행 (PostCompact hook)
  → 스냅샷 내용이 새 컨텍스트에 주입됨
```

수동으로 압축하려면 `/aura-compact` → `/compact` 순서로 실행.

---

*AuraKit — Disk > Memory 원칙: 스냅샷은 항상 디스크에 저장*
