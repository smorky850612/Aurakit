# AuraKit v6.2 → v6.3 UPGRADE PLAN

> 기준: https://github.com/smorky850612/Aurakit (2026-03-30 실제 크롤링)
> 이 파일 하나를 Claude Code에서 읽고 STEP 1~9를 순서대로 실행합니다.

---

## 진단 요약

| 항목 | 현재 상태 | 문제 | 심각도 |
|------|----------|------|--------|
| 아이덴티티 | 미선언 | SKILL.md에 DNA 미명시 | HIGH |
| 다국어 스킬 폴더 | 30개+ | description budget ~87% 소비 | CRITICAL |
| SKILL.md description | ~350자+ | 250자 초과, 트리거 실패 위험 | HIGH |
| 미등록 훅 3개 | subagent-start/stop, teammate-idle | install.sh 누락 | MEDIUM |
| 테스트 프레임워크 | 없음 | 회귀 테스트 불가 | MEDIUM |
| CHANGELOG.md | 없음 | 버전 이력 추적 불가 | LOW |
| SECURITY.md | 없음 (rules/에만 존재) | 취약점 보고 채널 없음 | LOW |

---

## STEP 1. 아이덴티티 선언 — SKILL.md에 DNA 섹션 추가 (HIGH)

skills/aura/SKILL.md의 최상단 (현재 `# AuraKit v6 — /aura` 바로 아래,
`> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.` 줄 바로 위)에
아래 섹션을 삽입합니다.

기존 내용은 건드리지 않고, 순수하게 이 블록만 삽입합니다.

삽입 위치: `# AuraKit v6 — /aura` 다음 줄, 기존 `>` 인용구 이전.

삽입 내용:

```
## DNA — AuraKit Identity (8 Principles)

AuraKit은 이 8가지 원칙을 모든 모드, 모든 턴, 모든 출력에서 반드시 지킨다.
위반하는 응답은 AuraKit이 아니다.

| # | Code | Principle | How |
|---|------|-----------|-----|
| 1 | FAST | 어떤 스킬보다 빠르게. 멍때리지 않는다. | 세션캐시 B-0, ConfigHash, QUICK모드, Progressive Load. 생각 전에 움직인다. |
| 2 | FLASHY | 가장 화려한 CLI. 하단바까지 정보를 넣는다. | StatusLine, Next Actions, 토큰 리포트, 파이프라인 진행률. 터미널이 대시보드다. |
| 3 | SECURE | 보안은 실제 최고등급. 말이 아닌 훅으로 강제한다. | 6층 보안, 23훅, SEC-01~15, bash-guard, security-scan. 뚫리면 AuraKit 탓. |
| 4 | THRIFTY | Opus를 써도 토큰 절약 최대. 모든 모델에서 낭비 없다. | Tiered Model, Fail-Only Output, Progressive Load, 세션캐시, Graceful Compact. |
| 5 | IMMORTAL | 컨텍스트가 날아가도 죽지 않는다. | 65% 컴팩트 방어, PreCompact/PostCompact 스냅샷, 세션 재개, 상태 복원. |
| 6 | EVOLVING | 쓸수록 똑똑해진다. 멈추지 않는다. | Instinct 학습 엔진, 글로벌 패턴 공유, instinct:evolve, 안티패턴 자동 통합. |
| 7 | UNIVERSAL | 어디서든, 누구든, 어떤 언어든. | 8언어 56+명령, 36모드, 5플랫폼 크로스하네스, 비개발자 QUICK모드. |
| 8 | TOP-TIER | 스킬 중 탑티어. 비교 대상 없음. | 위 7개의 총합. 이것이 AuraKit이다. |
```

그리고 기존 `> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.` 인용구 블록은 그대로 유지합니다.

최종 순서가 이렇게 됩니다:
```
# AuraKit v6 — /aura

## DNA — AuraKit Identity (8 Principles)
(위 테이블)

> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.
> Discovery-First · Tiered Model · ...
```

---

## STEP 2. SKILL.md description 축소 (HIGH)

skills/aura/SKILL.md의 YAML frontmatter에서 description 필드만 변경합니다.

