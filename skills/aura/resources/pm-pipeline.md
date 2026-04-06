# AuraKit — PM Pipeline (제품 기획 모드)

> PM 모드 또는 `/aura pm:기능명` 명시 호출 시 로딩.
> 빌드 전 제품 기획 단계. BUILD와 완전 분리.

---

## 실행 흐름

Research 선행 → Discovery + Strategy 병렬 → PRD 순차 → BUILD 선택 전환

```
[PM-Research]  ──→  [PM-Discovery] ──┐
                     [PM-Strategy]  ──┴→ [PM-PRD] → .aura/pm/prd.md → BUILD 전환?
```

빠른 모드 (Research 생략):
```
[PM-Discovery] ──┐
                 ├→ [PM-PRD] → .aura/pm/prd.md
[PM-Strategy]  ──┘
```

---

## Step 1 — PM-Research [ECO/PRO: Agent(model="haiku") 필수]

**시장 조사 + 경쟁 분석 + 페르소나 정의**

```
분석 항목:
1. 타겟 시장 규모 (TAM → SAM → SOM)
   → 산업 규모, 접근 가능 시장, 실질 목표 시장

2. 경쟁사 분석 (Top 3~5)
   → 강점/약점, 차별화 포인트, 가격 전략

3. 사용자 페르소나 (2~3개)
   → 이름, 나이, 직업, 목표, 페인포인트, 행동 패턴

4. 시장 트렌드
   → 성장 방향, 기술 변화, 규제 환경

출력: .aura/pm/research.md
```

**PRO 모드**: 웹 검색 활용 (최신 시장 데이터)
**ECO 모드**: 일반 지식 기반 추론

---

## Step 2a — PM-Discovery [ECO/PRO: Agent(model="haiku") 필수]

**Teresa Torres Opportunity Solution Tree (OST) 방법론 적용**

```
분석 항목:
1. 원하는 결과 (Desired Outcome)
   → 사용자가 달성하려는 비즈니스 목표

2. 고객 기회 (Opportunities)
   → 페인포인트, 니즈, 욕구 (페르소나별)

3. 솔루션 가설 (Solutions)
   → 기회를 해결할 수 있는 아이디어 목록

4. 실험 (Experiments)
   → 솔루션 검증을 위한 최소 테스트

출력: .aura/pm/discovery.md
```

---

## Step 2b — PM-Strategy [ECO/PRO: Agent(model="haiku") 필수]

**JTBD (Jobs-to-be-Done) + Lean Canvas 간략 버전**

```
JTBD 6-Part 분석:
1. When [상황]
2. I want to [동기]
3. So I can [기대 결과]
4. But [장애물]
5. Which means [핵심 가치]
6. Help me [요청]

Lean Canvas 핵심 항목:
- 문제 (Top 3)
- 고객 세그먼트 (얼리어답터 포함)
- 고유 가치 제안 (UVP)
- 솔루션 (Top 3 기능)
- 채널
- 수익 구조 + 비용 구조

출력: .aura/pm/strategy.md
```

---

## Step 3 — PM-PRD (sonnet/opus(PRO/MAX), 격리 서브에이전트)

**Discovery + Strategy 결과를 종합한 PRD 자동 생성**

```
PRD 8섹션 구조:
1. Executive Summary
   - 기능명, 목적, 핵심 지표

2. 문제 정의
   - OST 기회 목록, 사용자 인용구

3. 목표 & 성공 지표
   - KPI, 측정 방법, 목표값

4. 사용자 스토리
   - As a [페르소나], I want [행동], So that [결과]
   - 우선순위: Must Have / Should Have / Nice to Have

5. 기능 명세
   - 각 기능 설명, 입출력, 제약 조건

6. 기술 고려사항
   - 스택 제약, 의존성, 보안 요구사항

7. 범위 제외 (Non-goals)
   - 명시적 제외 항목 (scope creep 방지)

8. 타임라인 제안
   - 마일스톤 (Phase 1/2/3)

출력: .aura/pm/prd.md
```

---

## Step 4 — BUILD 전환 (선택)

```
PRD 완성 후:

PRD를 기반으로 BUILD 모드로 전환하시겠습니까?
  [Y] → /aura build:[PRD에서 추출한 Phase 1 기능]
  [N] → PRD 파일만 저장, 수동 진행

자동 연결: PRD의 "기능 명세" → BUILD Step 0 Discovery로 주입
```

---

## 에이전트 배정

| 에이전트 | 모델 | 역할 | 병렬 |
|---------|------|------|------|
| PM-Research | haiku | TAM/SAM/SOM, 경쟁사, 페르소나 | Step 1 |
| PM-Discovery | haiku | OST 분석, 페인포인트 추출 | Step 2 (Research 완료 후) |
| PM-Strategy | haiku | JTBD, Lean Canvas | Step 2 (Research 완료 후, Discovery와 병렬) |
| PM-PRD | sonnet/opus(PRO/MAX) | PRD 8섹션 작성 | Step 3 (Discovery+Strategy 완료 후) |

**PRO/MAX 티어에서 PM 모드:**
- PRO: PM-PRD만 sonnet → opus (더 정교한 PRD)
- MAX: 전체 sonnet → opus

**빠른 PM 모드 (Research 생략):**
- `/aura pm:기능명` — Discovery + Strategy 병렬 → PRD
- `/aura pm research:기능명` — Research 포함 전체 4단계

---

## 출력 구조

```
.aura/pm/
  ├── discovery.md   (OST, 페르소나, 기회 목록)
  ├── strategy.md    (JTBD, Lean Canvas)
  └── prd.md         (8섹션 전체 PRD)
```

---

## 빠른 시작

```bash
/aura pm:소셜 로그인 기능
/아우라 pm:결제 시스템
/aura pro pm:마이크로서비스 API 설계
```

---

*PM Pipeline — Discovery + Strategy 병렬 → PRD 순차 → BUILD 전환 선택*
