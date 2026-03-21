---
name: aura
description: "올인원 풀스택 개발 엔진. 빌드, 수정, 정리, 배포, 리뷰를 한 줄 명령으로. Discovery-First · Tiered Model · 6중 보안 · 4중 오케스트레이션 · Gap Detection · QA Pipeline · 다국어 UI · 토큰 ~55% 절감. Use when user asks to build, fix, clean, deploy, review, debug, qa, brainstorm, or orchestrate any code."
argument-hint: "[자연어 설명]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch
---

# AuraKit v4.0 — /aura

> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.
> Discovery-First · Tiered Model · 6중 보안 · 4패턴 오케스트레이션 · Gap Detection · QA Pipeline · 토큰 ~55% 절감.

**언어 규칙**: 사용자 메시지 언어 자동 감지 → 같은 언어 응답.
한국어→한국어, 日本語→日本語, 中文→中文, English→English, Español→Español, Français→Français, Deutsch→Deutsch, Italiano→Italiano.

---

## 빠른 시작

```bash
claude --dangerously-skip-permissions

/aura 로그인 기능 만들어줘   # BUILD (자동 감지)
/aura TypeError 수정해줘     # FIX
/aura 코드 정리해줘          # CLEAN
/aura Vercel 배포 설정해줘   # DEPLOY
/aura 코드 리뷰해줘          # REVIEW
/aura build:로그인 기능      # Namespace 명시
/aura! 버튼 색상 변경        # QUICK 모드 (프로토콜 최소화)
```

---

## A. 모드 감지 (Namespace 지원)

| 모드 | Namespace | 키워드 (한/영) |
|------|-----------|--------------|
| BUILD | `build:` | 만들어, 추가, 生成, create, implement |
| FIX | `fix:` | 에러, 버그, bug, TypeError, crash |
| CLEAN | `clean:` | 정리, refactor, リファクタリング, 重构 |
| DEPLOY | `deploy:` | 배포, vercel, docker, production |
| REVIEW | `review:` | 리뷰, review, check, audit |
| GAP | `gap:` | gap, 갭, match rate, 설계 vs 구현 |
| ITERATE | `iterate:` | 반복, auto-fix, 자동수정 |
| TDD | `tdd:` | tdd, 테스트 주도, test-first |
| PM | `pm:` | 기획, PRD, discovery, persona |
| PLAN | `plan:` | 계획, 설계 전, plan |
| DESIGN | `design:` | DB 설계, API 명세, design |
| REPORT | `report:` | 완료 보고서, report |
| PIPELINE | `pipeline:` | 파이프라인, 어디서 시작, 개발 순서 |
| STYLE | `style:` | 스타일, learning, expert, concise |
| SNIPPETS | `snippets:` | 스니펫, 저장, 재사용 |
| QA | `qa:` | qa, 품질 검증, docker logs |
| DEBUG | `debug:` | 디버그, 근본 원인, 5-why |
| BRAINSTORM | `brainstorm:` | 브레인스토밍, 아이디어, hmw |
| ORCHESTRATE | `orchestrate:` | 오케스트레이션, leader, swarm, council |
| MOBILE | `mobile:` | react native, expo, flutter |
| DESKTOP | `desktop:` | electron, tauri |
| BAAS | `baas:` | supabase, firebase, bkend |
| STATUS | `status` | 현재 상태, 진행률, 다음 단계 |
| CONFIG | `config:` | 설정, .aura/config.json |
| ARCHIVE | `archive:` | 아카이브, archive:list |
| BATCH | `batch:` | 병렬 처리, batch:status |
| FINISH | `finish:` | 브랜치 마무리, squash merge |
| QUICK | `!` 접미사 | `/aura! 요청` — 프로토콜 최소화 |

다국어 52개 명령 → `resources/mode-reference.md`

---

## B. 품질 티어 (Model Tier)

기본값: **ECO**.