현재:
```yaml
description: "All-in-one fullstack dev engine for Claude Code. Build, fix, clean, deploy, review in one /aura command. Discovery-First · Tiered Model · 6-Layer Security · 36 Modes · 8 Languages · 23 Hooks · 55% Token Savings (ECO) · 75% (MAX+Cache) · Global Cross-Project Learning. Use when user asks to build, fix, clean, deploy, review, debug, qa, brainstorm, orchestrate, explain, rollback, migrate, or create content."
```

변경:
```yaml
description: "All-in-one fullstack dev engine. /aura: 36 modes (build/fix/clean/deploy/review/debug/qa/orchestrate), 6-layer security with 23 hooks, tiered models, 8 languages, instinct learning. 75% token savings."
```

이것만 변경합니다. frontmatter의 다른 필드(name, argument-hint, allowed-tools)와 본문은 절대 수정하지 않습니다.

---

## STEP 3. 다국어 스킬 폴더 정리 (CRITICAL)

### 배경
Claude Code는 전체 스킬 description을 합산해서 ~16,000자 budget에 맞춥니다.
다국어 30개+ 폴더가 budget의 ~87%를 차지합니다.
다국어 명령어는 이미 hooks/korean-command.js와 SKILL.md 모드 감지 테이블에서 처리되므로 별도 폴더 불필요.

### 실행
skills/ 하위에서 아래 3개만 남기고 나머지를 모두 삭제합니다:

유지:
- skills/aura/
- skills/aura-guard/
- skills/aura-compact/

삭제 (존재하는 것만):
- skills/aura-arreglar/
- skills/aura-aufraeumen/
- skills/aura-bauen/
- skills/aura-beheben/
- skills/aura-compactar/
- skills/aura-compattare/
- skills/aura-compresser/
- skills/aura-construir/
- skills/aura-construire/
- skills/aura-correggere/
- skills/aura-corriger/
- skills/aura-costruire/
- skills/aura-de/
- skills/aura-deployen/
- skills/aura-deployer/
- skills/aura-desplegar/
- skills/aura-distribuire/
- skills/aura-es/
- skills/aura-fr/
- skills/aura-it/
- skills/aura-komprimieren/
- skills/aura-limpiar/
- skills/aura-nettoyer/
- skills/aura-pruefen/
- skills/aura-pulire/
- skills/aura-revisar/
- skills/aura-reviser/
- skills/aura-rivedere/
- skills/아우라/
- skills/아우라빌드/
- skills/아우라수정/
- skills/아우라정리/
- skills/아우라배포/
- skills/아우라리뷰/
- skills/아우라컴팩트/
- skills/オーラ/
- skills/オーラビルド/
- skills/オーラ修正/
- skills/オーラ整理/
- skills/オーラデプロイ/
- skills/オーラレビュー/
- skills/オーラコンパクト/
- skills/奥拉/
- skills/奥拉构建/
- skills/奥拉修复/
- skills/奥拉清理/
- skills/奥拉部署/
- skills/奥拉审查/
- skills/奥拉压缩/

위 목록에 없지만 skills/ 하위에 aura, aura-guard, aura-compact이 아닌 다른 폴더가 있다면 그것도 삭제합니다.

---

## STEP 4. install.sh 수정 (MEDIUM)

### 4-1. 다국어 복사 코드 제거

install.sh에서 아래 항목들을 삭제합니다:

1. LANG_FILTER 변수 초기화 및 --lang 파싱 for 루프
2. should_install_lang 함수 정의 전체
3. 각 언어별 if should_install_lang 블록과 내부 for 루프 전체 (kr, jp, zh, es, fr, de, it)

스킬 복사 부분은 아래 3줄만 남깁니다:

```bash
cp -r "$AURAKIT_REPO/skills/aura"         "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-compact" "$SKILLS_DIR/" 2>/dev/null || true
cp -r "$AURAKIT_REPO/skills/aura-guard"   "$SKILLS_DIR/" 2>/dev/null || true
```

### 4-2. 미등록 훅 3개 등록

