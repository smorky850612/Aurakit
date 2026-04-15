# Autopus Enhanced Pipeline v2

> Absorbed from Autopus-ADK. Extends AuraKit BUILD pipeline with 5-phase structure,
> intermediate phases (1.5, 1.8, 2.1, 2.5, 3.5), and formal gate system.

---

## Full Pipeline Overview

```
Phase 1:    Planning (planner agent)
Phase 1.5:  Test Scaffold (tester agent — FAILING tests first)
Phase 1.8:  Doc Fetch / Context7 (research enrichment)
Phase 2:    Implementation (executor agents, worktree isolation)
Phase 2.1:  Worktree Merge (consolidate parallel work)
Gate 2:     Validation (validator — 8 checks, retry max 3)
Phase 2.5:  Annotation (@AX tagging, annotator agent)
Phase 3:    Testing (test runner — all must pass)
Gate 3:     Coverage ≥ 85% (configurable per tier)
Phase 3.5:  UX Verify (frontend changes only)
Phase 4:    Review (reviewer agent, TRUST 5 criteria)
```

---

## Phase 1 — Planning

**Agent**: planner (opus in MAX/Balanced; sonnet+Amplifier in PRO; adaptive in ECO)

Steps:
1. Read SPEC (`spec.md` + `acceptance.md` if exists)
2. Assess complexity: HIGH | MEDIUM | LOW (see below)
3. Produce file manifest with agent profile assignments
4. Define implementation order (dependency sort)
5. Identify worktree candidates (parallel-safe files)

### Complexity Assessment

| Level | Criteria |
|-------|---------|
| HIGH | 3+ files changed, 200+ lines new code, OR cross-module changes |
| MEDIUM | 1-2 files, 50-200 lines, single module |
| LOW | Single file, < 50 lines, isolated change |

HIGH → opus for executor; MEDIUM/LOW → sonnet (Balanced mode only)

### Agent Assignment Table Format

```
| File | Action | Profile | Complexity | Worktree |
|------|--------|---------|------------|---------|
| src/auth/login.ts | CREATE | typescript | MEDIUM | wt-auth |
| src/auth/login.test.ts | CREATE | typescript | LOW | wt-auth |
| src/api/routes.ts | MODIFY | typescript | HIGH | wt-api |
```

---

## Phase 1.5 — Test Scaffold

**Agent**: tester (sonnet)
**Critical Rule**: Tests MUST be written BEFORE implementation.

