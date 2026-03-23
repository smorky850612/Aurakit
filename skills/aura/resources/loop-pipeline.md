# AuraKit — Loop Pipeline (자율 반복 실행)

> `/aura batch:loop:` 명시 호출 시 로딩.
> 자율 루프 오퍼레이터: 조건 충족 시 자동 종료.

---

## 개요

반복 작업을 자동으로 처리하는 자율 루프 오퍼레이터.
ITERATE 모드(Gap 기반)와 달리, **작업 단위 반복**에 특화.

```bash
/aura batch:loop:[작업명]             # 기본 루프 (최대 10회)
/aura batch:loop:[작업명] max:5       # 최대 5회
/aura batch:loop:[작업명] until:pass  # 테스트 통과 시 자동 종료
/aura batch:loop:[작업명] until:90%   # Gap Rate ≥90% 달성 시 종료
```

---

## 사용 시나리오

### 1. 테스트 통과까지 반복 수정

```bash
/aura batch:loop:실패 테스트 수정 until:pass max:5
→ 테스트 실행 → 실패 시 FIX → 재실행 → 통과 시 자동 종료
```

### 2. 빌드 성공까지 반복

```bash
/aura batch:loop:빌드 until:build-pass max:3
→ 빌드 → 실패 시 에러 분석 + 수정 → 재빌드 → 성공 시 종료
```

### 3. Gap Rate 목표까지 구현

```bash
/aura batch:loop:gap-check until:90% max:5
→ Gap 분석 → 미달 시 구현 → 재분석 → 90% 달성 시 종료
```

### 4. 린트 클린 달성

```bash
/aura batch:loop:린트 수정 until:lint-pass max:3
→ npx eslint → 에러 수정 → 재실행 → 경고 0 시 종료
```

---

## 실행 흐름

```
[루프 시작]
N = 0, max = 10 (기본값)

while N < max:
  Step 1: 작업 실행 (격리 서브에이전트)
  Step 2: 결과 평가
    → until 조건 충족? → 루프 종료 ✅
    → 실패? → 에러 분석 + 최소 수정
  Step 3: N++
  Step 4: 체크포인트 저장 (.aura/snapshots/)

N ≥ max → 강제 종료 + 수동 확인 요청
```

---

## 종료 조건 (until 옵션)

| 조건 | 설명 |
|------|------|
| `until:pass` | 모든 테스트 통과 시 |
| `until:build-pass` | 빌드 성공 시 |
| `until:90%` | Gap Rate ≥ N% 달성 시 |
| `until:no-error` | 에러 0개 시 |
| `until:lint-pass` | 린트 경고 0 시 |
| (없음) | max 횟수까지 모두 실행 |

---

## BATCH 모드와의 차이

| | BATCH | LOOP |
|-|-------|------|
| 목적 | 독립 작업 병렬 처리 | 단일 작업 반복 처리 |
| 실행 방식 | 병렬 (최대 5개) | 순차 (1개씩) |
| 종료 조건 | 모든 작업 완료 | until 조건 or max |
| 사용 예 | A+B+C 동시 구현 | 테스트 통과할 때까지 수정 |

---

## 안전 규칙

```
- 기본 max: 10회
- 절대 max: 20회 (초과 불가, 인자 무시)
- 각 루프는 격리 서브에이전트 → 메인 컨텍스트 보호
- 기존 통과 테스트 깨는 변경 금지 (TestRunner 확인)
- 파일 삭제로 조건 충족 시도 감지 → 즉시 중단
- 컨텍스트 65% 초과 → 체크포인트 저장 + 경고
```

---

## 에이전트 배정

```
Loop-Coordinator (sonnet):
  → 작업 계획, 종료 조건 판단

Loop-Worker (tier에 따라):
  ECO: sonnet
  PRO: sonnet
  MAX: opus
  → 실제 수정 작업 수행

Loop-Evaluator (haiku):
  → until 조건 달성 여부 판단
  → 각 반복 결과 파싱
```

---

## 출력 포맷

```markdown
## AuraKit Loop 리포트

작업: [작업명]
루프: [N]/[max]
종료: [조건 충족 ✅ / max 도달 ⚠️]

### 반복 이력
반복 1: [결과] → [변경 요약]
반복 2: [결과] → [변경 요약]
...

### 최종 상태
[완료 상태]

💰 [티어] | 루프 [N]회 완료
```

---

*Loop Pipeline — 자율 반복 · until 조건 자동 종료 · max 안전 제한 · 격리 서브에이전트*
