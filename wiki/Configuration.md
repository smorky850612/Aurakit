<div align="center">

[![Config](https://img.shields.io/badge/config-zero%20required-6ee7b7?style=flat-square&labelColor=161b22)]()
[![MCP](https://img.shields.io/badge/MCP%20servers-14%20supported-38bdf8?style=flat-square&labelColor=161b22)]()

</div>

# Configuration

> AuraKit works with zero configuration. Everything here is optional customization.

---

## Quality Tier

<details open>
<summary><b>Set your default tier</b></summary>

```bash
/aura config: set default-tier pro
```

Or override per-command:
```bash
/aura build: payment integration --tier max
/aura fix: typo in button --tier quick
```

| Tier | When to use |
|------|-------------|
| `quick` | Quick fixes, typos, simple one-liners |
| `eco` | Most tasks — the right balance |
| `pro` | Complex features, security-critical code |
| `max` | Architecture decisions, full system design |

</details>

---

## Project Profile Override

<details>
<summary><b>Fix incorrect stack detection</b></summary>

Scout auto-detects your stack. If it gets something wrong, edit the profile directly:

```markdown
# .aura/project-profile.md

Framework:    Next.js 14 (App Router)
Language:     TypeScript 5.3
Package mgr:  pnpm
Database:     PostgreSQL via Prisma
Auth:         NextAuth.js
Styling:      Tailwind CSS v3
Testing:      Vitest + Playwright
CI:           GitHub Actions
Deploy:       Vercel
```

</details>

---

## Design System

<details>
<summary><b>Make all UI generation consistent</b></summary>

Create `.aura/design-system.md` and every UI-related `/aura` command will use these tokens:

```markdown
# .aura/design-system.md

Primary:       #6366f1
Secondary:     #8b5cf6
Background:    #0f0f13
Surface:       #161b22
Text:          #e2e8f0
Text-muted:    #8b949e
Border:        #30363d

Font-family:   Inter, system-ui
Font-size-base: 16px
Border-radius: 8px
Shadow:        0 4px 24px rgba(0,0,0,0.4)
```

</details>

---

## MCP Server Configuration

<details>
<summary><b>Configure external service integrations</b></summary>

```bash
/aura mcp: setup supabase
/aura mcp: setup github
/aura mcp: setup playwright
```

**Supported servers:**

| Server | What it enables |
|--------|-----------------|
| **Playwright** | E2E test generation + execution |
| **GitHub** | PR creation, issue management |
| **Slack** | Deploy notifications |
| **Linear** | Issue tracking integration |
| **Notion** | Documentation sync |
| **Supabase** | Direct DB operations |
| **PostgreSQL** | Raw query execution |
| **MongoDB** | Document operations |
| **Redis** | Cache management |
| **Stripe** | Payment integration helpers |
| **Vercel** | Deployment + preview URLs |
| **AWS** | S3, Lambda, CloudFormation |
| **Sanity** | CMS content management |

</details>

---

## Instinct System

<details>
<summary><b>View and manage learned patterns</b></summary>

```bash
/aura instinct: show patterns        # What AuraKit has learned
/aura instinct: show anti-patterns   # Mistakes it avoids
/aura instinct: reset                # Clear all learned patterns
```

Manually add a pattern to teach AuraKit team-specific conventions:

```markdown
# .aura/instincts/patterns.md

## Always use Prisma transactions for multi-table writes
When writing to more than one table, wrap in prisma.$transaction([...])
Context: We had a data consistency bug when payment wrote but order
         status didn't update.
```

</details>

---

## Session Snapshots

<details>
<summary><b>Save context before /compact</b></summary>

```bash
/aura-compact
```

This saves to `.aura/snapshots/current.md` and walks you through `/compact`. After compacting, AuraKit restores context automatically via `post-compact-restore.js`.

Manual checkpoint:
```bash
/aura archive: save checkpoint
```

> [!TIP]
> Run `/aura-compact` proactively when you're about to start a large task. Having a clean snapshot makes recovery from interruptions instant.

</details>

---

## Hook Configuration

<details>
<summary><b>Disable individual hooks (not recommended)</b></summary>

Hooks live in `~/.claude/settings.json`. To disable one:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.claude/hooks/bash-guard.js",
            "enabled": false
          }
        ]
      }
    ]
  }
}
```

> [!WARNING]
> Disabling security hooks (L3–L5) removes active protections. Only do this if you have a specific reason and understand the risk. The `bash-guard.js`, `security-scan.js`, and `migration-guard.js` hooks should remain enabled.

</details>

---

## Environment Variables

| Variable | Effect |
|----------|--------|
| `AURA_TIER` | Override default quality tier |
| `AURA_LANG` | Set default language reviewer |
| `AURA_INSTINCT` | Set to `off` to disable instinct loading |
| `AURA_LOG` | Set to `verbose` for full hook output |
