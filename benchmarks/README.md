# AuraKit Benchmarks

Independent token usage measurement: **Control** vs **ECO** vs **PRO** tier.

## Tasks

| Task | Description | Stack |
|------|-------------|-------|
| [T1](tasks/T1-rest-api.md) | REST API + JWT Auth | TypeScript + Express + PostgreSQL |
| [T2](tasks/T2-jwt-auth.md) | JWT Refresh Token Flow | TypeScript + Express + Redis |
| [T3](tasks/T3-sql-opt.md) | SQL Query Optimization | PostgreSQL + Prisma |
| [T4](tasks/T4-refactor.md) | Component Refactor (250-line) | React 18 + TypeScript |
| [T5](tasks/T5-devops.md) | Docker + CI/CD Setup | Node.js + Docker + GitHub Actions |

## Methodology

- **3 runs per task/tier** → average with 95% confidence interval
- **Control**: Claude Code without AuraKit (raw prompts)
- **ECO**: `/aura [task]` (haiku Scout + sonnet Builder)
- **PRO**: `/aura pro [task]` (haiku Scout + opus Builder)

## Running

```bash
bash benchmarks/run-benchmark.sh        # Show measurement guide
bash benchmarks/run-benchmark.sh T1 eco # Guide for specific task/tier
```

Token measurement requires manual tracking via Claude.ai Usage dashboard or Anthropic API proxy.

## Results

Results are stored in `results/benchmark-[timestamp].json` after manual measurement.

> Results will be published to README.md badges once 3-run averages are established.
