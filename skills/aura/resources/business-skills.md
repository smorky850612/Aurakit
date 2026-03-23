# AuraKit — Business & Content Skills

> 개발 너머의 영역. 콘텐츠 제작, 시장 조사, 투자자 자료까지 `/aura content:`로 통합.
> AuraKit 단일 진입점 아이덴티티 유지 — 모든 것이 `/aura`를 통해.

---

## CONTENT 모드 진입

```bash
/aura content:blog [주제]       → SEO 최적화 블로그 포스트
/aura content:market [분야]     → 시장 조사 리포트
/aura content:investor          → 투자자 자료 (IR 덱 구조)
/aura content:product [제품명]  → 제품 설명서 / 기능 매뉴얼
/aura content:email [목적]      → 마케팅 이메일 시퀀스
/aura content:social [플랫폼]   → SNS 콘텐츠 캘린더
/aura content:docs [기능명]     → 기술 문서 (API Docs, README)
/aura content:pitch [아이디어]  → 스타트업 피치 덱 구조
```

---

## Blog Post Pipeline

### 구조
```
Discovery (주제 확인):
  → 타겟 독자 정의
  → 핵심 메시지 1줄
  → SEO 키워드 선정 (3~5개)

작성 순서:
  1. 제목 3개 후보 (클릭률 최적화)
  2. 메타 설명 (150자 이내)
  3. 목차 (H2 기준 4~6개)
  4. 본문 작성 (섹션별)
  5. CTA (Call to Action)
  6. 내부 링크 제안

SEO 체크:
  □ 주요 키워드 제목 포함
  □ 첫 단락에 키워드 등장
  □ 이미지 alt 텍스트
  □ 읽기 시간: 5~8분 (1200~2000자)
  □ 소제목에 키워드 변형
```

### 출력 포맷
```markdown
# [최적화된 제목]

**요약**: [2-3문장 핵심 요약]
**읽기 시간**: N분 | **난이도**: 입문/중급/고급

---

## 목차
1. [섹션 1]
2. [섹션 2]
...

## [섹션 1]
[본문]

...

## 마치며
[핵심 요약 + CTA]
```

---

## Market Research Pipeline

### 구조
```
1. 시장 규모 분석
   → TAM (전체 시장)
   → SAM (유효 시장)
   → SOM (획득 가능 시장)

2. 경쟁사 분석 (3~5개)
   → 포지셔닝 매트릭스
   → 강점/약점
   → 가격 전략

3. 고객 세그먼트
   → 주요 페르소나 2~3개
   → JTBD (Jobs-to-be-Done)
   → Pain Points

4. 트렌드 분석
   → 성장 드라이버
   → 위협 요소

5. 진입 전략 제안
```

### 출력 포맷
```markdown
# [분야] 시장 조사 리포트
작성일: [날짜] | 조사 기간: [기간]

## Executive Summary
[3~5문장 핵심 인사이트]

## 시장 규모
| 구분 | 규모 | 성장률 |
|------|------|-------|
| TAM  | $XXB | X%    |
| SAM  | $XXB | X%    |
| SOM  | $XXM | X%    |

## 경쟁사 분석
[경쟁사별 표]

## 고객 페르소나
[페르소나 카드]

## 기회와 위협
[SWOT 간략 버전]

## 권장 진입 전략
[전략 제안]
```

---

## Investor Materials Pipeline

### IR 덱 구조 (12슬라이드)
```
슬라이드 1: 표지 (회사명, 슬로건, 날짜)
슬라이드 2: 문제 (Pain Point — 데이터로 증명)
슬라이드 3: 솔루션 (제품/서비스 핵심)
슬라이드 4: 시장 규모 (TAM/SAM/SOM)
슬라이드 5: 제품 (스크린샷/데모)
슬라이드 6: 비즈니스 모델 (수익화 방법)
슬라이드 7: 견인력 (Traction — 지표, 사용자 수)
슬라이드 8: 경쟁 포지셔닝 (매트릭스)
슬라이드 9: 팀 (창업자 + 핵심 멤버)
슬라이드 10: 재무 계획 (3년 예측)
슬라이드 11: 투자 요청 (금액, 사용 계획)
슬라이드 12: 비전 (3~5년 후 모습)
```

### Executive Summary (1페이지)
```markdown
# [회사명] — [한 줄 설명]

**문제**: [구체적 Pain Point]
**솔루션**: [제품/서비스]
**시장**: TAM $XXB, SAM $XXB
**견인력**: [MAU/ARR/성장률 등 핵심 지표]
**팀**: [창업자 배경 핵심]
**투자 요청**: [금액] for [목적 2~3가지]
**연락처**: [이메일]
```

