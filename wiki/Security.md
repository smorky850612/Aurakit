<div align="center">

<img src="security-layers.svg" alt="6-Layer Security System" width="900"/>

<br/>

[![OWASP](https://img.shields.io/badge/OWASP-Top%2010%20Complete-ef4444?style=flat-square&labelColor=161b22)]()
[![SEC Rules](https://img.shields.io/badge/security%20rules-SEC--01%20to%20SEC--15-f97316?style=flat-square&labelColor=161b22)]()
[![Zero Config](https://img.shields.io/badge/configuration-zero-6ee7b7?style=flat-square&labelColor=161b22)]()

</div>

# Security

> AuraKit enforces production-grade security automatically — no configuration required.

---

## What Happens on Every Command

Every `/aura` command passes through all 6 layers before writing a single byte to disk.

<details open>
<summary><b>Layer breakdown</b></summary>

**L1 — Agent Role Boundaries** `[always active]`
Scout agents are read-only. Worker agents cannot modify infrastructure. Security agents cannot deploy. Roles are hard-coded — not overridable at runtime.

**L2 — Tool Disallowlists** `[always active]`
Each agent has an explicit list of forbidden tools. A Scout cannot call `Write` or `Edit`. A Worker cannot call destructive `Bash` commands.

**L3 — bash-guard.js** `[PreToolUse: Bash]`
Intercepts every Bash call and blocks dangerous patterns before they execute.

**L4 — security-scan.js** `[PreToolUse: Write/Edit]`
Scans every file before it's written for secrets, injection, XSS, and insecure auth patterns.

**L5 — migration-guard.js** `[PreToolUse: Write]`
Blocks destructive database operations without explicit user confirmation.

**L6 — npm audit** `[BUILD / FIX]`
Runs `npm audit --audit-level=high` after every build or fix. High-severity vulnerabilities block the commit.

</details>

---

## L3 — Blocked Shell Commands

> [!WARNING]
> These commands are **automatically blocked** whenever AuraKit's bash-guard detects them:

```bash
rm -rf /           # BLOCKED
rm -rf *           # BLOCKED
DROP TABLE         # BLOCKED
eval(userInput)    # BLOCKED
curl | bash        # BLOCKED
chmod 777          # BLOCKED
> /dev/sda         # BLOCKED
```

---

## L4 — Blocked Code Patterns

> [!WARNING]
> These code patterns are **blocked at write time** — the file write is cancelled and AuraKit generates the corrected version automatically:

| Pattern | Example | Why blocked |
|---------|---------|-------------|
| Hardcoded secret | `apiKey = "sk-live-..."` | SEC-03 |
| localStorage JWT | `localStorage.setItem('token', jwt)` | SEC-02 |
| SQL concatenation | `"SELECT * WHERE id=" + userId` | SEC-01 |
| XSS vector | `element.innerHTML = userInput` | SEC-04 |
| Plaintext password | `password: req.body.password` | SEC-02 |
| eval with input | `eval(req.body.code)` | SEC-05 |
| HTTP (not HTTPS) | `fetch('http://api.example.com')` | SEC-09 |

**What an L4 block looks like:**
```
[AURA SECURITY] L4 violation — SEC-02
File:    src/auth/login.ts:47
Pattern: localStorage.setItem('token', jwt)

Blocked. Corrected code:
  res.cookie('token', jwt, {
    httpOnly: true,
    sameSite: 'strict',
    secure: process.env.NODE_ENV === 'production'
  })
```

---

## SEC-01 to SEC-15

<details>
<summary><b>Injection (SEC-01, SEC-11)</b></summary>

**SEC-01 — SQL Injection**
Parameterized queries only. No string concatenation or template literals in SQL.
```typescript
// ❌ BLOCKED
db.query(`SELECT * WHERE id=${userId}`)

// ✅ REQUIRED
db.query('SELECT * WHERE id=$1', [userId])
```

**SEC-11 — NoSQL / Command / XML / LDAP Injection**
Same principle applied to MongoDB queries, shell commands, XML parsers, and LDAP queries.

</details>

<details>
<summary><b>Authentication (SEC-02)</b></summary>

**SEC-02 — Secure Token Storage**
JWT and session tokens must be stored in httpOnly cookies.

```typescript
// ❌ BLOCKED
localStorage.setItem('token', jwt)

// ✅ REQUIRED
res.cookie('token', jwt, {
  httpOnly: true,
  sameSite: 'strict',
  secure: process.env.NODE_ENV === 'production',
  maxAge: 7 * 24 * 60 * 60 * 1000
})
```

</details>

<details>
<summary><b>Secrets (SEC-03)</b></summary>

**SEC-03 — No Hardcoded Secrets**
API keys, passwords, tokens must come from environment variables.

```typescript
// ❌ BLOCKED
const stripe = new Stripe('sk_live_abc123')

// ✅ REQUIRED
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)
```

`.env` must be in `.gitignore` before any commit. AuraKit checks this automatically.

</details>

<details>
<summary><b>Input Validation (SEC-04)</b></summary>

**SEC-04 — All External Input Validated**
Every HTTP body, query param, and route param must be validated at the boundary.

| Language | Required library |
|----------|-----------------|
| TypeScript | Zod |
| Python | Pydantic |
| Java | `@Valid` + Bean Validation |
| Go | Manual validation |

</details>

<details>
<summary><b>eval / exec (SEC-05)</b></summary>

**SEC-05 — No eval with User Input**
`eval()`, `exec()`, `subprocess(shell=True)` with user-controlled input is blocked unconditionally.

</details>

<details>
<summary><b>Error Handling (SEC-06)</b></summary>

**SEC-06 — No Sensitive Data in Error Responses**
Stack traces, internal paths, database schema info, and environment variables must never appear in error responses.

```typescript
// ❌ BLOCKED
res.status(500).json({ error: err.stack })

// ✅ REQUIRED
res.status(500).json({ error: 'Internal server error' })
// Log the full error internally
logger.error(err)
```

</details>

<details>
<summary><b>Transport & Cryptography (SEC-08, SEC-09, SEC-12)</b></summary>

**SEC-08 — Secure Random Values**
```typescript
// ❌ BLOCKED for security use
Math.random()

// ✅ REQUIRED
crypto.randomBytes(32)              // Node.js
secrets.token_urlsafe(32)          // Python
crypto/rand                         // Go
```

**SEC-09 — HTTPS Only**
No HTTP fallbacks in production. External requests always use HTTPS.

**SEC-12 — Strong Cryptography**
AES-256+ for data at rest. No MD5 or SHA1 for password hashing. Use bcrypt, argon2, or scrypt.

</details>

<details>
<summary><b>Dependencies & Logging (SEC-13, SEC-14, SEC-15)</b></summary>

**SEC-13 — Dependency Audit**
`npm audit --audit-level=high` runs automatically after every BUILD and FIX. High-severity items block the commit.

**SEC-14 — Security Logging**
Security-relevant events (login attempts, permission changes, data access) must be logged. Sensitive data must never appear in logs.

**SEC-15 — SSRF Prevention**
Outbound HTTP requests must be validated against an allowlist. User-controlled URLs are blocked from reaching internal services.

</details>

---

## Always-Active Rules

> [!IMPORTANT]
> These rules are installed to `~/.claude/rules/aurakit-security.md` and apply to **every Claude Code session** — with or without running `/aura`.

```
1. No hardcoded secrets        → process.env.X required
2. No localStorage JWT         → httpOnly Cookie required
3. No SQL string concatenation → parameterized queries required
4. No eval(userInput)          → blocked unconditionally
5. .env not in .gitignore      → commit blocked
```

---

## See Also

- [[Agents]] — the Security agent for full OWASP audits (`/aura review: --mode:owasp`)
- [[Architecture]] — how hooks intercept tool calls
- [[Commands and Modes]] — `review` mode details
