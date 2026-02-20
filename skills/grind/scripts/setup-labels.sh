#!/usr/bin/env bash
# setup-labels.sh — Create the agent workflow labels in a GitHub repository.
#
# Usage:
#   ./setup-labels.sh                  # Uses the current repo
#   ./setup-labels.sh owner/repo       # Targets a specific repo
#
# Safe to run multiple times — gh label create is idempotent (errors on
# duplicates are suppressed).

set -euo pipefail

REPO_FLAG=""
if [[ $# -ge 1 ]]; then
  REPO_FLAG="--repo $1"
fi

declare -A LABELS=(
  ["agent-ready"]="0E8A16|Issue triaged and ready for an agent"
  ["agent-claimed"]="E4E669|An agent has claimed this issue"
  ["agent-in-progress"]="F9A825|Agent implementation underway"
  ["agent-completed"]="1D76DB|PR created successfully"
  ["agent-failed"]="D93F0B|Agent failed, needs human review"
)

for label in "${!LABELS[@]}"; do
  IFS='|' read -r color description <<< "${LABELS[$label]}"
  echo "Creating label: $label ($color)"
  gh label create "$label" --color "$color" --description "$description" $REPO_FLAG 2>/dev/null \
    && echo "  Created" \
    || echo "  Already exists (skipped)"
done

echo "Done. All agent workflow labels are set up."
