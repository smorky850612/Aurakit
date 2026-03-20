# AuraKit — Pipeline Guide (9단계 개발 파이프라인)

> `/aura pipeline:` 또는 `/aura pipeline:[기능명]` 호출 시 로딩.
> 신규 프로젝트 또는 "어디서 시작해야 하나?" 질문에 대응.
> Scout가 Starter/Dynamic/Enterprise 자동 감지 후 맞춤 경로 제공.

---

## 복잡도 자동 감지 (Scout 분류 기준)

```
Starter:
  - 정적 웹사이트, HTML/CSS/JS, 포트폴리오, 랜딩 페이지
  - 백엔드 없음 (또는 단순 폼 제출만)
  - 1~3 파일, 외부 의존성 최소

Dynamic:
  - 풀스택 앱, 로그인/인증, DB CRUD, REST API
  - BaaS (Supabase, Firebase, bkend.ai) 또는 자체 서버
  - 5~20개 주요 컴포넌트/파일

Enterprise:
  - 마이크로서비스, K8s, 멀티 팀, CI/CD 파이프라인
  - 복잡한 도메인 모델, 이벤트 소싱, CQRS
  - 20+ 서비스, 테넌트 분리
```

---

## 9단계 파이프라인

### Phase 1 — Schema (스키마/도메인 모델)
```
목표: 프로젝트에서 사용되는 용어와 데이터 구조 정의
산출물:
  - 도메인 용어 사전 (예: User, Post, Order 정의)
  - 데이터 엔티티 관계 (ERD)
  - 핵심 타입/인터페이스 정의

Starter:  생략 가능 (데이터 없으면)
Dynamic:  필수 — DB 테이블 설계
Enterprise: 필수 — 이벤트/커맨드/도메인 모델
```

### Phase 2 — Convention (코딩 컨벤션)
```
목표: AI 협업을 위한 코딩 규칙 명시
산출물:
  - 파일/폴더 구조 규칙
  - 네이밍 컨벤션 (camelCase, snake_case 등)
  - import 순서, 포맷 규칙
  - 브랜치 전략 (git flow, trunk-based)

Starter:  생략 가능
Dynamic:  권장 — ESLint/Prettier 설정
Enterprise: 필수 — 멀티 팀 일관성 확보
```

### Phase 3 — Mockup (UI 프로토타입)
```
목표: 디자이너 없이 UI 방향 결정
산출물:
  - HTML/CSS 프로토타입 또는 Tailwind 목업
  - 핵심 화면 흐름 (로그인 → 대시보드 → 상세)
  - 디자인 시스템 토큰 (색상, 타이포, 간격)

Starter:  핵심 (빠른 결과물)
Dynamic:  권장 — 컴포넌트 설계 기준
Enterprise: API 계약 확정 후 진행
```

### Phase 4 — API (백엔드 API 설계)
```
목표: 프론트-백엔드 계약 정의 + 구현
산출물:
  - API 엔드포인트 명세 (OpenAPI/Swagger 또는 문서)
  - 인증/인가 미들웨어
  - DB 쿼리 + ORM 모델
  - Zero Script QA (Docker 로그 기반 검증)

Starter:  생략 (정적 사이트)
Dynamic:  핵심 — REST API + BaaS 연동
Enterprise: 필수 — GraphQL/gRPC, 이벤트 버스
```

### Phase 5 — Design System (디자인 시스템)
```
목표: 재사용 가능한 UI 컴포넌트 라이브러리 구축
산출물:
  - 버튼, 입력, 카드, 모달 등 기본 컴포넌트
  - CSS 변수/토큰 (--color-primary 등)
  - Storybook 또는 컴포넌트 문서

Starter:  CSS 변수 + 기본 컴포넌트 몇 개
Dynamic:  권장 — Tailwind + shadcn/ui 또는 직접 구현
Enterprise: 필수 — 독립 패키지로 배포 가능하게
```

### Phase 6 — UI Integration (UI + API 연동)
```
목표: 프론트엔드와 백엔드 실제 연결
산출물:
  - API 클라이언트 (fetch/axios/react-query)
  - 상태 관리 (Zustand, Redux, Context)
  - 에러/로딩 상태 UI
  - 실제 데이터 렌더링

모든 레벨: 핵심 단계
```