| 티어 | 호출 | Scout | Builder | Reviewer | TestRunner | 절감 |
|------|------|-------|---------|----------|------------|------|
| QUICK | `/aura! 요청` | — | sonnet | — | — | ~60% |
| ECO | `/aura 요청` | haiku | sonnet | sonnet | haiku | ~55% |
| PRO | `/aura pro 요청` | haiku | **opus** | sonnet | haiku | ~20% |
| MAX | `/aura max 요청` | sonnet | **opus** | **opus** | sonnet | ~0% |

- QUICK: 색상 변경, 텍스트 수정, 단순 설정
- ECO: 일반 기능 구현, 대부분의 개발 작업
- PRO: 결제, 인증, 복잡한 비즈니스 로직
- MAX: 보안 감사, 아키텍처 설계, 프로덕션 크리티컬 기능

---

## C. 공통 프로토콜 (모든 모드 — 필수)

> ⚠️ B-1~B-4 생략 불가. 실패 시 작업 중단. 상세 → `resources/common-protocol.md`

**B-1. 프로젝트 프로필** [필수]
- `.aura/project-profile.md` 확인
- 없으면: Scout(haiku, context:fork) → `.aura/project-profile.md` + `.aura/design-system.md` 생성
- v4.0: ConfigHash 캐시 — `md5sum package.json go.mod pyproject.toml Dockerfile 2>/dev/null | md5sum` → 변경 시만 재실행

**B-2. 보안 L1+L5** [필수]
- `.aura/` 존재 + `.env` → `.gitignore` 포함 확인
- BUILD/FIX: `npm audit --audit-level=high` 자동 실행

**B-3. 디자인 시스템** [UI 파일 생성 시]
- `.aura/design-system.md` 로딩. 없으면 default 복사. CSS 토큰 필수.

**B-4. 스냅샷 복구** [필수]
- `.aura/snapshots/current.md` 존재 시 → 이전 작업 복구

**B-5. 크로스세션 메모리** [v4.0]
- `.aura/memory.md` → 아키텍처 결정사항 로딩
- `.aura/team/` → decisions.md(ADR 형식), conventions.md, glossary.md

---

## D. BUILD 모드

> 상세 → `resources/build-pipeline.md` · `resources/security-rules.md` · `resources/discovery-protocol.md`

1. **Discovery** [필수] — 5체크: 실제 문제 / 기존 코드 / YAGNI / 범위 / 성공 기준
2. **마이크로 플랜** (200 토큰) — 파일 목록 + 의존성 순서
3. **파일별 구현** — API(try-catch+응답 포맷) · SQL(parameterized) · 접근성(alt/label) · 안전한 인증 방식 · 200줄 제한 · CSS 토큰 · v4.0: Atomic Design · App Router 패턴 · 상태 관리 가이드
4. **스냅샷 기록** — 파일 완료마다 `.aura/snapshots/current.md` 업데이트
5. **3중 검증** — V1(빌드) + V2(Reviewer+Security, sonnet) + V3(TestRunner, haiku), V2+V3 병렬
6. **보안 L4** — security-scan.js pre-commit hook 자동
7. **Convention Check** — convention-check.sh (CONV-001~005) 자동 [v4.0]
8. **커밋** — `git commit -m "feat(scope): description"`
9. **완료 리포트**

---

## E. FIX 모드

> 상세 → `resources/fix-pipeline.md`

에러 파싱 → Scout 탐색 → 근본 원인 파악 → 최소 변경 → 3중 검증 → `fix(scope):` 커밋

---

## F. CLEAN 모드

> 상세 → `resources/clean-pipeline.md`

bloat-check.js → 중복 탐색 → dead code 제거 → 250줄 초과 분할 → 3중 검증 → `refactor(scope):` 커밋

---

## G. DEPLOY 모드

> 상세 → `resources/deploy-pipeline.md` · Enterprise → `resources/deploy-enterprise.md`

프레임워크 감지 → `.env.example` 생성 → 배포 설정 파일 → 보안 L1 재검사 → `chore(deploy):` 커밋
Enterprise: K8s(Deployment/HPA/Ingress) + Terraform(AWS ECS+RDS) + GitHub Actions + ArgoCD

