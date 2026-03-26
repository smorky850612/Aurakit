# AuraKit -- Cross-Harness Compatibility Guide

> Run AuraKit at full capability on any AI coding platform.
> Loaded when user asks about platform compatibility, migration, or multi-tool setup.

---

## Overview

AuraKit is built on the **SKILL.md open standard** -- a frontmatter-based skill definition format that any AI coding harness can consume. While Claude Code has native first-class support, every major platform can run AuraKit's core workflows with the right adapter configuration.

### Support Matrix

| Platform | Setup Effort | Modes | Hooks | Agents | Security Layers |
|----------|-------------|-------|-------|--------|-----------------|
| Claude Code | None | All 33 | All 23 | Full isolation | 6/6 |
| OpenAI Codex CLI | Low | All 33 | Partial (sandbox) | Via agents.md | 4/6 |
| Cursor | Medium | All 33 | Manual | No isolation | 3/6 |
| Manus | Medium | All 33 | Via events | Native multi-agent | 3/6 |
| Windsurf | Medium | Most | Manual | Cascade only | 3/6 |
| Aider | High | BUILD, FIX | None | None | 1/6 |

---

## 1. Claude Code (Native -- Full Support)

AuraKit was designed for Claude Code. Zero additional setup required.

### What works out of the box

- **SKILL.md frontmatter**: `name`, `description`, `argument-hint`, `allowed-tools` -- all parsed natively.
- **Slash commands**: `/aura build:login`, `/aura fix:TypeError`, all 33 modes including multilingual variants.
- **Hooks (23 total)**: `PreToolCall`, `PostToolCall`, `UserPromptSubmit` -- security-scan.js, bash-guard.js, build-verify.js, convention-check.sh, korean-command.js all fire automatically.
- **Agent sub-processes**: Scout, Builder, Reviewer, SecurityAgent, TestRunner, etc. run as isolated sub-agents with `disallowed-tools` enforced per role.
- **6-layer security**: L1 (.env guard), L2 (tool restrictions), L3 (bash-guard), L4 (secret scanner), L5 (worktree isolation), L6 (convention checks).
- **Tiered model routing**: ECO/PRO/MAX with automatic haiku/sonnet/opus assignment per agent.

### Installation

```bash
bash install.sh
claude --dangerously-skip-permissions
/aura build:login feature
```

No adapter, no config files, no workarounds.

---

## 2. OpenAI Codex CLI

Codex adopted the SKILL.md / agents.md open standard (December 2025), making it the closest alternative to Claude Code for running AuraKit.

### Setup

1. **Copy SKILL.md** to Codex's skill directory:

```bash
cp skills/aura/SKILL.md ~/.codex/skills/aura/SKILL.md
cp -r skills/aura/resources/ ~/.codex/skills/aura/resources/
```

2. **Agent definitions** -- Codex reads `agents.md` format natively:

```bash
cp -r agents/ ~/.codex/agents/
```

### Agent Mapping

AuraKit agents map to Codex agent files in the `agents/` directory:

| AuraKit Agent | Codex agents.md file | Notes |
|---------------|---------------------|-------|
| Scout | `agents/scout.md` | Set `disallowedTools: [Write, Edit]` |
| Builder | `agents/builder.md` | Full tool access |
| Reviewer | `agents/reviewer.md` | Set `disallowedTools: [Write, Edit]` |
| SecurityAgent | `agents/security.md` | Read-only + limited Bash |
| TestRunner | `agents/tester.md` | Read + Bash (test execution) |

### Model Mapping

| AuraKit Tier | AuraKit Model | Codex Equivalent |
|-------------|---------------|------------------|
| ECO (haiku) | claude-haiku-4-5 | gpt-4o-mini |
| PRO (sonnet) | claude-sonnet-4 | gpt-4o |
| MAX (opus) | claude-opus-4 | o3 |

Set in Codex config:

```json
{
  "model": "gpt-4o",
  "agents": {
    "scout": { "model": "gpt-4o-mini" },
    "builder": { "model": "gpt-4o" },
    "reviewer": { "model": "o3" }
  }
}
```

### Hooks Workaround

Codex does not support `PreToolCall` / `PostToolCall` hooks natively. Use Codex's sandbox pre/post commands instead:

```yaml
# .codex/sandbox.yml
pre_commands:
  - node .aura/hooks/security-scan.js
  - bash .aura/hooks/convention-check.sh
post_commands:
  - node .aura/hooks/build-verify.js
```

