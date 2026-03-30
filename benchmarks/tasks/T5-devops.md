# T5 — Docker + CI/CD Setup

## Task
Create production-ready Docker + GitHub Actions setup:

Requirements:
- `Dockerfile` — multi-stage build (builder + runtime)
- `docker-compose.yml` — app + postgres + redis
- `.github/workflows/ci.yml` — lint + test + build + push to GHCR
- `.github/workflows/deploy.yml` — tag-triggered deploy to production
- Health check endpoint: `GET /api/health`
- Non-root user in container
- No secrets in Dockerfile

Target stack: Node.js 20 + PostgreSQL 16 + Redis 7

## Measurement
- Token usage: input + output
- Files created: count
- Security issues in Dockerfile: count (non-root, no secrets)
- CI config correctness: manual review

## Success Criteria
- Multi-stage Dockerfile (no dev deps in production image)
- Non-root user configured
- Secrets via environment variables only
- CI runs on PR, deploy runs on tag push
- Health check returns `{ status: "ok" }`