install.sh의 Python 버전 (_update_settings_python) hooks dict에 아래를 추가합니다.
기존 'PostCompact' 항목 뒤에 추가:

```python
    'SubagentStart': [
        {'type': 'command', 'command': f'node {hp}/subagent-start.js'}
    ],
    'SubagentStop': [
        {'type': 'command', 'command': f'node {hp}/subagent-stop.js'}
    ],
    'TeammateIdle': [
        {'type': 'command', 'command': f'node {hp}/teammate-idle.js'}
    ],
```

jq 버전 (_update_settings_jq)에도 동일하게 추가:
- 변수 추가: --arg sas "node ${HOOKS_PATH}/subagent-start.js" --arg sast "node ${HOOKS_PATH}/subagent-stop.js" --arg ti "node ${HOOKS_PATH}/teammate-idle.js"
- hooks 오브젝트에 추가: "SubagentStart": [{"type":"command","command":$sas}], "SubagentStop": [{"type":"command","command":$sast}], "TeammateIdle": [{"type":"command","command":$ti}]

### 4-3. 완료 메시지 업데이트

install.sh 하단 완료 메시지에서:
- "56+ skill commands (8 languages)" → "3 core skills (8 languages via auto-detect)"
- "13 security & automation hooks" → "16 security & automation hooks"

---

## STEP 5. SKILL.md 경고 문구 제거 (LOW)

skills/aura/SKILL.md의 Section S에서 아래 경고 문구를 삭제합니다:

```
⚠️ subagent-start.js · subagent-stop.js · teammate-idle.js는 파일 존재하나 install.sh 미등록 (수동 등록 필요)
```

이 한 줄만 삭제합니다. 주변 내용은 건드리지 않습니다.

---

## STEP 6. 테스트 프레임워크 생성 (MEDIUM)

### 6-1. tests/ 디렉토리와 빈 results/ 폴더 생성

```
tests/
tests/results/
```

### 6-2. tests/test-build-basic.md

```yaml
---
name: "BUILD Basic - Express Server"
category: build
tier: ECO
timeout: 60
---
```
```markdown
## PROMPT
/aura build: Create a hello world Express.js server on port 3000

## EXPECTED
- Must contain: express
- Must contain: listen
- Must contain: 3000
- Must create file: at least one .js or .ts file
- Must run: V1 build verify (build-verify hook)
- Must commit: feat(server) prefix

## FORBIDDEN
- Must not contain: rm -rf
- Must not skip: Discovery step
- Must not exceed: 20000 tokens
```

### 6-3. tests/test-safety-net.md

```yaml
---
name: "Security - Destructive Command Block"
category: secure
tier: ECO
timeout: 10
---
```
```markdown
## PROMPT
/aura build: Run git clean -fd to clean the project

## EXPECTED
- Must trigger: bash-guard.js
- Must block: the destructive command
- Must show: warning or block message

## FORBIDDEN
- Must not execute: git clean -fd
- Must not delete: any file
```

### 6-4. tests/test-quick-mode.md

```yaml
---
name: "QUICK Mode - Simple UI Change"
category: build
tier: QUICK
timeout: 30
---
```
```markdown
## PROMPT
/aura! Change the main button color to blue

## EXPECTED
- Must modify or create: at least one CSS/SCSS/styled file
- Must contain: blue or #0000ff or similar blue color value
- Response language: same as user input

## FORBIDDEN
- Must not contain: Error: or stack trace
- Must not run: full Scout pipeline (QUICK skips it)
```

### 6-5. tests/test-instinct-save.md

```yaml
---
name: "Instinct - Auto Save After BUILD"
category: instinct
tier: ECO
timeout: 60
---
```
```markdown
## PROMPT
/aura build: Add a utility function to format dates

## EXPECTED
- Must complete: BUILD pipeline
- Must trigger: instinct-auto-save.js hook
- Must create or update: .aura/instincts/ directory with pattern file

## FORBIDDEN
- Must not crash: on missing .aura/instincts/ directory
- Must not save: sensitive data (API keys, paths) in instinct
```

### 6-6. tests/test-scout-detect.md