**Limitations**: No real-time `UserPromptSubmit` interception (Korean IME reverse-mapping, slash command aliases will not auto-fire). Users must type commands in English.

### Tool Restrictions

Codex uses `full-auto` mode by default. Enforce AuraKit's least-privilege model via the `disallowedTools` field in each `agents.md` file:

```markdown
---
name: aura-reviewer
disallowedTools:
  - Write
  - Edit
  - Bash
---
```

---

## 3. Cursor

Cursor is an AI-powered IDE with its own rules system and Composer Agent mode.

### Setup

**Option A -- .cursorrules file** (recommended):

```bash
# From your project root
cp skills/aura/SKILL.md .cursorrules
```

**Option B -- Cursor Settings UI**:

1. Open Cursor Settings > Rules.
2. Paste the full contents of `SKILL.md` into the Rules text area.
3. For resource files, add them as additional context files.

### Agent Mode

Cursor's **Composer Agent** mode supports multi-file edits, which aligns with AuraKit's BUILD/FIX/CLEAN workflows:

| AuraKit Workflow | Cursor Equivalent |
|-----------------|-------------------|
| BUILD pipeline | Composer Agent with multi-file edit |
| FIX pipeline | Composer Agent with error context |
| REVIEW pipeline | Manual -- use Cursor's inline review |
| CLEAN pipeline | Composer Agent with refactor prompt |

### Model Mapping

| AuraKit Tier | AuraKit Model | Cursor Equivalent |
|-------------|---------------|-------------------|
| ECO (haiku) | claude-haiku-4-5 | cursor-small |
| PRO (sonnet) | claude-sonnet-4 | claude-sonnet (via model selector) |
| MAX (opus) | claude-opus-4 | claude-opus (via model selector) |

Select models in Cursor's model dropdown per conversation. Cursor does not support per-agent model assignment.

### Hooks

Cursor has no native hook system. Workarounds:

1. **VS Code Tasks** -- define pre-commit hooks as VS Code tasks in `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "AuraKit Security Scan",
      "type": "shell",
      "command": "node .aura/hooks/security-scan.js",
      "runOptions": { "runOn": "folderOpen" }
    },
    {
      "label": "AuraKit Convention Check",
      "type": "shell",
      "command": "bash .aura/hooks/convention-check.sh"
    }
  ]
}
```

2. **Manual execution** -- run hooks via Cursor's integrated terminal before committing.

### Limitations

- No automatic agent sub-process isolation.
- No real-time hook triggers on tool calls.
- No `disallowed-tools` enforcement -- all tools available to every "agent" prompt.
- Multi-language slash commands not supported.

---

## 4. Manus

Manus is a cloud-based AI agent platform with native multi-agent orchestration.

### Setup

1. **System prompt method**: Paste the contents of `SKILL.md` as the system prompt for your Manus workspace.
2. **Knowledge base method**: Upload the full `skills/aura/resources/` directory as a knowledge base, then reference it in agent prompts.

```
Manus Dashboard > Workspace > Knowledge Base > Upload Directory
Select: skills/aura/resources/
```

### Agent Orchestration

Manus has native multi-agent support. Map AuraKit agents directly to Manus agents:

| AuraKit Agent | Manus Agent Config |
|---------------|-------------------|
| Scout | Create agent: read-only tools, exploration prompt |
| Builder | Create agent: full tool access, implementation prompt |
| Reviewer | Create agent: read-only, review checklist prompt |
| SecurityAgent | Create agent: read-only, OWASP scan prompt |
| CTO (orchestrator) | Use Manus's built-in orchestrator to coordinate |

Manus's orchestration maps well to AuraKit's 4 patterns:

| AuraKit Pattern | Manus Equivalent |
|----------------|------------------|
| Solo (single agent) | Single agent execution |
| Pipeline (sequential) | Sequential agent chain |
| Swarm (parallel) | Parallel agent execution |
| Council (vote) | Multi-agent consensus |

### Hooks via Events

Use Manus's event system to replicate AuraKit hooks:

```yaml
events:
  on_task_start:
    - action: run_script
      script: security-scan.js
  on_task_complete:
    - action: run_script
      script: build-verify.js
  on_file_write:
    - action: run_script
      script: convention-check.sh
```

### Model Mapping

Manus uses its own model routing engine. You cannot directly select haiku/sonnet/opus. Instead:

