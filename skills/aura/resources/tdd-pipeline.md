# AuraKit — TDD Pipeline (테스트 주도 개발)

> TDD 모드에서 로딩. SuperPower 수준 RED-GREEN-REFACTOR 규율 강제.
> 테스트 없는 구현은 차단된다.

---

## 핵심 원칙

```
1. 테스트 먼저 (Test-First) — 구현 코드 작성 전 테스트 필수
2. 최소 구현 (Minimal Code) — GREEN 단계에서 over-engineering 금지
3. 지속 리팩토링 (Continuous Refactor) — 테스트 통과 후에만 개선
4. 빠른 피드백 (Fast Feedback) — 각 단계 즉시 검증
```

---

## 실행 흐름

### 🔴 RED — 실패 테스트 작성 [필수, 위반 시 차단]

```
TDD-Writer (model: sonnet, context:fork)

입력: 구현할 기능 설명
출력: 실패하는 테스트 파일

작성 규칙:
  - 테스트는 아직 구현되지 않은 기능을 검증해야 함
  - 실행 시 반드시 실패 (Red) 상태 확인
  - 테스트 파일 위치: [기능명].test.ts / [기능명]_test.py / [기능명]_test.go

검증: TestRunner (haiku) → 실패 확인
  → 실패 확인됨: GREEN 단계 진입
  → 통과됨 (이미 구현 존재): 테스트 수정 요청
```

**차단 규칙**: RED 단계 건너뛰고 구현 시도하면 즉시 중단.
```
❌ 구현 코드를 먼저 작성할 수 없습니다.
   /aura tdd:[기능명] 은 RED → GREEN → REFACTOR 순서를 강제합니다.
   먼저 실패하는 테스트를 작성하세요.
```

---

### 🟢 GREEN — 최소 구현

```
Builder (model: [tier], context:fork)

입력: RED 단계 테스트 파일
출력: 테스트를 통과하는 최소 구현

구현 규칙:
  - 테스트 통과에 필요한 최소한의 코드만 작성
  - 중복 허용 (REFACTOR에서 제거)
  - 성능 최적화 금지 (REFACTOR에서 처리)
  - 하드코딩 임시 허용 (명백히 임시인 경우)

검증: TestRunner (haiku) → 통과 확인
  → 통과: REFACTOR 진입
  → 실패: Builder 재시도 (최대 2회)
  → 2회 실패: FIX 모드 제안
```

---

### 🔵 REFACTOR — 코드 개선

```
Reviewer (model: sonnet, context:fork)

입력: GREEN 통과 코드 + 테스트
출력: 개선된 코드 (테스트 통과 유지 필수)

개선 항목:
  - 중복 코드 제거 → 함수/모듈 추출
  - 하드코딩 → 상수/설정으로 이동
  - 네이밍 개선 (명확성)
  - 성능 최적화 (간단한 것만)
  - 접근성 + 보안 기본 검사

검증: TestRunner (haiku) → 여전히 통과 확인
커밋:
  git commit -m "test(scope): add RED tests for [기능명]"
  git commit -m "feat(scope): GREEN implementation for [기능명]"
  git commit -m "refactor(scope): cleanup [기능명]"
```

---

## 에이전트 + 모델 배정

| 단계 | 에이전트 | ECO | PRO | MAX |
|------|---------|-----|-----|-----|
| RED | TDD-Writer | sonnet | sonnet | opus |
| RED 검증 | TestRunner | haiku | haiku | haiku |
| GREEN | Builder | sonnet | opus | opus |
| GREEN 검증 | TestRunner | haiku | haiku | haiku |
| REFACTOR | Reviewer | sonnet | sonnet | opus |
| REFACTOR 검증 | TestRunner | haiku | haiku | haiku |

---

## 커버리지 목표

```
ECO: ≥ 70% (핵심 경로)
PRO: ≥ 80% (브랜치 커버리지)
MAX: ≥ 90% (엣지 케이스 포함)

미달 시: 추가 테스트 작성 요청 (차단 아님, 경고)
```

---

## 빠른 시작

```bash
/aura tdd:로그인 기능      # 로그인 기능 TDD
/aura pro tdd:결제 시스템  # PRO 티어 TDD (Builder=opus)
/aura max tdd:인증 미들웨어 # MAX 티어 전체 opus
```

---

## 출력 포맷

```markdown
## AuraKit TDD — [기능명]

🔴 RED:   [파일명].test.ts 작성 → 실패 확인 ✓
🟢 GREEN: [파일명].ts 구현 → 테스트 통과 ✓ ([N]/[N] passed)
🔵 REFACTOR: 중복 제거 [N]개, 네이밍 개선 [N]개

커버리지: [N]% ([목표]% 목표)
커밋: 3개 (test/feat/refactor)

💰 [티어] | TDD 완료
```

---

*TDD Pipeline — RED 없이 GREEN 불가 · 테스트 깨는 REFACTOR 차단*
