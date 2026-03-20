---
name: aura
description: "올인원 풀스택 개발 엔진. 빌드, 수정, 정리, 배포, 리뷰를 한 줄 명령으로. Step-back Discovery · 필수 규칙 · Tiered Model · Git Worktree · 진행률 · 4중 보안 · 3중 검증 · Graceful Compact. Use when user asks to build, fix, clean, deploy, or review any code."
argument-hint: "[자연어 설명]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch
---

# AuraKit v3.0 — /aura

> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.
> Discovery-First · Tiered Model · 5중 보안 · Gap Detection · 다국어 UI · 토큰 ~55% 절감.

**언어 규칙**: 사용자 메시지 언어를 자동 감지하여 같은 언어로 응답한다.
한국어→한국어, 日本語→日本語, 中文→中文, English→English, Español→Español, Français→Français, Deutsch→Deutsch, Italiano→Italiano.

---

## 빠른 시작 (Quick Start)

```bash
# Claude Code 시작 (권장 — 권한 프롬프트 없이 완전 자율 실행)
claude --dangerously-skip-permissions

# 기본 사용 (모드 자동 감지)
/aura 로그인 기능 만들어줘       # BUILD
/aura TypeError 수정해줘         # FIX
/aura 코드 정리해줘              # CLEAN
/aura Vercel 배포 설정해줘       # DEPLOY
/aura 코드 리뷰해줘              # REVIEW

# Namespace 명시 (모드가 불명확할 때)
/aura build:로그인 기능
/aura fix:TypeError at UserList.tsx:45
/aura clean:Dashboard.tsx 분할
/aura deploy:vercel
/aura review:보안 점검

# Compact (훅 자동 실행 — /aura-compact 불필요)
/compact    # PreCompact 훅 → 스냅샷 저장 → 압축 → PostCompact 훅 → 복구
```

**자율 실행**: `--dangerously-skip-permissions` 모드에서도 security-scan.sh · migration-guard.sh 훅은 그대로 동작 (보안 유지)
**토큰 사용량**: `/context` 명령으로 확인 | 자동 compact: 65% (`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65`)

---

## A. 모드 자동 감지 (Namespace 지원)

`/aura [tier] [mode:]$ARGUMENTS` 형태로 모드 및 품질 티어 명시 가능. 명시 없으면 키워드로 자동 감지.

### 모드 테이블

| 모드 | Namespace | 키워드 (한/영) |
|------|-----------|--------------|
| **BUILD** | `build:` | 만들어, 추가, 生成, 构建, create, implement, 作って |
| **FIX** | `fix:` | 에러, 버그, エラー, 错误, bug, TypeError, crash |
| **CLEAN** | `clean:` | 정리, リファクタリング, 重构, refactor, optimize |
| **DEPLOY** | `deploy:` | 배포, デプロイ, 部署, vercel, docker, production |
| **REVIEW** | `review:` | 리뷰, レビュー, 审查, review, check, audit |
| **GAP** | `gap:` | gap, 갭, ギャップ, 差距, 설계 vs 구현, match rate |
| **ITERATE** | `iterate:` | 반복, 개선, iterate, auto-fix, 자동수정, gap 낮음 |
| **TDD** | `tdd:` | tdd, 테스트 주도, test-first, red-green, 테스트 먼저 |
| **PM** | `pm:` | 기획, 분석, persona, discovery, PRD, 시장조사, jtbd |
| **PLAN** | `plan:` | 계획, 기획, 설계 전, 구현 전 계획 문서, plan, 플랜 |
| **DESIGN** | `design:` | DB 설계, API 명세, 컴포넌트 구조, design, 설계 |
| **REPORT** | `report:` | 완료 보고서, 요약, 진행 상황, report, 리포트, 보고 |
| **PIPELINE** | `pipeline:` | 파이프라인, 단계, 어디서 시작, 개발 순서, 신규 프로젝트 |
| **QUICK** | `!` 접미사 | `/aura! [요청]` — 단일 파일, 프로토콜 최소화 |
| **COMPACT** | — | 자동 (65% 임계값) |

감지 불가 시: 모드 명시 요청.

