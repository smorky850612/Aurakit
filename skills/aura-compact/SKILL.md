---
name: aura-compact
description: "스냅샷 저장 + /compact 자동 실행. 단일 명령으로 완료."
allowed-tools: Write, Read, Bash
---

# /aura-compact — 스냅샷 저장 + 컴팩트

## 실행 순서 (순서대로, 생략 없이)

### Step 1 — 스냅샷 저장 (Write 도구)

`.aura/` 디렉토리 존재 시 `.aura/snapshots/current.md` 갱신. 없으면 스킵.

```
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
```

### Step 2 — 컴팩트 실행

**중요**: PowerShell SendKeys 사용하지 않는다. 아래 방법을 순서대로 시도:

**방법 A** — `claude` CLI 서브프로세스 (추천):
```bash
echo '/compact' | claude --resume 2>/dev/null
```

**방법 B** — 방법 A 실패 시, 사용자에게 즉시 안내:
아무 대기 없이 바로 출력:
```
⚡ 스냅샷 저장 완료.
👉 /compact 를 입력해주세요.
```

### Step 3 — 최종 출력

```
⚡ aura-compact — 스냅샷 저장 완료.
🗜️ 컴팩트 [실행됨 / 수동 입력 필요].
```

## 금지 사항
- ❌ PowerShell SendKeys 사용 금지
- ❌ wscript.shell 사용 금지
- ❌ Start-Sleep 대기 금지
- ❌ "5초 후 실행" 같은 비동기 해킹 금지
