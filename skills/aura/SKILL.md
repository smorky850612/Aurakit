---
name: aura
description: "올인원 풀스택 개발 엔진. 빌드, 수정, 정리, 배포, 리뷰를 한 줄 명령으로. 4중 보안 + 3중 검증 + 컴팩트 방어 내장. Use when user asks to build, fix, clean, deploy, or review any code."
argument-hint: "[자연어 설명]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch
---

# AuraKit — /aura

> 한 줄 명령으로 풀스택 앱을 완성하는 Claude Code 스킬.
> 4중 보안 · 3중 검증 · 컴팩트 방어 · 토큰 최적화 내장.

---

## A. 모드 자동 감지

사용자 입력($ARGUMENTS)을 분석해 6개 모드 중 하나를 선택한다.

| 모드 | 키워드 (한/영) |
|------|--------------|
| **BUILD** | 만들어, 추가, 생성, 구현, build, create, add, implement, new, 만들기 |
| **FIX** | 에러, 버그, 수정, 안됨, 안 됨, crash, fix, error, bug, TypeError, undefined, 고쳐 |
| **CLEAN** | 정리, 리팩토링, 중복, 최적화, clean, refactor, optimize, duplicate, 분리 |
| **DEPLOY** | 배포, 호스팅, deploy, vercel, netlify, docker, production, 올려 |
| **REVIEW** | 리뷰, 검토, 분석, review, check, audit, 확인, 점검 |
| **COMPACT** | (내부 자동 — aura-guard 트리거, 직접 호출 시 aura-compact 실행) |

감지 불가 시: 사용자에게 모드 명시 요청.

---

## B. 공통 프로토콜 (모든 모드 실행 전)

### B-1. 프로젝트 프로필 체크
```
파일 존재 확인: .aura/project-profile.md
→ 없으면: Scout 에이전트 실행 (context:fork)
  Scout가 .aura/project-profile.md + .aura/design-system.md 자동 생성
→ 있으면: 프로필 로딩 (Read 도구, 0 LLM 토큰)
```

### B-2. 보안 L1 확인
```
pre-session.sh가 SessionStart에 이미 실행됨.
확인 사항:
  - .aura/ 디렉토리 존재
  - .env가 .gitignore에 포함
이상 감지 시: 작업 중단 + 사용자 안내
```

### B-3. 디자인 시스템 로딩
```
파일 존재 확인: .aura/design-system.md
→ 있으면: CSS 변수 목록 메모리에 로딩
→ 없으면: templates/design-system-default.md 복사 후 사용
코드 생성 시 var(--color-primary) 등 토큰 사용 필수
```

### B-4. 스냅샷 복구 체크
```
파일 존재 확인: .aura/snapshots/current.md
→ 있으면: 내용 로딩 → "이전 작업을 이어서 진행합니다" 안내
→ 없으면: 새 작업 시작
```

---

## C. BUILD 모드

> 상세 구현 규칙 → `resources/build-pipeline.md` 참조 (해당 모드에서만 로딩)

### 실행 순서

**Step 1 — 마이크로 플랜** (200 토큰 이내)
- 필요 파일 목록 + 역할 1줄 + 의존성 순서 출력
- 사용자 확인 후 진행

**Step 2 — 파일별 구현**
적용 규칙 (build-pipeline.md §2 상세):
- API: try-catch + `{success, error, message}` 응답
- 입력: zod 또는 수동 validation
- SQL: parameterized query 필수
- 접근성: alt, label, htmlFor, tabIndex
- 인증: httpOnly cookie (localStorage 토큰 금지)
- 컴포넌트: 200줄 이내
- CSS: 디자인 시스템 토큰
- loading/error 상태 UI 포함

**Step 3 — 진행 상태 기록**
파일 완료마다 `.aura/snapshots/current.md` 업데이트 (snapshot-template.md 포맷)

