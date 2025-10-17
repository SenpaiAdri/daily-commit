#!/usr/bin/env bash
set -euo pipefail

# Generate 1-3 random commits by appending timestamped lines to a log file
LOG_FILE="daily.log"

# Ensure we are at repo root if invoked from Actions
cd "$(git rev-parse --show-toplevel)"

# Create log file if it doesn't exist so it's tracked
if [[ ! -f "$LOG_FILE" ]]; then
  echo "# Daily contribution log" > "$LOG_FILE"
  git add "$LOG_FILE"
  git commit -m "chore: initialize daily log"
fi

# Random number between 1 and 3 (inclusive)
NUM_COMMITS=$(( (RANDOM % 3) + 1 ))

for ((i=1; i<=NUM_COMMITS; i++)); do
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') commit $i" >> "$LOG_FILE"
  git add "$LOG_FILE"
  git commit -m "chore: daily auto commit $i/$(printf '%d' "$NUM_COMMITS")"
  # Add small sleep to avoid identical timestamps
  sleep 1
done


