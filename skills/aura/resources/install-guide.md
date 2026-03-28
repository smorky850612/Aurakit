# AuraKit 설치 가이드

> `install.sh` 실행 시 자동으로 활성화되는 보안·자동화 레이어 설명.

---

## 빠른 설치

```bash
cd /path/to/aurakit
bash install.sh
```

**요구사항**: Node.js ≥ 18 · Python ≥ 3.8 · Claude Code CLI · Git

---

## install.sh가 하는 일

### 1. 스킬 배포
```
skills/aura/         → ~/.claude/skills/aura/
skills/aura-compact/ → ~/.claude/skills/aura-compact/
skills/*/            → ~/.claude/skills/*/  (한글 단축어 56개+)
```

### 2. 훅 배포 + settings.json 등록

13개 훅을 `~/.claude/settings.json`에 자동 등록:

| 이벤트 | 핸들러 | 기능 |
|--------|--------|------|
| SessionStart | pre-session.sh | .env 보안 · 패키지 매니저 감지 · 스냅샷 확인 |
| UserPromptSubmit | korean-command.js | 한글/IME 명령어 자동 변환 |
| PreToolUse | security-scan.sh | 시크릿 패턴 차단 (L5) |
| PreToolUse | bash-guard.js | 위험 bash 명령 차단 (L3) |
| PostToolUse | build-verify.sh | V1 빌드 검증 |
| PostToolUse | bloat-check.sh | 250줄 초과 경고 |
| PostToolUse | instinct-auto-save.js | Instinct 패턴 자동 저장 + 글로벌 승격 |
| PostToolUse | auto-format.js | Prettier/gofmt/black/rustfmt 자동 포맷 |
| PostToolUse | governance-capture.js | 아키텍처 결정 감사 로그 |
| PostToolUseFailure | post-tool-failure.js | MCP 실패 복구 + 에러 추적 |
| Stop | session-stop.js | 세션 메트릭 · Instinct 힌트 · 미완료 알림 |
| PreCompact | pre-compact-snapshot.sh | 컴팩트 전 스냅샷 저장 |
| PostCompact | post-compact-restore.sh | 컴팩트 후 컨텍스트 복원 |

### 3. Statusline 설정
```
statusline/statusline-command.sh → ~/.claude/statusline-command.sh
settings.json의 statusLine 필드에 등록
```

### 4. 규칙 파일 배포
```
rules/aurakit-security.md → ~/.claude/rules/aurakit-security.md
```
이 파일은 `/aura` 호출 없이도 모든 세션에서 자동 활성화됨.

---

## 보안 레이어 활성화 여부

| 레이어 | install.sh 없이 | install.sh 후 |
|--------|----------------|---------------|
| L1 역할 분리 (프롬프트) | ✅ 항상 활성 | ✅ |
| L2 disallowed-tools | ✅ 항상 활성 | ✅ |
| L3 bash-guard.js | ❌ 비활성 | ✅ |
| L4 Worktree 격리 | ✅ agent 옵션 | ✅ |
| L5 security-scan.sh | ❌ 비활성 | ✅ |

---

## 언인스톨

```bash
node hooks/uninstall.js
# 또는
/aura uninstall
```

settings.json에서 AuraKit 훅을 모두 제거하고 백업 파일을 생성합니다.

---

## 수동 훅 등록 (선택사항)

다음 훅은 install.sh에 포함되지 않아 필요 시 수동 등록:

| 훅 | 이벤트 | 기능 |
|----|--------|------|
| subagent-start.js | PostToolUse | 에이전트 증식 추적 + 제한 |
| subagent-stop.js | PostToolUse | 에이전트 완료 기록 |
| teammate-idle.js | PostToolUse | 에이전트 메모리 저장 |

settings.json 직접 편집 또는 `/aura config:` 사용.

---

## 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| Settings Error 팝업 | 훅 형식 오류 | `install.sh` 재실행 |
| bypass 경고 팝업 | 구버전 훅 형식 | `install.sh` 재실행 |
| statusline 미표시 | statusLine 미등록 | `install.sh` 재실행 |
| 훅 충돌 | 중복 등록 | `node hooks/uninstall.js` 후 재설치 |

*AuraKit install.sh — 원클릭 설치, 백업 생성, 플랫폼 자동 감지 (Python/jq 듀얼 경로)*
