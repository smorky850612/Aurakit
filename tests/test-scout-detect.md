---
name: "Scout - Framework Auto-Detection"
category: scout
tier: ECO
timeout: 30
---

## PROMPT
/aura status

## EXPECTED
- Must read: package.json or equivalent
- Must detect: framework type
- Must create or update: .aura/project-profile.md

## FORBIDDEN
- Must not overwrite: existing project-profile.md without ConfigHash change
- Must not use: Write tool (Scout is read-only)
