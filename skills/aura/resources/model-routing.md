# Model Routing — 스마트 모델 라우팅

> AuraKit LEAKFORGE v7.0.0 | COST 모듈
> Sonnet 4.6은 Opus의 98% 코딩 성능(SWE-bench 79.6% vs 80.8%)을 1/5 가격에 제공.
> 올바른 라우팅만으로 최대 ~95% 비용 절감 가능.

---

## Haiku 100% 활용 가이드 [핵심 — 먼저 읽기]

> ECO/PRO 티어에서 Sonnet 한도를 지키는 핵심은 Haiku를 실제로 사용하는 것이다.
> 문서에 "model: haiku"라고 쓰여있어도 Agent 도구를 호출할 때 명시하지 않으면 Sonnet이 기본값이 된다.

### Claude Code에서 Haiku 실제 사용법

```javascript
// ✅ 올바른 Haiku 사용 — Agent 도구에 model 파라미터 명시
Agent({
  subagent_type: "general-purpose",
  model: "haiku",        // ← 이것이 없으면 Sonnet 사용됨
  description: "Scout: 프로젝트 파일 탐색",
  prompt: "다음 파일들을 읽고 프로젝트 구조를 요약해줘: ..."
})

// ❌ 잘못된 방식 — 메인 세션(Sonnet)이 직접 실행
// Glob("**/*.ts") // Sonnet이 직접 읽음 → Sonnet 한도 소진
// Read("package.json") // 위와 동일
```

### 환경변수 설정 (가장 쉬운 방법)

```bash
# .claude/settings.json 또는 환경변수로 설정
export CLAUDE_CODE_SUBAGENT_MODEL="claude-haiku-4-5-20251001"
# 설정 후: model 파라미터 생략해도 모든 서브에이전트가 Haiku 사용
```

### Haiku가 적합한 태스크 vs Sonnet이 필요한 태스크

| 구분 | 태스크 | 모델 |
|------|--------|------|
| ✅ Haiku | 파일 탐색·읽기·구조 파악 | haiku |
| ✅ Haiku | 테스트 실행 + 결과 보고 | haiku |
| ✅ Haiku | 파일 목록 생성 (마이크로 플랜) | haiku |
| ✅ Haiku | Gap 분석·Match Rate 계산 | haiku |
| ✅ Haiku | 스냅샷 파일 쓰기 | haiku |
| ✅ Haiku | 템플릿 채우기 (리포트, PM 분석) | haiku |
| ✅ Haiku | Convention 패턴 체크 | haiku |
| ✅ Haiku | 설계 일관성 비교 (Cross-Check) | haiku |
| ⚠️ Sonnet | 실제 코드 구현 (Builder) | sonnet |
| ⚠️ Sonnet | 코드 품질 리뷰 (Worker-A) | sonnet |
| ⚠️ Sonnet | 보안 취약점 분석 (Worker-B) | sonnet |
| ⚠️ Sonnet | PRD 작성 (PM-PRD) | sonnet |
| 🔴 Opus | 보안 감사·아키텍처 설계 (MAX) | opus |

### 왜 Haiku를 쓰지 못하는가 — 흔한 실수

1. **Scout를 inline 실행**: Agent 도구 없이 Read/Glob 직접 호출 → Sonnet 사용됨
2. **model 파라미터 생략**: Agent 호출하지만 model 미지정 → Sonnet 기본값
3. **Haiku 태스크를 한번에 처리**: "이것도 저것도" → Sonnet이 모든 것 처리
4. **ECO 티어임에도 Worker-C/D를 Sonnet으로**: 명시 없으면 Sonnet 기본

---

## 티어별 모델 배정 (6 Tiers)

### ZERO — 초저가 / 무료 모델 라우팅

```
Scout:      Haiku
Builder:    Haiku + Amplifier v2
Reviewer:   Haiku
TestRunner: Haiku
절감:       ~80% (vs Opus baseline)
호출:       /aura zero [요청]
```

