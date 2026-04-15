# Autopus Lore Commit Protocol

> Absorbed from Autopus-ADK. Decision-tracking commit format.
> Every commit is a story — not just a change, but a record of WHY.

---

## Overview

Lore commits extend conventional commits with 9 structured trailers that capture:
- What was decided and why
- What was rejected
- Confidence level and reversibility
- Test coverage status

---

## Format

```
{type}({scope}): {description}

{optional body — explain the non-obvious}

Constraint: {constraint that forced this approach}
Rejected: {alternative considered and why discarded}
Confidence: low | medium | high
Scope-risk: local | module | system
Reversibility: trivial | moderate | difficult
Directive: {what this commit directs/implements}
Tested: {test files / scenarios that cover this}
Not-tested: {what was explicitly not tested and why}
Related: SPEC-XXX, #{issue}, {other-commit-sha}

🐙 Autopus
```

---

## Commit Type Taxonomy

| Type | When to Use |
|------|------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructure without behavior change |
| `test` | Test additions or changes |
| `docs` | Documentation only |
| `chore` | Build, tooling, config changes |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace (no logic change) |
| `ci` | CI/CD pipeline changes |
| `lore` | Architecture decision record (no code change) |
| `revert` | Reverts a previous commit |

---

## Trailer Reference

### `Constraint:`
External constraint that limited implementation options.
```
Constraint: PostgreSQL 14 JSON operator not available — used JSONB cast
Constraint: Rate limit 100 req/s from upstream API
Constraint: Must maintain backward compat with v1 API consumers
```

### `Rejected:`
Alternative approach considered and reason for rejection.
```
Rejected: Redis pub/sub — adds infra dependency for single-node deployment
Rejected: GraphQL — over-engineered for 3 endpoints
Rejected: Optimistic UI update — inconsistency risk with concurrent edits
```

### `Confidence:`
How confident the author is this is the right approach.
```
Confidence: high    # Well-understood, tested, proven pattern
Confidence: medium  # Some uncertainty, monitored post-deploy
Confidence: low     # Experimental, needs follow-up
```

### `Scope-risk:`
How wide the blast radius if this commit breaks something.
```
Scope-risk: local    # Single function/component
Scope-risk: module   # Affects a feature module
Scope-risk: system   # Cross-cutting concern, global state
```

### `Reversibility:`
How hard to undo this change.
```
Reversibility: trivial    # git revert, no data migration
Reversibility: moderate   # Requires migration or downstream updates
Reversibility: difficult  # Data schema change, external API contract
```

### `Directive:`
What requirement, spec, or goal this commit implements.
```
Directive: Implements SPEC-001 AC-02 (JWT refresh flow)
Directive: Addresses SEC-07 (httpOnly cookie requirement)
Directive: Fulfills NFR-01 (p99 < 200ms)
```

### `Tested:`
What testing covers this change.
```
Tested: auth/login.test.ts — 5 unit tests, 2 integration
Tested: e2e/auth.spec.ts — happy path + token expiry
Tested: manual — browser devtools confirm httpOnly flag
```

### `Not-tested:`
What was explicitly NOT tested, with rationale.
```
Not-tested: concurrent token refresh race — requires load test setup
Not-tested: database failover scenario — infrastructure concern
Not-tested: IE11 — dropped from support matrix
```

### `Related:`
Links to related context.
```
Related: SPEC-001, #234, abc1234
Related: ADR-007 (session management decision)
```

---

## `/aura lore:` Mode

```bash
/aura lore:commit [message]   → Write commit with Lore trailers (interactive)
/aura lore:check              → Validate current staged commit has required trailers
/aura lore:validate           → Run lore validation on recent commits
/aura lore:show [sha]         → Display lore trailers for a commit
/aura lore:search [keyword]   → Search commit history by Directive/Constraint
/aura lore:adr                → Generate ADR from recent lore commits
```

---

## Validation Rules

When `/aura lore:check` runs, it enforces:

| Rule | Condition |
|------|-----------|
| LORE-01 | `Confidence` trailer required |
| LORE-02 | `Scope-risk` trailer required |  
| LORE-03 | `Tested` OR `Not-tested` required (at least one) |
| LORE-04 | `Rejected` required for `feat` commits (document what you didn't do) |
| LORE-05 | `Directive` required when SPEC exists in `.autopus/specs/` |
| LORE-06 | `🐙 Autopus` sign-off required (auto-appended) |

Violations → WARN (not blocking by default); `LORE_STRICT=true` → blocking.

---

## AuraKit Integration

### In BUILD mode (optional, activated with `lore:on` config):

After successful build + verification, Claude prepares lore commit:

```
[LORE] Preparing decision-tracked commit:

Constraint: [detected from implementation notes]
Rejected: [alternatives considered during Discovery]
Confidence: medium  ← set based on V2 review result
Scope-risk: [computed from files changed]
Reversibility: [computed from migration files / schema changes]
Tested: [from V3 test results]
```

### Quick Lore (QUICK mode):

```bash
/aura! lore: add login endpoint
# → minimal trailers: Confidence + Scope-risk only
```

---

## Example Full Commit

```
feat(auth): implement JWT httpOnly cookie session

Replace localStorage token storage with httpOnly cookie to eliminate
XSS token theft vector. Token is set server-side on /api/auth/login
and cleared on /api/auth/logout.

Constraint: Safari ITP requires SameSite=None with Secure for cross-origin
Rejected: SessionStorage — same XSS vulnerability, short-lived only
Rejected: In-memory token store — lost on page refresh, bad UX
Confidence: high
Scope-risk: module
Reversibility: moderate
Directive: Implements SPEC-003 AC-01, SEC-02 (no localStorage tokens)
Tested: auth/session.test.ts — 8 unit tests covering set/clear/validate
Not-tested: Cross-origin iframe scenario — not in current use cases
Related: SPEC-003, #89

🐙 Autopus
```
