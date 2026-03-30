<div align="center">

[![Installation](https://img.shields.io/badge/install%20time-30%20seconds-6ee7b7?style=flat-square&labelColor=161b22)](https://github.com/smorky850612/Aurakit)
[![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-34d399?style=flat-square&labelColor=161b22&logo=node.js&logoColor=34d399)](https://nodejs.org)

</div>

# Getting Started

> From zero to `/aura` in 30 seconds.

---

## Prerequisites

| Requirement | Version | Where to get it |
|-------------|---------|-----------------|
| [Claude Code](https://claude.ai/code) | Latest | claude.ai/code |
| Node.js | ≥ 18.0.0 | nodejs.org |
| Git | Any | git-scm.com |

> [!NOTE]
> AuraKit installs into `~/.claude/` — it does **not** modify your project files. Safe to install globally and use across all projects.

---

## Installation

<details open>
<summary><b>Option A — One-line bash (recommended)</b></summary>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/smorky850612/Aurakit/main/install.sh)
```

This is the fastest method. The installer:
1. Downloads the latest release
2. Copies skills, hooks, agents, rules into `~/.claude/`
3. Merges hooks into your `settings.json` (non-destructive)
4. Verifies installation

</details>

<details>
<summary><b>Option B — npm</b></summary>

```bash
npx @smorky85/aurakit
```

Requires Node.js ≥ 18. The npm `postinstall` script runs the same installer automatically.

</details>

<details>
<summary><b>Option C — Manual clone</b></summary>

```bash
git clone https://github.com/smorky850612/Aurakit.git
cd Aurakit
bash install.sh
```

Use this if you want to inspect the installer before running it, or if you want to pin a specific version.

</details>

---

## What Gets Installed

```
~/.claude/
├── skills/
│   ├── aura/                   ← Core engine (SKILL.md + 44 resource guides)
│   ├── aura-compact/           ← Snapshot + compact shortcut
│   ├── aura-guard/             ← Token budget monitor
│   └── [46 multilingual shortcuts]
│
├── hooks/
│   ├── security-scan.js        ← Secret & injection detection (L4)
│   ├── bash-guard.js           ← Dangerous command blocking (L3)
│   ├── auto-format.js          ← Prettier / gofmt / black / rustfmt
│   ├── build-verify.js         ← Compile + type-check on every write
│   ├── migration-guard.js      ← Destructive DB migration guard (L5)
│   └── [18 more hooks]
│
├── agents/
│   ├── scout.md                ← Read-only project scanner (Haiku)
│   ├── worker.md               ← Code review + test runner (Sonnet)
│   ├── security.md             ← OWASP audit
│   └── [4 more agents]
│
└── rules/
    └── aurakit-security.md     ← Always-active security rules
```

> [!IMPORTANT]
> The `aurakit-security.md` rules file is installed to `~/.claude/rules/` and applies to **every Claude Code session** — even when you're not using `/aura`. This is intentional.

---

## Verify Installation

Open Claude Code in any project and run:

```
/aura status
```

Expected output:
```
[AURA] v6.4.0 — Status Check
✓ Skills:         49 loaded
✓ Hooks:          23 active
✓ Agents:         7 ready
✓ Security rules: active
✓ Session:        fresh
```

---

## First Command

```bash
/aura build: hello world API in Express
```

AuraKit will automatically:

1. **Scan** your project (framework, language, dependencies)
2. **Plan** a minimal implementation
3. **Generate** production-ready code with tests
4. **Verify** types + security + formatting
5. **Commit** with a clean message

> [!TIP]
> You don't need to specify a mode. `/aura hello world API` works the same — AuraKit infers `build` from context.

---

## What's Next

<details>
<summary><b>Recommended next steps after install</b></summary>

1. **Browse modes** → [[Commands and Modes]]
   Learn the 36 available modes and when to use each

2. **Understand security** → [[Security]]
   See exactly what's being enforced on every command

3. **Set your language** → [[Multilingual]]
   Use AuraKit in Korean, Japanese, Chinese, or 5 more languages

4. **Configure your tier** → [[Configuration]]
   Switch between QUICK / ECO / PRO / MAX quality tiers

</details>
