---
name: aura-compact
description: "스냅샷 저장 + /compact 자동 실행. 단일 명령으로 완료."
allowed-tools: Write, Bash
---

# /aura-compact — 단일 명령 컴팩트

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

### Step 2 — /compact 자동 실행 시도 (Bash 도구)

다음 Bash 명령을 그대로 실행:

```bash
PS_SCRIPT="/tmp/aura_compact_$$.ps1"
cat > "$PS_SCRIPT" << 'PSEOF'
Start-Sleep -Seconds 5
$w = New-Object -ComObject wscript.shell
# Try to activate the terminal window — if all fail, SendKeys goes to whatever has focus
# (Claude Code terminal should still have focus after 5s of response rendering)
$titles = @("claude", "bash", "pwsh", "Windows PowerShell", "Command Prompt", "cmd", "WindowsTerminal")
foreach ($t in $titles) {
  if ($w.AppActivate($t)) { break }
}
# NOTE: No fallback AppActivate(own PID) — that would send keys to hidden PowerShell window
Start-Sleep -Milliseconds 300
$w.SendKeys("/compact{ENTER}")
Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
PSEOF
WIN_PATH=$(cygpath -w "$PS_SCRIPT" 2>/dev/null || echo "$PS_SCRIPT")
cmd.exe /c "start \"\" /b powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -File \"${WIN_PATH}\"" 2>/dev/null || true
```

### Step 3 — 최종 출력 (이것만, 다른 텍스트 없음)

```
⚡ aura-compact — 스냅샷 저장됨.
/compact 자동 실행 시도 중 (5초 후)...
👉 실행되지 않으면 직접 입력하세요: /compact
```