Steps:
1. Read SPEC acceptance criteria (`acceptance.md`)
2. For each `Given/When/Then` scenario → write one test function
3. Tests MUST be failing (implementation doesn't exist yet)
4. Assert on OBSERVABLE BEHAVIOR — not just `require.NoError(t, err)`

### Behavioral Assertion Rule (Critical)

```go
// BAD — does not verify behavior
func TestCreateUser(t *testing.T) {
    err := CreateUser(...)
    require.NoError(t, err)  // Only checks it didn't crash
}

// GOOD — asserts observable behavior
func TestCreateUser(t *testing.T) {
    err := CreateUser(input)
    require.NoError(t, err)
    
    user, fetchErr := GetUser(input.Email)
    require.NoError(t, fetchErr)
    assert.Equal(t, input.Email, user.Email)      // Verify persisted
    assert.NotEmpty(t, user.ID)                    // ID was assigned
    assert.True(t, time.Since(user.CreatedAt) < 5*time.Second)
}
```

Completion verification: All tests from Phase 1.5 MUST FAIL before Phase 2 begins.
If any test passes, tester has leaked implementation — restart.

---

## Phase 1.8 — Doc Fetch / Context7

**Agent**: haiku (read-only research)

For each library in the implementation:
1. Identify top 5 libraries used by implementation files
2. Fetch current documentation via Context7 MCP or web search
3. Store in `research.md`

**Adaptive Token Budget**:
| Libraries | Tokens per lib |
|-----------|---------------|
| 1 | 5000 |
| 2-3 | 3000 |
| 4-5 | 2000 |
| Hard cap | 10000 total |

Skip if: library is stable/well-known AND last research < 7 days old.

---

## Phase 2 — Implementation

**Agent**: executor (profile-matched)
**Rule**: ALWAYS read `spec.md` and `acceptance.md` BEFORE writing any code (Step 0).

Executor Step 0 (mandatory):
```
1. Read .autopus/specs/{SPEC-ID}/spec.md
2. Read .autopus/specs/{SPEC-ID}/acceptance.md  
3. Load executor profile for file type (see autopus-executor-profiles.md)
4. Then begin implementation
```

**Worktree Isolation**: Each parallel executor works in isolated git worktree.
- Max 5 concurrent worktrees
- File ownership conflict detection before assignment
- See `autopus-worktree-isolation.md`

**Completion Report Format** (executor must return):
```
## Executor Report

Status: DONE | PARTIAL | BLOCKED

Files Modified:
- src/auth/login.ts (CREATE, 94 lines)
- src/auth/types.ts (MODIFY, +12 lines)

Notes:
- [Any deviation from plan]
- [Assumption made]

PARTIAL/BLOCKED reason:
- [What remains, what blocked]
```

**Phase 1.5 Test Constraint**: Executor MUST NOT modify test files written in Phase 1.5.
If a test needs changing, executor must flag it and stop — do not silently fix tests.

---

## Phase 2.1 — Worktree Merge

Merge all parallel executor worktrees back to main branch.

Rules:
- Merge immediately after each executor completes (sequential merge preferred)
- OR batch merge all at end of Phase 2
- Conflict → ABORT that worktree, report BLOCKED
- GC suppression: `git -c gc.auto=0 merge`
- See full rules in `autopus-worktree-isolation.md`

---

## Gate 2 — Validation

**Agent**: validator (sonnet)
**Max retries**: 3 (RALF loop — RED→GREEN→REFACTOR→LOOP)

8 validation checks (in order):
1. Build verification
2. Test execution
3. Lint / type check
4. Coverage threshold
5. File structure (300-line limit)
6. Seam verification (behavioral stub detection + smoke test)
7. Acceptance coverage (all ACs from acceptance.md mapped)
8. Migration file validation (if schema changes exist)

Gate Verdict:
```
PASS: All 8 checks passed
CONDITIONAL_PASS: Minor warnings, proceed with tracking
FAIL: One or more blocking failures — return to Phase 2
```

See full details in `autopus-validator-gates.md`.

---

## Phase 2.5 — Annotation

**Agent**: annotator (haiku)

Triggered when any of:
- File > 50 lines was created/modified
- Security-sensitive code detected
- SPEC TODOs remain incomplete

Actions:
- Add @AX:ANCHOR to public interfaces
- Add @AX:WARN to security-critical sections
- Add @AX:NOTE to non-obvious behaviors
- Add @AX:TODO for remaining SPEC items

See `autopus-ax-annotation.md`.

---

## Phase 3 — Testing

**Agent**: tester / test runner (haiku)

```bash
# Run all tests including Phase 1.5 scaffold
npm test / pytest / go test ./... / cargo test

# Coverage report
npx vitest run --coverage
pytest --cov=src --cov-report=term-missing
go test -coverprofile=coverage.out ./...
```

All Phase 1.5 tests MUST NOW PASS (implementation fills them in).

---

## Gate 3 — Coverage Threshold

| Tier | Coverage |
|------|---------|
| ECO | ≥ 70% |
| PRO | ≥ 80% |
| MAX | ≥ 90% |
| SPEC mode | ≥ 85% (fixed) |

FAIL → return to executor for additional test coverage.

---

## Phase 3.5 — UX Verify

**Agent**: ux-validator (sonnet)
**Condition**: Only runs if frontend files (*.tsx, *.vue, *.svelte) were modified.

Checks:
- Accessibility: alt attributes, label+htmlFor, role="alert" on errors
- Keyboard navigation: Tab order, Enter/Space on interactive elements
- Loading states: skeleton / spinner during async operations
- Error states: user-facing error message (not raw error object)
- Responsive behavior: mobile breakpoint coverage

Report format:
```
## UX Verification
- Accessibility: PASS / FAIL: [details]
- Keyboard Nav: PASS / FAIL
- Loading States: PASS / FAIL
- Error States: PASS / FAIL
- Responsive: PASS / SKIP (no responsive changes)
```

---

## Phase 4 — Review

**Agent**: reviewer (sonnet in ECO/PRO; opus in MAX)

TRUST 5 review criteria:
- **T**ested: Are tests comprehensive? Behavioral assertions?
- **R**eadable: Can another agent/dev understand this in 30 seconds?
- **U**nified: Consistent with project conventions and patterns?
- **S**ecured: No injection, no hardcoded secrets, proper auth?
- **T**rackable: Lore trailers present? Decision rationale captured?

Parallel review pattern (MAX tier):
```
Reviewer-A (code quality) ──┐
Reviewer-B (security)      ──┤→ Lead Consolidator → unified report
Reviewer-C (architecture)  ──┘
```

REQUEST_CHANGES triggers retry (max 2 retries in Phase 4).

---

## RALF Loop (Quality Gate Retry)

```
RED    → Gate failure detected
GREEN  → Builder fixes the specific issue
REFACTOR → Cleanup if fix introduced new issues
LOOP   → Re-run validation
```

Abort conditions:
- Gate 2: 3 consecutive failures → escalate to user
- Phase 4: 2 consecutive REQUEST_CHANGES → escalate
- Circuit breaker: 3 failures with same error → STOP

---

## AuraKit Integration

Use `/aura build: [feature] --pipeline=v2` to activate full pipeline.

Or configure as default in `.aura/config.json`:
```json
{
  "pipeline": "v2",
  "coverage_threshold": 85,
  "lore_commits": true,
  "ax_annotation": true
}
```

Default in SPEC mode: always uses pipeline v2.
