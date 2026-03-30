---
name: "Instinct - Auto Save After BUILD"
category: instinct
tier: ECO
timeout: 60
---

## PROMPT
/aura build: Add a utility function to format dates

## EXPECTED
- Must complete: BUILD pipeline
- Must trigger: instinct-auto-save.js hook
- Must create or update: .aura/instincts/ directory with pattern file

## FORBIDDEN
- Must not crash: on missing .aura/instincts/ directory
- Must not save: sensitive data (API keys, paths) in instinct