---

## H. REVIEW 모드

> 상세 → `resources/review-pipeline.md`

Worker-A(Reviewer, sonnet) + Worker-B(SecurityAgent, sonnet) + Worker-C(TestRunner, haiku) + Worker-D(GapDetector, haiku)
→ 4에이전트 병렬 → 통합 리포트 (VULN-NNN 형식, A~F 등급, Match Rate %)

---

## I. ITERATE 모드

> 상세 → `resources/iterate-pipeline.md`

GapDetector(haiku) → Match Rate ≥90%: 완료 / <90%: Iterator(sonnet/opus) 자동 수정 → 최대 5회 반복

---

## J. TDD 모드

> 상세 → `resources/tdd-pipeline.md`

🔴 RED(TDD-Writer, sonnet) → TestRunner 실패 확인 → 🟢 GREEN(Builder) → TestRunner 통과 → 🔵 REFACTOR(Reviewer) → 커버리지 ≥80%

---

## K. PM 모드

> 상세 → `resources/pm-pipeline.md`

빠른: `PM-Discovery(haiku) + PM-Strategy(haiku)` 병렬 → `PM-PRD(sonnet)`
전체: `PM-Research(haiku)` 먼저 → 빠른 모드 흐름 → BUILD 전환 선택

---

## L. PLAN · DESIGN · REPORT

> 상세 → `resources/plan-pipeline.md` · `resources/design-pipeline.md` · `resources/report-pipeline.md`

```
/aura plan:[기능명]    → .aura/docs/plan-*.md
/aura design:[기능명]  → .aura/docs/design-*.md
/aura report:[기능명]  → .aura/docs/report-*.md
```

**DESIGN v4.0**: Worker-DB(sonnet) + Worker-API(sonnet) + Worker-UI(haiku) 병렬 → Cross-Check Worker(haiku) 자동 DB↔API↔UI 일관성 검증
**REPORT v4.0**: 4관점 가치 분석표 (사용자/비즈니스/기술/운영) 포함

권장 순서: PM → PLAN → DESIGN → BUILD → REVIEW → ITERATE → REPORT

---

## M. 확장 모드

| 모드 | 상세 리소스 | 주요 기능 |
|------|------------|---------|
| PIPELINE | `pipeline-guide.md` | Starter/Dynamic/Enterprise 9단계 가이드 |
| STYLE | `style-guide.md` | learning/expert/concise 페르소나 전환 |
| SNIPPETS | `snippets-guide.md` | 프롬프트 라이브러리 저장·재사용 |
| QA | `qa-pipeline.md` | Zero-Script QA, docker log 기반 검증 |
| DEBUG | `systematic-debugging.md` | 4-Phase 체계적 디버깅 (5-WHY) |
| BRAINSTORM | `brainstorming.md` | HMW + 우선순위 매트릭스 |
| ORCHESTRATE | `orchestration-patterns.md` | Leader/Swarm/Council/Watchdog |
| MOBILE | `mobile-pipeline.md` | React Native/Expo 전문 가이드 |
| DESKTOP | `desktop-pipeline.md` | Electron/Tauri 전문 가이드 |
| BAAS | `baas-pipeline.md` | Supabase/Firebase/bkend 전문 가이드 |

---

## N. STATUS · HEALTH · CONFIG

```bash
/aura status           → .aura/snapshots/current.md 기반 현황
/aura status:health    → Health Dashboard (resources/status-dashboard.md)
/aura config:show      → .aura/config.json 현재 설정
/aura config:set tier=pro  → 기본 티어 변경
/aura next             → 다음 추천 작업
```

Health Dashboard: Match Rate · 보안 점수 · 테스트 커버리지 · Tech Debt · Doc Lifecycle 인덱스

---

## O. ARCHIVE · BATCH · FINISH

> 상세 → `resources/archive-pipeline.md` · `resources/batch-pipeline.md` · `resources/branch-finishing.md`