**Step 4 — 3중 검증**
```
V1: build-verify.sh hook (tsc --noEmit / py_compile) — 자동 실행
V2: Worker 에이전트 → 코드 리뷰 + 보안 L3 (context:fork)
V3: Worker 에이전트 → 테스트 실행 (context:fork)
V2 + V3 병렬 실행 권장
```

**Step 5 — 보안 L4**
security-scan.sh pre-commit hook 자동 실행

**Step 6 — 커밋**
```bash
git add [변경 파일]
git commit -m "feat(scope): description"
```

**Step 7 — 완료 리포트** (100 토큰 이내)
생성 파일 목록 · 검증 결과 · 다음 단계 제안

---

## D. FIX 모드

> 상세 → `resources/fix-pipeline.md`

1. 에러 메시지/스택 트레이스 파싱
2. Scout 에이전트로 관련 파일 탐색 (context:fork)
3. 근본 원인 파악 → 최소 변경 수정
4. `.aura/snapshots/current.md` 업데이트
5. 3중 검증 (BUILD §4 동일)
6. `git commit -m "fix(scope): description"`
7. 수정 리포트

---

## E. CLEAN 모드

> 상세 → `resources/clean-pipeline.md`

1. bloat-check.sh 결과 수집
2. Scout로 중복 코드 탐색 (context:fork)
3. dead code 제거 (미사용 함수/import/변수)
4. 250줄 초과 파일 분할
5. 네이밍 + 포맷 통일
6. `.aura/snapshots/current.md` 업데이트
7. 3중 검증
8. `git commit -m "refactor(scope): description"`
9. 정리 리포트 (제거 줄 수, 분할 파일 수)

---

## F. DEPLOY 모드

> 상세 → `resources/deploy-pipeline.md`

1. 프로젝트 프로필에서 프레임워크 감지
2. `.env.example` 생성
3. 배포 설정 파일 생성 (vercel.json / Dockerfile / netlify.toml)
4. 보안 L1 재검사: .env → .gitignore 포함 확인
5. 배포 명령어 안내
6. `git commit -m "chore(deploy): add deployment configuration"`
7. 배포 체크리스트 출력

---

## G. REVIEW 모드

> 상세 → `resources/review-pipeline.md`

1. `git diff --name-only` 로 변경 파일 감지
2. Worker → 코드 리뷰 (context:fork)
3. Worker → 보안 L3 스캔 (context:fork)
4. Worker → 테스트 실행 (context:fork)
5. bloat-check.sh 실행
6. 통합 리포트 생성 (VULN-001 형식, A~F 점수)

---

## H. 안티 블로트 규칙

- **250줄 초과** 파일 생성 시 → 즉시 분할 계획 제안
- **중복 코드** 3회 이상 → 유틸리티 함수 추출
- **미사용 import** → 자동 제거
- bloat-check.sh PostToolUse hook이 자동 감지

---

## I. 토큰 절약 규칙

| 규칙 | 방법 |
|------|------|
| Context Isolation | 모든 에이전트는 `context: fork` 실행 |
| Fail-Only Output | 성공 시 "Pass" 한 줄, 실패 시 상세 반환 |
| Dynamic Injection | `!cat .aura/project-profile.md` 로 파일 주입 |
| Progressive Load | resources/ 파일은 해당 모드에서만 로딩 |
| Scan-Once Cache | 프로젝트 프로필 `.aura/` 에 캐싱 |

---

## J. 에러 처리

| 상황 | 대응 |
|------|------|
| Scout 실패 | 수동 프로파일 입력 요청 |
| V1 빌드 에러 | 에러 표시 후 FIX 모드 제안 |
| V2/V3 이슈 발견 | 이슈 목록 표시 후 자동 수정 여부 확인 |
| 보안 L4 차단 | 시크릿 제거 후 재시도 안내 |
| 스냅샷 없음 | 새 작업으로 시작 |

---

*AuraKit v1.0 — Hook-First · Progressive Disclosure · Fail-Only Output*
