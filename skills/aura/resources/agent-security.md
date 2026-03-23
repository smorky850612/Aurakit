# AuraKit — Agent Security (G20)

> 에이전트별 권한 분리 · disallowed-tools · 최소 권한 원칙

---

## 개요

AuraKit의 에이전트는 역할에 따라 도구 접근 권한이 다르다.
"빌더는 쓰고, 리뷰어는 읽기만" — 최소 권한 원칙.

---

## 에이전트별 권한 매트릭스

| 에이전트 | Read | Write | Edit | Bash | Glob/Grep | Agent | 목적 |
|---------|------|-------|------|------|-----------|-------|------|
| Scout   | ✅   | ❌    | ❌   | 제한 | ✅        | ❌    | 탐색만 |
| Builder | ✅   | ✅    | ✅   | ✅   | ✅        | ❌    | 구현 |
| Reviewer| ✅   | ❌    | ❌   | 제한 | ✅        | ❌    | 읽기+검토 |
| Tester  | ✅   | ❌    | ❌   | ✅   | ✅        | ❌    | 테스트 실행 |
| Security| ✅   | ❌    | ❌   | 제한 | ✅        | ❌    | 감사 |
| Debugger| ✅   | ✅    | ✅   | ✅   | ✅        | ❌    | 수정 허용 |
| CTO     | ✅   | ✅    | ✅   | ✅   | ✅        | ✅    | 오케스트레이션 |

---

## Skills 2.0 Frontmatter 기반 권한

SKILL.md frontmatter에서 에이전트 권한 선언:

```yaml
---
name: aura-scout
description: 프로젝트 탐색 전용 에이전트. 읽기 전용.
disallowed-tools:
  - Write
  - Edit
  - Bash
model: claude-haiku-4-5-20251001
---
```

```yaml
---
name: aura-reviewer
description: 코드 리뷰 전용. 파일 수정 불가.
disallowed-tools:
  - Write
  - Edit
model: claude-sonnet-4-6
---
```

```yaml
---
name: aura-security
description: 보안 감사 전용. 외부 네트워크 접근 불가.
disallowed-tools:
  - Write
  - Edit
  - WebFetch
  - WebSearch
model: claude-sonnet-4-6
---
```

---

## Bash 명령 제한 패턴

Reviewer/Security 에이전트는 Bash를 허용하되 안전 명령만 실행:

```javascript
// bash-guard.js — 에이전트 컨텍스트별 명령 필터링
const REVIEWER_ALLOWED = [
  /^git (log|diff|status|show)/,
  /^npm (audit|list)/,
  /^npx (tsc|eslint)/,
];

const SECURITY_ALLOWED = [
  /^git (log|diff|blame)/,
  /^grep /,
  /^find /,
];

// 에이전트 타입 감지 (환경변수 또는 프롬프트 분석)
const agentRole = process.env.AURA_AGENT_ROLE || 'builder';

if (agentRole === 'reviewer') {
  const allowed = REVIEWER_ALLOWED.some(r => r.test(command));
  if (!allowed) block(`Reviewer 에이전트: '${command}' 실행 불가`);
}
```

---

## 에이전트 호출 시 권한 명시

AuraKit에서 에이전트를 호출할 때 프롬프트에 역할을 명시:

```javascript
// BUILD Step 4 — 에이전트 호출
{
  subagent_type: "Explore",   // 읽기 전용 탐색 에이전트
  prompt: `[ROLE: reviewer] 아래 코드를 검토하라.
파일 수정 금지. 이슈 목록만 반환.
...`
}
```

```javascript
// REVIEW 모드 — Security Worker
{
  subagent_type: "bkit:security-architect",
  prompt: `[ROLE: security-auditor] OWASP Top 10 기준으로 감사.
외부 요청 금지. 현재 코드만 분석.
...`
}
```

---

## 크로스 에이전트 데이터 흐름 보안

```
[Scout (read-only)]
    ↓ (파일 경로 목록만 전달)
[Builder (read+write)]
    ↓ (구현 결과 경로만 전달)
[Reviewer (read-only)]
    ↓ (이슈 목록만 반환)
[CTO (orchestrator)]
```

**규칙**:
- 에이전트 간 데이터는 `.aura/agent-memory/[type].json` 경유
- 시크릿, 환경변수는 에이전트 프롬프트에 직접 포함 금지
- 에이전트 결과는 500자 이내로 요약 (전체 파일 내용 전달 금지)

---

## 보안 L5 — 에이전트 격리

```
격리 레벨:
  L1: 프롬프트 역할 명시 (최소)
  L2: disallowed-tools frontmatter (Skills 2.0)
  L3: bash-guard.js 명령 필터 (런타임)
  L4: Git Worktree 파일시스템 격리
  L5: security-scan.js pre-commit 자동 스캔
```

**ECO 티어**: L1 + L3 + L5
**PRO 티어**: L1 + L2 + L3 + L5
**MAX 티어**: L1 + L2 + L3 + L4 + L5

---

## AuraKit Agent Security 규칙

```
AGENT SECURITY 규칙:
  Scout/Reviewer/Security 에이전트: Write/Edit 도구 금지
  에이전트 프롬프트에 API 키/시크릿 포함 금지
  에이전트 간 데이터: .aura/agent-memory/ 경유 (직접 전달 금지)
  모든 에이전트: 격리 서브프로세스로 실행 (메인 컨텍스트 토큰 보호)
  CTO 에이전트만 하위 에이전트 호출 권한 보유
```