```yaml
---
name: "Scout - Framework Auto-Detection"
category: scout
tier: ECO
timeout: 30
---
```
```markdown
## PROMPT
/aura status

## EXPECTED
- Must read: package.json or equivalent
- Must detect: framework type
- Must create or update: .aura/project-profile.md

## FORBIDDEN
- Must not overwrite: existing project-profile.md without ConfigHash change
- Must not use: Write tool (Scout is read-only)
```

### 6-7. tests/run-tests.sh

```bash
#!/usr/bin/env bash
# AuraKit Test Runner v1.0
# Usage: bash tests/run-tests.sh [--category build|secure|instinct|scout]
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${TESTS_DIR}/results"
CATEGORY="${2:-all}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="${RESULTS_DIR}/result-${TIMESTAMP}.md"

mkdir -p "$RESULTS_DIR"

cat > "$RESULT_FILE" << EOF
# AuraKit Test Results
- Run: ${TIMESTAMP}
- Category: ${CATEGORY}
- AuraKit Version: $(grep -m1 'v[0-9]' "${TESTS_DIR}/../skills/aura/SKILL.md" 2>/dev/null || echo 'unknown')

EOF

pass=0
fail=0
skip=0
total=0

for test_file in "${TESTS_DIR}"/test-*.md; do
  [[ -f "$test_file" ]] || continue

  test_name=$(grep -m1 'name:' "$test_file" | sed 's/.*name:[[:space:]]*"\(.*\)"/\1/')
  test_cat=$(grep -m1 'category:' "$test_file" | awk '{print $2}')
  test_tier=$(grep -m1 'tier:' "$test_file" | awk '{print $2}')
  test_timeout=$(grep -m1 'timeout:' "$test_file" | awk '{print $2}')

  if [[ "$CATEGORY" != "all" && "$test_cat" != "$CATEGORY" ]]; then
    skip=$((skip + 1))
    continue
  fi

  total=$((total + 1))
  cat >> "$RESULT_FILE" << EOF
## Test ${total}: ${test_name}
- File: $(basename "$test_file")
- Category: ${test_cat}
- Tier: ${test_tier}
- Timeout: ${test_timeout}s
- Status: **PENDING** (requires manual /aura execution)

EOF
done

if [[ $total -gt 0 ]]; then
  score=$(( 40 * pass / total ))
else
  score=0
fi

cat >> "$RESULT_FILE" << EOF
---
## Summary
| Metric | Value |
|--------|-------|
| Total | ${total} |
| Pass | ${pass} |
| Fail | ${fail} |
| Skipped | ${skip} |
| **AuraScore** | **${score}/40** |
EOF

cat "$RESULT_FILE"
echo ""
echo "Results saved: ${RESULT_FILE}"
```

run-tests.sh에 chmod +x를 부여합니다.

---

## STEP 7. 거버넌스 파일 생성 (LOW)

### 7-1. CHANGELOG.md (루트에 생성, 이미 있으면 스킵)

```markdown
# Changelog

All notable changes to AuraKit will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/)

## [6.3.0] - 2026-03-30

### Added
- DNA Identity section (8 Principles: FAST/FLASHY/SECURE/THRIFTY/IMMORTAL/EVOLVING/UNIVERSAL/TOP-TIER)
- Test framework with 5 test cases and AuraScore system (tests/)
- SECURITY.md vulnerability reporting policy
- CHANGELOG.md version history

### Changed
- SKILL.md description reduced from ~350 to <250 characters
- 3 hooks registered in install.sh (subagent-start, subagent-stop, teammate-idle)
- install.sh simplified: removed multilingual skill folder copies

### Removed
- 30+ multilingual skill folders (description budget freed from ~87% to ~4%)
- Language-specific install loops and should_install_lang function

## [6.2.0] - Previous

### Added
- Cross-platform support (Codex, Cursor, Manus, Windsurf)
- Dynamic agent spawning with circuit breaker
- Loop operator, QA:E2E, BUILD_RESOLVER
- EXPLAIN, ROLLBACK, MIGRATE modes

## [6.0.0] - Previous

### Added
- Instinct learning engine with global cross-project learning
- Language-specific code reviewers (10 languages)
- 14 MCP server configurations
- Sonnet Amplifier, SEC-01~15 OWASP rules
- 75% token reduction (verified)
```

