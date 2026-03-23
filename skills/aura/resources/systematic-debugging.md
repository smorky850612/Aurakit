# AuraKit — Systematic Debugging (G5)

> 이 파일은 FIX 모드 복잡 버그 또는 `/aura debug:` 명시 시 로딩된다.

---

## 개요: 4-Phase Systematic Debugging

단순 증상 수정(workaround) 금지. 근본 원인 → 패턴 → 가설 → 구현 순서 필수.

```
Phase 1: Root Cause Analysis  → "이 에러의 진짜 원인은?"
Phase 2: Pattern Recognition  → "이 패턴이 다른 곳에도 있나?"
Phase 3: Hypothesis Testing   → "내 수정이 정말 해결하나?"
Phase 4: Implementation       → "최소 변경으로 수정"
```

---

## Phase 1: Root Cause Analysis (근본 원인 분석)

### 1.1 에러 분류

| 에러 타입 | 특징 | 분석 도구 |
|----------|------|---------|
| **런타임** | TypeError, undefined, null | 스택 트레이스 추적 |
| **로직** | 잘못된 결과, 계산 오류 | 입/출력 비교 |
| **비동기** | Promise reject, race condition | 타임라인 추적 |
| **타입** | TypeScript 오류 | tsc --noEmit |
| **환경** | 환경변수 누락, 경로 오류 | 설정 검사 |
| **의존성** | 모듈 버전 충돌 | npm audit, lock 파일 |

### 1.2 5-WHY 분석

```
증상:  "UserList 페이지에서 TypeError: Cannot read properties of undefined"
Why 1: user.profile이 undefined이기 때문
Why 2: API가 user.profile을 포함하지 않기 때문
Why 3: SELECT 쿼리가 JOIN profile을 빠뜨렸기 때문
Why 4: 새 API 추가 시 기존 JOIN 패턴을 참고하지 않았기 때문
Why 5: 에러 발생 → 원인은 쿼리 작성 관례 부재
→ 근본 원인: JOIN 패턴 표준화 필요
```

### 1.3 스택 트레이스 읽기

```
에러 위치 파악 순서:
1. 마지막 "at [파일:줄번호]" → 실제 오류 발생 지점
2. 호출 스택 역방향 추적 → 호출 경로 파악
3. 사용자 코드 vs 라이브러리 코드 구분
4. async/await 체인에서 Promise.reject 위치 확인
```

---

## Phase 2: Pattern Recognition (패턴 인식)

### 2.1 동일 패턴 탐색

```bash
# 같은 에러 패턴 탐색
grep -r "user\.profile" src/ --include="*.ts"
grep -r "optional chaining 없이 중첩 접근" src/

# 동일한 취약 패턴 파일 목록
```

### 2.2 패턴 분류

| 패턴 | 설명 | 수정 전략 |
|------|------|---------|
| **산재** | 동일 버그 여러 파일 | 헬퍼 함수 추출 후 일괄 수정 |
| **격리** | 단일 파일만 | 해당 파일만 수정 |
| **시스템** | 아키텍처 문제 | 설계 변경 제안 + 점진적 수정 |

### 2.3 영향 범위 평가

```
수정 전 확인:
□ 이 수정이 다른 파일에 영향을 주는가?
□ API 계약이 변경되는가?
□ 데이터베이스 스키마가 바뀌는가?
□ 하위 호환성이 깨지는가?

영향 범위:
  좁음 (단일 함수) → Phase 3 즉시 진행
  중간 (단일 모듈) → 관련 테스트 모두 확인
  넓음 (API/DB)   → Migration + 하위 호환 설계 필요
```

---

## Phase 3: Hypothesis Testing (가설 검증)

### 3.1 가설 작성

```
가설 템플릿:
"[수정 내용]을 하면 [근본 원인]이 해결되어 [증상]이 사라질 것이다."

예시:
"user 쿼리에 LEFT JOIN profile을 추가하면
 profile 데이터 누락이 해결되어 TypeError가 사라질 것이다."
```

### 3.2 검증 방법

```bash
# 방법 1: 단위 테스트 (빠름)
npx vitest run src/services/user.test.ts

# 방법 2: 통합 테스트
npx vitest run --reporter=verbose

# 방법 3: 수동 검증 시나리오
curl -X GET /api/users/123 | jq '.profile'
```

### 3.3 가설 기각 시

```
가설이 틀렸을 때:
1. Phase 1로 돌아가서 5-WHY 재분석
2. 새 증거를 바탕으로 가설 수정
3. 최대 3회 가설 시도 → 실패 시 사용자에게 에스컬레이션
   → "근본 원인 불명확 — 추가 정보 필요: [질문]"
```

---

## Phase 4: Implementation (구현)

### 4.1 최소 변경 원칙

```
금지:
✗ 전체 파일 재작성
✗ 관련 없는 코드 동시 수정
✗ 기능 추가 (버그 수정과 분리할 것)

허용:
✓ 버그 수정에 직접 필요한 변경만
✓ 같은 커밋에 동일 패턴 일괄 수정
✓ 테스트 추가 (재발 방지)
```

### 4.2 수정 순서

```
1. 재발 방지 테스트 먼저 작성 (RED)
2. 최소 수정 구현 (GREEN)
3. 동일 패턴 일괄 수정 (REFACTOR)
4. 빌드 검증 (V1: tsc/py_compile)
5. 테스트 실행 (V3)
6. 커밋: git commit -m "fix(scope): [근본 원인 설명]"
```

### 4.3 커밋 메시지 규칙

```bash
# 나쁜 예 (증상만 설명)
git commit -m "fix: TypeError 수정"

# 좋은 예 (근본 원인 설명)
git commit -m "fix(user-api): add profile JOIN to prevent undefined access

Cause: getUserById 쿼리가 profile 테이블 JOIN을 누락
Impact: 3개 엔드포인트 동일 패턴 일괄 수정
Test: user.service.test.ts:45 재발 방지 테스트 추가"
```

---

## 디버깅 체크리스트

```
Phase 1 완료:
□ 에러 타입 분류됨
□ 스택 트레이스 최하단 파일:줄번호 확인
□ 5-WHY로 근본 원인 도출

Phase 2 완료:
□ 동일 패턴 grep으로 탐색
□ 영향 범위 평가됨
□ 수정 전략 선택 (격리/산재/시스템)

Phase 3 완료:
□ 가설 명시적으로 작성
□ 검증 방법 선택
□ 가설 확인 (또는 재가설)

Phase 4 완료:
□ 재발 방지 테스트 추가
□ 최소 변경만 적용
□ V1 빌드 통과
□ 커밋 메시지에 근본 원인 명시
```

---

## 에이전트 배분 (FIX 모드)

```
Scout (haiku/sonnet(MAX)):
  → 에러 발생 파일 + 관련 파일 탐색
  → Phase 2 패턴 탐색 grep

Debugger (sonnet/opus(MAX)):
  → Phase 1~3 분석 + 가설 수립
  → 수정 계획 작성

Builder (tier에 따라):
  → Phase 4 최소 수정 구현

TestRunner (haiku/sonnet(MAX)):
  → 테스트 실행 + 결과 보고
```
