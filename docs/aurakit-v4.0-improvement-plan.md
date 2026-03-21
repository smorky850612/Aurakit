# AuraKit v4.0 개선 기획서

> 작성일: 2026-03-21
> 기준: AuraKit v3.6 vs bkit 약점 분석 18개 항목
> 원칙: **빠르고 가볍고 쉽고 안전하고 토큰 효율적** — 정체성 훼손 금지

---

## 목차

1. [우선순위별 개선항목 총괄 테이블](#1-우선순위별-개선항목-총괄-테이블)
2. [P0 Critical — 상세 기획](#2-p0-critical--상세-기획)
3. [P1 High — 상세 기획](#3-p1-high--상세-기획)
4. [P2 Medium — 상세 기획](#4-p2-medium--상세-기획)
5. [P3 Nice-to-have — 상세 기획](#5-p3-nice-to-have--상세-기획)
6. [v4.0 아키텍처 변경 요약](#6-v40-아키텍처-변경-요약)
7. [토큰 전체 영향 평가](#7-토큰-전체-영향-평가)

---

## 1. 우선순위별 개선항목 총괄 테이블

### P0 — Critical (경쟁력 현저히 저하)

| # | 약점 | 개선항목 | 토큰 영향 | 구현 복잡도 |
|---|------|---------|----------|------------|
| P0-1 | SKILL.md 14K 토큰 매회 로딩 | SKILL.md 슬림화 + 라우터 분리 | **-3K~-5K 매회** | 중 |
| P0-2 | STATUS 빈약 (현재 작업만 표시) | Health Dashboard + Match Rate KPI | +200 토큰/회 | 낮 |
| P0-3 | Convention Enforcement 없음 | Convention Validator 자동 검사 | +100 토큰/회 | 낮 |
| P0-4 | Scout 캐시 만료 규칙 없음 | 해시 기반 캐시 무효화 | -50 토큰/회(절감) | 낮 |

### P1 — High (엔터프라이즈 이탈 위험)

| # | 약점 | 개선항목 | 토큰 영향 | 구현 복잡도 |
|---|------|---------|----------|------------|
| P1-1 | Design Validator 없음 | DESIGN 모드에 검증 단계 추가 | +300 토큰/회 | 낮 |
| P1-2 | 인프라 아키텍처 얕음 | DEPLOY 파이프라인 IaC 확장 | +800 토큰(로딩 시만) | 중 |
| P1-3 | Zero Script QA 미완성 | QA 모드 방법론 구체화 | +500 토큰(로딩 시만) | 중 |
| P1-4 | Executive Summary 없음 | REPORT 모드 4관점 가치 테이블 | +200 토큰/회 | 낮 |
| P1-5 | 팀 컨텍스트 공유 약함 | .aura/team/ 공유 문서 구조 | +150 토큰/회 | 낮 |

### P2 — Medium (있으면 좋지만 대체 가능)

| # | 약점 | 개선항목 | 토큰 영향 | 구현 복잡도 |
|---|------|---------|----------|------------|
| P2-1 | 문서 생명주기 부재 | Doc Lifecycle Tracker | +200 토큰/회 | 중 |
| P2-2 | Match Rate 비형식적 | KPI Dashboard 통합 | +100 토큰/회 | 낮 |
| P2-3 | PM-Research 에이전트 부재 | PM-Research 공식화 | 0 (이미 pm-pipeline.md에 존재) | 낮 |
| P2-4 | 프론트엔드 아키텍처 전문화 부족 | BUILD 파이프라인 FE 아키텍처 섹션 | +400 토큰(로딩 시만) | 중 |
| P2-5 | Plan-Plus 없음 | BRAINSTORM + PLAN 통합 경로 | +100 토큰/회 | 낮 |

### P3 — Nice-to-have (향후 고려)

| # | 약점 | 개선항목 | 토큰 영향 | 구현 복잡도 |
|---|------|---------|----------|------------|
| P3-1 | Loop/Cron 통합 없음 | WATCH 모드 (경량 폴링) | +300 토큰/세션 | 높 |
| P3-2 | 초보자 온보딩 얕음 | ONBOARD 모드 추가 | +600 토큰(로딩 시만) | 중 |
| P3-3 | BaaS 통합 얕음 | BaaS 쿡북 확장 | +500 토큰(로딩 시만) | 중 |
| P3-4 | PM 팀 구성 덜 세분화 | PM-Lead 코디네이터 추가 | +200 토큰/회 | 중 |

---

## 2. P0 Critical — 상세 기획

### P0-1. SKILL.md 슬림화 + 라우터 분리

**문제**
현재 SKILL.md가 14K 토큰으로, 모든 `/aura` 호출마다 전체 로딩된다. 25+ 모드의 요약, 공통 프로토콜, 모드 테이블, 다국어 명령표까지 포함되어 있어 QUICK 모드(`/aura!`)에서도 14K 토큰을 소비한다. bkit는 각 스킬 파일이 독립적으로 작아서 이 문제가 없다.

**해결책 — 2-Tier Routing Architecture**

SKILL.md를 "라우터 코어"(5K 이내)와 "확장 레퍼런스"로 분리한다.

```
SKILL.md (라우터 코어, ~5K 토큰):
  - frontmatter
  - Quick Start (10줄)
  - 모드 테이블 (키워드 매칭용 최소 테이블)
  - 품질 티어 테이블 (4줄)
  - 공통 프로토콜 B-1~B-5 (압축)
  - 필수 규칙 요약 (10줄)
  - 에러 처리 (10줄)
  - 토큰 절약 규칙 (5줄)

resources/mode-reference.md (~4K 토큰, 필요 시만 로딩):
  - 각 모드 상세 설명 (C~K 섹션)
  - 다국어 명령표 전체

resources/common-protocol.md (~2K 토큰, BUILD/FIX/CLEAN에서만 로딩):
  - B-1~B-5 상세 규칙
  - Discovery 5-Question 상세
```

**구현 위치**
- 변경: `skills/aura/SKILL.md` — 14K -> 5K 이하로 축소
- 신규: `skills/aura/resources/mode-reference.md`
- 신규: `skills/aura/resources/common-protocol.md`

**토큰 영향**
- 변경 전: 매회 14K 토큰 로딩
- 변경 후: 매회 5K + 해당 모드 파이프라인 (평균 3K) = 8K
- 절감: 매회 약 **-3K~-6K 토큰** (QUICK 모드에서는 5K만 로딩하여 -9K)
- 연간 추정: 하루 50회 호출 기준, 일 150K~300K 토큰 절감

**aura 정체성 적합성**
- "가볍고": 핵심 원칙 직접 구현. 불필요한 컨텍스트 로딩 제거.
- "토큰 효율적": 가장 큰 토큰 절감 효과. Progressive Disclosure 원칙의 완성.
- "빠르고": 라우터 코어가 작아서 모드 감지 속도 향상.
- 기존 Progressive Disclosure(모드별 resource 로딩)를 SKILL.md 자체에도 적용하는 자연스러운 확장.

---

### P0-2. Health Dashboard (STATUS 강화)

**문제**
현재 `/aura status`는 `.aura/snapshots/current.md` + `.aura/pipeline-state.md`만 읽어 현재 작업 상태만 보여준다. bkit `/pdca status`는 전체 사이클 건강도(Match Rate 추이, 보안 이슈 수, 기술 부채 트렌드)를 종합적으로 보여주어 프로젝트 전체 상태를 파악할 수 있다.

**해결책 — Lightweight Health Dashboard**

STATUS 모드 출력에 프로젝트 건강도 섹션을 추가한다. 별도의 대시보드 UI가 아니라 기존 텍스트 출력을 확장하는 방식.

```
/aura status 출력 변경:

## 현재 작업 (기존)
  모드: BUILD | 진행: 3/5 파일

## 프로젝트 건강도 (신규)
  Match Rate:  92% (최근) | 85% → 92% (추이)
  보안:        이슈 0개 (L3 마지막 스캔: 2시간 전)
  테스트:      24/24 Pass (커버리지 78%)
  기술 부채:   250줄 초과 파일 2개 | dead code 3곳
  파이프라인:  Phase 6/9 (Dynamic)

## 다음 단계
  /aura build:UI 연동 (Phase 6 계속)
```

건강도 데이터는 이미 존재하는 파일들에서 수집:
- Match Rate: `.aura/docs/report-*.md` 또는 최근 REVIEW 결과
- 보안: 최근 security-scan.sh 실행 결과
- 테스트: 최근 TestRunner 결과
- 기술 부채: `bloat-check.sh` 결과
- 파이프라인: `.aura/pipeline-state.md`

**구현 위치**
- 변경: `skills/aura/SKILL.md` G10 섹션 확장
- 신규: `skills/aura/resources/status-dashboard.md` (상세 수집 로직)

**토큰 영향**
- 추가: +200 토큰/회 (기존 파일 읽기로 수집, LLM 추가 호출 없음)
- Scout 에이전트 추가 호출 불필요 — git/bash 명령으로 직접 수집

**aura 정체성 적합성**
- "쉽고": 한 명령으로 프로젝트 전체 상태 파악. 사용자가 별도 도구 불필요.
- "코드 중심 + 가벼운 문서화": PDCA 문서 사이클이 아닌, 실행 결과 기반 실시간 집계.
- bkit처럼 문서를 관리하는 게 아니라, 이미 생성된 산출물에서 데이터를 긁어오는 방식. 추가 문서 생성 부담 없음.

---

### P0-3. Convention Validator (코딩 규칙 자동 검사)

**문제**
aura `build-pipeline.md`에 코딩 규칙(zod 검증, parameterized query, httpOnly cookie 등)이 있지만, 이 규칙들이 실제로 지켜졌는지 자동 검증하는 메커니즘이 없다. Reviewer가 사후 체크하지만, 규칙 위반이 BUILD 단계에서 즉시 잡히지 않는다. bkit `phase-2-convention`은 규칙을 명시적으로 정의하고 자동 검사한다.

**해결책 — Convention Check를 V1 검증에 통합**

별도의 에이전트를 추가하지 않고, 기존 `build-verify.sh` 훅에 Convention 검사 단계를 추가한다.

```
기존 V1: tsc --noEmit (타입 체크)
변경 V1: tsc --noEmit + convention-check.sh

convention-check.sh:
  - grep 기반 패턴 매칭 (LLM 호출 없음, 0 토큰)
  - SQL 문자열 보간 패턴 감지: `${.*}` inside SQL 문자열
  - localStorage.setItem('token') 패턴 감지
  - 하드코딩 색상값 감지: #[0-9a-f]{3,8} in .tsx/.css
  - console.log(password/secret/token) 감지
  - any 타입 사용 빈도 경고

  출력: Pass 또는 CONV-NNN 목록
  차단: HIGH 위반만 차단 (SQL injection, localStorage token)
  경고: MEDIUM 이하는 경고만 (하드코딩 색상, any 타입)
```

**구현 위치**
- 신규: `scripts/convention-check.sh` (bash 스크립트, grep 기반)
- 변경: `hooks/build-verify.sh` — convention-check.sh 호출 추가
- 변경: `skills/aura/resources/build-pipeline.md` Step 4 V1 설명 업데이트

**토큰 영향**
- 추가: +100 토큰/회 (bash 출력 결과 표시)
- LLM 호출 없음 — 순수 bash/grep 기반으로 0 토큰 비용
- 위반 조기 감지로 REVIEW 단계에서 잡히던 이슈 감소 -> 총 토큰 절감 효과

**aura 정체성 적합성**
- "빠르고": LLM 호출 없이 grep으로 즉시 감지. 빌드 시간 +1초 이내.
- "안전하고": 6중 보안의 V1에 Convention 검사를 자연스럽게 통합. 별도 레이어 추가 아님.
- "가볍고": 새 에이전트가 아닌 bash 스크립트. 최소 구현.
- bkit는 규칙을 문서로 관리하지만, aura는 스크립트로 자동 실행. 코드 중심 철학에 부합.

---

### P0-4. Scout 해시 기반 캐시 무효화

**문제**
Scout 에이전트가 `.aura/project-profile.md`를 캐시하지만, 파일 구조가 변경되어도 캐시가 갱신되지 않는다. 새 패키지 추가, 디렉토리 구조 변경 후에도 오래된 프로파일을 참조하여 잘못된 판단을 하게 된다.

**해결책 — package.json 해시 기반 무효화**

프로젝트의 주요 설정 파일(package.json, go.mod, pyproject.toml, Dockerfile) 해시를 프로파일에 저장하고, B-1 체크 시 해시 비교로 무효화 여부를 판단한다.

```
B-1 프로젝트 프로필 체크 변경:

1. .aura/project-profile.md 존재 확인
2. 존재하면: 프로파일 내 ConfigHash 필드 읽기
3. 현재 설정 파일 해시 계산:
   md5sum package.json go.mod pyproject.toml Dockerfile 2>/dev/null | md5sum
4. 해시 일치 → 캐시 사용 (0 토큰)
   해시 불일치 → Scout 재실행 (haiku 비용)

project-profile.md에 추가:
  ConfigHash: abc123def456
  LastScanned: 2026-03-21T10:00:00Z
```

**구현 위치**
- 변경: `skills/aura/SKILL.md` B-1 섹션
- 변경: Scout 에이전트 프로필 출력에 ConfigHash 필드 추가 규칙

**토큰 영향**
- 절감: 불필요한 Scout 재실행 방지 — 회당 ~500 토큰(haiku) 절감
- 필요한 경우에만 갱신하여 정확성 + 효율성 동시 확보
- 추가 비용: md5sum bash 명령 (~50 토큰)

**aura 정체성 적합성**
- "토큰 효율적": Scan-Once Cache의 정확성 개선. 불필요한 재스캔 방지.
- "빠르고": 해시 비교는 즉시 완료. 변경 없으면 0 LLM 토큰.
- "가볍고": 기존 B-1 로직에 3줄 bash 추가만으로 구현.

---

## 3. P1 High — 상세 기획

### P1-1. Design Validator (설계 검증 단계)

**문제**
DESIGN 모드는 3-Worker 병렬로 DB/API/UI 설계 문서를 생성하지만, 이 설계의 **완결성과 일관성**을 검증하지 않는다. DB 스키마에 정의된 필드가 API 명세에 누락되거나, API 응답 구조와 UI 컴포넌트 Props가 불일치하는 상태로 BUILD에 진입할 수 있다.

**해결책 — DESIGN Step 4: Cross-Check (haiku)**

별도 에이전트가 아니라, 기존 DESIGN 파이프라인의 마지막 단계에 Cross-Check 스텝을 추가한다.

```
DESIGN 실행 순서 변경:
  Step 1 — 프로필 + Plan 로딩 (기존)
  Step 2 — 3 Worker 병렬 설계 (기존)
  Step 3 — 설계 문서 작성 (기존)
  Step 4 — Cross-Check (신규, haiku, context:fork)
    체크 항목:
      - DB 컬럼 ↔ API 요청/응답 필드 매핑 완전성
      - API 엔드포인트 ↔ UI 컴포넌트 호출 매핑
      - 인증/인가 설계 ↔ API 미들웨어 명시 여부
      - 에러 케이스 ↔ UI 에러 상태 매핑
    출력:
      일치: "Design Cross-Check: Pass"
      불일치: "DESIGN-GAP-001: [DB.users.avatar] → API /users 응답에 avatar 미포함"
  Step 5 — 파일 저장 (기존 Step 4)
  Step 6 — 완료 출력 (기존 Step 5, Cross-Check 결과 포함)
```

**구현 위치**
- 변경: `skills/aura/resources/design-pipeline.md` — Step 4 추가

**토큰 영향**
- 추가: +300 토큰/회 (haiku Cross-Check 에이전트)
- 절감 효과: BUILD 단계에서 설계 불일치로 인한 재작업 방지 -> 전체 사이클 토큰 절감

**aura 정체성 적합성**
- "안전하고": BUILD 진입 전 설계 품질 게이트. 6중 보안의 논리적 확장.
- "가볍고": 별도 에이전트 정의가 아닌 haiku Worker 하나 추가. 기존 DESIGN 파이프라인에 스텝 1개만 추가.
- "토큰 효율적": haiku 사용으로 비용 최소화. Fail-Only Output 적용.

---

### P1-2. DEPLOY 파이프라인 IaC 확장

**문제**
현재 DEPLOY 모드는 Vercel/Docker/Netlify 수준의 배포 설정만 다룬다. Enterprise 프로젝트에서 필요한 K8s, Terraform, CI/CD 파이프라인 설정은 빈약하다. bkit `infra-architect`는 AWS/K8s/Terraform 전문성을 갖추고 있다.

**해결책 — DEPLOY 3-Tier 확장**

기존 DEPLOY 파이프라인을 복잡도별로 3단계로 나누어, Enterprise 사용자가 필요한 인프라 설정을 커버한다.

```
DEPLOY Tier 1 (Starter/Dynamic — 기존):
  vercel.json, Dockerfile, netlify.toml, docker-compose.yml

DEPLOY Tier 2 (Dynamic+ — 신규):
  GitHub Actions CI/CD 파이프라인 자동 생성
  Railway/Fly.io/Render 배포 설정
  Preview 환경 자동 구성 (PR별 프리뷰)
  DB 마이그레이션 자동화 스크립트

DEPLOY Tier 3 (Enterprise — 신규):
  K8s manifest 템플릿 (Deployment, Service, Ingress, HPA)
  Terraform 기본 모듈 (AWS ECS/EKS, RDS, S3)
  Helm chart 기본 구조
  ArgoCD Application 정의
  멀티 스테이지 CI/CD (build → test → staging → production)
```

Scout가 감지한 복잡도(Starter/Dynamic/Enterprise)에 따라 해당 Tier만 로딩.

**구현 위치**
- 변경: `skills/aura/resources/deploy-pipeline.md` — Tier 2 섹션 추가
- 신규: `skills/aura/resources/deploy-enterprise.md` — Tier 3 상세 (Enterprise에서만 로딩)

**토큰 영향**
- Tier 1: 변경 없음
- Tier 2: +400 토큰 (기존 deploy-pipeline.md에 추가)
- Tier 3: +800 토큰 (별도 파일, Enterprise 프로젝트에서만 로딩)
- Progressive Disclosure 적용으로 불필요한 로딩 없음

**aura 정체성 적합성**
- "가볍고": Progressive Disclosure. Starter 프로젝트는 Tier 3 로딩 안 함.
- "쉽고": 복잡도 자동 감지로 사용자가 IaC 수준을 결정할 필요 없음.
- bkit는 infra-architect 전용 에이전트를 두지만, aura는 DEPLOY 모드 내에서 자연스럽게 확장. 새 에이전트 불필요.

---

### P1-3. Zero Script QA 방법론 구체화

**문제**
QA 모드가 존재하지만 방법론이 추상적이다. "Docker 로그 실시간 모니터링"이라고 했지만, 구체적인 테스트 시나리오 생성, API 엔드포인트 자동 탐지, 응답 검증 로직이 부족하다. bkit `qa-monitor`는 구조화된 QA 프로세스를 갖추고 있다.

**해결책 — QA 3-Phase Methodology**

```
Phase 1 — Discovery (QA-Coordinator, haiku)
  API 엔드포인트 자동 수집:
    - Next.js: app/api/**/route.ts 경로 파싱
    - Express: app.get/post/put/delete 패턴 grep
    - FastAPI: @app.get/post 데코레이터 grep
  출력: 엔드포인트 목록 + 예상 입출력 스키마

Phase 2 — Execution (병렬, context:fork)
  QA-API (haiku):
    - 각 엔드포인트에 curl 요청
    - Happy path + Edge case (빈 입력, 초과 길이, SQL 문자 포함)
    - 응답 코드 + 응답 구조 검증
  QA-Security (sonnet):
    - OWASP Top 5 집중 검사 (Injection, Broken Auth, XSS, SSRF, 시크릿 노출)
    - 인증 없이 보호 라우트 접근 시도
  QA-Performance (haiku):
    - 각 엔드포인트 응답 시간 측정 (time curl)
    - 임계값: API < 500ms, 페이지 < 2s

Phase 3 — Report
  QA 리포트:
    Endpoint: 15/15 Tested
    Happy Path: 14/15 Pass
    Edge Case: 12/15 Pass
    Security: OWASP 5/5 Clean
    Performance: 13/15 < 500ms
    Overall: B (1 failure + 2 slow endpoints)
```

**구현 위치**
- 변경: `skills/aura/resources/qa-pipeline.md` — 전면 개편 (구체적 Phase 추가)

**토큰 영향**
- 추가: +500 토큰 (qa-pipeline.md 확장)
- QA 모드 호출 시에만 로딩 (Progressive Disclosure)

**aura 정체성 적합성**
- "빠르고": 에이전트 3개 병렬 실행. 순차 QA 대비 3배 빠름.
- "코드 중심": 문서 검토가 아닌 실제 curl 실행으로 검증. aura의 "실행 먼저" 철학.
- "안전하고": OWASP 집중 검사로 보안 QA 강화.

---

### P1-4. REPORT Executive Summary + 4관점 가치 테이블

**문제**
REPORT 모드에 Executive Summary 테이블이 있지만, bkit처럼 비기술 이해관계자를 위한 4관점 가치 전달 테이블이 없다. 엔터프라이즈에서 PM, 디자이너, 경영진에게 보고할 때 기술 지표만으로는 부족하다.

**해결책 — Executive Summary 확장**

기존 REPORT의 Executive Summary 테이블을 유지하면서, 그 아래에 4관점 요약을 추가한다.

```
기존 Executive Summary (유지):
  기능 | 기간 | Match Rate | 커밋 수 | 변경 파일 | +/-줄

4관점 가치 테이블 (신규):
  | 관점 | 상태 | 요약 |
  |------|------|------|
  | 사용자 | 로그인 3초→1초, 에러 메시지 개선 | 사용 편의성 향상 |
  | 비즈니스 | 결제 전환율 예상 +5%, 이탈 감소 | 매출 기여 |
  | 기술 | 테스트 78% 커버리지, 보안 A등급 | 안정성 확보 |
  | 운영 | CI/CD 완비, 헬스체크 구현 | 배포 자동화 |
```

이 테이블은 LLM이 기존 보고서 데이터에서 추론하여 작성. 별도 데이터 수집 불필요.

**구현 위치**
- 변경: `skills/aura/resources/report-pipeline.md` Step 3 — 보고서 템플릿에 4관점 추가

**토큰 영향**
- 추가: +200 토큰/회 (테이블 생성 비용)
- 별도 에이전트 호출 없음 — Reporter(sonnet)가 기존 데이터에서 추론

**aura 정체성 적합성**
- "쉽고": 사용자가 별도 요약을 작성할 필요 없이 자동 생성.
- "가볍고": 별도 에이전트나 데이터 수집 없이 기존 데이터 재활용.
- bkit는 별도의 report-generator 에이전트가 생성하지만, aura는 기존 Reporter 워크플로우에 추가.

---

### P1-5. 팀 컨텍스트 공유 구조

**문제**
`.aura/agent-memory/`는 에이전트 간 데이터 전달용이지, 팀원 간 컨텍스트 공유 구조가 아니다. 여러 개발자가 같은 프로젝트에서 aura를 사용할 때, 아키텍처 결정사항, 코딩 규칙, 진행 상태를 공유하기 어렵다.

**해결책 — .aura/team/ 공유 문서 디렉토리**

```
.aura/team/
  decisions.md      ← 아키텍처 결정 로그 (ADR 경량 버전)
  conventions.md    ← 프로젝트 코딩 규칙 (convention-check.sh가 참조)
  glossary.md       ← 도메인 용어 사전

규칙:
  - .aura/team/ 은 git에 포함 (팀 공유)
  - .aura/agent-memory/ 는 .gitignore (개인 로컬)
  - .aura/memory.md 의 "팀 규칙" 항목은 자동으로 team/conventions.md에도 기록

자동 기록 트리거:
  - BUILD에서 아키텍처 결정 시: decisions.md에 추가
  - PLAN에서 용어 정의 시: glossary.md에 추가
  - CONFIG에서 규칙 설정 시: conventions.md에 추가
```

**구현 위치**
- 변경: `skills/aura/SKILL.md` B-5 섹션 확장
- 변경: `skills/aura/resources/build-pipeline.md` — 아키텍처 결정 시 team/decisions.md 기록 규칙 추가

**토큰 영향**
- 추가: +150 토큰/회 (파일 읽기 + 소량 기록)
- team/ 파일이 클 경우: 처음 100줄만 로딩하여 토큰 제한

**aura 정체성 적합성**
- "쉽고": 자동 기록. 개발자가 별도로 문서를 작성할 필요 없음.
- "가볍고": 3개 파일만. bkit의 PDCA 문서 체계보다 훨씬 가벼움.
- "팀/엔터프라이즈 규모": 팀 협업의 최소 필수 요소만 포함. 과도한 프로세스 강요 없음.

---

## 4. P2 Medium — 상세 기획

### P2-1. Doc Lifecycle Tracker (문서 생명주기)

**문제**
PLAN/DESIGN/REPORT 문서가 `.aura/docs/`에 생성되지만, 문서 간 연결이나 상태 추적이 없다. plan이 design으로 이어졌는지, design이 build에 반영되었는지 추적 불가.

**해결책 — .aura/docs/index.md 자동 인덱스**

```
.aura/docs/index.md (자동 생성/갱신):

| 기능 | Plan | Design | Build | Review | Report | Match Rate |
|------|------|--------|-------|--------|--------|------------|
| login | plan-login.md | design-login.md | v3 커밋 | A등급 | report-login.md | 94% |
| payment | plan-payment.md | (미작성) | — | — | — | — |

상태 업데이트 규칙:
  - /aura plan: 완료 시 → index.md에 Plan 열 업데이트
  - /aura design: 완료 시 → Design 열 업데이트
  - /aura build: 완료 시 → Build 열 업데이트 (커밋 해시 또는 버전)
  - /aura review: 완료 시 → Review 열 + Match Rate 업데이트
  - /aura report: 완료 시 → Report 열 업데이트
```

**구현 위치**
- 변경: `skills/aura/resources/plan-pipeline.md` Step 4 — index.md 갱신 추가
- 변경: `skills/aura/resources/design-pipeline.md` Step 5 — index.md 갱신 추가
- 변경: `skills/aura/resources/report-pipeline.md` Step 4 — index.md 갱신 추가

**토큰 영향**
- 추가: +200 토큰/회 (index.md 읽기 + 1줄 추가)
- LLM 비용 최소 — Read + Edit 도구로 처리 가능

**aura 정체성 적합성**
- "가벼운 문서화": 1개 인덱스 파일로 전체 문서 생명주기 추적. bkit의 PDCA 문서 체계 대비 극도로 가벼움.
- "자연스럽게 흐르는 개발 플로우": 사용자가 별도로 문서 상태를 관리하지 않아도 자동 업데이트.

---

### P2-2. Match Rate KPI Dashboard 통합

**문제**
GAP/ITERATE 모드에서 Match Rate 90% 임계값을 사용하지만, STATUS에서 Match Rate 추이를 보여주지 않고 보고서 형식이 비표준이다.

**해결책 — Match Rate를 STATUS Health Dashboard에 통합 (P0-2와 연동)**

P0-2의 Health Dashboard에 Match Rate 추이를 포함시킨다. 별도 구현이 아니라 P0-2의 일부로 통합.

```
STATUS Health Dashboard 내:
  Match Rate: 92% (현재)
  추이: 72% (v1) → 85% (v2) → 92% (v3)
  임계값: 90% ✅ 달성

데이터 소스: .aura/docs/report-*.md 에서 Match Rate 필드 수집
```

**구현 위치**
- P0-2 Health Dashboard 구현에 포함 (`skills/aura/resources/status-dashboard.md`)

**토큰 영향**
- 추가: +100 토큰/회 (기존 report 파일에서 grep)
- P0-2와 통합되어 별도 비용 미미

**aura 정체성 적합성**
- P0-2와 동일한 원칙 적용.

---

### P2-3. PM-Research 공식화

**문제**
pm-pipeline.md에 PM-Research 에이전트가 이미 정의되어 있지만(`Step 1 — PM-Research (haiku, context:fork) [신규]`), agent-team.md의 12개 에이전트 목록에는 포함되지 않았고, SKILL.md에서는 "빠른 PM 모드"에서 PM-Research가 생략되는 구조이다. 공식 에이전트로 등록되어 있지 않다.

**해결책 — PM-Research를 공식 에이전트로 승격**

```
agent-team.md 에이전트 목록에 PM-Research 추가 (12 → 13개):
  | PM-Research | haiku | TAM/SAM/SOM, 경쟁사, 페르소나 | PM (research 모드) |

SKILL.md G4 PM 모드 업데이트:
  - 에이전트 수: 3에이전트 → 4에이전트 (Research 포함)
  - 기본 모드(/aura pm:)에서도 Research 간소화 버전 실행 (페르소나만)
  - /aura pm research: 에서 전체 Research 실행
```

**구현 위치**
- 변경: `skills/aura/resources/agent-team.md` — PM-Research 행 추가
- 변경: `skills/aura/SKILL.md` G4 섹션 — 4에이전트 명시

**토큰 영향**
- 추가: 0 (이미 pm-pipeline.md에 구현되어 있음. 선언만 통일)

**aura 정체성 적합성**
- "쉽고": 에이전트 목록 일관성으로 사용자 혼란 방지.
- 새 에이전트 추가가 아닌 기존 구현의 공식화.

---

### P2-4. 프론트엔드 아키텍처 전문화

**문제**
BUILD 모드가 프론트엔드를 커버하지만, Design System 구축, 컴포넌트 아키텍처 패턴(Atomic Design, Compound Components), Next.js App Router 전문 패턴 등의 깊이가 부족하다.

**해결책 — build-pipeline.md에 FE Architecture Section 추가**

```
기존 Step 2 (파일별 구현 규칙)에 FE 아키텍처 서브섹션 추가:

2-10. 컴포넌트 아키텍처 패턴
  - Atomic Design: atoms/ molecules/ organisms/ templates/ pages/
  - Compound Components: [Component].Root + [Component].Item 패턴
  - Container/Presentational 분리 규칙

2-11. Next.js App Router 전문 패턴
  - Server Components vs Client Components 결정 기준
  - Data Fetching 패턴 (RSC → Server Action → Client Fetch)
  - Metadata API 활용 (generateMetadata)
  - Route Groups & Parallel Routes

2-12. 상태 관리 선택 기준
  - 서버 상태: React Query / SWR
  - 전역 UI 상태: Zustand (< Redux 복잡성)
  - 폼 상태: React Hook Form + Zod
  - URL 상태: nuqs / searchParams
```

**구현 위치**
- 변경: `skills/aura/resources/build-pipeline.md` — Section 2-10~2-12 추가

**토큰 영향**
- 추가: +400 토큰 (build-pipeline.md 확장)
- BUILD 모드에서만 로딩 (Progressive Disclosure)

**aura 정체성 적합성**
- "코드 중심": 패턴 가이드는 코드 예시로 제공. 문서가 아닌 구현 규칙.
- "가볍고": 별도 에이전트(frontend-architect)가 아닌 기존 BUILD 파이프라인 확장.

---

### P2-5. BRAINSTORM + PLAN 통합 경로 (Plan-Plus)

**문제**
BRAINSTORM과 PLAN이 완전히 분리되어 있어, 아이디어 발산 후 바로 계획으로 이어지는 자연스러운 흐름이 없다. bkit `/plan-plus`는 브레인스토밍과 구조적 계획을 통합한다.

**해결책 — BRAINSTORM 완료 시 PLAN 자동 제안**

```
BRAINSTORM 완료 출력 변경:

기존:
  출력: 아이디어 N개 + 범위 결정 + 다음 단계

변경:
  출력: 아이디어 N개 + 범위 결정 + PLAN 자동 제안

  "아이디어 정리 완료.
   선택된 아이디어: [상위 3개]
   → /aura plan:[선택 아이디어] 로 구현 계획 작성?"

통합 명령어 추가:
  /aura brainstorm+plan:[주제]  → BRAINSTORM → 상위 아이디어 자동 선택 → PLAN 자동 실행
```

**구현 위치**
- 변경: `skills/aura/resources/brainstorming.md` — 완료 출력에 PLAN 연결 추가
- 변경: `skills/aura/SKILL.md` G12 섹션 — brainstorm+plan 명령어 추가

**토큰 영향**
- 추가: +100 토큰/회 (PLAN 자동 제안 출력)
- brainstorm+plan 명령 시: 2개 모드 순차 실행이지만 중간 사용자 확인 불필요로 시간 절약

**aura 정체성 적합성**
- "자연스럽게 흐르는 개발 플로우": 아이디어 → 계획의 자연스러운 연결.
- "빠르고": 사용자가 두 단계를 별도로 호출하는 오버헤드 제거.

---

## 5. P3 Nice-to-have — 상세 기획

### P3-1. WATCH 모드 (Loop/Cron 대안)

**문제**
bkit `/loop` + Cron은 반복 모니터링(테스트 통과 여부, 빌드 상태, 로그 감시)을 지원한다. aura에는 이런 메커니즘이 없어 사용자가 수동으로 반복 확인해야 한다.

**해결책 — 경량 WATCH 모드 (Cron 불필요)**

bkit의 Cron 연동 대신, aura 세션 내에서 경량 폴링을 수행하는 WATCH 모드를 추가한다. 외부 Cron 의존성 없이 순수 aura 내에서 동작.

```
/aura watch:test        → 파일 변경 감지 → 자동 테스트 실행
/aura watch:build       → 파일 변경 감지 → 자동 빌드 검증
/aura watch:log [path]  → 로그 파일 tail → 에러 패턴 감지 시 알림
/aura watch:stop        → WATCH 중단

구현 방식:
  - bash inotifywait (Linux) / fswatch (macOS) / file hash polling (Windows)
  - 변경 감지 시 해당 모드 자동 실행
  - 결과 요약만 출력 (Fail-Only)
```

**구현 위치**
- 신규: `skills/aura/resources/watch-pipeline.md`
- 변경: `skills/aura/SKILL.md` — WATCH 모드 행 추가

**토큰 영향**
- 추가: +300 토큰/세션 (watch-pipeline.md 로딩)
- 각 폴링 시: bash 명령만 실행 (LLM 호출은 에러 발견 시만)
- Fail-Only 적용으로 성공 시 0 LLM 토큰

**aura 정체성 적합성**
- "빠르고": 파일 변경 즉시 감지하여 수동 검증 불필요.
- "가볍고": Cron 서비스 불필요. bash 기본 도구만 사용.
- "코드 중심": 문서 관리가 아닌 코드 변경 감시.
- v4.0에서는 기본 구현만, v4.1에서 고급 기능 확장 고려.

---

### P3-2. ONBOARD 모드 (초보자 온보딩)

**문제**
`style:learning`은 출력 포맷만 변경할 뿐, 프로젝트 구조 이해, 개발 환경 설정, 첫 기여까지의 가이드를 제공하지 않는다.

**해결책 — ONBOARD 모드 (프로젝트 진입 가이드)**

```
/aura onboard:            → 프로젝트 온보딩 가이드 생성
/aura onboard:quick       → 5분 빠른 시작 가이드

출력 구조:
  1. 프로젝트 개요 (Scout 프로필 기반, 3줄)
  2. 환경 설정 (필요한 도구, 설치 명령어)
  3. 로컬 실행 (dev server 시작 방법)
  4. 코드 구조 (주요 디렉토리 설명, 5줄)
  5. 첫 기여 가이드 (/aura build:[간단한 작업] 제안)

자동 감지:
  - package.json scripts → npm run dev, npm test 안내
  - .env.example → 환경변수 설정 안내
  - README.md → 기존 문서 참조
```

**구현 위치**
- 신규: `skills/aura/resources/onboard-pipeline.md`
- 변경: `skills/aura/SKILL.md` — ONBOARD 모드 행 추가

**토큰 영향**
- 추가: +600 토큰 (onboard-pipeline.md 로딩)
- 1회성 실행이므로 반복 비용 없음
- Scout 프로필 재사용으로 추가 탐색 불필요

**aura 정체성 적합성**
- "쉽고": 프로젝트 진입 장벽을 aura가 제거. 자연어 질문 없이 한 명령으로 완전한 가이드.
- bkit `starter-guide`는 문서 중심이지만, aura ONBOARD는 실행 중심 (실제 npm install 실행 가능).

---

### P3-3. BaaS 쿡북 확장

**문제**
BAAS 모드가 일반적이다. Supabase, Firebase, bkend.ai 각각의 인증/데이터/스토리지 패턴이 얕다.

**해결책 — BaaS 프로바이더별 쿡북**

```
resources/baas-pipeline.md 확장:

Supabase 쿡북:
  - Auth: supabase.auth.signUp/signIn + RLS 정책
  - Data: supabase.from().select().eq() 패턴
  - Storage: supabase.storage.from().upload() + 접근 정책
  - Realtime: supabase.channel().on().subscribe()

Firebase 쿡북:
  - Auth: signInWithEmailAndPassword + onAuthStateChanged
  - Firestore: collection/doc/query 패턴 + 보안 규칙
  - Storage: ref().put() + getDownloadURL
  - Functions: HTTPS callable + scheduled

bkend.ai 쿡북:
  - Scout가 bkend 프로젝트 감지 시 자동 로딩
  - bkit:bkend-expert 에이전트 연동 (이미 SKILL.md에 언급)
```

**구현 위치**
- 변경: `skills/aura/resources/baas-pipeline.md` — 프로바이더별 쿡북 추가

**토큰 영향**
- 추가: +500 토큰 (BAAS 모드에서만 로딩)
- 감지된 프로바이더 섹션만 출력하여 토큰 절약 가능

**aura 정체성 적합성**
- "쉽고": 프로바이더 자동 감지 → 해당 쿡북만 제공.
- "코드 중심": 개념 설명이 아닌 코드 스니펫 위주.

---

### P3-4. PM-Lead 코디네이터

**문제**
bkit는 PM-Lead가 pm-discovery, pm-strategy, pm-research, pm-prd를 조율한다. aura PM 모드는 조율자 없이 에이전트가 직접 연결된다.

**해결책 — PM 모드에 코디네이터 로직 추가 (에이전트 아닌 프로토콜)**

별도의 PM-Lead 에이전트를 추가하는 대신, PM 모드의 실행 프로토콜에 코디네이션 로직을 포함시킨다.

```
PM 모드 실행 프로토콜 변경:

기존: Research → Discovery + Strategy 병렬 → PRD
변경: Research → [품질 게이트] → Discovery + Strategy 병렬 → [품질 게이트] → PRD

품질 게이트 (LLM 추가 호출 없음):
  Gate 1: Research 출력에 TAM/경쟁사/페르소나 3개 섹션 모두 존재? → 없으면 재실행
  Gate 2: Discovery OST + Strategy JTBD 출력이 PRD 입력으로 충분한가? → 누락 시 보완 요청

→ 코디네이터 에이전트 없이 프로토콜로 품질 보장
```

**구현 위치**
- 변경: `skills/aura/resources/pm-pipeline.md` — Gate 로직 추가

**토큰 영향**
- 추가: +200 토큰/회 (Gate 검사 출력)
- 별도 에이전트 호출 없음 — 메인 컨텍스트에서 조건 분기만

**aura 정체성 적합성**
- "가볍고": bkit처럼 PM-Lead 에이전트를 추가하지 않음. 프로토콜만으로 동일 효과.
- "필요할 때만 에이전트화": aura 원칙에 정확히 부합. 조율은 에이전트가 아닌 흐름 규칙으로.

---

## 6. v4.0 아키텍처 변경 요약

### 파일 구조 변경사항

```
skills/aura/
├── SKILL.md                          [변경] 14K → ~5K 토큰 (라우터 코어)
├── resources/
│   ├── mode-reference.md             [신규] 모드 상세 설명 (SKILL.md에서 분리)
│   ├── common-protocol.md            [신규] B-1~B-5 상세 (SKILL.md에서 분리)
│   ├── status-dashboard.md           [신규] Health Dashboard 수집 로직
│   ├── deploy-enterprise.md          [신규] Enterprise IaC 전용 (K8s, Terraform)
│   ├── watch-pipeline.md             [신규, P3] WATCH 모드 파이프라인
│   ├── onboard-pipeline.md           [신규, P3] ONBOARD 모드 파이프라인
│   ├── agent-team.md                 [변경] 12 → 13 에이전트 (PM-Research 공식화)
│   ├── build-pipeline.md             [변경] Convention 검사 + FE 아키텍처 추가
│   ├── design-pipeline.md            [변경] Cross-Check Step 추가
│   ├── deploy-pipeline.md            [변경] Tier 2 추가
│   ├── report-pipeline.md            [변경] 4관점 가치 테이블 추가
│   ├── plan-pipeline.md              [변경] Doc Index 갱신 규칙 추가
│   ├── pm-pipeline.md                [변경] Gate 로직 + PM-Research 공식화
│   ├── qa-pipeline.md                [변경] 3-Phase 구체화
│   ├── brainstorming.md              [변경] PLAN 자동 연결 추가
│   └── (기존 파일들 유지)

scripts/
├── convention-check.sh               [신규] grep 기반 Convention 검사

hooks/
├── build-verify.sh                   [변경] convention-check.sh 호출 추가
```

### 모드 변경사항

| 변경 유형 | 모드 | 설명 |
|----------|------|------|
| 강화 | STATUS | Health Dashboard + Match Rate KPI |
| 강화 | DESIGN | Cross-Check 검증 단계 추가 |
| 강화 | DEPLOY | 3-Tier 확장 (Starter/Dynamic/Enterprise) |
| 강화 | REPORT | 4관점 가치 테이블 |
| 강화 | QA | 3-Phase 방법론 구체화 |
| 강화 | PM | PM-Research 공식화 + Gate 로직 |
| 강화 | BRAINSTORM | PLAN 자동 연결 (brainstorm+plan) |
| 신규(P3) | WATCH | 경량 파일 변경 감시 |
| 신규(P3) | ONBOARD | 프로젝트 온보딩 가이드 |

### 에이전트 변경사항

| 변경 | 에이전트 | 설명 |
|------|---------|------|
| 공식화 | PM-Research | 기존 pm-pipeline.md에서 agent-team.md로 승격 |
| (총 13개) | — | Scout, Builder, Reviewer, SecurityAgent, TestRunner, GapDetector, Optimizer, TDD-Writer, Iterator, PM-Discovery, PM-Strategy, PM-PRD, **PM-Research** |

새 에이전트 추가 없음 (PM-Research는 이미 존재하던 것의 공식화). aura의 "필요할 때만 에이전트화" 원칙 유지.

---

## 7. 토큰 전체 영향 평가

### 매회 호출 기준 (ECO 티어, BUILD 모드)

| 항목 | v3.6 | v4.0 | 변화 |
|------|------|------|------|
| SKILL.md 로딩 | 14,000 | 5,000 | **-9,000** |
| build-pipeline.md 로딩 | 3,500 | 3,900 | +400 |
| common-protocol.md (분리) | 0 | 2,000 | +2,000 |
| Convention Check 출력 | 0 | 100 | +100 |
| Scout (캐시 히트 시) | 500 | 50 | -450 |
| Health Dashboard (STATUS 시) | 0 | 200 | +200 |
| **매회 합계** | **18,000** | **11,250** | **-6,750 (-37.5%)** |

### QUICK 모드 기준 (`/aura!`)

| 항목 | v3.6 | v4.0 | 변화 |
|------|------|------|------|
| SKILL.md 로딩 | 14,000 | 5,000 | **-9,000** |
| 모드 파이프라인 | 0 | 0 | 0 |
| **매회 합계** | **14,000** | **5,000** | **-9,000 (-64.3%)** |

### 모드별 추가 토큰 (해당 모드 호출 시만)

| 모드 | 추가 토큰 | 빈도 | 설명 |
|------|----------|------|------|
| DESIGN | +300 | 가끔 | Cross-Check (haiku) |
| DEPLOY (Enterprise) | +800 | 드물게 | deploy-enterprise.md 로딩 |
| QA | +500 | 가끔 | qa-pipeline.md 확장 |
| REPORT | +200 | 가끔 | 4관점 테이블 |
| STATUS | +200 | 자주 | Health Dashboard |
| PM | +200 | 가끔 | Gate 로직 |
| WATCH (P3) | +300 | 세션당 1회 | watch-pipeline.md |
| ONBOARD (P3) | +600 | 프로젝트당 1회 | onboard-pipeline.md |

### 전체 평가 요약

```
핵심 지표:
  v3.6 매회 평균: ~18K 토큰
  v4.0 매회 평균: ~11.3K 토큰
  절감률: -37.5% (BUILD 기준)

  v3.6 QUICK 모드: ~14K 토큰
  v4.0 QUICK 모드: ~5K 토큰
  절감률: -64.3%

하루 50회 호출 기준:
  v3.6: ~900K 토큰/일
  v4.0: ~565K 토큰/일
  일일 절감: ~335K 토큰 (-37.2%)

결론:
  P0-1 (SKILL.md 슬림화) 단독으로 전체 토큰 비용 30%+ 절감.
  나머지 P0~P2 개선항목의 추가 토큰은 이 절감분 내에서 충분히 흡수됨.
  v4.0은 v3.6보다 기능이 늘어나면서도 토큰 비용은 줄어드는 구조.
```

### "aura답게" 원칙 준수 체크

| 원칙 | v3.6 | v4.0 | 평가 |
|------|------|------|------|
| 빠르고 | 자동 모드 감지 | + 라우터 코어 축소로 감지 속도 향상 | 개선 |
| 가볍고 | Progressive Disclosure | + SKILL.md 자체도 Progressive | 개선 |
| 쉽고 | 자연어 입력 | + Health Dashboard 한 명령, ONBOARD | 개선 |
| 안전하고 | 6중 보안 | + Convention Validator, Design Cross-Check | 개선 |
| 토큰 효율적 | ~55% 절감 | + SKILL.md 슬림화로 추가 ~37% 절감 | 대폭 개선 |
| 팀/엔터프라이즈 | 12에이전트, Worktree | + 팀 컨텍스트 공유, IaC, QA 강화 | 개선 |

---

> **v4.0 핵심 메시지**: SKILL.md 슬림화(P0-1)로 토큰 37% 절감하면서, 그 절감분으로 Design Validator, Convention Enforcement, Health Dashboard, IaC 확장 등 12개 개선사항을 "무료로" 추가한다. 기능은 늘어나고 비용은 줄어드는 구조.
