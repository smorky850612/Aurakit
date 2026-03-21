# AuraKit — BRAINSTORM Pipeline (아이디어 발산 모드)

> `/aura brainstorm:` 또는 `/aura brainstorm:[주제]` 호출 시 로딩.
> HMW 기반 아이디어 발산 → 수렴 → PLAN 자동 연결.

---

## 역할

- 구현 전 아이디어 발산 및 범위 정의
- 산출물: 우선순위화된 아이디어 목록 + 구현 범위 결정
- 자동 연결: BRAINSTORM 완료 → PLAN 모드 전환 제안

---

## 실행 순서

### Step 1 — 맥락 파악

```
프로젝트 프로필 로딩: .aura/project-profile.md
크로스세션 메모리: .aura/memory.md (이전 결정사항 참고)
팀 컨텍스트: .aura/team/decisions.md (기존 ADR 참고)
```

---

### Step 2 — HMW 아이디어 발산 (5~10분)

HMW(How Might We) 형식으로 아이디어 생성:

```
주제: [주제]

HMW 질문 생성:
  HMW-1: 어떻게 하면 [사용자 목표]를 [현재 방식]보다 더 쉽게 달성할 수 있을까?
  HMW-2: 어떻게 하면 [핵심 불편함]을 제거할 수 있을까?
  HMW-3: 어떻게 하면 [기존 기능]을 활용해 [새 가치]를 제공할 수 있을까?
  HMW-4: 어떻게 하면 가장 단순한 방법으로 [목표]를 달성할 수 있을까?
  HMW-5: 어떻게 하면 [엣지 케이스]를 우아하게 처리할 수 있을까?

아이디어 (각 HMW에 2~3개):
  HMW-1 → 아이디어 A, B, C
  HMW-2 → 아이디어 D, E
  ...
```

---

### Step 3 — 우선순위 매트릭스

각 아이디어를 Impact × Effort로 평가:

```
                높은 Impact
                    │
    Quick Win       │    전략적 투자
    (빠르게 실행)   │    (장기 계획 필요)
                    │
낮은 Effort ───────┼─────────── 높은 Effort
                    │
    버리기          │    재검토
    (가성비 낮음)   │    (가치 불확실)
                    │
                낮은 Impact

배치 결과:
  Quick Win: 아이디어 A, D  ← 이번 스프린트
  전략적 투자: 아이디어 B    ← 다음 스프린트
  재검토: 아이디어 E         ← 추후 결정
  버리기: 아이디어 C         ← 제외
```

---

### Step 4 — 범위 정의 (Scope Decision)

```
✅ 이번에 구현할 것:
  - 아이디어 A (Quick Win, 예상 2h)
  - 아이디어 D (Quick Win, 예상 1h)

⏭️ 다음 버전:
  - 아이디어 B (전략적, 예상 1d)

❌ 제외:
  - 아이디어 C (YAGNI — 현재 필요 없음)
  - 아이디어 E (복잡도 대비 가치 불명확)

성공 기준:
  - [측정 가능한 완료 조건 1]
  - [측정 가능한 완료 조건 2]
```

---

### Step 5 — PLAN 연결 (v4.0 자동 연결)

브레인스토밍 완료 후 자동 제안:

```
✅ BRAINSTORM 완료 — [주제]

📋 아이디어: [N]개 발산 → [M]개 선정
⭐ Quick Win: [아이디어 이름들]

다음 단계를 선택하세요:
  1. /aura plan:[주제]  → 선정된 아이디어로 구현 계획 수립
  2. /aura brainstorm+plan:[주제]  → 계획까지 자동 실행
  3. /aura build:[주제]  → 계획 없이 바로 구현 (간단한 경우)
```

**`brainstorm+plan:` 통합 명령** [v4.0]:
- Step 1~4 실행 → 범위 결정 → 자동으로 PLAN 모드 실행
- PLAN 결과: `.aura/docs/plan-[기능명].md` (아이디어 섹션 포함)

---

### Step 6 — 완료 출력

```
✅ BRAINSTORM 완료 — [주제]

💡 발산:
  HMW 질문: [N]개
  아이디어: [M]개

⭐ 선정:
  이번 스프린트: [아이디어 목록]
  다음 스프린트: [아이디어 목록]
  제외: [아이디어 목록]

다음: /aura plan:[주제] 또는 /aura brainstorm+plan:[주제]
```

---

## 빠른 모드 (`brainstorm:quick`)

5분 내 빠른 아이디어 발산 (HMW 3개 + 아이디어 6개 + 즉시 범위 결정):

```bash
/aura brainstorm:quick 알림 기능    # 빠른 브레인스토밍
/aura brainstorm+plan:소셜 로그인   # 브레인스토밍 + 계획 통합
```

---

## 빠른 시작

```bash
/aura brainstorm:결제 시스템         # 전체 브레인스토밍
/aura brainstorm:quick 알림          # 빠른 5분 브레인스토밍
/aura brainstorm+plan:소셜 로그인    # 브레인스토밍 → PLAN 자동 연결
/아우라 brainstorm:마이크로서비스    # 한국어 입력
```

---

*AuraKit BRAINSTORM — HMW 발산 · Impact×Effort 매트릭스 · PLAN 자동 연결*
