# AuraKit — Agent Team (멀티에이전트 팀 오케스트레이션)

> BUILD/FIX/CLEAN/REVIEW/ITERATE/TDD/PM 모드에서 필요 시 로딩.
> 모든 에이전트는 격리된 서브프로세스로 실행 — 메인 컨텍스트 토큰 보호.

---

## 에이전트 역할 분담 (13개)

| 에이전트 | 기본 모델 | 역할 | 활성 모드 |
|---------|----------|------|----------|
| Scout | haiku / sonnet(MAX) | 코드베이스 탐색, 파일 구조 파악, 프로젝트 프로필 생성 | ALL |
| Builder | sonnet(ECO) / opus(PRO/MAX) | 핵심 구현, 복잡한 로직 | BUILD, TDD(GREEN) |
| Reviewer | sonnet / opus(MAX) | 코드 품질 리뷰, 접근성 검사 | BUILD, REVIEW, TDD(REFACTOR) |
| SecurityAgent | sonnet / opus(MAX) | OWASP Top 10 스캔 | BUILD, REVIEW |
| TestRunner | haiku / sonnet(MAX) | 테스트 실행, 커버리지 확인 | BUILD, REVIEW, TDD |
| GapDetector | haiku / sonnet(MAX) | 설계 vs 구현 비교, Match Rate 계산 | REVIEW, ITERATE |
| Optimizer | haiku | dead code, bloat 감지 | CLEAN |
| TDD-Writer | sonnet / opus(MAX) | RED 단계: 실패 테스트 작성 | TDD |
| Iterator | sonnet(ECO/PRO) / opus(MAX) | 미구현 항목 자동 수정 (최대 5회) | ITERATE |
| PM-Discovery | haiku | OST 분석, 고객 페인포인트, 기회 목록 | PM |
| PM-Strategy | haiku | JTBD 6-Part, Lean Canvas | PM |
| PM-Research | haiku | TAM/SAM/SOM 시장조사, 경쟁사 분석, 페르소나 생성 | PM (research 모드) |
| PM-PRD | sonnet / opus(PRO/MAX) | PRD 8섹션 자동 생성 | PM |

---

## 병렬 실행 패턴

### BUILD 완료 후 3중 검증 (V2+V3 병렬)

```
V1: build-verify.js hook (동기, 자동) ─────────── 타입 에러
V2: Reviewer + SecurityAgent (병렬, 격리 서브에이전트) ─ 품질+보안
V3: TestRunner (병렬, 격리 서브에이전트) ──────────── 테스트

V1 실패 → 즉시 중단
V2/V3 실패 → 이슈 목록 출력 후 FIX 자동 전환
```

### REVIEW 모드 4에이전트 병렬

```
Worker-A: Reviewer      (sonnet/opus(MAX)) ─ 품질+접근성+성능
Worker-B: SecurityAgent (sonnet/opus(MAX)) ─ 보안 L3
Worker-C: TestRunner    (haiku/sonnet(MAX)) ─ 테스트 실행
Worker-D: GapDetector   (haiku/sonnet(MAX)) ─ 설계 vs 구현
→ 4개 동시 실행, 결과 취합
```

### ITERATE 모드 순차 루프

```
GapDetector (haiku/sonnet(MAX))
  ↓ Match Rate < 90%
Iterator (sonnet/opus(MAX))
  ↓ 수정 완료
build-verify.js (자동)
  ↓ 성공
GapDetector (재실행) → 최대 5회 반복
```

### TDD 모드 순차 단계

```
🔴 TDD-Writer (sonnet/opus(MAX)) → 실패 테스트 작성
       ↓
   TestRunner (haiku/sonnet(MAX)) → 실패 확인 [필수]
       ↓ 실패 확인됨
🟢 Builder (tier) → 최소 구현
       ↓
   TestRunner (haiku/sonnet(MAX)) → 통과 확인
       ↓ 통과
🔵 Reviewer (sonnet/opus(MAX)) → 리팩토링
       ↓
   TestRunner (haiku/sonnet(MAX)) → 여전히 통과 확인
```

