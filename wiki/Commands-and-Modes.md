<div align="center">

[![Modes](https://img.shields.io/badge/modes-36-818cf8?style=flat-square&labelColor=161b22)]()
[![Languages](https://img.shields.io/badge/languages-8-fcd34d?style=flat-square&labelColor=161b22)]()

</div>

# Commands & Modes

> AuraKit detects intent from natural language — no rigid syntax required.

---

## Basic Syntax

```bash
/aura <mode>: <description>
```

The mode keyword is **optional**. AuraKit infers it from your description.

```bash
/aura build: user authentication with JWT
/aura fix: login button not responding on mobile
/aura review: the auth middleware
/aura clean: remove all the dead code in utils/
/aura deploy: to Vercel production
```

---

## Core Modes

<details open>
<summary><b>⚡ Core — BUILD · FIX · CLEAN · DEPLOY · REVIEW</b></summary>

| Mode | Triggers | What it does |
|------|----------|--------------|
| `build` | `build:` `implement` `create` `add` | Full pipeline: scan → plan → generate → verify ×3 → commit |
| `fix` | `fix:` `bug` `error` `broken` | Root-cause → minimal patch → verify → commit |
| `clean` | `clean:` `refactor` `remove dead` | Dead code removal, duplication elimination, complexity reduction |
| `deploy` | `deploy:` `ship` `release` | Vercel / Docker / CI/CD configuration and deployment |
| `review` | `review:` `check` `audit` | Code quality + security scoring + actionable feedback |

**Examples:**
```bash
/aura build: dark mode toggle with system preference detection
/aura fix: the pagination breaks when there are 0 results
/aura clean: consolidate the 4 duplicate fetch utility functions
/aura deploy: to Vercel preview branch
/aura review: security -- mode:owasp
```

</details>

---

## Quality Modes

<details>
<summary><b>🧪 Quality — GAP · ITERATE · TDD · QA · DEBUG</b></summary>

| Mode | Triggers | What it does |
|------|----------|--------------|
| `gap` | `gap` `missing` `what's wrong` | Design ↔ implementation gap analysis |
| `iterate` | `iterate` `improve` `refine` | Incremental improvement loop |
| `tdd` | `tdd` `test first` `write tests` | Test-driven development cycle |
| `qa` | `qa` `test` `coverage` | Test generation + coverage analysis |
| `debug` | `debug` `trace` `why is this` | Step-by-step debugging with hypothesis |

**Examples:**
```bash
/aura gap: compare Figma spec against current implementation
/aura tdd: user registration flow
/aura qa: generate tests for the payment module
/aura debug: why is the cart total wrong on mobile
```

</details>

---

## Planning Modes

<details>
<summary><b>📐 Planning — PM · PLAN · DESIGN · REPORT · PIPELINE · BRAINSTORM</b></summary>

| Mode | Triggers | What it does |
|------|----------|--------------|
| `pm` | `pm` `product` `user story` | OST/JTBD mapping → Lean Canvas → PRD |
| `plan` | `plan` `architect` `design system` | Architecture planning before any implementation |
| `design` | `design` `UI` `component` | UI/UX design system generation |
| `report` | `report` `summarize` `status` | Progress report + governance snapshot |
| `pipeline` | `pipeline` `workflow` `CI/CD` | CI/CD and automation setup |
| `brainstorm` | `brainstorm` `ideas` `options` | Structured ideation with trade-off analysis |

</details>

---

## Advanced Modes

<details>
<summary><b>🤖 Advanced — ORCHESTRATE · BATCH · LOOP · FINISH</b></summary>

| Mode | Triggers | What it does |
|------|----------|--------------|
| `orchestrate` | `orchestrate` `multi-agent` `swarm` | Multi-agent coordination (Leader/Swarm/Council/Watchdog) |
| `batch` | `batch` `multiple files` `bulk` | Apply changes across multiple files simultaneously |
| `loop` | `loop` `until` `keep going` | Autonomous iteration until a condition is met |
| `finish` | `finish` `complete` `wrap up` | Finalize incomplete or interrupted work |

**Loop operator examples:**

```bash
# Run until all TypeScript errors are gone
/aura loop: fix all TypeScript errors -- until:no-error

# Run until test coverage hits 90%
/aura loop: improve test coverage -- until:90%

# Run until all tests pass
/aura loop: make all tests pass -- until:pass --max-iterations:10
```

> [!TIP]
> The loop operator has a built-in circuit breaker. It stops automatically if it detects it's going in circles (same error 3x in a row).

</details>

---

## v6 New Modes

<details>
<summary><b>✨ v6 New — INSTINCT · LANG · MCP · CONTENT</b></summary>

| Mode | What it does |
|------|--------------|
| `instinct` | View, train, or reset the pattern learning engine |
| `lang` | Switch the active language-specific code reviewer |
| `mcp` | Configure and connect MCP servers |
| `content` | Generate documentation, changelogs, blog posts |

**Language reviewers:**
```bash
/aura lang: typescript   # TypeScript + React/Next.js patterns
/aura lang: python       # Python + FastAPI/Django patterns
/aura lang: go           # Go idiomatic patterns
/aura lang: rust         # Rust ownership + safety patterns
/aura lang: java         # Java Spring patterns
/aura lang: kotlin       # Kotlin coroutines patterns
/aura lang: swift        # Swift + SwiftUI patterns
/aura lang: cpp          # C++ modern patterns
```

</details>

---

## Quality Tiers

Control cost vs quality with the `--tier` flag (or set a default in config):

```bash
/aura build: payment integration --tier pro
/aura fix: typo in button label --tier quick
```

| Tier | Scout | Builder | Reviewer | TestRunner | Token Savings |
|------|:-----:|:-------:|:--------:|:----------:|:-------------:|
| `quick` | — | Sonnet | — | — | ~60% |
| `eco` **(default)** | Haiku | Sonnet | Sonnet | Haiku | ~55% |
| `pro` | Haiku | **Opus** | Sonnet | Haiku | ~35% |
| `max` | Sonnet | **Opus** | **Opus** | Sonnet | ~25% |

> [!NOTE]
> ECO is the default for a reason — Sonnet handles 95% of tasks perfectly. Use PRO or MAX only for complex architecture or security-critical code.

---

## Platform & Utility Modes

<details>
<summary><b>📱 Platform — MOBILE · DESKTOP · BAAS</b></summary>

| Mode | Use for |
|------|---------|
| `mobile` | React Native, Flutter, Expo — mobile-specific patterns |
| `desktop` | Electron, Tauri — desktop app patterns |
| `baas` | Supabase, Firebase — Backend-as-a-Service integration |

</details>

<details>
<summary><b>🔧 Utility — STYLE · SNIPPETS · STATUS · CONFIG · ARCHIVE · QUICK</b></summary>

| Mode | Use for |
|------|---------|
| `style` | CSS, Tailwind, design token work |
| `snippets` | Reusable boilerplate generation |
| `status` | Project + AuraKit health check |
| `config` | AuraKit settings management |
| `archive` | Manual session checkpoint |
| `quick` | One-liner, minimal output, fast |

</details>
