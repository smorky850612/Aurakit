# Autopus Agent Teams

> Absorbed from Autopus-ADK. Structured multi-agent team topology with
> Lead/Builder/Guardian roles, SendMessage communication, and circuit breaker.

---

## Overview

Agent Teams organizes agents into three functional roles working in parallel.
Unlike ad-hoc agent spawning, Teams has defined communication patterns and
escalation paths.

---

## Three-Role Structure

### Lead Team
Agents: planner + reviewer

Responsibilities:
- Phase 1: Decompose task into file manifest + agent assignments
- Phase 4: Review consolidated output from Builder team
- Arbitrate conflicts between Builder outputs
- Make final APPROVE / REQUEST_CHANGES decision

Lead Consolidator pattern:
```
Reviewer-A (code quality)  ──┐
Reviewer-B (security)      ──┤→ Lead Consolidator (planner) → unified verdict
Reviewer-C (architecture)  ──┘
```

### Builder Team
Agents: executor + tester + annotator + frontend-specialist

Responsibilities:
- Phase 1.5: tester writes failing tests
- Phase 2: executor implements per profile
- Phase 2.5: annotator adds @AX tags
- frontend-specialist handles *.tsx/*.vue files when present

Builder communication:
- Executor sends DONE/PARTIAL/BLOCKED status to Lead
- Tester sends test scaffold to Lead for Phase 1.5 sign-off
- Annotator sends annotation summary (count by type)

### Guardian Team
Agents: validator + security-auditor + perf-engineer

Responsibilities:
- Gate 2: validator runs all 8 checks
- security-auditor: parallel SEC-01~15 scan
- perf-engineer: benchmark-critical paths (activated for PERF flag)

Guardian circuit pattern:
```
validator (all 8 checks) ──────────────────┐
security-auditor (SEC scan, parallel) ─────┤→ Guardian Verdict
perf-engineer (if --perf flag, parallel) ──┘
```

---

## Communication Patterns

### Builder → Lead (status update)

```javascript
// Executor sends completion to Lead Consolidator
SendMessage({
  to: "lead-consolidator",
  message: {
    type: "EXECUTOR_DONE",
    files: ["src/auth/login.ts", "src/auth/types.ts"],
    status: "DONE",
    notes: "Implemented JWT cookie flow per SPEC-003 AC-01, AC-02"
  }
})
```

### Guardian → Lead (gate result)

```javascript
SendMessage({
  to: "lead-planner",
  message: {
    type: "GATE_RESULT",
    gate: 2,
    verdict: "FAIL",
    blocking_checks: [
      { check: "6a", issue: "Stub detected in src/api/payment.ts:47" }
    ],
    retry_count: 1
  }
})
```

### Lead → Builder (fix request)

```javascript
SendMessage({
  to: "executor-worker",
  message: {
    type: "FIX_REQUEST",
    issues: [
      { file: "src/api/payment.ts", line: 47, issue: "Implement processRefund" }
    ],
    gate_retry: 2  // This is retry #2 of 3 allowed
  }
})
```

### Builder ↔ Guardian (direct validation — P1-R3)

Builder can request Guardian validation without going through Lead:

```javascript
// Builder asks Guardian to validate specific file before full gate
SendMessage({
  to: "validator",
  message: {
    type: "PARTIAL_VALIDATE",
    files: ["src/auth/login.ts"],
    checks: [1, 2, 6]  // Build + test + stub check only
  }
})

// Guardian responds directly to Builder
SendMessage({
  to: "executor-worker",
  message: {
    type: "PARTIAL_VALIDATE_RESULT",
    pass: true,
    notes: "No stubs detected in login.ts"
  }
})
```

---

## Subagent Fallback Strategy

When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is NOT available:

```
Agent Teams mode → Individual Agent mode fallback:

Lead Team → Main orchestrator (sonnet/opus)
Builder Team → Parallel Agent() calls with model assignment
Guardian Team → Sequential validation after builders complete
```

Fallback spawning pattern:
```javascript
// Phase 2 in fallback mode
Agent({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Execute: src/auth/login.ts",
  prompt: "Implement per profile...",
  isolation: "worktree"
})

Agent({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "Execute: src/auth/types.ts",
  prompt: "Implement type definitions...",
  isolation: "worktree"
})
```

---

## Agent Team Configuration

`.autopus/team.yaml` (or `.aura/config.json` teams section):

```yaml
teams:
  lead:
    planner:
      model: opus  # MAX tier; sonnet in ECO/PRO
    reviewer:
      model: sonnet
      
  builder:
    executor:
      model: adaptive  # HIGH→opus, MEDIUM/LOW→sonnet
      max_concurrent: 5
    tester:
      model: sonnet
    annotator:
      model: haiku
    frontend_specialist:
      model: sonnet
      trigger: "*.tsx|*.vue|*.svelte"  # Only spawned for frontend files
      
  guardian:
    validator:
      model: sonnet
      max_retries: 3
    security_auditor:
      model: sonnet
      parallel: true
    perf_engineer:
      model: sonnet
      trigger: "--perf flag or NFR present"  # Optional
```

---

## Team Lifecycle

```
[Session Start]
  └─ Lead Team spawned (planner + reviewer as Lead Consolidator)
     
[Phase 1]
  └─ planner: decompose task → file manifest → agent assignments
  
[Phase 1.5]
  └─ Builder.tester: write failing tests
     → reports to Lead on completion
     
[Phase 2]
  └─ Builder.executor(s): parallel implementation in worktrees
     → each reports DONE/PARTIAL/BLOCKED to Lead
     └─ Builder.frontend-specialist: spawned if *.tsx present
     
[Phase 2.1]
  └─ Lead: orchestrate worktree merges
  
[Gate 2]
  └─ Guardian Team spawned
     ├─ validator: 8 checks (with model escalation)
     ├─ security-auditor: SEC scan (parallel)
     └─ perf-engineer: if --perf (parallel)
     → Guardian Verdict → Lead
     → FAIL: Lead sends FIX_REQUEST to Builder
     → PASS/CONDITIONAL: proceed to Phase 2.5
     
[Phase 2.5]
  └─ Builder.annotator: @AX tagging
  
[Phase 3 + Gate 3]
  └─ Guardian.validator: test run + coverage check
  
[Phase 3.5]
  └─ Builder.frontend-specialist: UX verify (if frontend files)
  
[Phase 4]
  └─ Lead.reviewer(s): TRUST 5 review
     → Lead Consolidator: unified verdict
     → APPROVE: commit + lore trailers
     → REQUEST_CHANGES: FIX_REQUEST to Builder (max 2 retries)
```

---

## `/aura orchestrate: teams` Mode

```bash
/aura orchestrate: teams [feature]   → Full Teams pipeline
/aura orchestrate: teams:lead        → Lead-only (plan + review, no build)
/aura orchestrate: teams:guardian    → Guardian-only (validate existing code)
/aura orchestrate: teams:status      → Show active team agents
```

Also accessible as:
```bash
/aura build: [feature] --teams       → BUILD mode with Teams topology
```

---

## Hard Limits (from agent-spawning.md)

| Limit | Value |
|-------|-------|
| Max agent depth | 3 |
| Max agents per session | 12 |
| Max concurrent agents | 5 |
| Timeout per agent | 5 minutes |
| Circuit breaker trigger | 3 consecutive failures |
| Context budget freeze | > 30% of remaining context |
