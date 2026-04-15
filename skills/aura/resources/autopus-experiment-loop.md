# Autopus XLOOP — Experiment Loop

> Absorbed from Autopus-ADK. XLOOP = Autonomous metric-driven improvement loop.
> Continuously measures → changes → measures → decides → repeats.

---

## Overview

XLOOP is an autonomous improvement loop that:
1. Measures a baseline metric
2. Makes a focused change
3. Measures the new metric
4. Keeps or discards the change based on improvement
5. Repeats until improvement threshold or circuit breaker

Unlike ITERATE (which targets a fixed gap), XLOOP explores improvement space autonomously.

---

## Metric Types

```
performance  → benchmark time (ms), throughput (req/s)
quality      → test coverage (%), lint score
size         → bundle size (KB), binary size
complexity   → cyclomatic complexity, file line count
custom       → any numeric metric you define
```

---

## XLOOP Protocol

### Init

```bash
/aura experiment:init [metric-type] [target]
# Example:
/aura experiment:init performance p99<50ms
/aura experiment:init coverage >=85%
/aura experiment:init size bundle<200KB
```

Creates: `.aura/experiments/{id}/baseline.json`

### Measure Baseline

```bash
/aura experiment:metric
```

Runs measurement command appropriate for metric type:
```bash
# Performance
npx autocannon -d 10 http://localhost:3000/api/endpoint
# Coverage
npx vitest run --coverage --reporter=json | jq '.total.lines.pct'
# Bundle size
npx next build && du -sh .next/static/chunks/*.js | sort -rh | head -5
```

### Change Cycle

```bash
/aura experiment:commit [change-description]
# Agent makes focused change, measures new metric
# Decision: keep (improved) or discard (no improvement)
```

Decision formula:
```
improvement_ratio = (new_metric - baseline_metric) / baseline_metric

Keep if:
  improvement_ratio > 0 (better than baseline)
  AND simplicity_score > 0.001 (change is worth the complexity)

simplicity_score = improvement_ratio / lines_changed
```

### Record

```bash
/aura experiment:record [notes]
# Saves iteration result to .aura/experiments/{id}/history.json
```

### Summary

```bash
/aura experiment:summary
# Show: baseline → best result, all iterations, kept/discarded changes
```

### Reset

```bash
/aura experiment:reset
# Discard all uncommitted changes, return to baseline
```

---

## Circuit Breaker

Stops XLOOP when exploration is exhausted:

```
Trigger: N consecutive iterations with no improvement (default N=10)
Action: STOP → report best achieved result → suggest manual review
```

Configure N:
```json
// .aura/config.json
{
  "experiment": {
    "circuit_breaker_n": 10,
    "min_improvement_ratio": 0.01
  }
}
```

---

## Scope Validation

Before each change, XLOOP validates change is within scope:

```
Valid scope changes:
  ✅ Algorithm optimization in same function
  ✅ Caching addition (no interface change)
  ✅ Database query optimization
  ✅ Bundle splitting / code splitting

Out of scope (requires manual approval):
  ❌ Interface/API changes
  ❌ Database schema changes
  ❌ Dependency version upgrades
  ❌ Architecture changes
```

---

## Simplicity Gate

Even if a change improves the metric, it's discarded if:
```
simplicity_score = improvement_ratio / lines_changed < 0.001

Example:
  10% improvement with 100 lines changed → score = 0.001 → borderline
  10% improvement with 50 lines changed  → score = 0.002 → keep
  1% improvement with 200 lines changed  → score = 0.00005 → discard
```

Purpose: Prevent overcomplicated "improvements" that gain little but add maintenance burden.

---

## SIGINT / Crash Handling

If experiment is interrupted:
```
1. Save current iteration state to .aura/experiments/{id}/checkpoint.json
2. Record: was change kept or discarded at interrupt point
3. On resume (/aura experiment:resume): restore from checkpoint
```

Never leave repository in a modified state without recording.

---

## History Format

`.aura/experiments/{id}/history.json`:

```json
{
  "id": "exp-001",
  "metric": "performance.p99",
  "target": "< 50ms",
  "baseline": 87.3,
  "started": "2025-01-15T10:00:00Z",
  "iterations": [
    {
      "n": 1,
      "change": "Add Redis cache for user lookups",
      "metric_before": 87.3,
      "metric_after": 62.1,
      "improvement": 0.288,
      "lines_changed": 34,
      "simplicity_score": 0.0085,
      "decision": "keep",
      "files": ["src/lib/user.ts", "src/lib/cache.ts"]
    },
    {
      "n": 2,
      "change": "Optimize DB query with index hint",
      "metric_before": 62.1,
      "metric_after": 61.8,
      "improvement": 0.005,
      "lines_changed": 8,
      "simplicity_score": 0.000625,
      "decision": "discard",
      "reason": "simplicity_score below threshold"
    }
  ],
  "best_result": 62.1,
  "best_improvement": "28.8%",
  "status": "completed",
  "circuit_breaker_triggered": false,
  "consecutive_non_improvements": 0
}
```

---

## `/aura experiment:` Mode

```bash
/aura experiment:init performance p99<50ms    → Initialize experiment
/aura experiment:metric                        → Measure current metric
/aura experiment:commit "add caching"          → Execute change + measure + decide
/aura experiment:record                        → Save iteration result
/aura experiment:summary                       → Show progress report
/aura experiment:reset                         → Undo uncommitted changes
/aura experiment:resume                        → Resume interrupted experiment
/aura experiment:list                          → List all experiments in .aura/
```

---

## Integration with AuraKit

XLOOP can be triggered from any mode:

```bash
/aura build: user auth --xloop performance
# After BUILD completes, automatically enters XLOOP to optimize

/aura experiment:init coverage >=85% --auto
# Fully autonomous: runs until target or circuit breaker
```

Config for autonomous mode:
```json
{
  "experiment": {
    "auto_mode": true,
    "target_metric": "coverage",
    "target_value": 85,
    "max_iterations": 20,
    "circuit_breaker_n": 5
  }
}
```

Reports stored in `.aura/experiments/` for audit trail.