**사용 사례**: 간단한 유틸리티, 스크립트, 프로토타입, 학습 목적
**활성화**: `CLAUDE_CODE_SUBAGENT_MODEL=claude-haiku-4-5-20251001` 환경변수 또는 AnyClaude 라우팅

---

### QUICK — 단일 턴 최속

```
Scout:      (없음)
Builder:    Sonnet
Reviewer:   (없음)
TestRunner: (없음)
절감:       ~60%
호출:       /aura! [요청]
```

**사용 사례**: 색상 변경, 텍스트 수정, 단순 설정 — Discovery/검증 생략

---

### ECO — 기본 (권장)

```
Scout:      Haiku
Builder:    Sonnet
Reviewer:   Sonnet
TestRunner: Haiku
절감:       ~55%
호출:       /aura [요청]
```

**사용 사례**: 일반 기능 구현, 대부분의 개발 작업

---

### PRO — 고품질 Sonnet 강화

```
Scout:      Haiku
Builder:    Sonnet + Amplifier v2  ← (Opus 제거, 2026-04-01)
Reviewer:   Sonnet
TestRunner: Haiku
절감:       ~55% (이전 PRO는 ~20%)
호출:       /aura pro [요청]
```

> **변경 이유**: Sonnet 4.6 SWE-bench 79.6% vs Opus 80.8% — 성능 차이 1.2%,
> 가격 차이 5배. Amplifier v2(7단계)가 성능 차이를 상쇄.
> Opus는 /aura escalate 수동 트리거로만 사용 (명시적 승격).

**사용 사례**: 결제/인증/복잡한 비즈니스 로직 (PAYMENT 모드 기본)

---

### MAX — 전체 Opus

```
Scout:      Sonnet
Builder:    Opus
Reviewer:   Opus
TestRunner: Sonnet
절감:       ~0% (Opus baseline)
호출:       /aura max [요청]
```

**사용 사례**: 보안 감사, 아키텍처 설계, 프로덕션 크리티컬 기능

---

### ESCALATE — 수동 Opus 승격

```
Scout:      (현재 세션 컨텍스트 활용)
Builder:    Opus  ← 서브에이전트로 단일 작업만
Reviewer:   (없음 — 메인 세션이 검토)
TestRunner: (없음 — 메인 세션이 실행)
절감:       작업 규모에 따라 가변
호출:       /aura escalate [특정 작업 설명]
```

**동작**:
1. 현재 작업을 Opus 서브에이전트에 위임
2. 서브에이전트 완료 후 결과를 메인 세션에 반환
3. 메인 세션 모델은 변경 없음 (CACHE-RULE-04 준수)

**사용 사례**: PRO 세션 중 특히 복잡한 알고리즘 1개, 아키텍처 결정 1건

---

## 비용 시뮬레이션

> 기준: 10턴 / 파일 5개 / 서브에이전트 2회
> 실측 기반 추정 (2026-04 기준 Anthropic 공식 요금)

| Tier   | Input Cost | Output Cost | Total  | vs Opus baseline |
|--------|-----------|-------------|--------|-----------------|
| ZERO   | $0.03     | $0.30       | $0.33  | -95%            |
| ECO    | $0.09     | $1.35       | $1.44  | -79%            |
| PRO    | $0.09     | $2.25       | $2.34  | -66%            |
| MAX    | $0.15     | $3.75       | $3.90  | -43%            |
| Opus전체 | $0.25   | $6.50       | $6.75  | baseline        |

**요금 기준 (MTok)**:
| 모델 | Input | Output | Cache Hit |
|------|-------|--------|-----------|
| Haiku 4.5 | $1.00 | $5.00 | $0.10 |
| Sonnet 4.6 | $3.00 | $15.00 | $0.30 |
| Opus 4.6 | $15.00 | $75.00 | $1.50 |

---

