# AuraKit Security Rules — Always Active

> 이 파일은 `~/.claude/rules/` 에 위치하며, /aura 호출 여부와 관계없이
> 모든 Claude Code 세션에서 항상 적용됩니다.

---

## 절대 금지 (위반 시 즉시 중단)

1. **시크릿 하드코딩 금지**
   API 키, 비밀번호, 토큰을 코드에 직접 작성하지 않는다.
   → 환경변수(`process.env.X`, `os.environ["X"]`) 필수.

2. **localStorage JWT/Token 저장 금지**
   `localStorage.setItem('token', ...)` 패턴 사용 금지.
   → httpOnly Cookie (`sameSite: 'strict'`, `secure: true`) 사용.

3. **SQL 문자열 직접 연결 금지**
   사용자 입력을 SQL 쿼리에 `+` 또는 템플릿 리터럴로 삽입하지 않는다.
   → Parameterized query / ORM 필수.

4. **eval() / exec() 사용자 입력 금지**
   사용자 입력을 eval, exec, subprocess(shell=True)에 전달하지 않는다.

5. **.env 파일 .gitignore 미등록 시 커밋 금지**
   .env가 .gitignore에 없으면 커밋 전에 반드시 추가한다.

---

## 항상 적용되는 보안 패턴

### 인증 / 인가
- 보호된 라우트 → 인증 없을 시 반드시 401 반환
- 다른 사용자 리소스 접근 시도 → 403 반환
- 비밀번호 저장 → bcrypt/argon2 해시 (평문 절대 금지)
- JWT → httpOnly Cookie (만료 시간 명시)

### 입력 검증
- 모든 외부 입력 (HTTP body, query, params) → 검증 필수
  TypeScript: Zod | Python: Pydantic | Java: @Valid | Go: 직접 검증
- 파일 업로드 → MIME 타입 + 크기 제한 + 경로 주입 방지

### 응답 보안
- 에러 응답 → 스택 트레이스, 내부 경로, DB 정보 미포함
- API 응답 → 필요한 필드만 반환 (전체 모델 직렬화 금지)

### 암호화 / 랜덤
- 보안 랜덤값 → `crypto.randomBytes()` / `secrets.token_urlsafe()` / `crypto/rand`
  (`Math.random()`, `random.random()` 보안 용도 금지)
- 외부 통신 → HTTPS 전용 (HTTP 폴백 금지)

---

## 코드 품질 기준 (항상 적용)

- 컴포넌트 / 함수 250줄 초과 → 즉시 분리
- `any` 타입 (TypeScript) → `unknown` + type narrowing
- 미처리 Promise → `catch` 또는 `void` 명시
- `console.log` → 프로덕션 코드에서 제거
- 의존성 취약점 → `npm audit` 고위험 항목 즉시 업그레이드

---

## /aura 실행 시 추가 보안 (자동 활성화)

/aura 명령 실행 시 6중 보안 레이어가 추가로 활성화됩니다:
- L1: .env 보안 상태 확인
- L2: disallowed-tools 역할 분리
- L3: bash-guard.js 위험 명령 차단
- L4: security-scan.js 시크릿 패턴 스캔
- L5: Worktree 격리 (agent 실행 시)
- Convention: CONV-001~005 코드 관례 검사
