# AuraKit — 공통 프로토콜 (B-1 ~ B-5 상세)

> 모든 모드 실행 전 필수 프로토콜 상세.
> SKILL.md에서 참조 — 각 단계별 상세 로직.

---

## B-0. 세션 캐시 체크 [속도 최적화 — v5.0 신규]

```bash
SESSION_FILE=".aura/runtime/session.json"
SESSION_EXPIRE=7200  # 2시간

if [ -f "$SESSION_FILE" ]; then
  SESSION_AGE=$(( $(date +%s) - $(date -r "$SESSION_FILE" +%s 2>/dev/null || echo 0) ))
  if [ "$SESSION_AGE" -lt "$SESSION_EXPIRE" ]; then
    # 캐시 유효 → B-1, B-5 건너뜀 (이미 로딩됨)
    echo "⚡ 세션 캐시 유효 → 빠른 시작"
    # B-2, B-3, B-4만 실행
    skip_b1=true
    skip_b5=true
  fi
fi
```

세션 파일 생성/갱신 (B-5 완료 후):
```json
{
  "sessionId": "uuid",
  "startedAt": "ISO",
  "profile": "loaded",
  "memory": "loaded",
  "instincts": "loaded",
  "language": "TypeScript",
  "framework": "Next.js"
}
```

---

## B-1. 프로젝트 프로필 체크 [필수]

### 프로필 존재 확인

```bash
if [ -f ".aura/project-profile.md" ]; then
  # Read 도구로 로딩 (0 LLM 토큰)
  echo "프로필 캐시 로딩"
else
  echo "Scout 에이전트 실행 → 프로필 생성"
fi
```

### ConfigHash 기반 캐시 무효화 (v4.0)

```bash
# 현재 ConfigHash 계산 (의존성 파일 기준)
CURRENT_HASH=$(md5sum package.json go.mod pyproject.toml Dockerfile 2>/dev/null | md5sum | cut -d' ' -f1)

# 저장된 ConfigHash 확인
SAVED_HASH=$(grep "ConfigHash:" .aura/project-profile.md 2>/dev/null | awk '{print $2}')

if [ "$CURRENT_HASH" != "$SAVED_HASH" ]; then
  echo "의존성 변경 감지 → Scout 재실행"
fi
```

project-profile.md 포맷:
```markdown
# Project Profile
ConfigHash: [md5값]
Language: TypeScript/Python/Go/...
Framework: Next.js/FastAPI/...
PackageManager: npm/pnpm/yarn/bun/pip/poetry
TestTool: jest/vitest/pytest/go test
BuildTool: tsc/vite/webpack
Level: Starter / Dynamic / Enterprise
MainDirs: src/, app/, api/, components/
```

### Scout 실행 (프로필 없을 때)

```
Scout 에이전트 (model: haiku):
  탐색 항목:
    - 언어/프레임워크 (package.json, go.mod, pyproject.toml)
    - 주요 디렉토리 구조
    - 테스트 도구, 패키지 매니저, 빌드 도구
    - 복잡도: Starter / Dynamic / Enterprise
      Starter:    정적 사이트, 백엔드 없음
      Dynamic:    풀스택, 로그인/DB 포함
      Enterprise: 마이크로서비스, k8s/, Dockerfile 다수
  출력:
    .aura/project-profile.md (ConfigHash 포함)
    .aura/design-system.md (CSS 변수 목록)
```

---

## B-2. 보안 L1 + L5 확인 [필수]

```bash
# L1: .aura 디렉토리 확인
[ -d ".aura" ] || mkdir -p ".aura"

# L1: .env → .gitignore 확인
if [ -f ".env" ]; then
  if ! grep -q "^\.env$\|^\.env\." .gitignore 2>/dev/null; then
    echo "⚠️  경고: .env가 .gitignore에 없습니다!"
    echo "  → echo '.env' >> .gitignore 실행 필요"
  fi
fi

# L5: 의존성 취약점 검사 (BUILD/FIX 모드에서 자동)
if [ -f "package.json" ]; then
  npm audit --audit-level=high 2>&1 | grep -E "HIGH|CRITICAL" && echo "⚠️  HIGH 이상 취약점 존재"
fi
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  pip check 2>&1 | grep -v "No broken requirements" && echo "⚠️  Python 의존성 문제"
fi
```

이상 감지 시: 즉시 작업 중단 + 사용자 안내 후 해결 요청.

---

## B-3. 디자인 시스템 로딩 [필수 — UI 파일 생성 시]

```bash
if [ -f ".aura/design-system.md" ]; then
  echo "디자인 시스템 로딩"
else
  echo "기본 디자인 시스템 복사"
  cp "skills/aura/templates/design-system-default.md" ".aura/design-system.md"
fi
```

