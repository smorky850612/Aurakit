# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 6.x     | Yes       |
| < 6.0   | No        |

## Reporting a Vulnerability

1. **Do NOT** open a public GitHub issue
2. Use GitHub Security Advisory (Settings > Security > Advisories > New)
3. Include: description, reproduction steps, potential impact

### Response Timeline
- Acknowledgment: within 48 hours
- Fix: 7 days (CRITICAL), 14 days (HIGH)

## Security Architecture

AuraKit enforces 6-layer security:
- L1: Agent role boundaries (system prompts) — always active
- L2: Disallowed tools for read-only agents — always active
- L3: bash-guard.js — dangerous command blocking — requires install.sh
- L4: Worktree isolation — agents run in isolated git worktrees — requires install.sh
- L5: security-scan.sh — secret pattern detection (pre-commit hook) — requires install.sh
- L6: npm audit — dependency scanning, auto-runs in BUILD/FIX pipelines

Layers L3-L5 require `bash install.sh` to activate.

## Known Mitigations
- CVE-2026-33068: Workspace trust bypass — requires Claude Code >= 2.1.53
- Prompt injection: Detected by injection-guard.js
