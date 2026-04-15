# Autopus @AX Annotation System

> Absorbed from Autopus-ADK. AX = Agent Experience.
> Code annotated for AI agents as primary readers — not just humans.

---

## Philosophy: AX (Agent Experience)

Write code WITH agents in mind as the primary audience.
@AX annotations are navigation beacons that help agents:
- Find important decision points quickly
- Avoid dangerous areas
- Understand non-obvious contracts
- Track pending tasks

---

## Annotation Types

### `@AX:NOTE`
General information an agent needs to know. Context that isn't obvious from code.

```typescript
// @AX:NOTE Token is rotated on every use — always fetch fresh from cookie
const token = getCookieToken(req)

// @AX:NOTE This cache has 5-min TTL; don't assume freshness in tests
const cached = await redis.get(key)
```

Trigger conditions:
- Non-obvious behavior (caching, async side effects)
- Domain-specific knowledge required
- Performance characteristics
- External API quirks

### `@AX:WARN`
Danger zones. Code an agent must handle carefully or avoid modifying.

```go
// @AX:WARN Modifying this function breaks payment webhook signature validation
// Contact payment team before changing parameter order
func validateWebhookSignature(payload []byte, sig string) bool {

// @AX:WARN Race condition risk — mutex acquired in caller, DO NOT re-acquire here
func processItem(item *Item) error {
```

Trigger conditions:
- Security-critical code
- Known race conditions or concurrency hazards
- External API contracts that can't be changed
- Code where wrong modification causes data corruption

### `@AX:ANCHOR`
Stable reference points. Code that other code depends on — structural beacons.

```python
# @AX:ANCHOR UserRepository public interface — all user data access goes here
class UserRepository:
    def find_by_id(self, user_id: str) -> Optional[User]:

# @AX:ANCHOR API response envelope — ALL API routes must use this format
def api_response(data, status=200, error=None):
```

Trigger conditions:
- Public interfaces / contracts
- Shared utilities used by 5+ files
- Base classes / abstract interfaces
- Convention-defining examples ("all routes look like this")

### `@AX:TODO`
Pending work an agent should complete. Unlike regular TODO comments — these are tracked.

```rust
// @AX:TODO Add retry logic for transient 503 errors (3 retries, exponential backoff)
async fn call_payment_api(req: PaymentRequest) -> Result<Response> {

// @AX:TODO Implement rate limiting — currently unbounded, SPEC-007 NFR-02
pub async fn handle_request(req: Request) -> Response {
```

Trigger conditions:
- Known missing implementation
- SPEC requirement not yet implemented
- Technical debt with clear remediation path
- Performance optimization deferred

---

## Rules

### [AUTO] Prefix

All agent-generated annotations MUST use `[AUTO]` prefix:

```typescript
// @AX:NOTE [AUTO] This component re-renders on every parent update — consider memo
// @AX:WARN [AUTO] Null check missing — upstream can return undefined here
```

Human-authored annotations omit `[AUTO]`:
```typescript
// @AX:ANCHOR Core authentication boundary — validates all JWTs
```

Purpose: Distinguish agent observations from intentional human design decisions.
Agents should respect human annotations more strongly than [AUTO] annotations.

### Per-File Limits

| Type | Limit per file |
|------|---------------|
| @AX:ANCHOR | ≤ 3 |
| @AX:WARN | ≤ 5 |
| @AX:NOTE | ≤ 10 |
| @AX:TODO | No hard limit (but keep < 15) |

**Overflow strategy**: If limit reached, upgrade most important to next level:
- NOTE overflow → ANCHOR (if truly central)
- TODO overflow → consolidate into single tracking comment

### @AX:CYCLE Tracking

When a TODO stays unresolved for 3 review cycles, upgrade to WARN:

```typescript
// Before (3 cycles old):
// @AX:TODO [AUTO] Validate user input before DB insert

// After upgrade:
// @AX:WARN [AUTO] [CYCLE:3] Input validation still missing — security risk
```

Cycle counter format: `[CYCLE:N]` appended to annotation.

---

## Language Syntax Reference

| Language | Comment syntax |
|----------|---------------|
| TypeScript/JavaScript | `// @AX:TYPE` or `/* @AX:TYPE */` |
| Python | `# @AX:TYPE` |
| Go | `// @AX:TYPE` |
| Rust | `// @AX:TYPE` |
| Java/Kotlin | `// @AX:TYPE` |
| Ruby | `# @AX:TYPE` |
| Swift | `// @AX:TYPE` |

---

## `/aura annotate:` / `/aura ax:` Mode

```bash
/aura annotate: [file or directory]   → Analyze and add @AX annotations
/aura ax:scan                         → Scan project for annotation coverage
/aura ax:show [file]                  → Display all @AX annotations in file
/aura ax:todo                         → List all @AX:TODO across project
/aura ax:cycle-check                  → Find TODOs that have aged 3+ cycles
/aura ax:clean [file]                 → Remove stale [AUTO] annotations
```

---

## Phase 2.5 — Automatic Annotation

After Phase 2 implementation (BUILD mode), annotator agent runs automatically:

**Trigger**: Any of the following in implemented files:
- Function > 50 lines → consider @AX:NOTE
- Shared utility used by 3+ imports → @AX:ANCHOR
- Security-critical code (auth, crypto, payment) → @AX:WARN
- Incomplete SPEC requirements → @AX:TODO

**Annotator Agent behavior**:
1. Read each implemented file
2. Identify annotation candidates by pattern matching
3. Apply [AUTO] prefix to all generated annotations
4. Respect per-file limits
5. Report: N annotations added (X:NOTE, Y:WARN, Z:ANCHOR, W:TODO)

---

## Integration with Lore Commit

@AX:WARN annotations should appear in `Directive:` or `Not-tested:` trailers:

```
Tested: auth/login.test.ts
Not-tested: concurrent session scenario — @AX:WARN noted in session.ts:142
```

---

## AX Coverage Report

```
## @AX Coverage
Files annotated: 23/45 (51%)
Total annotations: 87
  @AX:ANCHOR  12  (anchors core contracts)
  @AX:WARN    18  (8 [AUTO], 10 human)
  @AX:NOTE    34  [AUTO]
  @AX:TODO    23  (3 aged → CYCLE warning)

Aged TODOs (CYCLE ≥ 3):
  src/api/rate-limit.ts:45  — Input rate limiting (SPEC-007 NFR-02)
  src/auth/refresh.ts:89    — Concurrent refresh race condition
  src/db/query.ts:123       — Query timeout configuration
```