### 품질 티어 (Model Tier)

사용자는 비용 vs 품질을 명시적으로 선택할 수 있다. 기본값은 **ECO**.

| 티어 | 호출 방법 | Scout | Builder | Reviewer | Security | TestRunner | 절감 |
|------|---------|-------|---------|----------|----------|------------|------|
| **QUICK** | `/aura! 요청` | — | sonnet | — | — | — | ~60% |
| **ECO** | `/aura 요청` (기본값) | haiku | sonnet | sonnet | sonnet | haiku | ~55% |
| **PRO** | `/aura pro 요청` | haiku | **opus** | sonnet | sonnet | haiku | ~20% |
| **MAX** | `/aura max 요청` | sonnet | **opus** | **opus** | **opus** | sonnet | ~0% |

```bash
# ECO (기본 — 일반 개발, 비용 절약)
/aura 로그인 기능 만들어줘

# PRO (핵심 구현만 opus — 헤비 유저 권장)
/aura pro 결제 시스템 만들어줘
/아우라 pro 결제 시스템 만들어줘

# MAX (전체 opus — 복잡한 아키텍처, 보안 중요 기능)
/aura max 마이크로서비스 인증 시스템 설계
/aura max review:전체 코드베이스 보안 감사

# QUICK (단순 수정 — 가장 빠름)
/aura! 버튼 색상 변경
```

**티어 선택 가이드**:
- QUICK: 색상 변경, 텍스트 수정, 단순 설정
- ECO: 일반 기능 구현, 대부분의 개발 작업
- PRO: 결제, 인증, 복잡한 비즈니스 로직 — Builder만 opus로 품질 극대화
- MAX: 보안 감사, 아키텍처 설계, 프로덕션 크리티컬 기능

**GAP 모드**: `/aura gap:` 또는 `/aura gap:path/to/spec.md` → `resources/gap-check.md` 로딩.

**PIPELINE 모드**: `/aura pipeline:` 또는 `/aura pipeline:[기능명]` → `resources/pipeline-guide.md` 로딩.
Scout가 Starter/Dynamic/Enterprise 자동 감지 → 맞춤 9단계 경로 제공.

---

## B. 공통 프로토콜 (모든 모드 실행 전 — 필수)

> ⚠️ 아래 B-1~B-4는 생략 불가 (Mandatory). 각 단계 실패 시 작업 중단.

### B-1. 프로젝트 프로필 체크 [필수]
```
파일 확인: .aura/project-profile.md
→ 없으면: Scout 에이전트 실행 (model: haiku, context:fork)
  Scout가 .aura/project-profile.md + .aura/design-system.md 자동 생성
  포함 항목: 언어, 프레임워크, 패키지 매니저, 테스트 도구, 주요 디렉토리 구조
  복잡도 감지: Starter / Dynamic / Enterprise (pipeline-guide.md 기준)
  → 감지 결과를 project-profile.md의 "Level:" 필드에 저장
→ 있으면: 프로필 로딩 (Read 도구, 0 LLM 토큰)
```

### B-2. 보안 L1 + L5 확인 [필수]
```
SessionStart에 pre-session.sh 이미 실행됨.
확인:
  - .aura/ 디렉토리 존재
  - .env가 .gitignore에 포함
L5 의존성 보안 (BUILD/FIX 모드에서 자동):
  - npm audit --audit-level=high (Node.js 프로젝트)
  - pip check (Python 프로젝트)
  HIGH 이상 취약점 발견 시: 경고 표시 (차단 안함, 사용자 판단)
이상 감지 시: 즉시 작업 중단 + 사용자 안내 후 해결 요청
```

### B-3. 디자인 시스템 로딩 [필수 - UI 파일 생성 시]
```
파일 확인: .aura/design-system.md
→ 있으면: CSS 변수 목록 메모리 로딩
→ 없으면: templates/design-system-default.md 복사 후 사용
규칙: 하드코딩 색상값 금지. var(--color-primary) 등 토큰 사용 필수.
```

### B-4. 스냅샷 복구 체크 [필수]
```
파일 확인: .aura/snapshots/current.md
→ 있으면: 내용 로딩 → "이전 작업을 이어서 진행합니다" 안내
→ 없으면: 새 작업 시작
```