- Configure agent complexity levels in Manus (low/medium/high).
- Manus will route to appropriate models internally.
- For critical agents (Builder, Reviewer in MAX tier), set agent priority to "high".

---

## 5. Windsurf (Codeium)

Windsurf is Codeium's AI IDE with the Cascade agent for multi-step workflows.

### Setup

**Option A -- .windsurfrules file**:

```bash
cp skills/aura/SKILL.md .windsurfrules
```

**Option B -- Cascade Settings**:

1. Open Windsurf Settings > Cascade > Custom Rules.
2. Paste SKILL.md contents.
3. Add resource files as context.

### Cascade Agent

Windsurf's Cascade supports multi-step flows that align with AuraKit pipelines:

| AuraKit Pipeline | Cascade Mapping |
|-----------------|-----------------|
| BUILD: Scout > Plan > Build > Verify | Cascade multi-step with file context |
| FIX: Diagnose > Fix > Verify | Cascade with error context |
| CLEAN: Analyze > Refactor > Verify | Cascade with refactor instructions |
| REVIEW: Read > Analyze > Report | Cascade read-only flow |

### Model Mapping

| AuraKit Tier | Windsurf Equivalent |
|-------------|---------------------|
| ECO (haiku) | Default Cascade model |
| PRO (sonnet) | Select via Windsurf model picker |
| MAX (opus) | Select via Windsurf model picker (if available) |

Model selection depends on your Windsurf subscription tier and available models.

### Limitations

- No per-agent tool restrictions.
- No hook system -- manual verification required.
- Cascade does not support isolated sub-agent execution.
- Multi-language slash commands not available.

---

## 6. Aider

Aider is a terminal-based pair-programming tool. It is the most limited platform for AuraKit.

### Setup

**Option A -- .aider.conf.yml**:

```yaml
# .aider.conf.yml
read:
  - skills/aura/SKILL.md
  - skills/aura/resources/build-pipeline.md
  - skills/aura/resources/fix-pipeline.md
```

**Option B -- Inline paste**: Start an Aider session and paste the relevant pipeline instructions directly.

### Supported Modes

Aider is pair-programming focused, not multi-agent. Only these AuraKit modes map well:

| AuraKit Mode | Aider Support | Notes |
|-------------|---------------|-------|
| BUILD | Partial | Aider can generate code across files |
| FIX | Partial | Aider can apply targeted fixes |
| CLEAN | Limited | Manual refactor guidance only |
| REVIEW | None | Aider does not have a read-only mode |
| DEPLOY | None | No deployment orchestration |
| TDD | Limited | Can write tests but no RED/GREEN/REFACTOR cycle |

### Limitations

- **No agents**: Aider runs a single model. No Scout/Builder/Reviewer separation.
- **No hooks**: No pre/post tool call interception.
- **No security layers**: No bash-guard, no secret scanning, no convention checks.
- **No orchestration patterns**: No pipeline, swarm, or council execution.
- **Best use case**: Quick BUILD and FIX tasks where you need AuraKit's code generation patterns but not its full orchestration.

---

## Universal Compatibility Layer

### SKILL.md Frontmatter (Open Standard)

The SKILL.md frontmatter is the portable unit of AuraKit. Every platform that reads markdown-based instructions can consume it:

```yaml
---
name: aura                          # Skill identifier
description: "All-in-one ..."      # Platform reads this for capability matching
argument-hint: "[natural language]" # Input guidance for the user
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch
---
```

**Field mapping across platforms**:

| SKILL.md Field | Claude Code | Codex CLI | Cursor | Manus | Windsurf | Aider |
|---------------|-------------|-----------|--------|-------|----------|-------|
| `name` | Skill name | Skill name | Rule name | Agent name | Rule name | -- |
| `description` | Auto-loaded | Auto-loaded | Displayed | System prompt | Displayed | -- |
| `allowed-tools` | Enforced | Enforced | Informational | Configurable | Informational | -- |
| `disallowed-tools` | Enforced | Via agents.md | Not enforced | Per-agent | Not enforced | -- |
| `argument-hint` | Shown in UI | Shown in UI | Not shown | Not shown | Not shown | -- |

### Agent Definitions (agents/ directory)

The `agents/` directory follows the agents.md standard. Each file defines:

