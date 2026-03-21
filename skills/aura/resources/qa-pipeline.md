# AuraKit — QA Pipeline (Zero-Script QA 3-Phase)

> `/aura qa:` 또는 `/aura qa:[범위]` 호출 시 로딩.
> 테스트 코드 없이 실제 실행 로그와 curl로 검증. Zero-Script QA.

---

## 역할

- 테스트 스크립트 없이 실제 동작 검증
- Docker 로그 모니터링 + curl API 테스트 + 응답시간 측정
- 산출물: QA 리포트 + 이슈 목록

---

## 3-Phase 실행 순서

### Phase 1 — Discovery (범위 정의)

```bash
# 변경 파일 파악
git diff --name-only HEAD~1 HEAD

# 관련 API 엔드포인트 탐색
grep -r "app.get\|app.post\|router.get\|router.post\|export.*GET\|export.*POST" src/ --include="*.ts" -l

# 포트 및 서비스 확인
cat package.json | grep '"start"\|"dev"\|"port"'
cat .env.example 2>/dev/null | grep PORT
```

탐색 결과로 테스트 대상 분류:
- **API 엔드포인트**: curl 테스트 대상
- **UI 컴포넌트**: 브라우저 로그 대상
- **통합 포인트**: Docker 로그 모니터링 대상

---

### Phase 2 — Execution (검증 실행)

#### 2-1. API 테스트 (QA-API 에이전트, haiku, context:fork)

```bash
# 서비스 실행 상태 확인
curl -s http://localhost:3000/api/health || echo "서비스 미실행"

# GET 엔드포인트 테스트
curl -s -w "\nHTTP Status: %{http_code}\nTime: %{time_total}s\n" \
  http://localhost:3000/api/[endpoint]

# POST 엔드포인트 테스트 (인증 없이)
curl -s -X POST http://localhost:3000/api/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}' \
  -w "\nStatus: %{http_code}"

# 인증 필요 엔드포인트 (쿠키 기반)
curl -s -X POST http://localhost:3000/api/[endpoint] \
  -H "Content-Type: application/json" \
  -b "session=[test-session]" \
  -d '{"field": "value"}'

# 에러 케이스 — 잘못된 입력
curl -s -X POST http://localhost:3000/api/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{}' \
  -w "\nStatus: %{http_code}"

# 예상 응답: 400 (입력 검증 실패)
```

응답 검증 체크리스트:
- `200/201`: 정상 응답 + `{ success: true, data: ... }` 형식
- `400`: 입력 검증 실패 + `{ success: false, error: "VALIDATION_ERROR" }` 형식
- `401`: 인증 필요 + `{ success: false, error: "UNAUTHORIZED" }` 형식
- `500`: 내부 오류 + `{ success: false, error: "INTERNAL_ERROR" }` 형식

#### 2-2. Docker 로그 모니터링 (QA-Monitor 에이전트, haiku, context:fork)

```bash
# Docker 실행 중이면 로그 수집
docker ps --format "{{.Names}}" 2>/dev/null

# 서비스 로그 실시간 모니터링 (30초)
docker logs [container-name] --since 30s 2>&1 | tail -50

# 에러 패턴 검색
docker logs [container-name] 2>&1 | grep -iE "error|exception|fatal|crash" | tail -20

# 데이터베이스 연결 확인
docker logs [container-name] 2>&1 | grep -i "connected\|connection refused\|timeout" | tail -10
```

#### 2-3. 보안 QA (QA-Security 에이전트, sonnet, context:fork)

```bash
# CORS 헤더 확인
curl -s -I -X OPTIONS http://localhost:3000/api/[endpoint] \
  -H "Origin: http://evil.com" | grep -i "access-control"
# 예상: evil.com이 Allow-Origin에 없어야 함

# 응답에 민감 정보 노출 확인
curl -s http://localhost:3000/api/[endpoint] | \
  grep -iE "password|secret|private_key|api_key" && \
  echo "⚠️ 민감 정보 노출 가능성" || echo "✅ 민감 정보 없음"

# 에러 메시지 스택 트레이스 노출 확인
curl -s -X POST http://localhost:3000/api/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {}}' | grep -i "stack\|at " && \
  echo "⚠️ 스택 트레이스 노출" || echo "✅ 안전"
```

#### 2-4. 성능 측정 (QA-Performance 에이전트, haiku, context:fork)

```bash
# 응답시간 측정 (5회 평균)
for i in {1..5}; do
  curl -s -o /dev/null -w "%{time_total}\n" http://localhost:3000/api/[endpoint]
done | awk '{ sum += $1; count++ } END { printf "평균: %.3fs (%d회)\n", sum/count, count }'

# 동시 요청 처리 (기본 부하)
for i in {1..10}; do
  curl -s http://localhost:3000/api/[endpoint] &
done
wait
echo "10개 동시 요청 완료"
```

---

### Phase 3 — Report (결과 보고)

```markdown
# QA Report: [기능명]
날짜: [날짜]

## 요약

| 항목 | 결과 |
|------|------|
| 테스트 범위 | [N]개 엔드포인트 |
| API 테스트 | [Pass/Fail] |
| 보안 검사 | [Pass/Fail] |
| 성능 기준 | [P/F] (<500ms) |
| Docker 로그 | [이상 없음 / N개 에러] |

## 상세 결과

### API 테스트
- ✅ GET /api/[endpoint]: 200 OK (123ms)
- ✅ POST /api/[endpoint]: 201 Created (89ms)
- ✅ POST /api/[endpoint] 잘못된 입력: 400 VALIDATION_ERROR
- ❌ POST /api/[endpoint] 미인증: 200 반환 (예상: 401) → 버그

### 보안
- ✅ CORS: 화이트리스트 적용 확인
- ✅ 민감 정보 노출 없음
- ✅ 스택 트레이스 미노출

### 성능
- 평균 응답시간: [N]ms (기준: <500ms)
- 동시 10개 요청: 모두 성공

### Docker 로그 이상
- [없음 또는 에러 내용]

## 발견된 이슈

| ID | 심각도 | 내용 | 재현 방법 |
|----|--------|------|---------|
| QA-001 | HIGH | 미인증 접근 허용 | POST /api/endpoint 쿠키 없이 요청 |

## 다음 단계
- [ ] QA-001 수정 → `/aura fix:` 실행
- [ ] 수정 후 QA 재실행
```

---

## 에이전트 배정

| 에이전트 | 모델 | 역할 |
|---------|------|------|
| QA-Coordinator | sonnet | 범위 결정, 리포트 종합 |
| QA-API | haiku | curl API 테스트 실행 |
| QA-Security | sonnet | OWASP L3 보안 검사 |
| QA-Performance | haiku | 응답시간 측정 |
| QA-Monitor | haiku | Docker 로그 분석 |

QA-API + QA-Security + QA-Performance + QA-Monitor → 4개 병렬 실행

---

## 빠른 시작

```bash
/aura qa:              → 현재 변경사항 전체 QA
/aura qa:api           → API 엔드포인트 집중 QA
/aura qa:security      → 보안 취약점 QA
/aura qa:performance   → 성능 측정만
/aura pro qa:결제 시스템 → opus QA-Security로 고품질 보안 검사
```

---

*AuraKit QA — Zero-Script · 4에이전트 병렬 · curl + Docker logs + 응답시간 측정*
