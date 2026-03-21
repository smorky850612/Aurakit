# AuraKit — Claude Code Plugin

> All-in-one fullstack development engine. One command, full stack, zero compromise.

## Install

```bash
claude plugin install aurakit
```

Or from source:

```bash
claude plugin install .
```

## What's Included

52 skills across 8 languages:

| Skill | Description |
|-------|-------------|
| `/aura` | Main engine — 28 modes (BUILD/FIX/CLEAN/DEPLOY/REVIEW/QA/...) |
| `/아우라` `/오라` | Korean shortcuts |
| `/オーラ` | Japanese shortcuts |
| `/奥拉` | Chinese shortcuts |
| `/aura-es` `/aura-fr` `/aura-de` `/aura-it` | European language shortcuts |
| `/aura-compact` | Snapshot + compact in one command |
| `/aura-guard` | Token budget monitor |

## Quick Start

```bash
# Build a feature
/aura 로그인 기능 만들어줘

# Fix a bug
/aura fix:TypeError at UserList.tsx:45

# Full QA
/aura qa:

# Review + security scan
/aura review:
```

## Modes (28 total)

BUILD · FIX · CLEAN · DEPLOY · REVIEW · GAP · ITERATE · TDD · PM · PLAN · DESIGN · REPORT · PIPELINE · STYLE · SNIPPETS · QA · DEBUG · BRAINSTORM · ORCHESTRATE · MOBILE · DESKTOP · BAAS · STATUS · CONFIG · ARCHIVE · BATCH · FINISH · QUICK

## Tiers

| Tier | Command | Cost | Use For |
|------|---------|------|---------|
| QUICK | `/aura! ...` | ~60% savings | Single-file, prototypes |
| ECO | `/aura ...` | ~55% savings | Daily development (default) |
| PRO | `/aura pro ...` | ~20% savings | Complex features |
| MAX | `/aura max ...` | Full | Security audits, architecture |

## Plugin Structure

```
.claude-plugin/
  plugin.json    — Plugin manifest
  README.md      — This file

skills/
  aura/          — Main skill (SKILL.md + resources/)
  aura-compact/  — Compact shortcut
  aura-guard/    — Token monitor
  aura-*/        — Language shortcuts (ES/FR/DE/IT/...)
  아우라*/        — Korean shortcuts
  オーラ*/        — Japanese shortcuts
  奥拉*/          — Chinese shortcuts

hooks/           — Build verify, security scan, agent lifecycle
scripts/         — Convention check, bloat check
```

## Requirements

- Claude Code v2.1.71+
- Git
