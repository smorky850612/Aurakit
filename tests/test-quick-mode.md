---
name: "QUICK Mode - Simple UI Change"
category: build
tier: QUICK
timeout: 30
---

## PROMPT
/aura! Change the main button color to blue

## EXPECTED
- Must modify or create: at least one CSS/SCSS/styled file
- Must contain: blue or #0000ff or similar blue color value
- Response language: same as user input

## FORBIDDEN
- Must not contain: Error: or stack trace
- Must not run: full Scout pipeline (QUICK skips it)
