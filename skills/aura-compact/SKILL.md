---
name: aura-compact
description: "스냅샷 저장 + /compact 안내. 단일 명령으로 완료."
allowed-tools: Read, Bash
---

# /aura-compact — 스냅샷 저장 + 컴팩트

## 실행 순서 (순서대로, 생략 없이)

### Step 1 — 스냅샷 저장 (Bash 도구로 직접 작성)

**Write 도구 사용 금지** — Read-before-Write 충돌 방지를 위해 Bash `cat >` 사용.

```bash
mkdir -p .aura/snapshots
cat > .aura/snapshots/current.md << 'SNAPEOF'
# AuraKit Snapshot
- Timestamp: [현재 UTC ISO 8601]
- Mode: [진행 중인 모드]
- Original Request: [사용자의 원래 요청]

## Completed
[완료된 항목들]

## Remaining
[남은 항목들]

## Next Action
[다음에 할 일]
SNAPEOF
```

### Step 2 — 최종 출력 (이것만, 짧게)

스냅샷 저장 완료 후 즉시 아래만 출력:

```
⚡ aura-compact 완료 — 스냅샷 저장됨.
👉 /compact
```

`👉 /compact` 를 반드시 마지막 줄에 단독으로 출력한다.
사용자가 이것만 복사해서 붙여넣으면 끝나도록.

## 금지 사항
- ❌ Write 도구 사용 금지 (Read-before-Write 충돌)
- ❌ PowerShell SendKeys 금지
- ❌ export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE 변경 금지 (자식 프로세스 한정, 효과 없음)
- ❌ Start-Sleep / 대기 금지
- ❌ 장황한 설명 금지 — 스냅샷 + 한 줄 안내만
