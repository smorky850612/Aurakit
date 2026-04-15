# Autopus Worktree Isolation

> Absorbed from Autopus-ADK. Rules R1-R7 for parallel agent execution
> in isolated git worktrees with conflict detection and GC suppression.

---

## Overview

When multiple executor agents work in parallel, each gets an isolated git worktree.
This prevents file conflicts during Phase 2 and enables true parallel development.

---

## Rules

### R1 — Isolation Flag

All executor agents MUST use `isolation: "worktree"` in Agent() calls:

```javascript
Agent({
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "Implement auth module",
  prompt: "...",
  isolation: "worktree"  // REQUIRED — never omit
})
```

Without isolation, concurrent writes corrupt each other's work.

### R2 — File Ownership Conflict Detection

Before assigning files to agents, the planner runs conflict detection:

Three-check algorithm:
```
Check 1: Prefix containment
  Files: ["src/auth/login.ts", "src/auth/"]
  Conflict: "src/auth/login.ts" is contained by "src/auth/"
  → Merge into single agent assignment

Check 2: Glob intersection
  Agent A: "src/auth/*.ts"
  Agent B: "src/auth/session.ts"
  Conflict: session.ts matches Agent A's glob
  → Assign session.ts to Agent A only

Check 3: Directory overlap
  Agent A files: src/auth/login.ts, src/auth/session.ts
  Agent B files: src/auth/types.ts
  → Same directory — merge A+B or add shared types to both read-only
```

Resolution: Conflicting files are merged into one agent's assignment.
Never assign the same file to two agents.

### R3 — Merge Strategy

Sequential merge (preferred):
```
As soon as executor A completes → merge immediately → executor B is working
on non-overlapping files in parallel
```

Batch merge (Phase 2.1):
```
All executors complete → merge in dependency order (no circular deps)
```

Conflict handling:
```
Merge conflict detected → ABORT that worktree
→ Report to Lead: which files conflicted
→ Lead decides: re-assign to single agent for sequential retry
```

### R4 — Conflict Abort

If merge fails with conflict:
```
1. git worktree remove --force {worktree-path}
2. Report: MERGE_CONFLICT in files [list]
3. Do NOT attempt to resolve automatically
4. Return BLOCKED status to Lead
```

Manual conflict resolution is always safer than automated merge in complex cases.

### R5 — GC Suppression + Lock Retry

Prevent git GC from interfering with worktrees:
```bash
git -c gc.auto=0 worktree add {path} {branch}
git -c gc.auto=0 merge {branch}
```

Lock retry for stale `.git/index.lock`:
```
If lock file exists:
  Wait 3 seconds → retry
  If still locked: wait 6 seconds → retry
  If still locked: wait 12 seconds → retry (exponential backoff)
  If still locked after 3 retries: FAIL → report stale lock
```

### R6 — Max Concurrent

Maximum 5 simultaneous worktrees at any time.

If planner assigns > 5 parallel agents:
```
Sort by dependency order
Execute first 5 in parallel
As each completes, start next in queue
```

### R7 — Branch Naming

```
Branch naming convention: autopus/wt-{task-id}-{short-desc}

Examples:
  autopus/wt-001-auth-login
  autopus/wt-001-auth-types
  autopus/wt-002-payment-webhook

Cleanup after merge: git worktree remove && git branch -d autopus/wt-*
```

---

## Worktree Lifecycle

```
[Planner] Detect parallel-safe files → assign to agent groups
    ↓
[For each agent group]
  git worktree add -b autopus/wt-{id}-{desc} .worktrees/{id}-{desc}
    ↓
  Agent runs in isolated worktree
    ↓
  Agent completes → git add + git commit (no push)
    ↓
[Merge sequence (Phase 2.1)]
  git merge --no-ff autopus/wt-{id}-{desc}
  ON CONFLICT → ABORT → report → single-agent retry
    ↓
  git worktree remove .worktrees/{id}-{desc}
  git branch -d autopus/wt-{id}-{desc}
```

---

## Directory Structure

```
project/
├── .worktrees/        ← active worktrees (gitignored)
│   ├── 001-auth/      ← Agent A's workspace
│   └── 002-payment/   ← Agent B's workspace
├── src/               ← main branch
└── .git/
```

Add to `.gitignore`:
```
.worktrees/
```

---

## Integration with AuraKit

AuraKit's existing batch pipeline uses worktrees for `/aura batch:`.
The Autopus rules extend this with:
- Formal conflict detection (R2 three-check algorithm)
- GC suppression (R5)
- Explicit ownership tracking per file

In BUILD mode with multiple files, planner activates worktree isolation automatically
when 2+ executor agents are needed for parallel implementation.

Config:
```json
{
  "worktree": {
    "max_concurrent": 5,
    "gc_suppression": true,
    "lock_retry_backoff": [3, 6, 12],
    "branch_prefix": "aura/wt"
  }
}
```
