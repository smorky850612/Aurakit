# AuraKit — Iterate Pipeline (자동 반복 개선)

> ITERATE 모드 또는 REVIEW Gap Rate < 90% 시 자동 로딩.
> 최대 5회 반복. 격리 서브에이전트 실행.

---

## 트리거 조건

```
1. 명시적: /aura iterate:[파일 또는 기능명]
2. 자동: REVIEW 모드 Gap Rate < 90% 감지 시
3. 자동: BUILD V2/V3 실패 후 자동 FIX 전환 실패 시
```

---

## 실행 흐름

### Phase 0 — 초기 Gap 측정 [ECO/PRO: Haiku 위임 필수]

```
Agent(model="haiku") 실행:  ← ECO/PRO 필수, Sonnet 직접 실행 금지
  입력: .aura/plan.md 또는 사용자 지정 spec
  출력: Match Rate N%, 미구현 항목 목록 (Fail-Only)

Match Rate ≥ 90% → 이미 충분. ITERATE 불필요. 리포트만 출력.
Match Rate < 90%  → Phase 1 진입
```

### Phase 1~5 — 반복 수정 루프

```
[반복 N/5]

Step A: 미구현 항목 추출 (GapDetector 결과에서 ❌ 항목)
Step B: Iterator 에이전트 (모델은 티어에 따라):
          ECO: sonnet
          PRO: sonnet
          MAX: opus
        → 미구현 항목 구현 (최소 변경, 기존 코드 보존)
Step C: V1 빌드 검증 (build-verify.js) — 실패 시 즉시 중단 + FIX 제안
Step D: GapDetector 재실행 Agent(model="haiku") — ECO/PRO 필수
        → 새 Match Rate 측정

Match Rate ≥ 90% → 성공. Phase 완료.
Match Rate < 90%  → 다음 반복 (N+1)
반복 5회 초과    → 중단 + 수동 확인 요청
```

---

## 에이전트 모델 배정

| 에이전트 | ECO | PRO | MAX |
|---------|-----|-----|-----|
| GapDetector | haiku | haiku | sonnet |
| Iterator | sonnet | sonnet | opus |
| V1 검증 | hook (자동) | hook (자동) | hook (자동) |

---

## 출력 포맷

```markdown
## AuraKit Iterate 리포트

반복: [N]/5
시작 Match Rate: [N]%
최종 Match Rate: [N]%

### 변화 추이
반복 1: [N]% → 수정 [X]개
반복 2: [N]% → 수정 [X]개
...

### 최종 상태
✅ 완료 [N]개 | ❌ 잔여 [N]개

### 잔여 미구현 (수동 처리 필요)
- [항목명] — 이유: [자동 수정 불가 이유]

💰 [티어] | 반복 [N]회 완료
```

---

## 안전 규칙

```
- 기존 통과 테스트 깨는 변경 금지 (TestRunner 확인)
- 기능 삭제로 Gap Rate 올리기 금지 (GapDetector 감지)
- 5회 미달성 시 강제 종료 후 수동 확인 요청
- 각 반복은 격리 서브에이전트 실행 — 메인 컨텍스트 토큰 보호
```

---

*Iterate Pipeline — 자동 수정 최대 5회 · Gap ≥ 90% 달성 시 자동 종료*
