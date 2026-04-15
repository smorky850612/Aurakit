# Autopus Validator Gates

> Absorbed from Autopus-ADK. Enhanced Gate 2 validation with 8 checks,
> behavioral stub detection, acceptance coverage, and seam verification.

---

## Overview

The validator runs at Gate 2 (after Phase 2 implementation) and Gate 3 (after Phase 3 testing).
It performs 8 sequential checks, each with PASS/FAIL/WARN output.

**Max retries**: 3 at Gate 2 (RALF loop). Gate verdict triggers builder to fix.

---

## Check 1 — Build Verification

```bash
# Detect language and run build
npm run build / tsc --noEmit   # TypeScript
go build ./...                  # Go
cargo build                     # Rust
python -m py_compile src/*.py   # Python
mvn compile                     # Java
```

PASS: Zero errors.
FAIL: Any compilation error → report file:line:error.

---

## Check 2 — Test Execution

Run full test suite including Phase 1.5 scaffold tests.

```bash
npm test / npx vitest run / npx jest --ci
go test ./...
pytest -x
cargo test
```

PASS: All tests pass.
FAIL: Report failing test names + error messages.

---

## Check 3 — Lint / Type Check

```bash
npx eslint src/ --max-warnings 0    # TypeScript
npx tsc --noEmit                     # TypeScript types
golangci-lint run                    # Go
ruff check src/                      # Python
cargo clippy -- -D warnings         # Rust
```

PASS: Zero errors, warnings within threshold.
WARN: Warnings present (non-blocking unless `--strict`).
FAIL: Errors present.

---

## Check 4 — Coverage Threshold

| Tier | Threshold |
|------|---------|
| ECO | ≥ 70% |
| PRO | ≥ 80% |
| MAX | ≥ 90% |
| SPEC mode | ≥ 85% |

```bash
npx vitest run --coverage --reporter=json
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out
pytest --cov=src --cov-report=json
```

PASS: Coverage ≥ threshold.
FAIL: Coverage < threshold → report which files are below.

---

## Check 5 — File Structure

Verify no file exceeds 300 lines (stricter than AuraKit's 250 for generated code).

```bash
# Find files over limit
find src -name "*.ts" -o -name "*.go" -o -name "*.py" | \
  xargs wc -l | sort -rn | awk '$1 > 300 {print $2, $1}'
```

PASS: All files ≤ 300 lines.
WARN: Files between 250-300 lines.
FAIL: Files > 300 lines → list them with line counts.

---

## Check 6 — Seam Verification

Three sub-checks (all must pass):

### 6a — Behavioral Stub Analysis (2-layer)

**Layer 1: Keyword Scan**
```
Search for: TODO, FIXME, stub, placeholder, not implemented, mock, fake
In: all files modified in Phase 2
```

**Layer 2: Function Body Analysis**
For each function in modified files, check for empty/stub bodies:
```
Patterns indicating stubs:
- Function body = single return nil/None/null/undefined
- Function body = single pass/noop statement  
- Function body = panic("not implemented") / raise NotImplementedError
- Function body = empty (just braces {})
- Function body only has comment, no logic
```

Layer 2 requires model escalation (sonnet minimum — haiku misses subtle stubs).

PASS: No stubs detected.
FAIL: List file:function for each stub found.

### 6b — Smoke Test

Verify the primary entry point works:
```bash
# CLI tool
./bin/app --help    # Must exit 0

# HTTP API
curl -s http://localhost:PORT/health | jq .status  # Must return "ok"

# Library
node -e "require('./dist/index.js')"  # Must not throw
```

PASS: Entry point responds without error.
SKIP: If no runnable entry point (library with no binary).

### 6c — Contract Parity

For API changes, verify client and server agree:
- API route defined in server → corresponding client function exists
- Request type in server matches client call signature
- Response type in server matches client parsing

```
Check: src/api/routes.ts endpoints ↔ src/lib/api-client.ts calls
```

PASS: All endpoints have matching client calls.
WARN: New endpoint without client function (acceptable if client update in separate SPEC).

---

## Check 7 — Acceptance Coverage

Read `acceptance.md` from the active SPEC and verify implementation:

```
For each AC in acceptance.md:
  1. Find the Given/When/Then scenario
  2. Search for test function that covers this scenario
  3. OR verify implementation directly handles the behavior
```

Coverage formula:
```
Match Rate = (Covered ACs / Total ACs) × 100%
```

PASS: Match Rate ≥ 90%.
FAIL: Match Rate < 90% → list uncovered ACs with file search suggestions.

Gate reports Match Rate in output:
```
Check 7 — Acceptance Coverage: 8/9 ACs = 89% → FAIL (threshold: 90%)
Uncovered: AC-05 (token refresh on 401 response)
```

Requires model escalation: sonnet minimum (acceptance mapping requires reasoning).

---

## Check 8 — Migration File Validation

Only runs if database migration files were created/modified.

```
Verify:
- Migration is reversible (has both up and down / forward and rollback)
- No destructive operations without explicit confirmation in commit message
- Migration timestamp is unique (no collision with existing migrations)
- Foreign key constraints accounted for in operation order
```

PASS: Migration is valid and reversible.
WARN: Destructive operation present but documented in Lore commit.
FAIL: Irreversible migration without documentation.

---

## Gate Verdict Format

```
## Gate 2 Verdict

Check 1 — Build:             PASS
Check 2 — Tests:             PASS  (24/24)
Check 3 — Lint:              WARN  (3 warnings — non-blocking)
Check 4 — Coverage:          PASS  (83% ≥ 70%)
Check 5 — File Structure:    PASS
Check 6a — Stubs:            FAIL  ← BLOCKING
Check 6b — Smoke Test:       PASS
Check 6c — Contract Parity:  PASS
Check 7 — Acceptance:        PASS  (9/9 = 100%)
Check 8 — Migrations:        SKIP  (no migrations)

VERDICT: FAIL (1 blocking issue)

## Fix Required
Check 6a — Stub at src/api/payment.ts:47
  Function: processRefund
  Body: return nil  ← empty stub detected
  Action: Implement refund logic per SPEC-008 AC-03
```

---

## CONDITIONAL_PASS

When all checks pass except non-blocking warnings:

```
## Gate 2 Verdict

All checks: PASS (with 2 warnings)

VERDICT: CONDITIONAL_PASS

Warnings (tracked, not blocking):
- Check 3: 3 ESLint warnings in src/utils/format.ts
- Check 5: src/auth/session.ts at 287 lines (threshold: 300)

Track in: .aura/tech-debt.md
```

---

## Model Requirements

| Check | Minimum Model | Reason |
|-------|--------------|--------|
| 1-5 | haiku | Mechanical execution |
| 6a Layer 1 | haiku | Keyword search |
| 6a Layer 2 | sonnet | Semantic stub detection |
| 6b | haiku | CLI/HTTP call |
| 6c | sonnet | Interface matching |
| 7 | sonnet | AC mapping reasoning |
| 8 | sonnet | Migration analysis |

Validator runs checks 1-6a-Layer1, 6b on haiku; escalates to sonnet for 6a-Layer2, 6c, 7, 8.

---

## Integration with AuraKit

Activated in:
- `/aura build:` → Gate 2 runs after Phase 2
- `/aura review:` → runs all 8 checks as Worker-V (Validator)
- `/aura spec:validate SPEC-XXX` → runs check 7 only

Configure thresholds in `.aura/config.json`:
```json
{
  "validator": {
    "coverage_threshold": 85,
    "line_limit": 300,
    "acceptance_threshold": 90,
    "strict_stubs": true
  }
}
```