### B-5. 크로스세션 메모리 [선택]
```
파일 확인: .aura/memory.md
→ 있으면: 아키텍처 결정사항·팀 규칙·반복 패턴 로딩
→ 없으면: 건너뜀 (작업 중 중요 결정 발생 시 자동 기록)

기록 조건: 아키텍처 결정, 반복되는 패턴, 팀 규칙 발견 시
포맷: ## [날짜] [주제]\n내용\n
```

---

## C. BUILD 모드

> 상세 구현 규칙 → `resources/build-pipeline.md` (이 모드에서만 로딩)
> 보안 규칙 → `resources/security-rules.md` (BUILD/FIX에서만 로딩)
> Discovery 프로토콜 → `resources/discovery-protocol.md`

### 실행 순서

**Step 0 — Discovery (필수, 생략 불가)**
`resources/discovery-protocol.md` 참조. 5가지 검토:
1. 실제 문제가 무엇인가? (표면 vs 핵심)
2. 이미 있는 것은 없는가? (Scout로 프로젝트 탐색)
3. YAGNI — 최소 구현으로 목표 달성 가능한가?
4. 구현 범위 (포함/제외 명확화)
5. 성공 기준 (완료 조건)

Discovery 출력 후 구현 시작. 모호한 항목만 사용자 확인.

**Step 0.5 — Git Worktree 격리 (선택, 신규 기능 시 권장)**
```bash
# 신규 기능 개발 시 독립된 작업 공간 생성
TASK_NAME=$(echo "$ARGUMENTS" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
git worktree add .aura/worktree/${TASK_NAME} -b aura/${TASK_NAME} 2>/dev/null || true
# 작업 완료 후: git worktree remove .aura/worktree/${TASK_NAME}
# 워크트리 없어도 작업 진행 가능 (생략 가능)
```

**Step 1 — 마이크로 플랜** (200 토큰 이내, Mandatory)
```
📋 BUILD PLAN — [기능명]
파일 목록 (의존성 순서):
1. [파일경로] — [역할 1줄]
의존성: [A] → [B]
예상: [N]개 파일
```
플랜 출력 후 즉시 구현 시작 (사용자 응답 대기 불필요).

**Step 2 — 파일별 구현 (필수 규칙, 위반 시 재작성)**
- API: try-catch + `{success, error, message}` 응답 [필수]
- 입력: zod 또는 수동 validation [필수]
- SQL: parameterized query [필수, 위반 시 보안 L4 차단]
- 접근성: alt, label, htmlFor, tabIndex [필수]
- 인증: httpOnly cookie (localStorage 토큰 [금지, 위반 시 차단])
- 컴포넌트: 200줄 이내 [초과 시 즉시 분할]
- CSS: 디자인 시스템 토큰 [하드코딩 금지]
- loading/error 상태 UI [필수]
- 언어별 전문 규칙: 프로젝트 프로필에서 감지된 언어에 맞는 패턴 적용

**Step 3 — 진행 상태 기록 + Graceful Compact 체크포인트 (Mandatory)**
파일 완료마다 `.aura/snapshots/current.md` 업데이트 (build-progress.sh 훅이 진행률 자동 표시).
체크포인트 조건: 완료 ≥ 2개 AND 마지막 파일 ≥ 100줄 AND 남은 파일 ≥ 1개
→ 조건 충족 시: `⚡ 체크포인트 [N/M]` 출력. Enter(계속) 또는 /compact(절약).
→ compact 선택: 스냅샷 보존 → PostCompact 복구 → `/aura`로 재개.

**Step 4 — 3중 검증 (Tiered Model, Mandatory)**
```
V1: build-verify.sh hook (tsc --noEmit / py_compile) — 자동 [필수]
V2: Worker (model: sonnet, context:fork) → 코드 리뷰 + 보안 L3
V3: Worker (model: haiku,  context:fork) → 테스트 실행
V2 + V3 병렬 실행 [필수]. 실패 시 FIX 모드 자동 전환.
```

