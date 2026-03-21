<div align="center">

<a href="https://github.com/smorky850612/Aurakit">
<picture>
<source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.svg">
<img src="assets/hero-dark.svg" width="100%" alt="AuraKit - One command. Full stack. Zero compromise.">
</picture>
</a>

<br/>

<img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" />
<img src="https://img.shields.io/badge/Claude_Code-Skill-blueviolet?style=flat-square" alt="Claude Code Skill" />
<img src="https://img.shields.io/badge/version-4.0.0-brightgreen?style=flat-square" alt="Version" />
<img src="https://img.shields.io/github/stars/smorky850612/Aurakit?style=flat-square&color=yellow" alt="Stars" />

<p>
<a href="#what-is-aurakit">What is AuraKit</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#getting-started">Getting Started</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#features">Features</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#commands">Commands</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#how-it-works">How It Works</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#compatibility">Compatibility</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#faq">FAQ</a>
</p>

</div>

<br/>

---

## What is AuraKit?

AuraKit is a **Claude Code skill** (a set of instructions that supercharges Claude Code) that transforms a single `/aura` command into a production-grade full-stack development pipeline.

Instead of giving Claude Code 20 separate instructions every time you start a project, AuraKit pre-loads all the best practices — security checks, code quality rules, token optimization, and smart context management — so Claude just *knows* what to do.

<pre>
You type this:
/aura 로그인/회원가입 기능 만들어줘 (Next.js + Prisma + PostgreSQL)

AuraKit does this:
 1. Scans your project structure automatically
 2. Creates a micro-plan (file-by-file build order)
 3. Generates each file with security checks baked in
 4. Verifies: compile > security > quality (triple check)
 5. Saves context snapshots so nothing gets lost
</pre>

---

## Getting Started

**Step 1 — Clone the repository**

<pre>
git clone https://github.com/smorky850612/Aurakit.git
</pre>

**Step 2 — Run the installer**

<pre>
cd Aurakit
bash scripts/init.sh
</pre>

This copies skills, agents, hooks, and templates into your Claude Code environment and merges hook configurations safely into your existing settings.json.

**Step 3 — Use it**

Open Claude Code in any project and type:

<pre>
/aura 로그인 기능 만들어줘
</pre>

That is it. AuraKit handles the rest.

---

## Features

### 28 Intelligent Modes

AuraKit auto-detects what you need based on your prompt, or you can use a namespace prefix (e.g. `build:`, `fix:`).

| Category | Modes | What It Does |
|:---------|:------|:-------------|
| **Core Dev** | BUILD, FIX, CLEAN, DEPLOY, REVIEW | Feature generation, bug fixes, refactoring, deploy config, security audit |
| **Quality** | GAP, ITERATE, TDD, QA, DEBUG | Gap analysis, auto-iteration (≥90%), red-green-refactor, zero-script QA, 5-WHY debugging |
| **Planning** | PM, PLAN, DESIGN, REPORT, PIPELINE, BRAINSTORM | OST discovery + PRD, implementation plan, DB/API design, completion report, 9-phase guide |
| **Style** | STYLE, SNIPPETS, STATUS, CONFIG | Output persona switching, prompt library, work status, settings management |
| **Platform** | MOBILE, DESKTOP, BAAS | React Native/Expo, Electron/Tauri, Supabase/Firebase/bkend |
| **Team** | ORCHESTRATE, ARCHIVE, BATCH, FINISH | Multi-agent patterns (Leader/Swarm/Council/Watchdog), feature archive, parallel batch, branch finalize |
| **Speed** | QUICK (`/aura!`) | Single-file, protocol-minimal — ~60% token savings |

### 6-Layer Security System

Every file AuraKit generates passes through 6 security gates.

