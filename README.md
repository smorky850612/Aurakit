<div align="center">

<img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" />
<img src="https://img.shields.io/badge/Claude_Code-Skill-blueviolet?style=flat-square" alt="Claude Code Skill" />
<img src="https://img.shields.io/badge/version-1.0.0-brightgreen?style=flat-square" alt="Version" />
<img src="https://img.shields.io/badge/security-4_layer-critical?style=flat-square" alt="Security" />
<img src="https://img.shields.io/github/stars/smorky850612/Aurakit?style=flat-square&color=yellow" alt="Stars" />

<br /><br />

<h1>AuraKit</h1>

<h3>One command. Full stack. Zero compromise.</h3>

<p><strong>All-in-one Claude Code skill</strong> that builds, fixes, cleans, deploys, and reviews your entire project<br />with 4-layer security, triple verification, and automatic context defense.</p>

<p>
<a href="#-getting-started">Getting Started</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#-features">Features</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#-how-it-works">How It Works</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#-commands">Commands</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#-security">Security</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="#-faq">FAQ</a>
</p>

</div>

<br />

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

### 6 Intelligent Modes

AuraKit auto-detects what you need based on your prompt.

| Mode | Trigger Example | What It Does |
|:-----|:---------------|:-------------|
| **BUILD** | "로그인 기능 만들어줘" | Full-stack feature generation |
| **FIX** | "이 에러 고쳐줘" | Root cause analysis and targeted fix |
| **CLEAN** | "코드 정리해줘" | Dead code removal and refactoring |
| **DEPLOY** | "배포해줘" | Build optimization and deploy config |
| **REVIEW** | "코드 리뷰해줘" | Security and quality audit |
| **COMPACT** | "컨텍스트 정리해줘" | Manual context compression |

### 4-Layer Security System

Every file AuraKit generates passes through 4 security gates.

| Layer | What It Checks | How |
|:------|:---------------|:----|
| **L1 — Skill Rules** | No eval(), no env exposure, parameterized SQL | Rules in SKILL.md |
| **L2 — Security Scan Hook** | Secret patterns, API keys, hardcoded credentials | hooks/security-scan.sh |
| **L3 — Worker Agent Review** | OWASP Top 10, XSS/CSRF, rate limiting, input validation | agents/worker.md |
| **L4 — Migration Guard** | Destructive DB migration blocking | hooks/migration-guard.sh |

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
| Hook-First Architecture (8 bash scripts, 0 tokens) | ~40% reduction |
| Fail-Only Output Filtering | ~25% reduction |
| Progressive Disclosure via resources/ | ~20% reduction |
| Scan-Once Cache (.aura/project-profile.md) | ~15% reduction |

Typical BUILD job uses ~4,600 tokens. Comparable setups without AuraKit use 25,000-50,000 tokens.

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

### Examples

<pre>
/aura 로그인/회원가입 기능 만들어줘 (Next.js + Prisma)
/aura Fix the TypeError in dashboard/page.tsx
/aura 코드 정리하고 안 쓰는 import 제거해줘
/aura 이 프로젝트 Vercel에 배포할 수 있게 설정해줘
/aura 전체 코드 보안 리뷰해줘
/aura 컨텍스트 정리해줘
</pre>

---

## Architecture

<pre>
aurakit/
├── skills/
│   ├── aura/                     # Main skill
│   │   ├── SKILL.md              # Core instructions (under 400 lines)
│   │   └── resources/
│   │       ├── build-pipeline.md
│   │       ├── fix-pipeline.md
│   │       ├── clean-pipeline.md
│   │       ├── deploy-pipeline.md
│   │       ├── review-pipeline.md
│   │       └── security-rules.md
│   ├── aura-compact/
│   │   └── SKILL.md              # Manual context compression
│   └── aura-guard/
│       └── SKILL.md              # Token budget monitor
├── agents/
│   ├── scout.md                  # Project scanner (Haiku model)
│   └── worker.md                 # Code reviewer (Sonnet model)
├── hooks/
│   ├── pre-session.sh            # Project profile check
│   ├── security-scan.sh          # Secret pattern detection
│   ├── build-verify.sh           # Compile verification
│   ├── bloat-check.sh            # Line count warning
│   ├── migration-guard.sh        # Destructive migration block
│   ├── output-filter.sh          # Suppress success output
│   ├── pre-compact-snapshot.sh   # Save state before compact
│   └── post-compact-restore.sh   # Restore state after compact
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

The security-scan.sh hook checks for these patterns on every file write:

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
| Auto security scanning | 4 layers | None | 0-1 layer |
| Triple verification | Yes | No | No |
| Context memory protection | 65% early compact | 95% (too late) | None |
| Token usage (typical build) | ~4,600 | ~25,000 | ~15,000-50,000 |
| Project auto-detection | Scout agent | Manual | Manual |
| Destructive migration guard | Yes | No | No |

---

## FAQ

**Q: What frameworks does AuraKit support?**

AuraKit is framework-agnostic. The Scout agent scans your project and adapts to whatever stack you use — Next.js, React, Vue, Svelte, Express, FastAPI, Django, and more. It reads your package.json, tsconfig, tailwind.config, prisma schema, and other config files to understand your setup.

**Q: Does AuraKit work with existing projects?**

Yes. AuraKit scans your existing codebase first, then generates code that matches your conventions, styling, and architecture.

**Q: What happens if I already have hooks configured?**

The init.sh installer merges AuraKit hooks into your existing settings.json without overwriting. Your current hooks stay intact.

**Q: Can I use AuraKit with Claude Code on Windows?**

Yes. The hooks use bash scripts, so on Windows you need WSL (Windows Subsystem for Linux) or Git Bash. Claude Code on Windows typically runs through WSL already.

**Q: How does the compact defense actually work?**

AuraKit sets CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65, which triggers compaction at 65% token usage instead of the default 95%. Before compaction, a PreCompact hook saves your current work state (completed files, remaining plan, key decisions) to a snapshot file on disk. After compaction, a PostCompact hook reloads that snapshot into context. Result: zero memory loss.

**Q: Is my code sent anywhere?**

No. AuraKit is a local skill. Everything runs inside your Claude Code session. No external APIs, no telemetry, no data collection.

---

## Roadmap

- v1.1 — Multi-project workspace support
- v1.2 — Custom security rule definitions
- v1.3 — Team shared configuration profiles
- v1.4 — Visual Studio Code extension integration

---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you would like to change.

---

## License

MIT License. See LICENSE file for details.

---

<div align="center">

<br />

**Built for developers who want to ship fast without cutting corners.**

<br />

<a href="https://github.com/smorky850612/Aurakit">GitHub</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="https://github.com/smorky850612/Aurakit/issues">Issues</a>&nbsp;&nbsp;·&nbsp;&nbsp;<a href="https://github.com/smorky850612/Aurakit/stargazers">Stars</a>

</div>