```markdown
---
name: aura-scout
description: Codebase exploration agent. Read-only.
disallowed-tools:
  - Write
  - Edit
  - Bash
model: claude-haiku-4-5
---

## Instructions
1. Scan the project structure using Glob and Read.
2. Generate project-profile.md.
3. Do NOT modify any files.
```

Platforms that support agents.md (Claude Code, Codex CLI) will parse these natively. For other platforms, convert to their agent configuration format.

### Manual Verification Steps (for platforms without hooks)

When hooks are not available, run these checks manually before every commit:

```bash
# 1. Secret scan -- no API keys, passwords, or tokens in code
node .aura/hooks/security-scan.js

# 2. Convention check -- code style, file size limits, type safety
bash .aura/hooks/convention-check.sh

# 3. Build verification -- type errors, test failures
node .aura/hooks/build-verify.js

# 4. Bash guard -- verify no dangerous shell commands were used
node .aura/hooks/bash-guard.js
```

Add these as a pre-commit git hook for any platform:

```bash
# .git/hooks/pre-commit
#!/bin/bash
node .aura/hooks/security-scan.js || exit 1
bash .aura/hooks/convention-check.sh || exit 1
node .aura/hooks/build-verify.js || exit 1
```

---

## Adapter Installation Script

AuraKit provides a CLI adapter that detects and configures for your platform.

> **Status**: Aspirational -- the adapter interface is defined below. Implementation is tracked in the AuraKit roadmap.

### Usage

```bash
# Auto-detect platform
npx @smorky85/aurakit --platform=auto

# Explicit platform selection
npx @smorky85/aurakit --platform=cursor
npx @smorky85/aurakit --platform=codex
npx @smorky85/aurakit --platform=manus
npx @smorky85/aurakit --platform=windsurf
npx @smorky85/aurakit --platform=aider
```

### What the adapter does per platform

| Platform | Adapter Action |
|----------|---------------|
| `cursor` | Copies SKILL.md to `.cursorrules`, creates `.vscode/tasks.json` with hook tasks |
| `codex` | Copies SKILL.md + resources to `~/.codex/skills/aura/`, generates agents.md files, creates `sandbox.yml` |
| `manus` | Generates system prompt file and event configuration YAML |
| `windsurf` | Copies SKILL.md to `.windsurfrules`, outputs manual hook instructions |
| `aider` | Generates `.aider.conf.yml` with resource file references |

### Adapter detection logic

```
1. Check for .claude/ directory         -> Claude Code
2. Check for .codex/ directory          -> Codex CLI
3. Check for .cursorrules or .cursor/   -> Cursor
4. Check for .windsurfrules             -> Windsurf
5. Check for .aider.conf.yml            -> Aider
6. Check MANUS_API_KEY env variable     -> Manus
7. Fallback                             -> Prompt user to select
```

---

## Migration Checklist

When moving an AuraKit project from Claude Code to another platform:

- [ ] Copy `skills/aura/SKILL.md` to the platform's rule location
- [ ] Copy `skills/aura/resources/` for pipeline reference docs
- [ ] Convert agent definitions to the platform's format (if not agents.md)
- [ ] Set up hooks as pre-commit hooks or platform-specific events
- [ ] Map model tiers to the platform's available models
- [ ] Test BUILD and FIX pipelines first (highest compatibility)
- [ ] Verify security checks run (secret scan, convention check)
- [ ] Accept limitations: some platforms will never support full agent isolation or real-time hooks

---

## FAQ

**Q: Can I run AuraKit on multiple platforms simultaneously?**
A: Yes. The SKILL.md and resources directory are read-only references. You can have `.cursorrules`, `.windsurfrules`, and `~/.codex/skills/` all pointing to the same source files. Use symlinks to avoid duplication.

**Q: Which platform is closest to Claude Code in capability?**
A: OpenAI Codex CLI, because it natively supports the SKILL.md frontmatter format and agents.md agent definitions. It only lacks real-time hook interception.

**Q: Do I lose security when running on non-Claude platforms?**
A: Partially. Layers L1 (env guard) and L6 (convention checks) work everywhere via git hooks. Layers L2-L5 (tool restrictions, bash-guard, secret scanner, worktree isolation) require platform-specific setup or may not be available. Always set up the pre-commit hook as a baseline.

**Q: What about model quality differences across platforms?**
A: AuraKit's pipeline logic is model-agnostic. The prompts, checklists, and verification steps work regardless of which LLM executes them. Model quality affects output quality, but the process remains consistent.