**Step 5 — 보안 L4 (Mandatory)**
security-scan.sh pre-commit hook 자동 실행. 시크릿 감지 시 커밋 차단.

**Step 6 — 커밋 (Mandatory)**
```bash
git add [변경 파일]
git commit -m "feat(scope): description"
```

**Step 7 — 완료 리포트**
```
✅ AuraKit BUILD 완료 — [기능명]
생성: [N]개 파일
V1: ✅ | V2: ✅ | V3: ✅ [N/N Pass]
토큰 확인: /context
다음: [후속 작업 제안]
```

---

## D. FIX 모드

> 상세 → `resources/fix-pipeline.md`

1. 에러 파싱 (에러 타입 분류 + 파일:라인 추출)
2. Scout (model: haiku, context:fork) → 관련 파일 탐색
3. 근본 원인 파악 → 최소 변경 수정 [증상 회피 금지, Mandatory]
4. `.aura/snapshots/current.md` 업데이트
5. 3중 검증: V1[필수] + V2(sonnet) + V3(haiku) 병렬
6. `git commit -m "fix(scope): description"`
7. 수정 리포트 + 재발 방지 권고

---

## E. CLEAN 모드

> 상세 → `resources/clean-pipeline.md`

1. bloat-check.sh 결과 수집 (250줄 초과 파일 감지)
2. Scout (model: haiku, context:fork) → 중복 코드 탐색
3. dead code 제거 (미사용 함수/import/변수) [기능 변경 금지, Mandatory]
4. 250줄 초과 파일 분할 [순환 의존성 없는지 확인]
5. 네이밍 + 포맷 통일 (프로젝트 ESLint/Prettier 설정 기준)
6. `.aura/snapshots/current.md` 업데이트
7. 3중 검증: V1 + V2(sonnet) + V3(haiku) 병렬
8. `git commit -m "refactor(scope): description"`
9. 정리 리포트 (제거 줄 수, 분할 파일 수, 추출 함수 수)

---

## F. DEPLOY 모드

> 상세 → `resources/deploy-pipeline.md`

1. 프로젝트 프로필에서 프레임워크 감지
2. `.env.example` 생성 (실제 시크릿 없이)
3. 배포 설정 파일 생성 (vercel.json / Dockerfile / netlify.toml)
4. 보안 L1 재검사: .env → .gitignore 포함 확인 [필수]
5. 배포 명령어 안내
6. `git commit -m "chore(deploy): add deployment configuration"`
7. 배포 체크리스트 출력

---

## G. REVIEW 모드

> 상세 → `resources/review-pipeline.md`

1. `git diff --name-only` 로 변경 파일 감지
2. Worker-A (model: sonnet, context:fork) → 코드 리뷰 (품질 + 접근성 + 성능)
3. Worker-B (model: sonnet, context:fork) → 보안 L3 스캔 (OWASP Top 10)
4. Worker-C (model: haiku,  context:fork) → 테스트 실행
5. Worker-D (model: haiku,  context:fork) → Gap Check (`resources/gap-check.md` 참조)
6. A+B+C+D 4에이전트 병렬 실행 (`resources/agent-team.md` 참조)
7. bloat-check.sh 실행
8. 통합 리포트 (VULN-NNN 형식, A~F 등급, Match Rate %, 권장 액션)

---

## G2. ITERATE 모드

> 상세 → `resources/iterate-pipeline.md`

Gap Rate < 90% 또는 `/aura iterate:` 명시 시 실행. 최대 5회 자동 반복.

```
Step 1: Gap Check (GapDetector, model: haiku, context:fork)
        → Match Rate 계산

Step 2: Match Rate ≥ 90% → 완료 리포트 출력 후 종료
        Match Rate < 90% → 미구현 항목 추출

Step 3: Iterator (model: haiku ECO / sonnet PRO / opus MAX, context:fork)
        → 미구현 항목 자동 수정

Step 4: V1 검증 → Step 1로 재귀 (최대 5회)

Step 5: 5회 초과 또는 90% 달성 → 최종 리포트
        💰 반복 [N/5] | Match Rate [N]% → [N]%
```

---

## G3. TDD 모드