```bash
/aura archive:[기능]        → .aura/archive/ 보관 (삭제 아님)
/aura archive:list          → 보관 목록
/aura batch:[A,B,C]        → 병렬 처리 (최대 5개, 각각 Git Worktree)
/aura batch:sequential:A,B → 순차 처리
/aura finish:              → squash merge + Worktree 정리
```

---

## P. 필수 규칙 (Mandatory — 위반 시 차단)

| 규칙 | 위반 결과 |
|------|----------|
| SQL: parameterized query | security-scan.js 차단 |
| 안전한 인증 방식 사용 | security-scan.js 차단 |
| 시크릿 하드코딩 금지 | security-scan.js 차단 |
| V1 빌드 검증 필수 | build-verify.js 차단 |
| Discovery → 플랜 → 구현 순서 | 순서 건너뛰면 재시작 |
| 컴포넌트 250줄 초과 즉시 분할 | bloat-check.js 경고 |
| CONV-001~005 HIGH 위반 | convention-check.sh 차단 |

---

## Q. 토큰 절감 메커니즘

| 메커니즘 | 방법 | 절감 |
|---------|------|------|
| SKILL.md 슬림화 | 14K→5K, 상세 내용 resource 위임 | 로딩 절감 |
| Tiered Model | Scout/V3: haiku, V2: sonnet | ~40% |
| Context Isolation | 모든 에이전트 context:fork | ~20% |
| Fail-Only Output | 성공 시 "Pass" 한 줄만 반환 | ~15% |
| Progressive Load | 해당 모드에서만 resource 로딩 | ~10% |
| Scout ConfigHash | 의존성 변경 시만 재실행 | ~10% |
| Graceful Compact | 65% 임계값, 파일 단위 체크포인트 | 낭비 최소화 |
| Quick Mode | `/aura!` — 프로토콜 생략 | ~60% |

**토큰 표시**: `💰 [티어] | 컨텍스트: [Y]% | 오늘: ↑[N] ↓[N] = [total]([N]회) | 주간: [N] | 다음: [제안]`

---

## R. 에러 처리

| 상황 | 대응 |
|------|------|
| Scout 실패 | 수동 프로파일 입력 요청 |
| V1 빌드 에러 | 에러 표시 + FIX 모드 자동 전환 |
| V2/V3 이슈 | 이슈 목록 표시 + 자동 수정 |
| 보안 L4 차단 | 패턴 제거 후 재시도 안내 |
| DESIGN Cross-Check 실패 | 해당 Worker 재실행 후 재검증 |
| Convention HIGH 위반 | 수정 후 커밋 재시도 안내 |
| Git Worktree 실패 | 경고 후 메인 브랜치에서 계속 |

---

## S. 에이전트 생명주기 · 보안 분리

> 상세 → `resources/agent-security.md` · `resources/agent-team.md`

| 에이전트 | Write | Edit | Bash | 역할 |
|---------|-------|------|------|------|
| Scout | ❌ | ❌ | 제한 | 읽기 전용 탐색 |
| Reviewer/Security | ❌ | ❌ | 제한 | 검토/감사만 |
| Builder/CTO | ✅ | ✅ | ✅ | 구현/오케스트레이션 |

보안 레벨: L1(역할 명시) → L2(disallowed-tools) → L3(bash-guard) → L4(Worktree) → L5(context:fork)

**에이전트 메모리**: 각 에이전트 결과 `.aura/agent-memory/[agent].json` 자동 저장 (subagent-stop.js 훅)
**생명주기 훅**: subagent-start.js(등록) · subagent-stop.js(완료) · `.aura/agent-memory/active.json`

---

*AuraKit v4.0 — Discovery-First · Tiered Model ~55% · 6중 보안 · 28모드 · 8개 언어 52명령 · 13에이전트 · Gap Detection · 에이전트 생명주기 · ConfigHash · Team Context · Cross-Check · 4-Perspective Value Table · Convention Check*
