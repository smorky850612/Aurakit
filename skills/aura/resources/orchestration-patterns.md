# AuraKit — 에이전트 오케스트레이션 패턴 (G1)

> 이 파일은 `/aura orchestrate:` 또는 복잡한 멀티-에이전트 작업 시 로딩된다.

---

## 개요

AuraKit은 4가지 오케스트레이션 패턴을 지원한다.
작업 복잡도와 목적에 따라 패턴을 선택하라.

| 패턴 | 구조 | 사용 시점 |
|------|------|---------|
| **Leader** | 1 조율자 + N 실행자 | 단계적 구현, 의존성 있는 작업 |
| **Swarm** | N 에이전트 병렬 | 독립적 부분 작업, 최대 속도 |
| **Council** | N 검토자 + 1 종합자 | 중요 결정, 아키텍처 설계 |
| **Watchdog** | 1 모니터 + N 실행자 | 장시간 작업, 품질 게이트 |

---

## 패턴 1: Leader (지휘자)

```
Leader (sonnet/opus)
  ├── Worker-A (haiku/sonnet) → 서브태스크 A
  ├── Worker-B (haiku/sonnet) → 서브태스크 B
  └── Worker-C (haiku/sonnet) → 서브태스크 C
       ↓ 결과 취합
  Leader → 통합 + 최종 검증
```

**언제**: 단계적 실행이 필요한 기능 구현.
- Step 1: Leader가 플랜 수립 (마이크로 플랜)
- Step 2: Worker들에게 파일 단위 작업 위임 (격리 서브에이전트)
- Step 3: 각 Worker 결과 Leader가 통합 검토
- Step 4: 불일치 발견 시 Leader가 수정 지시

**예시: `/aura max build:결제 시스템`**
```
Leader(opus):
  → Discovery + 마이크로 플랜 수립
  → Worker-A(sonnet): stripe-client.ts 구현
  → Worker-B(sonnet): payment-api/route.ts 구현
  → Worker-C(sonnet): payment.test.ts 작성
  → 통합 검증 + 보안 L4
```

---

## 패턴 2: Swarm (떼)

```
[독립 작업 A] ──┐
[독립 작업 B] ──┼→ 병렬 실행 → 결과 병합
[독립 작업 C] ──┘
```

**언제**: 파일 간 의존성이 없는 독립 작업 묶음.
- 모든 에이전트 동시 실행 (격리 서브에이전트)
- 실패 에이전트만 재실행
- 성공 에이전트는 "Pass" 한 줄만 반환 (Fail-Only Output)

**예시: `/aura review:전체 코드베이스`**
```
동시 실행:
  Scout(haiku/sonnet(MAX)):   변경 파일 목록 수집
  Worker-A(sonnet/opus(MAX)): 코드 품질 리뷰
  Worker-B(sonnet/opus(MAX)): 보안 L3 스캔 (OWASP Top 10)
  Worker-C(haiku/sonnet(MAX)):  테스트 실행
  Worker-D(haiku/sonnet(MAX)):  Gap Check
```

**비용 최적화**:
```
ECO Swarm:  haiku×N + sonnet×2 (기본)
PRO Swarm:  haiku×N + opus×1(Leader) + sonnet×2
MAX Swarm:  opus×2(A/B) + sonnet×2(C/D — TestRunner/GapDetector는 MAX에서도 sonnet)
```

---

## 패턴 3: Council (평의회)

```
Reviewer-A (sonnet/opus(MAX)) ─┐
Reviewer-B (sonnet/opus(MAX)) ─┼→ Council 집계 → 최종 결정
Reviewer-C (sonnet/opus(MAX)) ─┘      (다수결 or 가중치)
```

**언제**: 중요한 기술 결정, 상충되는 옵션 평가.
- 각 Reviewer가 독립적으로 평가 (격리 서브에이전트)
- 평가 기준: 보안성, 성능, 유지보수성, 비용
- 종합자가 각 의견 가중치 합산 → 최종 결정

**예시: `/aura max design:인증 아키텍처`**
```
병렬 평가:
  Reviewer-A(opus): 세션 기반 vs 토큰 기반 — 보안성 평가
  Reviewer-B(opus): 세션 기반 vs 토큰 기반 — 성능 평가
  Reviewer-C(opus): 세션 기반 vs 토큰 기반 — 유지보수성 평가

종합자(opus):
  → 3가지 평가 취합
  → 가중치: 보안 40% + 성능 30% + 유지보수 30%
  → 최종 권장: [결정]
  → 근거 + 트레이드오프 문서화 → .aura/memory.md 저장
```

---

## 패턴 4: Watchdog (감시자)

```
Watchdog (haiku) ──→ 품질 게이트 모니터링
    │
    ├── Worker-A 실행 → Watchdog 검증 → Pass → Worker-B
    ├── Worker-B 실행 → Watchdog 검증 → Fail → 재실행
    └── Worker-C 실행 → Watchdog 검증 → Pass → 완료
```

**언제**: 장시간 반복 작업 (ITERATE 모드, TDD 사이클).
- Watchdog이 각 단계 출력 검증
- 품질 기준 미달 시 즉시 재실행 (최대 3회)
- 3회 실패 시 사용자에게 에스컬레이션

**예시: `/aura iterate:` (Gap < 90%)**
```
Watchdog(haiku):
  반복 1: GapDetector → 75% → Iterator 실행
  반복 2: GapDetector → 83% → Iterator 실행
  반복 3: GapDetector → 91% → ✅ 완료

게이트 기준:
  ITERATE: Match Rate ≥ 90%
  TDD: 테스트 커버리지 ≥ 80%
  BUILD: V1(tsc) + V2(리뷰) 모두 Pass
```

---

## 패턴 조합 예시

### 복잡 기능 구현 (PRO 티어)

```
Leader(opus):
  → Discovery + 플랜

Swarm(ECO):
  ├── Worker-A: 데이터모델 구현
  ├── Worker-B: API 라우트 구현
  └── Worker-C: UI 컴포넌트 구현

Watchdog(haiku):
  → 빌드 검증 (V1)
  → 테스트 실행 (V3)

Council(opus×3) [선택]:
  → 보안 설계 검토 (MAX 티어만)
```

---

## 에이전트 메모리 공유 (G2 연동)

오케스트레이션 중 에이전트 간 컨텍스트 공유:
```
.aura/agent-memory/
  scout.json          ← Scout 분석 결과 (다른 에이전트가 읽음)
  reviewer-a.json     ← Reviewer-A 결론
  reviewer-b.json     ← Reviewer-B 결론
  watchdog.json       ← Watchdog 게이트 상태
```

포맷:
```json
{
  "agent": "scout",
  "timestamp": "2025-01-15T17:00:00Z",
  "task": "login-feature",
  "findings": {
    "framework": "Next.js",
    "existingAuth": false,
    "relatedFiles": ["src/lib/auth.ts", "src/middleware.ts"]
  },
  "handoff": "Reviewer-A 참고: 기존 auth.ts는 세션 기반"
}
```

---

## 사용법

```bash
# 자동 패턴 선택 (기본)
/aura max build:마이크로서비스 인증 시스템

# 패턴 명시
/aura orchestrate:leader build:결제 모듈
/aura orchestrate:swarm review:전체
/aura orchestrate:council design:데이터베이스 스키마
/aura orchestrate:watchdog iterate:gap-fix
```

**패턴 자동 선택 기준**:
- QUICK/ECO: Swarm (기본)
- PRO: Leader + Swarm
- MAX: Leader + Swarm + Council (복잡도 높을 때)
- ITERATE/TDD: Watchdog 필수
