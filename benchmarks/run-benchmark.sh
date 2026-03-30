#!/bin/bash
# ============================================================
# AuraKit Benchmark Runner
# Measures token usage: Control vs ECO vs PRO
# Usage: bash benchmarks/run-benchmark.sh [task] [tier]
#   task: T1|T2|T3|T4|T5|all (default: all)
#   tier: control|eco|pro|all (default: all)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/tasks"
RESULTS_DIR="$SCRIPT_DIR/results"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_FILE="$RESULTS_DIR/benchmark-$TIMESTAMP.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[Benchmark]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }

TASK="${1:-all}"
TIER="${2:-all}"
RUNS=3   # 3회 평균 (95% 신뢰구간)

mkdir -p "$RESULTS_DIR"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   AuraKit Benchmark Runner v1.0      ║"
echo "  ║   3-run average · 95% CI             ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

info "Task: $TASK | Tier: $TIER | Runs: $RUNS"
info "Results → $RESULT_FILE"
echo ""

# Initialize results JSON
cat > "$RESULT_FILE" << EOF
{
  "version": "1.0",
  "timestamp": "$TIMESTAMP",
  "runs": $RUNS,
  "tasks": {}
}
EOF

warn "MANUAL MEASUREMENT REQUIRED"
echo ""
echo "  AuraKit benchmarks require manual token measurement."
echo "  Claude Code does not expose token counts programmatically."
echo ""
echo "  Method 1 (Recommended): Use Claude.ai → Settings → Usage"
echo "    - Note tokens before and after each task"
echo "    - Record delta as task token usage"
echo ""
echo "  Method 2: Anthropic API proxy"
echo "    - Set up a proxy to capture usage headers"
echo "    - Run tasks via API with token tracking"
echo ""
echo "  Task files:"
for task in T1 T2 T3 T4 T5; do
  echo "    - $TASKS_DIR/$task-*.md"
done
echo ""
echo "  Record results in: $RESULT_FILE"
echo ""
echo "  Result format per task/tier:"
cat << 'EXAMPLE'
  {
    "T1": {
      "control": { "tokens_avg": 12400, "tokens_ci95": 800, "build_pass": true, "security_issues": 2 },
      "eco":     { "tokens_avg": 6800,  "tokens_ci95": 400, "build_pass": true, "security_issues": 0 },
      "pro":     { "tokens_avg": 8200,  "tokens_ci95": 300, "build_pass": true, "security_issues": 0 }
    }
  }
EXAMPLE
echo ""

success "Benchmark template ready: $RESULT_FILE"
info "Fill in measurements and run: node benchmarks/analyze.js $RESULT_FILE"