| Layer | What It Checks | How |
|:------|:---------------|:----|
| **L1 — Agent Roles** | Per-agent security boundary (read-only vs write) | agents/*.md system prompts |
| **L2 — Disallowed Tools** | Blocklist per agent (no Write/Edit/Bash for read-only agents) | agents/*.md frontmatter |
| **L3 — Bash Guard** | Runtime agent bash restriction | hooks/bash-guard.js |
| **L4 — Security Scan** | Secret patterns, API keys, hardcoded credentials | hooks/security-scan.js |
| **L5 — Migration Guard** | Destructive DB migration blocking | hooks/migration-guard.js |
| **L6 — Dependency Audit** | npm audit / pip check on BUILD and FIX modes | Automated in build protocol |

### Triple Verification Pipeline

After every file is generated, 3 checks run automatically.

| Step | Check | Fail Action |
|:-----|:------|:------------|
| 1 | Compile / Type Check | Rewrite until it passes |
| 2 | Security Scan | Block and alert |
| 3 | Quality Score | Refactor if below threshold |

### Compact Defense System

Claude Code's default auto-compact triggers at 95% token usage — by then, critical context is already lost. AuraKit fixes this.

| Stage | What Happens |
|:------|:-------------|
| **Early Trigger** | Auto-compact fires at 65% instead of 95% |
| **PreCompact Snapshot** | Current work state saved to disk before compaction |
| **PostCompact Restore** | Snapshot reloaded into context after compaction |

Your build progress, decisions, and remaining tasks are never lost.

### Token Optimization

AuraKit is designed to use as few tokens as possible.

| Technique | Savings |
|:----------|:--------|
| Tiered Model (Scout/V3: Haiku, V2/Review: Sonnet, Builder: ECO default) | ~40% reduction |
| Fail-Only Output Filtering | ~25% reduction |
| Progressive Disclosure via resources/ (loaded per mode only) | ~20% reduction |
| Scan-Once Cache (.aura/project-profile.md) | ~15% reduction |
| Context Isolation (context:fork per agent) | ~20% reduction |
| Graceful Compact (65% threshold + checkpoint saves) | eliminates waste |

Typical BUILD job: ~55% token savings vs comparable setups without AuraKit. QUICK mode (`/aura!`) saves ~60% for simple single-file edits.

---

## How It Works

<pre>
[You] ──▶ /aura "로그인 만들어줘"
              │
              ▼
     ┌─────────────────┐
     │  Mode Detection  │  ← AUTO: BUILD / FIX / CLEAN / DEPLOY / REVIEW
     └────────┬────────┘
              │
              ▼
     ┌─────────────────┐
     │   Scout Agent    │  ← Scans project: package.json, tsconfig, .env
     │   (Haiku model)  │     Outputs: .aura/project-profile.md
     └────────┬────────┘
              │
              ▼
     ┌─────────────────┐
     │   Micro-Plan     │  ← File-by-file build order
     │   Generation     │     Max 8 files per cycle
     └────────┬────────┘
              │
              ▼
     ┌─────────────────┐
     │  Code Generation │  ← One file at a time
     │  + Security Hook │     security-scan.sh runs after each file
     └────────┬────────┘
              │
              ▼
     ┌─────────────────┐
     │  Triple Verify   │  ← Compile → Security → Quality
     │  (Worker Agent)  │     Sonnet model reviews
     └────────┬────────┘
              │
              ▼
     ┌─────────────────┐
     │  Snapshot Save   │  ← Progress saved to .aura/snapshots/
     │  + Next File     │     Loop until plan complete
     └─────────────────┘
</pre>

---

## Commands

### Primary Command

<pre>
/aura [your request in natural language]
</pre>

AuraKit detects mode automatically from your prompt. You can also use a namespace prefix or specify a quality tier.

### Mode Examples

<pre>
# Auto-detect mode (recommended)
/aura 로그인 기능 만들어줘             # BUILD
/aura Fix the TypeError in user.tsx    # FIX
/aura 코드 정리해줘                    # CLEAN
/aura Vercel 배포 설정해줘             # DEPLOY
/aura 코드 리뷰해줘                    # REVIEW

# Namespace prefix (when mode is ambiguous)
/aura build:소셜 로그인 추가
/aura fix:TypeError at dashboard.tsx:45
/aura tdd:결제 모듈
/aura pm:신규 기능 기획
/aura plan:인증 시스템
/aura design:DB 스키마
/aura qa:API 엔드포인트 검증
/aura iterate:          # auto-improve until gap ≥ 90%
/aura status            # check current work state
</pre>

### Quality Tiers

<pre>
# QUICK — single file, no protocol (~60% token savings)
/aura! 버튼 색상 변경

# ECO — default, general development (~55% savings)
/aura 로그인 기능 만들어줘

# PRO — Builder uses Opus, best for complex logic (~20% savings)
/aura pro 결제 시스템 만들어줘

# MAX — all agents use Opus, for critical production features
/aura max 마이크로서비스 인증 시스템 설계
/aura max review:전체 코드베이스 보안 감사
</pre>

### Multilingual Commands

AuraKit ships 52 skills across 8 languages. Type in your language without switching input methods.

<pre>
# Korean (한국어)
/아우라 로그인 만들어줘      /아우라빌드   /아우라수정   /아우라정리
/아우라배포                  /아우라리뷰   /아우라컴팩트

# Japanese (日本語)
/オーラ ログイン作って        /オーラビルド /オーラ修正   /オーラ整理
/オーラデプロイ              /オーラレビュー /オーラコンパクト

# Chinese (中文)
/奥拉 创建登录功能            /奥拉构建    /奥拉修复    /奥拉清理
/奥拉部署                    /奥拉审查    /奥拉压缩

# Spanish · French · German · Italian
/aura-construir  /aura-arreglar  /aura-limpiar  /aura-desplegar
/aura-construire /aura-corriger  /aura-nettoyer /aura-deployer
/aura-bauen      /aura-beheben   /aura-aufraeumen /aura-deployen
/aura-costruire  /aura-correggere /aura-pulire  /aura-distribuire
</pre>

**IME support**: Korean and Japanese IME reverse-transliteration is handled automatically. Typing `/멱ㅁ` converts to `/aura`, `/채ㅡㅔㅁㅊㅅ` converts to `/compact`.

---

## Architecture

<pre>
aurakit/
├── .claude-plugin/
│   └── plugin.json               # Claude Code plugin manifest
├── skills/
│   ├── aura/                     # Main skill (single /aura entry point)
│   │   ├── SKILL.md              # Core instructions (AuraKit v3.6)
│   │   └── resources/            # 26 mode-specific pipeline guides
│   │       ├── build-pipeline.md
│   │       ├── fix-pipeline.md
│   │       ├── clean-pipeline.md
│   │       ├── deploy-pipeline.md
│   │       ├── review-pipeline.md
│   │       ├── security-rules.md
│   │       ├── qa-pipeline.md
│   │       ├── tdd-pipeline.md
│   │       ├── pm-pipeline.md
│   │       └── ...               # +16 more mode guides
│   ├── aura-compact/
│   │   └── SKILL.md              # Snapshot + auto compact
│   ├── aura-guard/
│   │   └── SKILL.md              # Token budget monitor
│   └── [49 multilingual shortcuts]  # 8 languages × mode commands
├── agents/
│   ├── scout.md                  # Read-only project scanner (Haiku)
│   ├── worker.md                 # Code reviewer + test runner (Sonnet)
│   ├── gap-detector.md           # Design-implementation gap check (Haiku)
│   ├── security.md               # OWASP Top 10 audit (Sonnet)
│   ├── pm-discovery.md           # OST opportunity discovery (Haiku)
│   ├── pm-strategy.md            # JTBD + Lean Canvas strategy (Haiku)
│   └── pm-prd.md                 # PRD generation (Sonnet)
├── hooks/
│   ├── lib/
│   │   ├── common.js             # Shared utilities (addContext, allow, block)
│   │   ├── snapshot.js           # Snapshot read/write/parse helpers
│   │   └── python.js             # Cross-platform Python executor
│   ├── security-scan.js          # Secret pattern detection (pre-commit)
│   ├── bash-guard.js             # Agent bash restriction (L3)
│   ├── build-verify.js           # Compile/type-check verification
│   ├── bloat-check.js            # 250-line file split warning
│   ├── migration-guard.js        # Destructive migration block
│   ├── injection-guard.js        # Prompt injection detection
│   ├── korean-command.js         # IME reverse-transliteration
│   ├── subagent-start.js         # Agent lifecycle: start tracking
│   ├── subagent-stop.js          # Agent lifecycle: stop + cache
│   ├── pre-compact-snapshot.js   # Save state before compact
│   ├── post-compact-restore.js   # Restore state after compact
│   ├── token-tracker.js          # Token usage tracking
│   └── token-stats-inject.js     # Token stats context injection
├── templates/
│   ├── design-system-default.md  # CSS variable tokens
│   ├── project-profile-template.md
│   └── snapshot-template.md
├── scripts/
│   └── init.sh                   # One-command installer
├── README.md
├── LICENSE                       # MIT
└── .gitignore
</pre>

---

## Security

### What AuraKit Blocks Automatically

- **Environment variable exposure** — .env values never appear in generated code
- **eval() and dynamic code execution** — always blocked
- **Raw SQL queries** — parameterized queries enforced
- **XSS vectors** — output encoding required
- **CSRF vulnerabilities** — token validation enforced
- **Hardcoded secrets** — regex patterns catch API keys, passwords, tokens
- **Destructive database migrations** — DROP TABLE, DROP COLUMN blocked without confirmation

### Security Scan Patterns

The security-scan.js hook checks for these patterns on every file write:

<pre>
DANGEROUS PATTERNS:
- API keys:       [A-Za-z0-9]{32,}
- AWS keys:       AKIA[0-9A-Z]{16}
- Private keys:   -----BEGIN.*PRIVATE KEY-----
- Passwords:      password\s*=\s*['"][^'"]+
- Tokens:         token\s*=\s*['"][^'"]+
- Connection strings with credentials
</pre>

---

## Comparison

| Feature | AuraKit | Manual Prompting | Other Skills |
|:--------|:--------|:----------------|:-------------|
| One-command full-stack build | Yes | No | Partial |
| Auto security scanning | 6 layers | None | 0-1 layer |
| Triple verification | Yes | No | No |
| Context memory protection | 65% early compact | 95% (too late) | None |
| Token usage (typical build) | ~4,600 | ~25,000 | ~15,000-50,000 |
| Project auto-detection | Scout agent | Manual | Manual |
| Destructive migration guard | Yes | No | No |
| Multilingual commands | 8 languages, 56 commands | No | No |
| Model tier selection | QUICK/ECO/PRO/MAX | No | No |
| Agent specialization | 7 dedicated agents | No | None |

---

## Compatibility

AuraKit follows the **Agent Skills open standard**. The core SKILL.md files work across multiple AI coding tools.

| Tool | SKILL.md | Hooks | Agents | Full Support |
|:-----|:---------|:------|:-------|:-------------|
| **Claude Code (Terminal)** | Yes | Yes | Yes | Yes |
| **Claude Code (Web)** | Yes | No | No | Partial |
| **Cursor** | Yes | No | No | Partial |
| **GitHub Copilot** | Yes | No | No | Partial |
| **Windsurf** | Yes | No | No | Partial |
| **Gemini CLI** | Yes | No | No | Partial |
| **Codex (OpenAI)** | Yes | No | No | Partial |
| **Goose** | Yes | No | No | Partial |
| **Amp** | Yes | No | No | Partial |
| **Roo Code** | Yes | No | No | Partial |
| **OpenCode** | Yes | No | No | Partial |
| **Antigravity** | Yes | No | No | Partial |

**Full support** means all features work: 6-layer security hooks, 7 specialized agents, compact defense, and triple verification. With partial support, you get the core skill instructions but without automated hook enforcement or agent delegation.

### Using AuraKit with other tools

Copy the skill folder into your tool's skill directory:

<pre>
# Cursor
cp -r skills/aura .cursor/skills/aura

# GitHub Copilot
cp -r skills/aura .github/skills/aura

# Codex
cp -r skills/aura .codex/skills/aura

# Gemini CLI
cp -r skills/aura .gemini/skills/aura
</pre>

---

## FAQ

**Q: What frameworks does AuraKit support?**

AuraKit is framework-agnostic. The Scout agent scans your project and adapts to whatever stack you use — Next.js, React, Vue, Svelte, Express, FastAPI, Django, and more. It reads your package.json, tsconfig, tailwind.config, prisma schema, and other config files to understand your setup.

**Q: Does AuraKit work with existing projects?**

Yes. AuraKit scans your existing codebase first, then generates code that matches your conventions, styling, and architecture.

**Q: What happens if I already have hooks configured?**

The init.sh installer merges AuraKit hooks into your existing settings.json without overwriting. Your current hooks stay intact.

**Q: Can I use AuraKit with Claude Code on Windows?**

Yes, and no WSL required. All hooks run as Node.js scripts (cross-platform). Git Bash is still recommended for running Claude Code itself, but all automation — including hook execution, snapshot saving, and Python script delegation — works natively on Windows without WSL.

**Q: How does the compact defense actually work?**

AuraKit sets CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65, which triggers compaction at 65% token usage instead of the default 95%. Before compaction, a PreCompact hook saves your current work state (completed files, remaining plan, key decisions) to a snapshot file on disk. After compaction, a PostCompact hook reloads that snapshot into context. Result: zero memory loss.

**Q: Is my code sent anywhere?**

No. AuraKit is a local skill. Everything runs inside your Claude Code session. No external APIs, no telemetry, no data collection.

---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you would like to change.

---

## License

MIT License. See LICENSE file for details.

---

<div align="center">

<br/>

**Built for developers who want to ship fast without cutting corners.**

<br/>

<a href="https://github.com/smorky850612/Aurakit">GitHub</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="https://github.com/smorky850612/Aurakit/issues">Issues</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="https://github.com/smorky850612/Aurakit/stargazers">Stars</a>

</div>
