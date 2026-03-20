# AuraKit — PLAN Pipeline (계획 문서 모드)

> `/aura plan:` 또는 `/aura plan:[기능명]` 호출 시 로딩.
> bkit PDCA의 Plan 단계와 동일한 역할 — 구현 전 계획 문서화.
> BUILD 모드와 분리: 이 모드는 구현하지 않는다.

---

## 역할

- 사용자 요청을 분석하여 **구현 계획 문서** 생성
- 산출물: `.aura/docs/plan-[기능명].md`
- 이후 `/aura design:` → `/aura build:` 순서로 진행 가능

---

## 실행 순서

### Step 1 — Discovery (5-Question Framework)
`resources/discovery-protocol.md` 참조. 내부 검토 후 플랜 작성 시작.

### Step 2 — 계획 문서 작성

```markdown
# Plan: [기능명]

## Executive Summary
- 기능: [기능명]
- 목적: [한 줄 설명]
- 예상 파일 수: [N]개
- 우선순위: [P0/P1/P2]

## 요구사항 분석
### Must Have (필수)
- [ ] [항목 1]
- [ ] [항목 2]

### Should Have (권장)
- [ ] [항목]

### Nice to Have (선택)
- [ ] [항목]

## 기술 스택
- 프레임워크: [감지된 스택]
- 라이브러리: [필요한 것]
- 외부 API: [있으면]

## 구현 범위
### 포함
- [명시적으로 포함할 것]

### 제외 (별도 작업)
- [범위 외 항목]

## 파일 계획
| 파일 경로 | 역할 | 우선순위 |
|---------|------|---------|
| [path] | [설명] | P0 |

## 의존성 순서
1. [먼저 구현할 것]
2. [다음]
3. [마지막]

## 성공 기준
- [ ] [완료 조건 1]
- [ ] [완료 조건 2]

## 리스크
- [잠재적 문제 + 대응 방안]

## 다음 단계
- [ ] `/aura design:[기능명]` — UI/DB 설계
- [ ] `/aura build:[기능명]` — 구현 시작
```

### Step 3 — 파일 저장

```bash
mkdir -p .aura/docs
# 파일명: plan-[kebab-case-기능명].md
```

### Step 4 — 완료 출력

```
✅ PLAN 완료 — [기능명]
저장: .aura/docs/plan-[기능명].md

📋 요약:
  Must Have: [N]개
  파일 계획: [N]개
  우선순위: [레벨]

다음: /aura design:[기능명] 또는 /aura build:[기능명]
```

---

## 에이전트 배정

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| Planner | sonnet (ECO) / opus (PRO/MAX) | Discovery + 계획 문서 작성 |

단일 에이전트 실행 (context:fork 불필요 — 메인 컨텍스트에서 직접 처리).

---

## 빠른 시작

```bash
/aura plan:소셜 로그인 기능
/아우라 plan:결제 시스템
/aura pro plan:마이크로서비스 인증
```

---

*AuraKit PLAN — Discovery-First 계획 문서화, 구현 없음*