> 상세 → `resources/tdd-pipeline.md`

SuperPower 수준의 RED-GREEN-REFACTOR 규율 강제. 테스트 없는 구현 차단.

```
🔴 RED   — 실패하는 테스트 먼저 작성 [필수, 구현 전 차단]
           TDD-Writer (model: sonnet, context:fork)
           출력: *.test.ts / *.spec.py / *_test.go

🟢 GREEN  — 테스트를 통과하는 최소 코드만 작성
           Builder (model: [tier], context:fork)
           규칙: 최소 구현, over-engineering 금지

🔵 REFACTOR — 테스트 유지하며 코드 개선
           Reviewer (model: sonnet, context:fork)
           → 중복 제거, 네이밍 개선, 성능 최적화

검증: TestRunner (haiku) → 커버리지 목표 ≥ 80%
커밋: git commit -m "test(scope): add RED tests" → "feat(scope): GREEN" → "refactor(scope): cleanup"
```

**규칙**: RED 단계 없이 구현 시도하면 즉시 중단 + TDD 흐름 재시작 안내.

---

## G4. PM 모드 (opt-in)

> 상세 → `resources/pm-pipeline.md`

빌드 전 제품 기획 단계. `/aura pm:기능명` 으로 명시 호출. BUILD와 분리.

```
[빠른 모드] /aura pm:기능명
  Step 1: PM-Discovery + PM-Strategy 병렬 (haiku)
  Step 2: PM-PRD 순차 (sonnet)
  Step 3: BUILD 전환 선택

[전체 모드] /aura pm research:기능명
  Step 0: PM-Research (haiku) → TAM/SAM/SOM, 경쟁사 분석, 페르소나
  Step 1: PM-Discovery + PM-Strategy 병렬 (haiku)
  Step 2: PM-PRD 순차 (sonnet)
  Step 3: BUILD 전환 선택
```

**4에이전트 흐름** (전체 모드):
```
[PM-Research] ──→ [PM-Discovery] ─┐
                  [PM-Strategy]  ─┴→ [PM-PRD] → BUILD?
```

---

## G5. PLAN / DESIGN / REPORT 모드 (문서 모드)

> 상세 → `resources/plan-pipeline.md`, `resources/design-pipeline.md`, `resources/report-pipeline.md`

BUILD 전 계획·설계 문서화, 또는 완료 후 보고서 생성. 구현 없음.

```
/aura plan:[기능명]    → 구현 계획 문서 (.aura/docs/plan-*.md)
/aura design:[기능명]  → DB/API/컴포넌트 설계 (.aura/docs/design-*.md)
/aura report:[기능명]  → PDCA 완료 보고서 (.aura/docs/report-*.md)

권장 순서:
  PM → PLAN → DESIGN → BUILD → REVIEW → ITERATE → REPORT
```

**DESIGN**: Worker-DB(sonnet) + Worker-API(sonnet) + Worker-UI(haiku) 3-Worker 병렬.
**REPORT**: Gap Check(haiku) + Reporter(sonnet). Match Rate + 학습 사항 포함.

---

## G6. PIPELINE 모드

> 상세 → `resources/pipeline-guide.md`

신규 프로젝트 또는 "어디서 시작해야 하나?" 상황. Scout가 복잡도 자동 감지.

```
/aura pipeline:           → 전체 9단계 가이드 + 레벨 감지
/aura pipeline:status     → 현재 단계 확인 (.aura/pipeline-state.md)
/aura pipeline:next       → 다음 단계 안내
```

**Scout 복잡도 자동 감지:**
```
Starter:    정적 사이트, 백엔드 없음 → Phase 3→5→7→9 (4단계)
Dynamic:    풀스택, 로그인/DB → Phase 1→2→4→3→5→6→7→8→9 (전체)
Enterprise: 마이크로서비스, K8s → PM 모드 먼저 → 전체 + 아키텍처 설계
```

감지 기준: `package.json`, `Dockerfile`, `k8s/`, `microservices/`, `prisma/`, `supabase/` 디렉토리 존재 여부.

---

## H. 필수 규칙 요약 (Mandatory Rules — 위반 시 중단)

