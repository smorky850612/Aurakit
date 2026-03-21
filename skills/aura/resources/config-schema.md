# AuraKit — .aura/config.json 스키마 (G13)

> 프로젝트 루트의 `.aura/config.json`으로 AuraKit 동작을 커스터마이즈한다.

---

## 전체 스키마

```json
{
  "$schema": "https://aurakit.dev/schemas/config.json",
  "version": "1.0",

  "tier": "eco",
  "outputStyle": "expert",

  "thresholds": {
    "matchRate": 90,
    "maxIterations": 5,
    "bloatLines": 250,
    "testCoverage": 80
  },

  "security": {
    "level": "L4",
    "auditLog": true,
    "blockSecrets": true,
    "warnSqlRaw": true
  },

  "agents": {
    "scout": "haiku",
    "builder": "sonnet",
    "reviewer": "sonnet",
    "testRunner": "haiku",
    "security": "sonnet"
  },

  "compact": {
    "threshold": 65,
    "autoSnapshot": true
  },

  "features": {
    "gitWorktree": true,
    "gracefulCompact": true,
    "progressTracker": true,
    "agentMemory": true,
    "designSystem": true
  },

  "paths": {
    "snippets": ".aura/snippets",
    "agentMemory": ".aura/agent-memory",
    "snapshots": ".aura/snapshots",
    "docs": ".aura/docs"
  },

  "tokenLimits": {
    "daily": 500000,
    "weekly": 2000000
  }
}
```

---

## 필드 설명

### tier
기본 모델 티어. 명시적 호출 (`/aura pro ...`)로 덮어쓸 수 있다.
- `"quick"` — sonnet만 사용, 가장 빠름
- `"eco"` — haiku + sonnet, 기본값
- `"pro"` — haiku + sonnet + opus(Builder)
- `"max"` — opus 전체

### outputStyle
기본 출력 스타일.
- `"expert"` — 핵심만, 파일:줄번호 참조 (기본)
- `"learning"` — 주석 풍부, 이유 설명
- `"concise"` — 최대 3줄 응답

### thresholds.matchRate
ITERATE 모드 완료 기준 Match Rate (%). 기본: 90.

### thresholds.maxIterations
ITERATE 모드 최대 반복 횟수. 기본: 5.

### thresholds.bloatLines
bloat-check 경고 줄 수 기준. 기본: 250.

### thresholds.testCoverage
테스트 커버리지 목표 (%). 기본: 80.

### security.level
보안 검사 수준.
- `"L1"` — .env/.gitignore 검사만
- `"L3"` — OWASP Top 10 코드 리뷰
- `"L4"` — 시크릿 패턴 차단 (기본)
- `"L5"` — 의존성 취약점 포함

### agents
에이전트별 모델 오버라이드. tier 설정보다 우선한다.

```json
"agents": {
  "builder": "opus"  // Builder만 opus로, 나머지는 tier 따름
}
```

### compact.threshold
자동 compact 트리거 컨텍스트 비율 (%). 기본: 65.

### features
개별 기능 활성화/비활성화.

---

## 최소 설정 예시

```json
{
  "tier": "pro",
  "thresholds": {
    "matchRate": 85,
    "maxIterations": 3
  }
}
```

## 팀 공유 설정 (git 포함)

```bash
# 팀 공유용 — 민감 정보 없음
git add .aura/config.json

# 개인 오버라이드 — git 제외
echo ".aura/config.local.json" >> .gitignore
```

`.aura/config.local.json`이 있으면 `config.json`을 덮어쓴다 (딥 병합).

---

## 설정 로딩 순서

```
1. 기본값 (SKILL.md 정의)
2. .aura/config.json (프로젝트)
3. .aura/config.local.json (개인, git 제외)
4. 명시적 명령 옵션 (/aura pro ..., /aura max ...)
```

높은 번호가 낮은 번호를 덮어쓴다.
