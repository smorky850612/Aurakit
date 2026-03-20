# AuraKit — REPORT Pipeline (완료 보고서 모드)

> `/aura report:` 또는 `/aura report:[기능명]` 호출 시 로딩.
> ITERATE 완료 후, 또는 명시적 보고서 요청 시 실행.
> bkit의 report-generator 역할과 동일.

---

## 역할

- 개발 완료 후 PDCA 사이클 요약 보고서 생성
- 산출물: `.aura/docs/report-[기능명].md`
- git log + 설계 문서 + Gap 분석 결과 종합

---

## 실행 순서

### Step 1 — 데이터 수집 (병렬)

```bash
# 변경 파일 목록
git log --oneline -20

# 파일 변경 통계
git diff --stat HEAD~N HEAD  # N = 이번 기능 커밋 수

# 테스트 결과 (있으면)
npm test --ci 2>&1 | tail -5
```

`.aura/docs/plan-[기능명].md` — 계획 문서 (있으면)
`.aura/docs/design-[기능명].md` — 설계 문서 (있으면)
`.aura/token-stats.json` — 토큰 사용량 (있으면)

### Step 2 — Gap Check (haiku, context:fork)

```
설계 문서 vs 실제 구현 비교
→ Match Rate 계산
→ 미구현 항목 목록
```

### Step 3 — 보고서 작성

```markdown
# Report: [기능명]
작성: [날짜]

---

## Executive Summary

| 항목 | 값 |
|------|---|
| 기능 | [기능명] |
| 시작 | [날짜] |
| 완료 | [날짜] |
| Match Rate | [N]% |
| 커밋 수 | [N]개 |
| 변경 파일 | [N]개 |
| 추가 줄 수 | +[N] |
| 삭제 줄 수 | -[N] |

---

## 구현 결과

### 완료된 기능
- [x] [항목 1]
- [x] [항목 2]

### 미완료 (후속 작업)
- [ ] [항목] — [이유]

---

## 품질 지표

| 지표 | 결과 |
|------|------|
| 빌드 (V1) | ✅ Pass |
| 코드 리뷰 (V2) | [A/B/C/D/F] |
| 테스트 (V3) | [N/N Pass] |
| 보안 (L3) | [이슈 수] |
| Match Rate | [N]% |

---

## 커밋 히스토리

```
[커밋 해시] [메시지] ([날짜])
```

---

## 학습 사항 (Lessons Learned)

### 잘 된 것
- [항목]

### 개선 필요
- [항목]

### 다음 반복에서 적용할 것
- [항목]

---

## 다음 단계

- [ ] [후속 기능 또는 작업]
- [ ] `/aura deploy:` — 배포 진행
```

### Step 4 — 파일 저장 + memory 기록

```bash
# 보고서 저장
.aura/docs/report-[기능명].md

# 중요 결정사항 memory에 기록
.aura/memory.md에 추가:
## [날짜] [기능명] 완료
Match Rate: [N]% | 주요 결정: [아키텍처 결정사항]
```

### Step 5 — 완료 출력

```
✅ REPORT 완료 — [기능명]
저장: .aura/docs/report-[기능명].md

📊 최종 요약:
  Match Rate: [N]%
  V1/V2/V3: ✅/✅/✅
  커밋: [N]개 | 파일: [N]개

다음: /aura deploy: 또는 /aura pipeline:next
```

---

## 에이전트 배정

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| Gap Worker | haiku | Match Rate 계산 |
| Reporter | sonnet | 보고서 종합 작성 |

---

## 빠른 시작

```bash
/aura report:소셜 로그인
/아우라 report:전체 작업 요약
/aura report:          # 현재 작업 자동 감지
```

---

*AuraKit REPORT — Gap Check + 품질 지표 + 학습 사항 종합*
