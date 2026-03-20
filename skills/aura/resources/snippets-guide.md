# AuraKit — Snippets Library (로컬 프롬프트 라이브러리)

> `/aura snippets:` 명령 시 로딩.
> 자주 쓰는 프롬프트 패턴을 로컬에 저장하고 단축어로 재사용.
> SuperPower "Snippet Library" 기능에 해당.

---

## 역할

- `.aura/snippets/` 디렉토리에 프롬프트 스니펫 저장
- `/aura snippets:list` → 저장된 스니펫 목록 출력
- `/aura snippets:add [이름]` → 현재 요청을 스니펫으로 저장
- `/aura snippets:use [이름]` → 저장된 스니펫 불러와서 실행
- `/aura snippets:delete [이름]` → 스니펫 삭제

---

## 스니펫 포맷

`.aura/snippets/[이름].md` 형식으로 저장:

```markdown
---
name: [스니펫 이름]
description: [한 줄 설명]
mode: [BUILD/FIX/CLEAN/REVIEW 등]
created: [날짜]
---

[프롬프트 내용]

## 변수
- {{COMPONENT_NAME}} — 컴포넌트 이름
- {{FEATURE}} — 기능명
- {{FILE_PATH}} — 파일 경로
```

---

## 내장 스니펫 (Built-in)

### auth-jwt
```
JWT 인증 미들웨어를 구현해줘.
- httpOnly cookie 저장
- Refresh Token 자동 갱신
- 보호 라우트 적용
- 모든 API 엔드포인트에 인증 체크
```

### crud-api
```
{{RESOURCE}} CRUD API를 만들어줘.
- GET /api/{{RESOURCE}} — 목록 (페이지네이션)
- GET /api/{{RESOURCE}}/:id — 단건 조회
- POST /api/{{RESOURCE}} — 생성
- PATCH /api/{{RESOURCE}}/:id — 수정
- DELETE /api/{{RESOURCE}}/:id — 삭제
- zod 입력 검증 + 에러 처리 포함
```

### component-split
```
{{FILE_PATH}} 파일이 너무 크다. 다음 기준으로 분할해줘:
- 각 컴포넌트 200줄 이내
- 단일 책임 원칙
- Props 인터페이스 명확히
- 기존 로직 유지 (기능 변경 없음)
```

### security-audit
```
이 코드베이스의 보안을 점검해줘:
- OWASP Top 10 기준
- SQL Injection, XSS, CSRF 체크
- 인증/인가 구현 확인
- 시크릿 노출 여부
- 결과: VULN-NNN 형식으로 리포트
```

### env-setup
```
이 프로젝트의 환경 변수 설정을 완성해줘:
- .env.example 생성 (값 없이)
- .gitignore에 .env 추가 확인
- README에 환경 변수 설명 추가
- 각 변수 목적 주석
```

### test-add
```
{{FILE_PATH}} 파일에 대한 테스트를 작성해줘:
- 유닛 테스트 + 통합 테스트
- 성공 케이스 + 에러 케이스
- 커버리지 목표: 80% 이상
- 기존 테스트 구조 유지
```

---

## 사용 예시

```bash
# 스니펫 목록 보기
/aura snippets:list

# 내장 스니펫 실행
/aura snippets:use auth-jwt
/아우라 snippets:use crud-api

# 변수 치환
/aura snippets:use crud-api --var RESOURCE=products

# 현재 요청을 스니펫으로 저장
/aura snippets:add my-auth-pattern
# → .aura/snippets/my-auth-pattern.md 생성

# 스니펫 삭제
/aura snippets:delete my-old-pattern

# 스니펫 + 티어 조합
/aura pro snippets:use security-audit
```

---

## 실행 순서

### `snippets:list`
```
.aura/snippets/ 디렉토리 스캔
→ 각 파일의 name + description 출력
→ 내장 스니펫도 포함

출력 포맷:
📚 저장된 스니펫 (N개):
  [이름]      — [설명]
  auth-jwt    — JWT 인증 미들웨어 (내장)
  crud-api    — CRUD API 생성 (내장)
  ...
```

### `snippets:use [이름]`
```
1. .aura/snippets/[이름].md 로딩
2. 내장 스니펫 확인 (없으면 내장에서 탐색)
3. 변수 치환 (--var KEY=VALUE)
4. 프롬프트 내용으로 해당 모드 실행
   → mode: BUILD → BUILD 파이프라인
   → mode: FIX → FIX 파이프라인
   → mode 없음 → 자동 감지
```

### `snippets:add [이름]`
```
1. 사용자의 현재/직전 프롬프트 추출
2. 모드 자동 감지
3. .aura/snippets/[이름].md 저장
4. 확인 출력:
   ✅ 스니펫 저장: .aura/snippets/[이름].md
   다음: /aura snippets:use [이름]
```

---

## 팀 공유 (옵션)

스니펫은 `.aura/snippets/` 에 저장되므로 git에 포함 가능:

```bash
# .gitignore에서 제외 (팀 공유 시)
# .aura/snippets/ 줄을 삭제하거나 주석

# 개인 스니펫만 제외
.aura/snippets/personal-*.md
```

---

## 에이전트 배정

단일 에이전트 실행 (list/add/delete):
- Snippets Manager: sonnet (메인 컨텍스트)

use 시:
- 해당 모드의 파이프라인 에이전트 배정 적용

---

## 빠른 시작

```bash
/aura snippets:list              # 사용 가능한 스니펫 확인
/aura snippets:use crud-api      # CRUD API 즉시 생성
/아우라 snippets:add 내인증패턴  # 현재 작업을 스니펫으로 저장
/aura pro snippets:use security-audit  # PRO 모드 보안 감사
```

---

*AuraKit Snippets — 반복 프롬프트를 저장하고 단축어로 재사용*
