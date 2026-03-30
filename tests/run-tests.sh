#!/usr/bin/env bash
# AuraKit Test Runner v1.0
# Usage: bash tests/run-tests.sh [--category build|secure|instinct|scout]
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${TESTS_DIR}/results"
CATEGORY="${2:-all}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="${RESULTS_DIR}/result-${TIMESTAMP}.md"

mkdir -p "$RESULTS_DIR"

cat > "$RESULT_FILE" << EOF
# AuraKit Test Results
- Run: ${TIMESTAMP}
- Category: ${CATEGORY}
- AuraKit Version: $(grep -m1 'v[0-9]' "${TESTS_DIR}/../skills/aura/SKILL.md" 2>/dev/null || echo 'unknown')

EOF

pass=0
fail=0
skip=0
total=0

for test_file in "${TESTS_DIR}"/test-*.md; do
  [[ -f "$test_file" ]] || continue

  test_name=$(grep -m1 'name:' "$test_file" | sed 's/.*name:[[:space:]]*"\(.*\)"/\1/')
  test_cat=$(grep -m1 'category:' "$test_file" | awk '{print $2}')
  test_tier=$(grep -m1 'tier:' "$test_file" | awk '{print $2}')
  test_timeout=$(grep -m1 'timeout:' "$test_file" | awk '{print $2}')

  if [[ "$CATEGORY" != "all" && "$test_cat" != "$CATEGORY" ]]; then
    skip=$((skip + 1))
    continue
  fi

  total=$((total + 1))
  cat >> "$RESULT_FILE" << EOF
## Test ${total}: ${test_name}
- File: $(basename "$test_file")
- Category: ${test_cat}
- Tier: ${test_tier}
- Timeout: ${test_timeout}s
- Status: **PENDING** (requires manual /aura execution)

EOF
done

if [[ $total -gt 0 ]]; then
  score=$(( 40 * pass / total ))
else
  score=0
fi

cat >> "$RESULT_FILE" << EOF
---
## Summary
| Metric | Value |
|--------|-------|
| Total | ${total} |
| Pass | ${pass} |
| Fail | ${fail} |
| Skipped | ${skip} |
| **AuraScore** | **${score}/40** |
EOF

cat "$RESULT_FILE"
echo ""
echo "Results saved: ${RESULT_FILE}"
