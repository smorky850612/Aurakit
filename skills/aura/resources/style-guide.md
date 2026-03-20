# AuraKit — Style Guide (출력 스타일 시스템)

> `/aura style:` 명령 시 로딩. 응답 포맷과 상세도를 조정.
> SuperPower "Output Personas" 기능에 해당.

---

## 출력 스타일 종류

### learning (학습자 모드)
```
대상: 코딩 입문자, 처음 보는 기술 스택
특징:
  - 한 줄 요약 → 상세 설명 순서
  - 코드 블록마다 주석 설명
  - "왜 이렇게 했는지" 이유 포함
  - 용어 설명 (예: "REST API란 ~")
  - 단계별 체크리스트 형식

예시 출력:
  ✅ 로그인 API를 만들었습니다.

  **로그인이 동작하는 방식:**
  1. 사용자가 이메일/비밀번호 입력 →
  2. 서버가 DB에서 사용자 확인 →
  3. 맞으면 토큰 발급 →
  4. 브라우저가 토큰 저장 (httpOnly 쿠키)

  ```typescript
  // POST /api/auth/login
  // 사용자가 이메일과 비밀번호를 보냅니다
  export async function POST(req: Request) {
    const { email, password } = await req.json() // 요청 데이터 읽기
    ...
  }
  ```
```

### expert (전문가 모드, 기본값)
```
대상: 경험 있는 개발자
특징:
  - 핵심만 간결하게
  - 파일명:줄번호 직접 참조
  - "왜"는 필요한 경우만
  - 기술 용어 그대로 사용

예시 출력:
  src/app/api/auth/login/route.ts:34 — bcrypt.compare + httpOnly cookie 적용
  주의: JWT 만료시간 ENV에서 로딩 필요 (JWT_EXPIRY 미설정)
```

### concise (초간결 모드)
```
대상: 바쁜 개발자, 빠른 확인만 필요
특징:
  - 최대 3줄 이내
  - 완료 여부 + 핵심 변경사항만
  - 설명 없음

예시 출력:
  ✅ login/route.ts — bcrypt + httpOnly cookie. JWT_EXPIRY ENV 필요.
```

---

## 스타일 설정 방법

```bash
# 현재 세션에서 스타일 변경
/aura style:learning    → 학습자 모드
/aura style:expert      → 전문가 모드 (기본)
/aura style:concise     → 초간결 모드

# 모드와 함께 사용
/aura style:learning build:로그인 기능  # 학습자 모드 + BUILD
/아우라 style:concise 버그 수정해줘     # 초간결 모드 + FIX
```

**영구 설정**: `.aura/project-profile.md`의 `Output Style: [스타일]` 필드에 저장.

---

## 스타일별 에이전트 설명 방식

| 스타일 | 코드 주석 | 이유 설명 | 용어 설명 | 길이 |
|--------|---------|---------|---------|------|
| learning | 풍부 | 항상 | 있음 | 길다 |
| expert | 최소 | 필요 시 | 없음 | 중간 |
| concise | 없음 | 없음 | 없음 | 짧다 |

---

## 💰 라인에서 스타일 표시

스타일이 기본(expert)과 다를 때만 표시:
```
💰 ECO | learning 모드 | 컨텍스트: N% | 오늘: ...
```

---

*AuraKit Style — 같은 작업, 다른 설명 방식*