### Phase 7 — SEO + Security (SEO + 보안)
```
목표: 검색 노출 + 보안 취약점 제거
산출물:
  - 메타 태그, OG 태그, Sitemap
  - OWASP Top 10 점검 (XSS, SQL Injection 등)
  - HTTPS, CSP, CORS 설정
  - 접근성 (ARIA, 색 대비, 키보드 내비)

Starter:  SEO 기본 (meta, OG)
Dynamic:  보안 + SEO
Enterprise: 전체 보안 감사 + 컴플라이언스
```

### Phase 8 — Review (코드 리뷰 + Gap 분석)
```
목표: 설계 vs 구현 일치도 확인
산출물:
  - 코드 품질 점검 (CLEAN 필요 항목)
  - Gap Analysis (Match Rate %)
  - 기술 부채 목록
  - 리팩토링 권고

Match Rate < 90% → ITERATE 모드 자동 전환
Match Rate ≥ 90% → Phase 9로 진행
```

### Phase 9 — Deployment (배포)
```
목표: 프로덕션 배포 + 모니터링
산출물:
  - 배포 설정 (Vercel/Netlify/Railway/Docker)
  - 환경변수 관리 (.env.example)
  - CI/CD 파이프라인 (GitHub Actions 등)
  - 모니터링/알림 설정

Starter:  Vercel/Netlify 원클릭
Dynamic:  Railway/Fly.io + DB 배포
Enterprise: K8s + Terraform + ArgoCD
```

---

## 레벨별 권장 경로

### Starter (1~3일)
```
Phase 3 (목업) → Phase 5 (디자인) → Phase 7 (SEO) → Phase 9 (배포)
생략 가능: Phase 1, 2, 4, 6, 8
핵심 도구: HTML/CSS, Vercel
```

### Dynamic (1~4주)
```
Phase 1 → Phase 2 → Phase 4 → Phase 3 → Phase 5 → Phase 6 → Phase 7 → Phase 8 → Phase 9
권장 병렬: Phase 3+4 동시, Phase 5+6 연계
핵심 도구: Next.js, BaaS, Vercel
```

### Enterprise (1~3개월)
```
PM 모드 → Phase 1 → Phase 2 → Phase 4 → Phase 3+5 → Phase 6 → Phase 7 → Phase 8 → Phase 9
필수: PM Discovery + PRD → 아키텍처 설계 → 팀 분배
핵심 도구: K8s, Terraform, CI/CD, 마이크로서비스
```

---

## AuraKit 명령어 매핑

| 파이프라인 단계 | AuraKit 명령 | 설명 |
|--------------|-------------|------|
| PM 기획 | `/aura pm:기능명` | OST + JTBD + PRD |
| Phase 1-2 | `/aura build:스키마 정의` | 타입/인터페이스 생성 |
| Phase 3 | `/aura build:목업` | HTML 프로토타입 |
| Phase 4 | `/aura build:API` | REST 엔드포인트 |
| Phase 5 | `/aura build:디자인시스템` | 컴포넌트 라이브러리 |
| Phase 6 | `/aura build:UI 연동` | API 클라이언트 |
| Phase 7 | `/aura review:보안` | OWASP 점검 |
| Phase 8 | `/aura review:` | Gap + 코드 품질 |
| Phase 9 | `/aura deploy:` | Vercel/Docker 배포 |

---

## Pipeline 상태 추적

```
/aura pipeline:status    → 현재 Phase 확인 (.aura/pipeline-state.md)
/aura pipeline:next      → 다음 Phase 안내
/aura pipeline:skip [N]  → 해당 Phase 건너뛰기 (Starter 전용)
```

상태 파일: `.aura/pipeline-state.md`
```markdown
# AuraKit Pipeline State
Level: Dynamic
Current Phase: 4 (API)
Completed: [1, 2, 3]
Remaining: [4, 5, 6, 7, 8, 9]
```

---

*AuraKit Pipeline — 9단계 → 레벨 자동 감지 → 맞춤 경로 제공*
