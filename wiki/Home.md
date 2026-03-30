<div align="center">

<img src="banner.svg" alt="AuraKit Banner" width="900"/>

<br/>

[![npm version](https://img.shields.io/npm/v/@smorky85/aurakit?style=flat-square&color=818cf8&labelColor=161b22&label=npm)](https://www.npmjs.com/package/@smorky85/aurakit)
[![npm downloads](https://img.shields.io/npm/dm/@smorky85/aurakit?style=flat-square&color=38bdf8&labelColor=161b22&label=downloads)](https://www.npmjs.com/package/@smorky85/aurakit)
[![GitHub Stars](https://img.shields.io/github/stars/smorky850612/Aurakit?style=flat-square&color=fcd34d&labelColor=161b22&logo=github)](https://github.com/smorky850612/Aurakit)
[![License: MIT](https://img.shields.io/badge/license-MIT-6ee7b7?style=flat-square&labelColor=161b22)](https://github.com/smorky850612/Aurakit/blob/main/LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-34d399?style=flat-square&labelColor=161b22&logo=node.js&logoColor=34d399)](https://nodejs.org)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-ready-a78bfa?style=flat-square&labelColor=161b22)](https://claude.ai/code)

</div>

---

## What is AuraKit?

AuraKit is a **Claude Code skill** that replaces 20+ manual instructions with a single `/aura` command — with built-in security enforcement, tiered model selection, and a self-learning instinct engine.

<details>
<summary><b>Without AuraKit vs With AuraKit</b></summary>

**Without AuraKit** — 30 minutes of back-and-forth:
```
You: "Build login API"
Claude: generates something
You: "Add validation"
Claude: regenerates, misses security
You: "Make it secure"
Claude: adds some checks but forgets the tests
... 12 more rounds
```

**With AuraKit** — 3 minutes, done:
```bash
/aura build: login API with JWT auth

# Automatically:
# [B-1] Scans your stack (Next.js 14, TypeScript, Prisma)
# [B-2] Loads 15 security rules
# [L4]  Blocks any localStorage token storage
# [SEC] Enforces parameterized queries
# [V3]  Validates types + security + tests
# → git commit "feat: add JWT login API"
```

</details>

---

## Key Metrics

<div align="center">

| | |
|:---:|:---:|
| **36** intelligent modes | **6-layer** security (OWASP complete) |
| **~55%** token savings | **30** runtime hooks |
| **7** specialized agents | **8** languages natively |

</div>

**Token reduction breakdown:**

<progress value="55" max="100"></progress> `~55%` fewer tokens vs manual prompting (estimated, v6 ECO tier)

<progress value="55" max="100"></progress> `55%` saved with ECO tier (default)

<progress value="60" max="100"></progress> `60%` saved with QUICK tier

---

## Quick Install

```bash
# Option 1: bash (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/smorky850612/Aurakit/main/install.sh)

# Option 2: npm
npx @smorky85/aurakit
```

> [!TIP]
> After install, run `/aura status` in any Claude Code session to confirm everything is active.

---

## First Command

```bash
/aura build: hello world API in Express
```

That's it. AuraKit handles the rest.

---

## Platform Support

<details>
<summary><b>Supported AI coding tools</b></summary>

| Tool | SKILL.md | Hooks | Agents | Level |
|------|:--------:|:-----:|:------:|-------|
| **Claude Code** | ✅ | ✅ 30 hooks | ✅ | Full |
| OpenAI Codex | ✅ | ✅ | ✅ | Full |
| Cursor | ✅ | ⚠️ VS Code Tasks | ✅ | Supported |
| Manus | ✅ | ✅ | ✅ native | Supported |
| Windsurf | ✅ | ⚠️ VS Code Tasks | ✅ | Supported |
| Aider | ✅ | ❌ | ❌ | Partial |
| Gemini CLI | ✅ | ❌ | ❌ | Experimental |

</details>

---

## Wiki

| Page | What you'll find |
|------|-----------------|
| [[Getting Started]] | Install, verify, first command |
| [[Commands and Modes]] | All 36 modes with examples |
| [[Security]] | 6-layer system, SEC-01–SEC-15 |
| [[Agents]] | 7 agents, roles, permissions |
| [[Multilingual]] | 8-language command reference |
| [[Architecture]] | Hooks, pipeline, instinct engine |
| [[Configuration]] | Tiers, design system, MCP |
| [[Changelog]] | Version history |

---

<div align="center">

**[GitHub](https://github.com/smorky850612/Aurakit)** · **[npm](https://www.npmjs.com/package/@smorky85/aurakit)** · MIT License

</div>
