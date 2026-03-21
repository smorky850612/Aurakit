# AuraKit — Orchestration Patterns

> `/aura orchestrate:` 호출 시 로딩. 4가지 멀티에이전트 패턴.

---

## 패턴 선택 가이드

| 패턴 | 적용 상황 | 에이전트 수 |
|------|----------|------------|
| Leader | 대규모 기능, 단계별 순서 있음 | 1 CTO + N Workers |
| Swarm | 독립적 병렬 작업, 순서 없음 | N Workers (병렬) |
| Council | 아키텍처 결정, 의견 수렴 필요 | 3-5 Experts |
| Watchdog | 장시간 작업, 품질 모니터링 | 1 Monitor + N Workers |

---

## Pattern 1 — Leader (리더-워커)

CTO가 작업을 분해하고 Worker들이 순차/병렬로 실행.

```
CTO(sonnet/opus)
  ├── [Plan] 작업 분해 + 의존성 분석
  ├── Worker-A(haiku) → [파일그룹 A]
  ├── Worker-B(haiku) → [파일그룹 B]  (A와 독립 → 병렬)
  └── Worker-C(sonnet) → [파일그룹 C] (A,B 완료 후 → 순차)
```

**사용 시점**: 풀스택 기능 (DB + API + UI), 5개 이상 파일 변경

---

## Pattern 2 — Swarm (스웜)

동일 수준의 에이전트들이 독립 작업을 병렬로 처리.

```
Coordinator(sonnet)
  ├── Worker-1(haiku) → [도메인 A] ─┐
  ├── Worker-2(haiku) → [도메인 B] ─┤ 모두 병렬
  ├── Worker-3(haiku) → [도메인 C] ─┤
  └── Worker-4(haiku) → [도메인 D] ─┘
      ↓ (모두 완료)
  Aggregator → 결과 통합
```

**사용 시점**: 다국어 번역, 다중 테스트, 독립 모듈 생성

---

## Pattern 3 — Council (의회)

전문가들이 각자 의견을 제시하고 합의를 도출.

```
Moderator(opus)
  ├── Expert-DB(sonnet)  → DB 관점 의견
  ├── Expert-API(sonnet) → API 관점 의견
  ├── Expert-UI(sonnet)  → UI/UX 관점 의견
  └── Expert-Sec(sonnet) → 보안 관점 의견
      ↓
  Moderator → 의견 통합 → 최종 결정 ADR 작성
```

**사용 시점**: 아키텍처 결정, 기술 스택 선택, 설계 trade-off 분석

---

## Pattern 4 — Watchdog (감시자)

Monitor가 Worker들의 출력을 실시간 감시하며 품질 보장.

```
Worker-A(sonnet) → [구현]
  ↓ (결과 전달)
Watchdog(haiku) → [품질 체크: 보안/성능/컨벤션]
  ├── Pass → 다음 Worker 진행
  └── Fail → Worker에게 재작업 지시 (최대 3회)
```

**사용 시점**: 보안 크리티컬 코드, 장시간 배치 작업, 자동화 파이프라인

---

## 에이전트 권한 매트릭스

| 에이전트 역할 | Write | Edit | Bash | 네트워크 |
|-------------|-------|------|------|---------|
| CTO/Coordinator | ✅ | ✅ | ✅ | ✅ |
| Builder/Worker | ✅ | ✅ | ✅ | 제한 |
| Reviewer/Expert | ❌ | ❌ | 제한 | ❌ |
| Scout/Watchdog | ❌ | ❌ | 제한 | ❌ |

모든 에이전트: `context:fork` 필수 (메모리 격리)

---

## Git Worktree 활용 (BATCH 모드)

```bash
# 각 Worker에 독립 Worktree 할당
git worktree add .worktrees/feature-A -b feature/A
git worktree add .worktrees/feature-B -b feature/B

# 완료 후 정리 (/aura finish:)
git worktree remove .worktrees/feature-A
```

최대 5개 Worktree 동시 운영. `/aura batch:[A,B,C]` 로 자동 관리.