## 환경변수 설정 가이드

### 기본 모델 재정의

```bash
# 서브에이전트 기본 모델 변경 (ZERO 티어 활성화)
export CLAUDE_CODE_SUBAGENT_MODEL="claude-haiku-4-5-20251001"

# Haiku 기본 모델 교체
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20251001"

# Sonnet 기본 모델 교체
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-6"

# Opus 기본 모델 교체
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-6"

# 대체 베이스 URL (AnyClaude 연동)
export ANTHROPIC_BASE_URL="http://localhost:3000"
```

### .aura/config.json 설정

```json
{
  "tier": "eco",
  "zero_subagent_model": "claude-haiku-4-5-20251001",
  "escalate_model": "claude-opus-4-6",
  "cost_tracking": true
}
```

---

## AnyClaude 연동 가이드

> AnyClaude 0.5.0: 7단계 파이프라인으로 서브에이전트를 대체 백엔드로 라우팅
> (extract → routing → headers → thinking → forward → transform → response)

### 설치

```bash
npm install -g anyclaude
anyclaude config set backend openai  # 또는 groq, together, local
```

### .claude/settings.json 연동

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:3000",
    "CLAUDE_CODE_SUBAGENT_MODEL": "gpt-4o-mini"
  }
}
```

### agents.md 스타일 설정 (ZERO 티어)

```toml
[agents]
subagent_backend = "alternative"
subagent_model = "gpt-4o-mini"    # 또는 llama-3.1-8b 등
main_model = "claude-sonnet-4-6"  # 메인은 Sonnet 유지
```

### ZERO 티어 전체 설정 예시

```bash
# 1. AnyClaude 실행
anyclaude serve --port 3000 --backend groq --model llama-3.1-70b

# 2. 환경변수 설정
export ANTHROPIC_BASE_URL="http://localhost:3000"
export CLAUDE_CODE_SUBAGENT_MODEL="llama-3.1-70b"

# 3. AuraKit ZERO 티어 실행
/aura zero [작업 설명]
```

---

## /aura escalate 사용법

```bash
# PRO 세션 중 특정 복잡 작업만 Opus로 승격
/aura escalate: 현재 인증 미들웨어의 JWT 리프레시 토큰 로직을 재설계해줘

# 결과: Opus 서브에이전트가 해당 작업 실행 후 메인 Sonnet 세션으로 복귀
# 메인 세션 모델 불변 (CACHE-RULE-04 준수)
```

**ESCALATE 흐름**:
```
메인 세션 (Sonnet)
  └─ /aura escalate 감지
     └─ Opus 서브에이전트 spawn
        └─ 작업 실행 (단일 작업 한정)
        └─ 결과 반환
     └─ 메인 세션에서 결과 통합
  └─ 다음 작업 계속 (Sonnet 유지)
```

**HEALER 자동 ESCALATE**: HEALER Phase 3에서 해결 불가 시 `/aura escalate` 자동 제안

---

## 티어 선택 가이드

```
질문 1: 작업이 단순한가? (설정 변경, 텍스트 수정)
  → YES: QUICK (/aura! 요청)
  → NO: 질문 2

질문 2: 비용을 최소화해야 하는가? (학습, 프로토타입)
  → YES: ZERO (/aura zero 요청)
  → NO: 질문 3

질문 3: 결제/보안/복잡한 비즈니스 로직인가?
  → YES: PRO (/aura pro 요청) — Sonnet+Amplifier v2
  → NO: ECO (/aura 요청) — 기본 권장

질문 4: 보안 감사/아키텍처 설계/프로덕션 크리티컬?
  → YES: MAX (/aura max 요청)
  → 특정 작업 1건만: /aura escalate

결론: 대부분의 작업 = ECO, 특수 작업 = PRO/escalate
```

---

*Reference: LEAKFORGE v7.0.0 — Anthropic 유출 소스 기반 모델 성능 분석 (2026-03-31)*
