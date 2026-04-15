# AuraKit — Brainstorming Pipeline (G6)

> 이 파일은 `/aura brainstorm:` 모드에서 로딩된다.

---

## 개요

기능 구현 전 아이디어 발산 → 수렴 → 의사결정 단계.
SuperPower의 Plan-Plus 방식: 브레인스토밍 → 요구사항 정제 → BUILD 전환.

```bash
/aura brainstorm:[주제]        → 아이디어 발산 + 우선순위
/aura brainstorm:quick [주제]  → 5분 빠른 아이디어
```

---

## Step 1: 현재 상황 파악

```
Scout (haiku/sonnet(MAX)):
  → 프로젝트 구조 스캔
  → 유사 기능 존재 여부 확인
  → 관련 코드/파일 목록 수집

출력: 현재 상황 요약 (1/2 페이지)
```

---

## Step 2: 아이디어 발산 (Diverge)

**원칙**: 판단 없이 모든 가능성 나열.

### 2.1 HOW MIGHT WE (HMW)

```
[주제]와 관련하여 어떻게 하면...

HMW-1: 사용자가 가장 빠르게 목표를 달성할 수 있을까?
HMW-2: 가장 적은 코드로 구현할 수 있을까?
HMW-3: 기존 코드를 최대한 재사용할 수 있을까?
HMW-4: 보안을 강화하면서도 사용성을 유지할 수 있을까?
HMW-5: 미래 확장성을 고려할 수 있을까?
```

### 2.2 6가지 관점 아이디어

```
관점 1 — 사용자 경험: 사용자가 원하는 결과는?
관점 2 — 기술: 기술적으로 가능한 방법은?
관점 3 — 데이터: 어떤 데이터가 필요한가?
관점 4 — 보안: 보안 위협은 무엇인가?
관점 5 — 성능: 성능 병목은 어디인가?
관점 6 — 팀: 유지보수하기 쉬운 방법은?
```

---

## Step 2.5: SCAMPER 창의적 발산 [Autopus-ADK 흡수]

아이디어가 막힐 때 SCAMPER 기법으로 관점 전환:

```
S — Substitute  (대체): 이 부분을 다른 것으로 바꾸면?
C — Combine     (결합): 두 기능을 합치면?
A — Adapt       (적용): 다른 분야의 해결책을 가져오면?
M — Modify      (수정): 크기/모양/속도를 바꾸면?
P — Put to use  (다른 용도): 이 코드를 다른 곳에 쓰면?
E — Eliminate   (제거): 없애도 되는 부분은?
R — Reverse     (역전): 순서를 뒤집으면?
```

---

## Step 3: 아이디어 수렴 (Converge)

### 3.1 ICE 점수 우선순위 [Autopus-ADK 흡수]

각 아이디어를 ICE 점수로 수치화:

```
ICE Score = (Impact × Confidence × Ease) / 100

Impact    (1-10): 구현 시 사용자/비즈니스에 미치는 영향
Confidence(1-10): 이 아이디어가 실제로 작동할 확신
Ease      (1-10): 구현 난이도의 역수 (쉬울수록 높음)

예시:
  아이디어 A: Impact=8, Confidence=7, Ease=6 → ICE=33.6 → 높음
  아이디어 B: Impact=9, Confidence=4, Ease=3 → ICE=10.8 → 낮음
  아이디어 C: Impact=6, Confidence=8, Ease=9 → ICE=43.2 → 최우선
```

ICE ≥ 40 → 즉시 구현 후보
ICE 20-39 → 계획 후 구현
ICE < 20 → backlog 또는 제거

### 3.2 우선순위 매트릭스 (2×2)

```
높은 가치 / 낮은 노력 → 즉시 구현 (Quick Win) ← ICE 높음
높은 가치 / 높은 노력 → 계획 후 구현 (Major Project)
낮은 가치 / 낮은 노력 → 나중에 (Fill-In)
낮은 가치 / 높은 노력 → 제거 (Time Waster) ← ICE 낮음
```

### 3.3 MoSCoW 우선순위 [Autopus-ADK 흡수]

```
Must have   → 없으면 실패 (ICE 최우선 + 핵심 요구사항)
Should have → 있으면 좋음 (ICE 중간, 이번 스프린트 가능)
Could have  → 여유 있으면 (ICE 낮음, 후순위)
Won't have  → 이번엔 안 함 (backlog.md 저장)
```

### 3.4 YAGNI 필터

```
질문: 지금 당장 필요한가?
  YES → 구현 목록에 포함
  NO  → .aura/backlog.md에 저장 (나중을 위해)
```

### 3.5 최종 범위 정의

```markdown
## 구현 범위

### 포함 (이번 스프린트)
- [항목 1]: [이유]
- [항목 2]: [이유]

### 제외 (이유 명시)
- [항목 A]: YAGNI — 현재 사용 사례 없음
- [항목 B]: 복잡도 높음 → backlog.md 저장

### 성공 기준
- [ ] [측정 가능한 완료 조건 1]
- [ ] [측정 가능한 완료 조건 2]
```

---

## Step 4: BUILD 전환

```
브레인스토밍 결과 → PLAN 문서 자동 생성

사용자 확인 후:
  /aura plan:[기능명]   → 계획 문서 생성
  /aura build:[기능명]  → 즉시 구현
  /aura tdd:[기능명]    → TDD로 구현
```

---

## 리포트 포맷

```markdown
# 브레인스토밍 결과 — [주제]
생성: [타임스탬프]

## 현재 상황
[Scout 분석 요약]

## 아이디어 (총 N개)
1. [아이디어 1] — 가치: 높음, 노력: 낮음 → ✅ 즉시 구현
2. [아이디어 2] — 가치: 높음, 노력: 높음 → 📅 계획 필요
3. [아이디어 3] — 가치: 낮음 → 🗄️ backlog.md

## 결정된 범위
포함: [N]개 항목
제외: [N]개 항목 (사유 포함)

## 다음 단계
→ /aura plan:[기능명]  또는  /aura build:[기능명]
```