### PM 모드 병렬→순차

빠른 모드 (`/aura pm:기능명`):
```
[PM-Discovery (haiku)] ─┐
                         ├→ [PM-PRD (sonnet/opus(PRO/MAX))] → BUILD 전환?
[PM-Strategy  (haiku)] ─┘
```

전체 모드 (`/aura pm research:기능명`):
```
[PM-Research  (haiku)] → TAM/SAM/SOM + 경쟁사 + 페르소나
        ↓
[PM-Discovery (haiku)] ─┐
                         ├→ [PM-PRD (sonnet/opus(PRO/MAX))] → BUILD 전환?
[PM-Strategy  (haiku)] ─┘
```

---

## Tiered Model 비용 최적화

```
haiku  사용: Scout(ECO/PRO), TestRunner(ECO/PRO), GapDetector(ECO/PRO), Optimizer, PM-Discovery, PM-Strategy, PM-Research
           → 단순 탐색·실행·비교·분석·조사 작업
sonnet 사용 (MAX 전용): Scout(MAX), TestRunner(MAX), GapDetector(MAX)

sonnet 사용 (ECO/PRO): Builder(ECO), Reviewer, SecurityAgent, TDD-Writer, Iterator(ECO/PRO), PM-PRD(ECO)
           → 복잡한 이해·판단·생성 작업

opus   사용 (PRO/MAX): Builder(PRO/MAX), Reviewer(MAX), SecurityAgent(MAX), TDD-Writer(MAX), Iterator(MAX), PM-PRD(PRO/MAX)
           → 최고 품질 생성, 복잡한 아키텍처·보안 분석

예상 비용 절감: ~55% (ECO 기준, 모든 sonnet 사용 대비)
```

---

## Fail-Only Output 규칙

```
성공 시: "Pass" 한 줄만 반환
실패 시: 상세 이슈 목록 반환

→ 성공한 에이전트가 긴 보고서를 반환하지 않음
→ 메인 컨텍스트 토큰 절약 (~30% 추가 절감)
```

---

## Scout 에이전트 (haiku / sonnet(MAX))

```
목적: 프로젝트 구조 파악, 관련 파일 탐색
실행: 모드 시작 전 또는 B-1 프로필 없을 때
출력: .aura/project-profile.md (캐시)

탐색 항목:
  - 언어/프레임워크 (package.json, go.mod, pyproject.toml)
  - 주요 디렉토리 구조
  - 테스트 도구 (jest, vitest, pytest, go test)
  - 패키지 매니저 (npm, pnpm, yarn, bun, pip, go)
  - 빌드 도구 (tsc, vite, webpack, turbopack)
  - 의존성 보안 도구 존재 여부
```

---

## 에이전트 실패 처리

| 에이전트 | 실패 시 대응 |
|---------|------------|
| Scout | 수동 프로파일 입력 요청 |
| Builder | 에러 표시 + 재시도 1회 |
| Reviewer | 경고 표시, 작업 계속 |
| SecurityAgent | ⚠️ 경고 표시 (차단하지 않음) |
| TestRunner | 테스트 결과 없음으로 처리 |
| GapDetector | Gap check 수동 실행 안내 |
| TDD-Writer | 수동 테스트 작성 요청 |
| Iterator | 수동 수정 후 재시도 안내 |
| PM-Discovery | 수동 OST 입력 요청 |
| PM-Strategy | 수동 Lean Canvas 입력 요청 |
| PM-Research | 수동 시장 조사 결과 입력 요청 |
| PM-PRD | Discovery/Strategy 결과 확인 후 재시도 |

---

*Agent Team — 13에이전트 · Tiered Model + Fail-Only + 격리 서브에이전트 = 토큰 ~55% 절감*