| 규칙 | 위반 결과 |
|------|----------|
| SQL: parameterized query 필수 | security-scan.sh L4 차단 |
| 토큰: localStorage 저장 금지 | security-scan.sh L4 차단 |
| 시크릿 하드코딩 금지 | security-scan.sh L4 차단 |
| V1 빌드 검증 필수 | build-verify.sh 자동 차단 |
| Discovery → 플랜 → 구현 순서 | 순서 건너뛰면 재시작 |
| 컴포넌트 250줄 초과 즉시 분할 | bloat-check.sh 경고 |

---

## I. 토큰 절약 / 품질 규칙

### 티어별 비용·품질 트레이드오프

| 티어 | 모델 구성 | 비용 | 품질 | 추천 대상 |
|------|---------|------|------|---------|
| QUICK | sonnet (메인만) | ●○○○ | ●●○○ | 단순 수정, 빠른 프로토타입 |
| ECO | haiku+sonnet | ●●○○ | ●●●○ | 일반 개발, API 사용자 |
| PRO | haiku+sonnet+opus(Builder) | ●●●○ | ●●●● | 헤비 유저, 복잡한 기능 |
| MAX | sonnet+opus(전체) | ●●●● | ●●●● | Max Plan, 크리티컬 프로덕션 |

### 절감 메커니즘 (ECO 기준)

| 규칙 | 방법 | 절감 |
|------|------|------|
| Tiered Model | Scout/V3: haiku, V2/Review: sonnet | ~40% |
| Context Isolation | 모든 에이전트 `context:fork` | ~20% |
| Fail-Only Output | 성공 시 "Pass" 한 줄만 반환 | ~15% |
| Progressive Load | resources/ 해당 모드에서만 로딩 | ~10% |
| Scan-Once Cache | 프로젝트 프로필 `.aura/` 캐싱 | ~10% |
| Graceful Compact | 65% 임계값, 파일 단위 체크포인트 | 낭비 최소화 |
| Quick Mode | `/aura!` — 프로토콜 생략, 즉시 실행 | ~60% |

> ECO/PRO/MAX 모두 Context Isolation · Fail-Only · Progressive Load · Compact는 동일하게 적용.
> 티어는 오직 **에이전트 모델 배정**만 변경한다.

**토큰 표시 규칙**: 모든 응답 끝에 다음 형식으로 표시한다.
```
💰 [티어] | 컨텍스트: [Y]% | 오늘: ↑[N] ↓[N] = [total]([N]회) | 주간: [N] | 다음: [후속 제안]
```
- [AuraKit 토큰] 컨텍스트(UserPromptSubmit 훅 주입)에서 수치 읽어 표시. 없으면 해당 필드 생략.
- 한도 설정: `.aura/token-limits.json` → `{"daily": 500000, "weekly": 2000000}` (생략 가능)
- 정확도: 직전 응답까지 누적값. 현재 응답분은 다음 턴에 반영됨.

---

## J. 에러 처리

| 상황 | 대응 |
|------|------|
| Scout 실패 | 수동 프로파일 입력 요청 |
| V1 빌드 에러 | 에러 표시 + 자동 FIX 모드 전환 |
| V2/V3 이슈 | 이슈 목록 표시 + 자동 수정 |
| 보안 L4 차단 | 시크릿 제거 후 재시도 안내 |
| 스냅샷 없음 | 새 작업으로 시작 |
| Git Worktree 실패 | 경고 출력 후 메인 브랜치에서 계속 진행 |

---

---

## K. 다국어 슬래시 명령 (Multi-Language Slash Commands)

입력 방법 없이 모국어로 /aura 사용 가능. 자동완성 지원. 총 8개 언어 · 56개 명령.

### 기본 / BUILD / FIX / CLEAN / DEPLOY / REVIEW / COMPACT

