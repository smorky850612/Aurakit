# AuraKit — Instinct System (학습 엔진)

> 쓸수록 똑똑해지는 AuraKit. 성공 패턴을 자동 축적하고 다음 작업에 자동 적용.
> everything-claude-code의 Instinct 시스템을 AuraKit 아이덴티티에 맞게 재설계.

---

## 구조

```
.aura/instincts/
  index.json          ← 전체 패턴 인덱스 (score 순 정렬)
  patterns/           ← 성공 패턴
    pattern-NNN.md
  anti-patterns/      ← 실패 패턴 (반복 실수 방지)
    anti-NNN.md
```

---

## index.json 포맷

```json
{
  "version": "1.0",
  "updated": "ISO-DATE",
  "patterns": [
    {
      "id": "pattern-001",
      "category": "auth",
      "language": "typescript",
      "framework": "nextjs",
      "description": "JWT → httpOnly cookie 패턴 (세션 만료 처리 포함)",
      "score": 87,
      "success_count": 12,
      "failure_count": 1,
      "tags": ["jwt", "cookie", "auth", "session"],
      "created": "ISO-DATE",
      "updated": "ISO-DATE"
    }
  ],
  "anti_patterns": [
    {
      "id": "anti-001",
      "description": "localStorage에 JWT 저장 — XSS 취약점",
      "score": 5,
      "tags": ["jwt", "localStorage", "xss"]
    }
  ]
}
```

---

## pattern-NNN.md 포맷

```markdown
---
id: pattern-001
category: auth
language: typescript
framework: nextjs
score: 87
tags: [jwt, cookie, auth]
---

## 컨텍스트
JWT 인증 구현 시 토큰 저장 방식

## 성공 패턴
```typescript
// httpOnly cookie — JS 접근 불가, XSS 방어
res.setHeader('Set-Cookie', serialize('token', jwt, {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 60 * 60 * 24,
}))
```

## 왜 효과적이었나
- XSS 공격으로부터 토큰 보호
- CSRF는 sameSite: strict로 방어
- 세션 만료 처리가 자동

## 적용 상황
- Next.js API Route에서 로그인 처리 시
- 모든 인증 관련 토큰 저장 시
```

---

## 로딩 로직 (B-5에서 실행)

```
1. .aura/instincts/index.json 존재 확인
2. 없으면: 건너뜀 (첫 사용)
3. 있으면:
   a. 현재 language + framework 필터링
   b. score > 40인 패턴만 선택
   c. score DESC 정렬 → 상위 5개만 로딩
   d. anti-patterns → 전체 로딩 (경량이므로)
4. 컨텍스트에 주입:
   "관련 패턴 N개 로딩됨 — [id 목록]"
```

---

## 저장 로직 (BUILD/FIX 완료 후 자동)

### 트리거 조건
- V1+V2+V3 모두 Pass → 성공 패턴 저장 후보
- 오류 발생 후 수정 → 실패 패턴 저장 후보

### 저장 프로세스
```
BUILD/FIX 완료 시:
  1. 핵심 결정사항 추출 (Key Decisions from snapshot)
  2. 기존 패턴과 유사도 확인 (태그 기반)
     - 유사 패턴 있음: score += 5, success_count += 1
     - 유사 패턴 없음: 새 패턴 생성 (score = 50)
  3. 실패 사례는 anti-patterns에 score -= 10
  4. index.json 업데이트
```

### 자동 프루닝 (월 1회 또는 /aura instinct:prune)
```
score < 20인 패턴 → 자동 삭제
success_count + failure_count < 2 && 30일 이상 → 삭제
patterns/ 총 100개 초과 시 → 하위 20% 삭제
```

---

## INSTINCT 모드 커맨드

```bash
/aura instinct:show              → 현재 학습된 패턴 목록 (score 순)
/aura instinct:show auth         → 카테고리별 필터
/aura instinct:show --lang=go    → 언어별 필터
/aura instinct:prune             → 저점수 패턴 정리
/aura instinct:export            → .aura/instincts/ 전체 → instincts-backup.json
/aura instinct:import [file]     → 다른 프로젝트 패턴 가져오기
/aura instinct:reset             → 전체 초기화 (확인 후)
/aura instinct:evolve            → 저점수 패턴 자동 개선 + anti-pattern 통합
```

