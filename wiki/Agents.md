<div align="center">

[![Agents](https://img.shields.io/badge/agents-7%20specialized-a78bfa?style=flat-square&labelColor=161b22)]()
[![Circuit Breaker](https://img.shields.io/badge/circuit%20breaker-max%2012%20agents-f97316?style=flat-square&labelColor=161b22)]()

</div>

# Agents

> 7 specialized agents. Each has a fixed role, model assignment, and permission boundary.

---

## Agent Map

```
                    ┌──────────────┐
                    │  /aura cmd   │
                    └──────┬───────┘
                           │
          ┌────────────────┼─────────────────┐
          ▼                ▼                 ▼
    ┌──────────┐    ┌───────────┐    ┌────────────┐
    │  Scout   │    │  Worker   │    │  Security  │
    │  Haiku   │    │  Sonnet   │    │   Sonnet   │
    │ read-only│    │build+test │    │OWASP audit │
    └──────────┘    └───────────┘    └────────────┘
          │                │                │
          ▼                ▼                ▼
  project-profile    code + tests     VULN-NNN report

         ┌─────────────────────────────────────┐
         │            PM Suite                 │
         │  Discovery │  Strategy  │    PRD    │
         │   Haiku    │   Haiku    │  Sonnet   │
         └─────────────────────────────────────┘
```

---

## Scout

<details open>
<summary><b>Scout — Project Scanner (Haiku · read-only)</b></summary>

**Model:** Haiku (fast, low cost)
**Permission:** Read files only — cannot write, edit, or run any commands

Scout runs automatically at the start of every `/aura` session (cached for 2 hours).

**Output: `.aura/project-profile.md`**
```markdown
Framework:    Next.js 14 (App Router)
Language:     TypeScript 5.3
Package mgr:  pnpm
Database:     PostgreSQL via Prisma
Auth:         NextAuth.js
Styling:      Tailwind CSS
Testing:      Vitest + Playwright
CI:           GitHub Actions
```

This profile is used by every other agent to make stack-aware decisions.

> [!NOTE]
> Scout re-runs only when `package.json` or a lockfile changes (ConfigHash check). Between those changes, the cached profile is reused — this is one of the key token reduction techniques.

</details>

---

## Worker

<details>
<summary><b>Worker — Primary Builder (Sonnet / Opus)</b></summary>

**Model:** Sonnet (ECO/default) or Opus (PRO/MAX tier)
**Permission:** Read, Write, Edit, Bash (non-destructive only)

Worker is the main code generator. Before writing every file, it runs the **Sonnet Amplifier** protocol:

```
1. I/O Contract    → Define inputs, outputs, side effects
2. Existing Code   → Search for similar code to avoid duplication
3. Edge Cases      → Enumerate: null, empty, overflow, concurrency
4. Security Rules  → Check applicable SEC-01 to SEC-15 rules
5. Implementation  → Write the code
```

After writing, Worker:
- Triggers `build-verify.js` (compile + type-check)
- Triggers `auto-format.js` (Prettier / gofmt / black)
- Runs the test suite
- Reports failures with root-cause analysis

</details>

---

## Security Agent

<details>
<summary><b>Security — OWASP Auditor (Sonnet · read-only)</b></summary>

**Model:** Sonnet
**Permission:** Read only — never modifies code

Triggered by:
```bash
/aura review: security
/aura review: --mode:owasp
```

**Output format:**
```
[SECURITY AUDIT] — smorky850612/Aurakit

VULN-001  HIGH    SQL Injection
  File:   src/api/users.ts:142
  Code:   db.query("SELECT * WHERE id=" + userId)
  Fix:    db.query("SELECT * WHERE id=$1", [userId])

VULN-002  MEDIUM  Missing rate limiting
  File:   src/api/auth/login.ts
  Note:   No rate limiting on POST /api/auth/login

──────────────────────────────
Score:    6.5 / 10
Critical: 0 | High: 1 | Medium: 1 | Low: 3
```

</details>

---

## Gap Detector

<details>
<summary><b>Gap Detector — Design vs Implementation (Haiku · read-only)</b></summary>

**Model:** Haiku
**Permission:** Read only

Compares:
- Figma/design spec against current implementation
- PRD requirements against codebase features
- Test coverage against feature completeness

Output: prioritized gap list with effort estimates (S/M/L).

```bash
/aura gap: compare PRD requirements against current implementation
```

</details>

---

## PM Agent Suite

<details>
<summary><b>PM Discovery → Strategy → PRD (chained pipeline)</b></summary>

Three agents run in sequence when you use PM mode:

**PM Discovery** (Haiku)
Maps user needs using OST (Opportunity Solution Tree) and JTBD (Jobs to Be Done).
```bash
/aura pm: we need to improve user retention for free tier users
```

**PM Strategy** (Haiku)
Generates a Lean Canvas from the discovery output.

**PM PRD** (Sonnet)
Produces a full PRD from the strategy output:
```markdown
# PRD: [Feature Name]

## Problem Statement
## Success Metrics (OKR-aligned)
## User Stories
## Acceptance Criteria
## Out of Scope
## Risks & Mitigations
```

</details>

---

## Agent Spawning Limits

> [!CAUTION]
> AuraKit enforces hard limits to prevent runaway costs. These cannot be overridden at runtime.

| Limit | Value |
|-------|:-----:|
| Max spawn depth | 3 |
| Max total agents per session | 12 |
| Max concurrent agents | 5 |
| Agent timeout | 5 minutes |

When any limit is hit, the circuit breaker fires — the orchestrator is notified and must proceed with whatever results are available.
