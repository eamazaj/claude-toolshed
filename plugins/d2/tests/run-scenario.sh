#!/usr/bin/env bash
# run-scenario.sh — test d2 skill scenarios
#
# Usage:
#   ./run-scenario.sh red   <scenario-file>              # baseline: no skill loaded
#   ./run-scenario.sh green <scenario-file> <skill-name> # with skill SKILL.md injected
#
# Examples:
#   ./run-scenario.sh red   scenarios/baseline-flow.txt
#   ./run-scenario.sh green scenarios/skill-flow.txt d2-diagram
#   ./run-scenario.sh green scenarios/skill-sequence.txt d2-diagram

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)" # plugins/d2/
SKILLS_DIR="$PLUGIN_ROOT/skills"

PHASE="${1:-}"
SCENARIO="${2:-}"
SKILL="${3:-}"

if [[ -z "$PHASE" || -z "$SCENARIO" ]]; then
  echo "Usage: $0 <red|green> <scenario-file> [skill-name]"
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/$SCENARIO" ]]; then
  echo "Error: scenario file not found: $SCRIPT_DIR/$SCENARIO"
  exit 1
fi

PROMPT="$(cat "$SCRIPT_DIR/$SCENARIO")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
SCENARIO_NAME="$(basename "$SCENARIO" .txt)"
RESULT_FILE="$SCRIPT_DIR/results/${PHASE}-${SCENARIO_NAME}-${TIMESTAMP}.json"

mkdir -p "$SCRIPT_DIR/results"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase:    $PHASE"
echo "Scenario: $SCENARIO_NAME"
if [[ -n "$SKILL" ]]; then
  echo "Skill:    $SKILL"
fi
echo "Output:   $RESULT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Unset CLAUDECODE so claude -p can be called from inside a Claude Code session
unset CLAUDECODE

if [[ "$PHASE" == "red" ]]; then
  # RED: disable all skills — baseline; see what agent does without guidance
  claude -p \
    --disable-slash-commands \
    --output-format json \
    --max-turns 8 \
    --dangerously-skip-permissions \
    "$PROMPT" | tee "$RESULT_FILE"

elif [[ "$PHASE" == "green" ]]; then
  # GREEN: inject skill SKILL.md via --append-system-prompt-file
  if [[ -z "$SKILL" ]]; then
    echo "Error: green phase requires a skill name (e.g. d2-diagram)"
    exit 1
  fi

  SKILL_FILE="$SKILLS_DIR/$SKILL/SKILL.md"
  if [[ ! -f "$SKILL_FILE" ]]; then
    echo "Error: skill file not found: $SKILL_FILE"
    echo "Available skills:"
    ls "$SKILLS_DIR/"
    exit 1
  fi

  echo "Skill file: $SKILL_FILE"
  echo ""

  claude -p \
    --append-system-prompt-file "$SKILL_FILE" \
    --disable-slash-commands \
    --output-format json \
    --max-turns 15 \
    --dangerously-skip-permissions \
    "$PROMPT" | tee "$RESULT_FILE"

else
  echo "Error: phase must be 'red' or 'green', got: $PHASE"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Saved to: $RESULT_FILE"
echo ""
echo "Key things to check in the output:"
echo "  RED:   Did it use d2 syntax (.d2 extension)? Save to correct location? Run d2 validate?"
echo "  GREEN: Did it find PLUGIN_DIR? Call ensure-deps.sh? Run d2 validate? Correct filename?"