| 언어 | 기본 | 빌드 | 수정 | 정리 | 배포 | 리뷰 | 컴팩트 |
|------|------|------|------|------|------|------|--------|
| 🇺🇸 EN | `/aura` | `/aura build:` | `/aura fix:` | `/aura clean:` | `/aura deploy:` | `/aura review:` | `/aura-compact` |
| 🇰🇷 KR | `/아우라` | `/아우라빌드` | `/아우라수정` | `/아우라정리` | `/아우라배포` | `/아우라리뷰` | `/아우라컴팩트` |
| 🇯🇵 JP | `/オーラ` | `/オーラビルド` | `/オーラ修正` | `/オーラ整理` | `/オーラデプロイ` | `/オーラレビュー` | `/オーラコンパクト` |
| 🇨🇳 ZH | `/奥拉` | `/奥拉构建` | `/奥拉修复` | `/奥拉清理` | `/奥拉部署` | `/奥拉审查` | `/奥拉压缩` |
| 🇪🇸 ES | `/aura-es` | `/aura-construir` | `/aura-arreglar` | `/aura-limpiar` | `/aura-desplegar` | `/aura-revisar` | `/aura-compactar` |
| 🇫🇷 FR | `/aura-fr` | `/aura-construire` | `/aura-corriger` | `/aura-nettoyer` | `/aura-deployer` | `/aura-reviser` | `/aura-compresser` |
| 🇩🇪 DE | `/aura-de` | `/aura-bauen` | `/aura-beheben` | `/aura-aufraeumen` | `/aura-deployen` | `/aura-pruefen` | `/aura-komprimieren` |
| 🇮🇹 IT | `/aura-it` | `/aura-costruire` | `/aura-correggere` | `/aura-pulire` | `/aura-distribuire` | `/aura-rivedere` | `/aura-compattare` |

### ITERATE / TDD / PM 모드 (네임스페이스 직접 사용)

| 모드 | 사용 예시 | 설명 |
|------|----------|------|
| ITERATE | `/aura iterate:로그인 기능` | Gap < 90% 자동 수정, 최대 5회 |
| TDD | `/aura tdd:결제 모듈` | RED→GREEN→REFACTOR 순서 강제 |
| PM | `/aura pm:소셜 로그인` | OST Discovery + PRD 생성 후 BUILD 전환 |
| PRO+TDD | `/aura pro tdd:인증 미들웨어` | Builder=opus로 TDD |
| MAX+PM | `/aura max pm:마이크로서비스 API` | PM-PRD=opus, 전체 고품질 |

### Tier + 언어 조합

```bash
/아우라 pro 결제 시스템 만들어줘   # KR PRO BUILD
/オーラビルド max 認証システム       # JP MAX BUILD
/奥拉 iterate:登录功能              # ZH ITERATE
/aura-construir pro sistema de pago # ES PRO BUILD
```

### IME 역변환

| 입력 | 변환 결과 | 처리 방법 |
|------|----------|---------|
| `/채ㅡㅔㅁㅊㅅ` | `/compact` | 두벌식 역변환 자동 처리 |
| `/멱ㅁ` | `/aura` | 두벌식 역변환 |

**Hook 처리**: `korean-command.sh` (UserPromptSubmit) → 두벌식 IME 역변환 → 8개 언어 명령 매핑 → Context 주입

---

## L. 호환 스택 (Framework Compatibility)

Scout 에이전트가 자동 감지. 별도 설정 불필요.

| 카테고리 | 지원 스택 |
|---------|---------|
| Frontend | React, Next.js, Vue, Svelte, SolidJS, Astro |
| Backend | Node.js/Express, Fastify, Python/FastAPI, Django, Go, Rust |
| DB/ORM | Prisma, Drizzle, SQLAlchemy, GORM, raw SQL |
| Deploy | Vercel, Netlify, Railway, Fly.io, AWS, GCP, Docker |
| Test | Jest, Vitest, Pytest, Go test, Playwright |
| Package | npm, pnpm, yarn, bun, pip, poetry, go modules |

---

*AuraKit v3.3 — Discovery-First · 5중 보안 · Tiered Model ~55% 절감 · 8개 언어 56개 명령 · ITERATE/TDD/PM/PLAN/DESIGN/REPORT/PIPELINE 모드 · 15에이전트 · ECO/PRO/MAX 티어 · 토큰 추적 · REVIEW→Gap→ITERATE 자동 체인*
