# Changelog

All notable changes to AuraKit will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/)

## [6.3.1] - 2026-03-30

### Added
- install.sh: `ensure_jq()` — jq 자동 설치 (winget/scoop/choco/brew/apt/dnf/yum/apk/pacman 순서)
- install.sh: node.js 감지 체크 추가

### Changed
- install.sh: jq 없으면 경고+종료 → 자동 설치 후 재시도
- install.sh: hook 경로 `bash "..."` / `node "..."` 따옴표 처리 일관화
- install.sh: 버전 v1.0 → v1.1

## [6.3.0] - 2026-03-30

### Added
- DNA Identity section (8 Principles: FAST/FLASHY/SECURE/THRIFTY/IMMORTAL/EVOLVING/UNIVERSAL/TOP-TIER)
- Test framework with 5 test cases and AuraScore system (tests/)
- SECURITY.md vulnerability reporting policy
- CHANGELOG.md version history
- STATUS:HEALTH mode (mode 36) — Health Dashboard with Match Rate, security score, coverage, Tech Debt

### Changed
- SKILL.md description reduced from ~350 to <250 characters
- 3 hooks registered in install.sh (subagent-start, subagent-stop, teammate-idle)
- install.sh simplified: removed multilingual skill folder copies
- Section S hook table: corrected file extensions (.sh vs .js), added bash-guard.js (L3), fixed security-scan label to (L5)
- SECURITY.md: aligned security layer definitions with SKILL.md (L3=bash-guard, L4=Worktree, L5=security-scan, L6=npm audit)
- install.sh manual fallback: added SubagentStart/SubagentStop/TeammateIdle to no-jq echo path
- Section P: corrected file extensions security-scan.js→.sh (×3), build-verify.js→.sh, bloat-check.js→.sh
- Section T hook compatibility note: "23개 훅 자동 설정" → "훅 파일 23개, 이벤트 16개 자동 등록" (clarify files vs events)

### Removed
- 30+ multilingual skill folders (description budget freed from ~87% to ~4%)
- Language-specific install loops and should_install_lang function

## [6.2.0] - 2026-03

### Added
- Cross-platform support (Codex, Cursor, Manus, Windsurf)
- Dynamic agent spawning with circuit breaker
- Loop operator, QA:E2E, BUILD_RESOLVER
- EXPLAIN, ROLLBACK, MIGRATE modes

## [6.0.0] - 2025-12

### Added
- Instinct learning engine with global cross-project learning
- Language-specific code reviewers (10 languages)
- 14 MCP server configurations
- Sonnet Amplifier, SEC-01~15 OWASP rules
- ~55% token savings (ECO tier, estimated)
