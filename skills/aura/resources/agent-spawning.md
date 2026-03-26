# AuraKit — Dynamic Agent Spawning Rules

> Defines which agents can spawn sub-agents, under what conditions,
> and the hard limits that prevent infinite-loop / runaway scenarios.

---

## Core Agents (Always Available)

These agents are pre-defined and can be invoked at any time without
counting toward dynamic spawn limits:

| Agent | Role |
|-------|------|
| **Scout** | Codebase exploration, file discovery, dependency mapping |
| **Worker / Builder** | Code generation, file creation, refactoring |
| **Reviewer** | Code review, convention checks, quality gates |
| **SecurityAgent** | OWASP checks, secret scanning, vulnerability analysis |
| **GapDetector** | Missing tests, uncovered edge cases, incomplete implementations |
| **TestRunner** | Test execution, coverage reporting, TDD cycles |
| **PM-Discovery** | Requirements gathering, stakeholder analysis |
| **PM-Strategy** | Roadmap planning, prioritization, trade-off analysis |
| **PM-PRD** | PRD generation, feature specification, acceptance criteria |

---

## Dynamic Spawning Rules

Agents **CAN** spawn additional agents when:

1. **Task scale** — A task touches more than 10 files and parallelism would reduce total time.
2. **Parallel review** — A single PR contains multiple languages (e.g., TypeScript + Python + SQL) and each needs a language-specific reviewer.
3. **Build Resolver sub-agents** — The Build Resolver detects errors in a specific framework/language and spawns a specialist (e.g., `vite-resolver`, `cargo-resolver`).
4. **ORCHESTRATE mode** — Leader/Swarm/Council patterns explicitly request a multi-agent topology.

Agents **MUST NOT** spawn when:

- The task can be handled by a single agent in under 2 minutes.
- The parent agent has not yet produced any output (no speculative pre-spawning).
- The session is already in a `frozen` state.

---

## Anti-Infinite-Loop Safeguards (CRITICAL)

### Hard Limits

| Limit | Value | Reason |
|-------|-------|--------|
| Max depth | 3 | Agent -> Child -> Grandchild. No deeper. |
| Max total agents per session | 12 | Prevents runaway spawning |
| Max concurrent agents | 5 | Matches Claude Code's Agent tool limit |
| Agent timeout | 5 minutes | Kill agents that hang |
| Retry limit per agent | 2 | Fail after 2 retries, don't respawn |
| Token budget per agent | 30% of remaining context | No single agent can consume more than 30% |

### Circuit Breaker Pattern

1. Track spawn count in `.aura/agent-memory/active.json`
2. If 3 agents fail consecutively -> **STOP** all spawning, alert user
3. If total token usage > 80% of context -> **FREEZE** spawning, complete current agents only
4. Each agent **MUST** declare its purpose and expected output size before spawning

### Enforcement

The `subagent-start.js` hook enforces these limits on every `PreToolUse:Agent` event:

- Reads `.aura/agent-memory/active.json`
- Checks: `spawn_count < 12`, `max_depth_reached < 3`, `frozen !== true`
- If any check fails: logs warning to stderr (Claude Code hooks cannot block the Agent tool, so enforcement is advisory)
- Increments `spawn_count` and writes back

---

## Spawn Request Format

Every dynamic spawn should include this metadata so the tracking system
can enforce limits and provide observability:

```json
{
  "parent": "builder-main",
  "child": "reviewer-ts",
  "purpose": "TypeScript convention review for auth module",
  "estimated_tokens": 2000,
  "depth": 2,
  "timeout_ms": 300000
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `parent` | string | yes | ID of the spawning agent |
| `child` | string | yes | ID to assign to the new agent |
| `purpose` | string | yes | One-line description of what the child will do |
| `estimated_tokens` | number | yes | Expected token consumption |
| `depth` | number | yes | Nesting level (parent=1, child=2, grandchild=3) |
| `timeout_ms` | number | no | Override default 300000ms timeout |

---

## Tracking File

**Path:** `.aura/agent-memory/active.json`

```json
{
  "session_id": "abc123",
  "spawn_count": 4,
  "max_depth_reached": 2,
  "failed_count": 0,
  "frozen": false,
  "agents": [
    {"id": "scout-1", "status": "completed", "depth": 1, "tokens_used": 500},
    {"id": "builder-1", "status": "running", "depth": 1, "children": ["reviewer-1"]},
    {"id": "reviewer-1", "status": "running", "depth": 2, "children": []}
  ]
}
```

### Status Values

| Status | Meaning |
|--------|---------|
| `running` | Agent is actively executing |
| `completed` | Agent finished successfully |
| `failed` | Agent encountered an unrecoverable error |
| `timed_out` | Agent exceeded its timeout |
| `killed` | Agent was terminated by the circuit breaker |

---

## Recovery from Runaway

If spawning goes wrong, the recovery sequence is:

1. `subagent-stop.js` detects `frozen === true` -> kills all running agents
2. Saves partial results to `.aura/snapshots/recovery.md`
3. Alerts user: **"Agent spawning frozen due to [reason]. Partial results saved."**

### Manual Recovery

If automatic recovery fails:

```bash
# Reset the tracking file
echo '{"session_id":"manual","spawn_count":0,"max_depth_reached":0,"failed_count":0,"frozen":false,"agents":[]}' > .aura/agent-memory/active.json

# Check for partial results
cat .aura/snapshots/recovery.md
```

---

## Design Rationale

- **Depth limit of 3** prevents exponential fan-out. Most tasks need at most
  Parent -> Worker -> Reviewer. Anything deeper is a design smell.
- **12 total agents** is generous for even the largest refactoring tasks
  while staying well within Claude Code's practical limits.
- **5 concurrent** matches the Agent tool's parallelism ceiling.
- **30% token budget** ensures no single agent can starve the session.
  With 3 agents active, that is 90% — leaving 10% for orchestration overhead.
- **Circuit breaker at 3 consecutive failures** catches systematic issues
  (e.g., wrong tool configuration) before wasting the entire context window.
