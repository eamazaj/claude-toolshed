#!/usr/bin/env bash
# ci-test.sh — Run all plugin test suites.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
errors=0
ran=0

echo "=== Plugin tests ==="

# trim-md unit tests
if [[ -f "$ROOT/plugins/trim-md/tests/test-trim-md.sh" ]]; then
  echo ""
  echo "--- trim-md ---"
  if bash "$ROOT/plugins/trim-md/tests/test-trim-md.sh"; then
    echo "trim-md: PASS"
  else
    echo "trim-md: FAIL"
    ((errors++)) || true
  fi
  ((ran++)) || true
fi

# mermaid scenario tests (requires claude CLI + API — skip in CI, run manually)
# Usage: bash plugins/mermaid/tests/run-scenario.sh red scenarios/baseline-flowchart.txt

echo ""
if ((errors > 0)); then
  echo "FAILED: $errors/$ran suite(s) failed"
  exit 1
fi

echo "All $ran test suite(s) passed"
