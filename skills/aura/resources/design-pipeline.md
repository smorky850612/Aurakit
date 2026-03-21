# AuraKit — DESIGN Pipeline (설계 문서 모드)

> `/aura design:` 또는 `/aura design:[기능명]` 호출 시 로딩.
> DB 스키마, API 명세, 컴포넌트 구조 설계 문서화.
> PLAN 완료 후, BUILD 전에 실행하는 설계 단계.

---

## 역할

- 기술 설계 명세서 생성 (구현 없음)
- 산출물: `.aura/docs/design-[기능명].md`
- 이후 `/aura build:` 시 이 설계를 기준으로 구현

---

## 실행 순서

### Step 1 — 프로젝트 프로필 + Plan 문서 로딩

```
.aura/project-profile.md → 스택, DB 종류 확인
.aura/docs/plan-[기능명].md → Plan 내용 참조 (있으면)
```

### Step 2 — 3 Worker 병렬 설계 [필수]

```
Worker-DB   (model: sonnet, context:fork) → DB 스키마 설계
Worker-API  (model: sonnet, context:fork) → API 명세 설계
Worker-UI   (model: haiku,  context:fork) → 컴포넌트 트리 설계

→ 3개 동시 실행 → 결과 취합 → 설계 문서 합성
```

### Step 3 — 설계 문서 작성

```markdown
# Design: [기능명]

## DB 스키마

### [테이블명]
| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| id | UUID | PK, NOT NULL | |
| created_at | TIMESTAMP | NOT NULL | |

### 인덱스
- [테이블].[컬럼] — [이유]

### 관계
- [테이블A] 1:N [테이블B] via [foreign key]

---

## API 명세

### POST /api/[resource]
- 인증: Bearer JWT
- Request Body:
  ```json
  {
    "field": "type"
  }
  ```
- Response 200:
  ```json
  {
    "success": true,
    "data": {}
  }
  ```
- Error Cases:
  - 400: 입력 검증 실패
  - 401: 인증 없음
  - 500: 서버 오류

### GET /api/[resource]/[id]
...

---

## 컴포넌트 트리

```
[PageComponent]
  ├── [HeaderComponent]
  ├── [MainComponent]
  │   ├── [ListComponent]
  │   │   └── [ItemComponent]
  │   └── [FormComponent]
  └── [FooterComponent]
```

### 상태 관리
- 전역: [Zustand/Redux store 구조]
- 로컬: [컴포넌트별 useState]

### Props 인터페이스
```typescript
interface [ComponentName]Props {
  [prop]: [type]
}
```

---

## 보안 설계
- 인증: [방식]
- 인가: [권한 체계]
- 입력 검증: [zod 스키마]

---

## 다음 단계
- [ ] `/aura build:[기능명]` — 이 설계 기반으로 구현
```

### Step 4 — Design Cross-Check (v4.0 신규) [필수]

3-Worker 결과 취합 후 일관성 자동 검증:

```
Cross-Check Worker (model: haiku, context:fork):
  목적: DB ↔ API ↔ UI 필드 매핑 일관성 검증

  검사 항목:
    1. DB 컬럼 → API Request/Response 필드 누락 여부
       예) users.email 컬럼 → POST /api/users body에 email 없음 → 오류
    2. API Response 필드 → UI Props 누락 여부
       예) API { user_id, name } → UI interface에 user_id 없음 → 오류
    3. 외래키 관계 → API 참조 엔드포인트 존재 여부
       예) orders.user_id → GET /api/users/:id 엔드포인트 없음 → 경고

  출력 형식:
    성공: "Design Cross-Check: Pass"
    실패: "DESIGN-GAP-001: [field]이 [위치A]에 있으나 [위치B]에 없음"
```

Cross-Check 실패 시: 해당 Worker(DB/API/UI) 재실행으로 불일치 수정 후 재검증.

### Step 5 — 파일 저장 + 문서 인덱스 업데이트

```bash
mkdir -p .aura/docs
# 파일명: design-[kebab-case-기능명].md

# Doc Lifecycle 인덱스 업데이트
FEATURE="[기능명]"
# .aura/docs/index.md에 Design 완료 표시 추가
```

### Step 6 — 완료 출력

```
✅ DESIGN 완료 — [기능명]
저장: .aura/docs/design-[기능명].md

📐 설계 요약:
  DB: [N]개 테이블
  API: [N]개 엔드포인트
  컴포넌트: [N]개
  Cross-Check: ✅ Pass (또는 수정됨)

다음: /aura build:[기능명]
```

---

## 에이전트 배정

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| Worker-DB | sonnet | DB 스키마 설계 |
| Worker-API | sonnet | API 명세 설계 |
| Worker-UI | haiku | 컴포넌트 트리 설계 |
| Cross-Check Worker | haiku | DB↔API↔UI 일관성 검증 |

ECO: Worker-UI + Cross-Check → haiku (절약). PRO/MAX: 전체 sonnet/opus.

---

## 빠른 시작

```bash
/aura design:소셜 로그인
/아우라 design:결제 시스템
/aura pro design:마이크로서비스 API
```

---

*AuraKit DESIGN — 3-Worker 병렬 기술 설계 + Cross-Check 자동 검증, 구현 없음*
