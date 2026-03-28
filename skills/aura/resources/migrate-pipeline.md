# MIGRATE 모드 — 마이그레이션 전문 파이프라인

> DB 스키마, API 버전, 프레임워크 업그레이드 등 안전한 마이그레이션.

## 트리거
```bash
/aura migrate: prisma schema 변경
/aura migrate: Next.js 14 → 15
/aura migrate: REST → GraphQL
/aura migrate: 의존성 업그레이드
```

## 마이그레이션 유형

### 1. DB 마이그레이션
- 현재 스키마 분석
- 마이그레이션 파일 생성 (Prisma/Drizzle/TypeORM)
- **롤백 플랜 필수 작성** — DOWN 마이그레이션 포함
- 단계별 검증 (스테이징 → 프로덕션)

### 2. 프레임워크 버전업
- Breaking changes 목록화 (공식 마이그레이션 가이드 참조)
- 영향 범위 파악 (codemod 가능 여부)
- 단계별 패치 적용

### 3. API 버전 마이그레이션
- v1 → v2 라우트 병렬 운영 기간 설정
- Deprecation warning 추가
- 클라이언트 마이그레이션 가이드 생성

## 파이프라인

1. **영향 분석** (Scout) — 변경 범위, 위험도 평가
2. **롤백 플랜 작성** — 실패 시 되돌리는 방법 명시
3. **단계별 마이그레이션** — 작은 단계로 나눠서 검증
4. **3중 검증** — V1(빌드) + V2(Reviewer) + V3(테스트)
5. **커밋** — `chore(migrate): [설명]`

## 안전 규칙
- DB 마이그레이션은 항상 트랜잭션 내 실행
- 프로덕션 데이터가 있는 경우 → `.env.production` 확인 필수
- 롤백 플랜 없으면 → 시작 전 롤백 플랜 먼저 작성
