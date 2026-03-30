<div align="center">

[![Current](https://img.shields.io/badge/current-v6.4.0-818cf8?style=flat-square&labelColor=161b22)]()
[![npm](https://img.shields.io/npm/v/@smorky85/aurakit?style=flat-square&color=38bdf8&labelColor=161b22)](https://www.npmjs.com/package/@smorky85/aurakit)

</div>

# Changelog

> All notable changes to AuraKit, newest first.

---

## v6.4.0 — Current

> [!NOTE]
> Benchmark system, Homebrew tap, zero-friction install, QA automation 5/5, Wiki complete.

**New features**
- `benchmarks/` — 5 standardized tasks (T1~T5): REST API, JWT refresh, SQL opt, refactor, DevOps
- `Formula/aurakit.rb` — Homebrew tap (`brew install smorky85/tap/aurakit`)
- curl one-liner: `curl -fsSL https://raw.githubusercontent.com/smorky850612/Aurakit/main/install.sh | bash`
- `.github/workflows/wiki-init.yml` — GitHub Wiki auto-initialization
- `tests/run-tests.sh` v2.0 — fully automated AuraScore 40/40 (no manual /aura required)

**Improvements**
- `install.sh` v2.0: `--auto` flag for CI/npx non-interactive mode
- `bin/install.js`: passes `--auto` to install.sh during npm postinstall
- README: 4 install methods, dual npm download badges (monthly + total)
- Wiki: all version references updated to v6.4.0, 36 modes, ~55% token savings, 30 hooks

---

## v6.3.2

> [!NOTE]
> Security audit fixes, payment mode, npm publish.

**Bug fixes**
- VULN-001~012: security audit — 12 vulnerabilities resolved (inject, auth, secrets)
- Payment: Polar integration throw-on-error consistency
- Installer: 3-hook registration fix, SKILL.md warning removed

---

## v6.2.1

> [!NOTE]
> Patch release: Windows compatibility fixes for `/aura-compact`.

**Bug fixes**
- `aura-compact`: switched to Bash for snapshot write — removes broken env var hack
- `aura-compact`: removed PowerShell SendKeys workaround that caused freeze on Windows
- `hero.svg`: updated version label v5.1 → v6.2

---

## v6.2.0

> [!NOTE]
> Major feature release: Sonnet Amplifier, Instinct Engine, 10 language reviewers, 14 MCP configs, Loop Operator.

<details>
<summary><b>New features</b></summary>

**Sonnet Amplifier**
Structured 5-step reasoning protocol before every file write: I/O contract → existing code check → edge case enumeration → security verification → implementation. This is the primary driver of the 75% token reduction.

**Instinct Learning Engine**
AuraKit now learns from every session. Successful patterns stored in `.aura/instincts/patterns.md`, mistakes stored in `anti-patterns.md`. Loaded at B-5 in subsequent sessions.

**10 Language-Specific Reviewers**
TypeScript, Python, Go, Java, Rust, Kotlin, C++, Swift, PHP, Perl — each with framework-aware review criteria.

**14 MCP Server Configurations**
Playwright, GitHub, Slack, Linear, Notion, Supabase, PostgreSQL, MongoDB, Redis, Stripe, Vercel, AWS, Sanity.

**Loop Operator**
Autonomous iteration with conditions: `until:pass`, `until:90%`, `until:no-error`. Built-in circuit breaker stops after 3 identical failures.

**Dynamic Agent Spawning**
Circuit breaker enforces: max depth 3, max 12 total, 5 concurrent, 5-min timeout.

**Cross-Harness Support**
Claude Code, Codex, Cursor, Manus, Windsurf — with platform-specific adapter configurations.

</details>

<details>
<summary><b>Performance improvements</b></summary>

- Token reduction: **75% vs v5.1** (verified on BUILD mode benchmarks)
- Graceful compact triggered at 65% context usage (was 95%)
- ConfigHash: rescan triggers only when `package.json` or lockfile changes
- Progressive resource loading: only mode-relevant guides loaded per command

</details>

<details>
<summary><b>New modes</b></summary>

| Mode | What it does |
|------|--------------|
| `instinct` | View/train the pattern learning engine |
| `lang` | Switch language reviewer mid-session |
| `mcp` | Configure MCP server connections |
| `content` | Generate docs, changelogs, blog posts |

</details>

---

## v6.1.0

> [!NOTE]
> PM Agent Suite, Gap Detector, orchestration patterns, Italian and German language support.

<details>
<summary><b>Changes</b></summary>

**New agents**
- PM Agent Suite: Discovery (Haiku) → Strategy (Haiku) → PRD (Sonnet)
- Gap Detector: design ↔ implementation gap analysis

**Orchestration patterns**
- Leader, Swarm, Council, Watchdog — 4 patterns for multi-agent coordination

**New languages**
- Italian shortcuts (`/aura-it` family)
- German shortcuts (`/aura-de` family)

**Security (SEC-11 to SEC-15)**
- SEC-11: NoSQL/Command/XML/LDAP injection
- SEC-12: Cryptography requirements (AES-256+)
- SEC-13: Automatic `npm audit` on BUILD/FIX
- SEC-14: Security event logging
- SEC-15: SSRF prevention

</details>

---

## v6.0.0

> [!IMPORTANT]
> Breaking change: quality tier names renamed.

<details>
<summary><b>Changes</b></summary>

**Breaking changes**
- Quality tiers renamed: `standard` → `eco`, `premium` → `pro`
- Hook config format updated (migration script included in release)

**New features**
- Tiered model selection: QUICK / ECO / PRO / MAX
- Session cache with 2-hour TTL
- `aura-guard` skill for token budget monitoring
- `pre-compact-snapshot.js` + `post-compact-restore.js` hooks
- Korean IME reverse-transliteration (`korean-command.js`)
- Japanese, Chinese, Spanish, French multilingual shortcuts

</details>

---

## v5.1.0 — Initial Release

<details>
<summary><b>What shipped</b></summary>

- Core BUILD / FIX / CLEAN / DEPLOY / REVIEW modes
- 6-layer security system (L1–L6)
- Scout + Worker + Security agents
- 23 runtime hooks
- English + Korean multilingual support
- npm package `@smorky85/aurakit`

</details>

---

## Versioning

| Increment | Meaning |
|-----------|---------|
| **Major** (6.x.x) | New agent architecture or breaking hook format changes |
| **Minor** (x.2.x) | New modes, agents, or language support |
| **Patch** (x.x.1) | Bug fixes, documentation, minor tweaks |