---

## Technical Docs Pipeline

### API 문서 포맷 (OpenAPI 호환)
```markdown
## POST /api/v1/users

사용자를 생성합니다.

**인증**: Bearer Token 필요

**요청 본문**
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| email | string | ✅ | 이메일 주소 (최대 255자) |
| name | string | ✅ | 사용자 이름 (최대 100자) |

**응답 (201 Created)**
```json
{
  "success": true,
  "data": {
    "id": "user_01HXXX",
    "email": "user@example.com",
    "name": "홍길동",
    "createdAt": "2026-01-01T00:00:00Z"
  }
}
```

**에러 코드**
| 코드 | HTTP | 설명 |
|------|------|------|
| EMAIL_EXISTS | 409 | 이미 사용 중인 이메일 |
| VALIDATION_ERROR | 400 | 입력값 형식 오류 |
```

---

## Product Docs Pipeline (content:product)

### 제품 설명서 구조
```
1. 개요 (What & Why)
   → 제품이 해결하는 문제 1줄
   → 핵심 기능 3가지

2. 시작하기 (Getting Started)
   → 설치 / 가입 단계
   → 첫 번째 성공 경험 (5분 이내)

3. 기능별 매뉴얼
   → 각 기능: 목적 → 사용 방법 → 예시 → 주의사항

4. FAQ
   → 상위 10개 질문 (지원팀 데이터 기반)

5. 문제 해결 (Troubleshooting)
   → 증상 → 원인 → 해결 순서
```

---

## Pitch Deck Pipeline (content:pitch)

### 스타트업 피치 구조 (5분 버전)
```
슬라이드 1: 훅 (Hook) — 청중이 공감할 문제 1가지
슬라이드 2: 문제 (Problem) — 데이터로 증명된 Pain Point
슬라이드 3: 솔루션 (Solution) — 제품 핵심 가치 1줄
슬라이드 4: 데모 또는 스크린샷
슬라이드 5: 시장 규모 + 비즈니스 모델
슬라이드 6: 견인력 (Traction) — 현재 지표
슬라이드 7: 팀 + 투자 요청
```

### 엘리베이터 피치 (30초 버전)
```
[회사명]은 [고객 유형]이 [문제]를 해결하도록 돕는 [제품 카테고리]입니다.
[경쟁사]와 달리 [핵심 차별점]으로 이미 [traction 지표]를 달성했습니다.
```

---

## Email Marketing Pipeline

### 이메일 시퀀스 구조
```
온보딩 시퀀스 (5개):
  Day 0: 환영 이메일 (제품 핵심 가치 1가지)
  Day 1: 첫 번째 성공 경험 유도
  Day 3: 고급 기능 소개
  Day 7: 소셜 증거 (사용자 후기)
  Day 14: 전환 유도 (업그레이드/결제)

각 이메일 구조:
  제목: [이익] 또는 [호기심] 또는 [긴급성]
  서두: 1~2문장 (본론 바로)
  본문: 핵심 1가지 (여러 개 금지)
  CTA: 버튼 1개 (클릭 유도 문구)
```

---

## Social Media Pipeline

### 플랫폼별 최적화
```
LinkedIn:
  - 길이: 1200~1500자
  - 형식: 첫 줄 훅 + 개행 + 본문 + CTA
  - 해시태그: 3~5개

Twitter/X:
  - 스레드: 10~15트윗
  - 첫 트윗: 핵심 가치 + 숫자
  - 마지막: RT/팔로우 요청

Instagram:
  - 캡션: 150자 이내 (더 보기 전)
  - 해시태그: 20~30개 (첫 댓글에)
  - 이미지 비율: 1:1 또는 4:5
```

---

## CONTENT 모드 공통 프로토콜

```
1. Discovery (2분):
   → 타겟 독자 확인
   → 목적 (인지도/전환/교육/SEO)
   → 톤앤매너 (전문적/친근/권위)

2. 초안 생성 (Scout로 참고 자료 수집)

3. 검토:
   → 사실 확인 필요 항목 표시 [검증 필요]
   → 숫자/데이터는 출처 표기

4. 저장: .aura/content/[type]-[slug].md
```

---

*AuraKit Business Skills — Blog · Market Research · Investor IR · Tech Docs · Email · Social*