규칙:
- 하드코딩 색상값 금지: `#2563eb` → `var(--color-primary)` [CONV-004 자동 감지]
- 하드코딩 픽셀값 금지: `16px` → `var(--spacing-md)`

---

## B-4. 스냅샷 복구 체크 [필수]

```bash
SNAPSHOT=".aura/snapshots/current.md"

if [ -f "$SNAPSHOT" ]; then
  echo "이전 작업을 이어서 진행합니다:"
  cat "$SNAPSHOT"
  echo "→ 계속하려면 Enter, 새 작업은 '/aura [새 요청]'"
else
  echo "새 작업 시작"
fi
```

---

## B-5. 크로스세션 메모리 + 에이전트 메모리 + 팀 컨텍스트

### 크로스세션 메모리

```
파일: .aura/memory.md
→ 있으면: 아키텍처 결정사항·팀 규칙·반복 패턴 로딩
→ 없으면: 건너뜀 (중요 결정 발생 시 자동 기록)
포맷: ## [날짜] [주제]\n내용\n
```

### Instinct 로딩 (v5.0 신규 — 쓸수록 똑똑해짐)

```
파일: .aura/instincts/index.json
→ 없으면: 건너뜀 (첫 사용)
→ 있으면:
   1. 현재 language + framework로 필터
   2. score > 40 패턴만 선택
   3. 상위 5개 로딩 → 컨텍스트 주입
   4. anti-patterns 전체 로딩 (실수 자동 방지)
→ 상세: resources/instinct-system.md
```

### 에이전트 메모리

```
디렉토리: .aura/agent-memory/
저장 시점: 각 에이전트 완료 시 자동 저장 (teammate-idle.js 훅)
포맷: {agent, timestamp, promptHash, result, status}
예시: Scout → .aura/agent-memory/scout.json
      Builder가 scout.json 읽어 관련 파일 파악
```

### 팀 컨텍스트 (v4.0 신규)

```
.aura/team/           ← git 포함, 팀 공유 가능
  decisions.md        ← 아키텍처 결정 기록 (ADR 형식)
  conventions.md      ← 코딩 컨벤션
  glossary.md         ← 도메인 용어 정의
```

decisions.md 포맷 (ADR):
```markdown
## ADR-001: [결정 제목]
날짜: YYYY-MM-DD
상태: 결정됨 / 검토중 / 폐기됨
컨텍스트: [왜 이 결정이 필요했는가]
결정: [무엇을 결정했는가]
결과: [예상 영향]
```

conventions.md 포맷:
```markdown
## 네이밍 규칙
- 컴포넌트: PascalCase
- 훅: use[Name] 접두사
- API 경로: /api/[resource] kebab-case

## 보안 규칙
- SQL: Parameterized query 필수 [CONV-001]
- CSS: 디자인 시스템 변수 사용 [CONV-004]
```

로딩 시점: B-5에서 `.aura/team/conventions.md` 확인 → 있으면 로딩

---

## Discovery 프로토콜 (BUILD Step 0)

5가지 검토 (생략 불가):

```
1. 실제 문제가 무엇인가?
   → 표면적 요청 vs 핵심 문제 구분
   예) "로그인 버그" → 실제: "세션 만료 처리 누락"

2. 이미 있는 것은 없는가?
   → Scout로 기존 구현 탐색
   → 중복 구현 방지 (YAGNI)

3. 최소 구현으로 목표 달성 가능한가?
   → 과도한 추상화 금지
   → 현재 요구사항에 맞는 최소 범위

4. 구현 범위 명확화
   → 포함: [기능 목록]
   → 제외: [의도적으로 생략한 항목]

5. 성공 기준 (완료 조건)
   → 완료: [측정 가능한 조건]
```

Discovery 출력 후 즉시 구현 시작. 모호한 항목만 사용자 확인.

---

## Git Worktree 격리 (Step 0.5 — 신규 기능 시 권장)

```bash
# 기능 브랜치 + Worktree 생성
TASK_NAME=$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
git worktree add ".aura/worktree/${TASK_NAME}" -b "aura/${TASK_NAME}" 2>/dev/null || \
  echo "Worktree 생성 실패 → 메인 브랜치에서 계속"

# 작업 완료 후 정리
git worktree remove ".aura/worktree/${TASK_NAME}" --force
git worktree prune
```

주의: Worktree 없어도 작업 진행 가능. Git 2.5+ 필요.

---

*AuraKit Common Protocol — B-0~B-5 상세 · 세션 캐시 · ConfigHash 캐시 · Instinct 로딩 · 팀 컨텍스트 · Discovery 5검토*