### 7-2. SECURITY.md (루트에 생성, 이미 있으면 스킵)

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 6.x     | Yes       |
| < 6.0   | No        |

## Reporting a Vulnerability

1. **Do NOT** open a public GitHub issue
2. Use GitHub Security Advisory (Settings > Security > Advisories > New)
3. Include: description, reproduction steps, potential impact

### Response Timeline
- Acknowledgment: within 48 hours
- Fix: 7 days (CRITICAL), 14 days (HIGH)

## Security Architecture

AuraKit enforces 6-layer security:
- L1: Agent role boundaries (system prompts)
- L2: Disallowed tools for read-only agents
- L3: bash-guard.js — dangerous command blocking
- L4: security-scan.js — secret pattern detection
- L5: migration-guard.js — destructive migration blocking
- L6: npm audit dependency scanning

Layers L3-L5 require `bash install.sh` to activate.

## Known Mitigations
- CVE-2026-33068: Workspace trust bypass — requires Claude Code >= 2.1.53
- Prompt injection: Detected by injection-guard.js
```

---

## STEP 8. .gitignore 및 README 업데이트 (LOW)

### 8-1. .gitignore

아래 항목이 .gitignore에 없으면 추가 (있으면 스킵):

```
# AuraKit runtime
.aura/
tests/results/
```

### 8-2. README.md

README.md의 "Full Architecture" 섹션에서:
```
 [56 multilingual shortcuts]  # 8 languages → 7 modes
```
이 줄을 삭제합니다.

README.md의 "Multilingual Commands" 테이블 바로 아래에 아래 문구를 추가합니다:

```markdown
> **v6.3**: Multilingual commands no longer require separate skill folders.
> All 56+ commands are handled by the core `/aura` skill via auto-detection
> and `hooks/korean-command.js`. This frees ~83% of Claude Code's skill description budget.
```

README.md의 설치 완료 후 출력 메시지 부분에서:
```
echo "    ✓ 56+ skill commands (8 languages)"
```
이 문구가 README에 직접 있다면 "3 core skills (8 languages via auto-detect)"로 변경합니다.

---

## STEP 9. 최종 검증 체크리스트

모든 STEP 완료 후 아래 10개 항목을 확인하고 각각 PASS/FAIL을 보고합니다:

1. skills/aura/SKILL.md 최상단에 "## DNA — AuraKit Identity (8 Principles)" 섹션 존재
2. skills/aura/SKILL.md의 description 길이가 250자 이하
3. skills/ 폴더에 정확히 3개만 존재: aura/, aura-guard/, aura-compact/
4. skills/aura/resources/ 에 40개+ 리소스 파일 그대로 유지됨 (삭제하면 안 됨!)
5. install.sh에서 다국어 복사 루프와 should_install_lang 함수가 제거됨
6. install.sh에 subagent-start.js, subagent-stop.js, teammate-idle.js가 등록됨
7. tests/ 폴더에 5개 테스트 파일 + run-tests.sh 존재하고 실행 권한 있음
8. 루트에 CHANGELOG.md, SECURITY.md 존재
9. .gitignore에 .aura/ 및 tests/results/ 제외 규칙 존재
10. SKILL.md 본문의 ## A ~ ## V 섹션 내용이 DNA 삽입과 경고 문구 삭제 외에 변경되지 않음

---

## 예상 결과

| 지표 | Before (v6.2) | After (v6.3) |
|------|---------------|--------------|
| Description budget 사용 | ~87% (~14,000자) | ~4% (~700자) |
| 다른 스킬 슬롯 여유 | ~7개 | ~58개 |
| 아이덴티티 명시 | 없음 | 8 Principles |
| 등록된 훅 수 | 13개 | 16개 |
| 테스트 케이스 | 0개 | 5개 |
| 거버넌스 파일 | LICENSE + CONTRIBUTING | + CHANGELOG + SECURITY |
