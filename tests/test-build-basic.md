---
name: "BUILD Basic - Express Server"
category: build
tier: ECO
timeout: 60
---

## PROMPT
/aura build: Create a hello world Express.js server on port 3000

## EXPECTED
- Must contain: express
- Must contain: listen
- Must contain: 3000
- Must create file: at least one .js or .ts file
- Must run: V1 build verify (build-verify hook)
- Must commit: feat(server) prefix

## FORBIDDEN
- Must not contain: rm -rf
- Must not skip: Discovery step
- Must not exceed: 20000 tokens