### /aura instinct:evolve 상세

저점수 패턴(score 20~40)을 분석해 개선하거나 anti-pattern으로 강등:

```
1. score 20~40 패턴 추출
2. 최근 6개월 성공/실패 기록 분석
3. failure_count > success_count → anti-pattern으로 이동
4. 유사 패턴 병합 → 더 일반화된 패턴으로 통합
5. description 자동 개선 (모호한 설명 → 구체화)
6. 결과: "X개 개선, Y개 강등, Z개 병합" 리포트
```

비용: haiku(ECO/PRO), sonnet(MAX)

---

## PostToolUse Hook 자동화

`install.sh` 실행 시 자동 설정되는 PostToolUse 훅:

```
hooks/instinct-auto-save.js → Write/Edit 완료 시마다 실행
→ 파일 경로 + 내용 분석 → 카테고리/언어 감지
→ 유사 패턴 있으면: score += 3, success_count += 1
→ 유사 패턴 없으면: 새 pattern-NNN.md 생성 (score = 50)
→ 민감 데이터 포함 시: 저장 안 함 (자동 스킵)
→ .aura 없는 프로젝트: 조용히 스킵
```

**제한사항 (v5.0)**:
- 훅 미설치 시 패턴 저장은 BUILD/FIX 완료 후 Claude 판단에 의존
- 완전 자동화는 `install.sh` 실행 필수
- 저장되는 패턴은 코드 스니펫 상위 50줄 (프라이버시 고려)

## 글로벌 학습 [v6 신규] — 전체 프로젝트 공유

```
~/.claude/.aura/global-instincts/
  index.json          ← 글로벌 패턴 인덱스
  typescript/         ← 언어별 하위 디렉토리
    g-typescript-0001.md
  python/
  go/
  ...
```

**동작 원리**:
- 로컬 패턴 score ≥ 60 → 자동 글로벌 승격
- 민감 정보(절대경로, URL, UUID) 자동 제거 후 저장
- 모든 프로젝트가 같은 글로벌 풀 공유 → 한 프로젝트에서 배운 것이 다른 프로젝트에도 적용

**B-5에서 로딩**:
```
현재 프로젝트 언어 감지 → global-instincts/[lang]/ 스캔
→ score 순 상위 3개 로딩 → 컨텍스트 주입
```

```bash
/aura instinct:global:show       # 전체 프로젝트 공유 패턴 조회
/aura instinct:global:prune      # 저점수 글로벌 패턴 정리
/aura instinct:global:merge      # 현재 프로젝트 패턴 즉시 글로벌 반영
/aura instinct:global:export     # 글로벌 패턴 백업/공유용 내보내기
```

---

## 팀 공유

```
.aura/instincts/         ← .gitignore에서 제외 → 팀 공유 가능
→ git에 포함시키면 팀 전체가 같은 학습 경험 공유
→ 새 팀원도 즉시 프로젝트의 베스트 프랙티스 활용
```

---

## 성장 지표

```
/aura instinct:show 출력 예시:

📚 AuraKit Instincts — [프로젝트명]
총 패턴: 23개 | 평균 점수: 71 | 총 성공: 156회

카테고리별:
  auth     ████████ 8개 (avg: 82)
  api      ██████   6개 (avg: 74)
  ui       ████     4개 (avg: 68)
  db       ███      3개 (avg: 65)
  security ██       2개 (avg: 90)

Top 3 패턴:
  1. [pattern-012] JWT httpOnly cookie (score: 95)
  2. [pattern-007] Zod 입력 검증 패턴 (score: 91)
  3. [pattern-019] React Query + Suspense (score: 87)

⚠️ Anti-Patterns: 5개 (자동 회피 중)
```

---

*AuraKit Instinct System — 프로젝트별 학습 · 팀 공유 · 자동 성장*
