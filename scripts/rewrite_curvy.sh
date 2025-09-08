#!/usr/bin/env bash
set -euo pipefail

# Rewrite history so that each UTC day between 2025-09-08 and today has
# a deterministic target of 1–4 commits. The first day carries a snapshot of
# current origin/main contents; subsequent commits only update timestamp.txt.

git fetch origin main

base=$(git rev-list -1 --before="2025-09-08 00:00:00 +0000" origin/main || true)
if [[ -z "${base:-}" ]]; then
  base=$(git rev-list --max-parents=0 origin/main)
fi
main_head=$(git rev-parse origin/main)

echo "Base commit: $base"
echo "Main head:   $main_head"

git checkout -B rewrite-curvy "$base"

git config user.name "SenpaiAdri"
git config user.email "adrian31dg@gmail.com"

start_ts=$(date -u -d "2025-09-08" +%s)
end_ts=$(date -u +%s)

synced=0
day_ts=$start_ts
while [[ $day_ts -le $end_ts ]]; do
  day=$(date -u -d "@${day_ts}" +%F)
  checksum=$(printf "%s" "$day" | cksum | awk '{print $1}')
  target=$(( (checksum % 4) + 1 ))

  made=0
  if [[ $synced -eq 0 ]]; then
    # Remove any tracked files from this base to avoid leftovers
    if [[ -n "$(git ls-files)" ]]; then
      git ls-files -z | xargs -0 rm -f || true
    fi
    # Bring in current repository state from main
    git checkout "$main_head" -- .
    git add -A
    hour=$((9 + RANDOM % 13)); minute=$((RANDOM % 60)); second=$((RANDOM % 60))
    printf -v hms "%02d:%02d:%02d" "$hour" "$minute" "$second"
    ts="$day $hms +0000"
    GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" git -c commit.gpgsign=false commit -m "Rewrite: sync to current state @ $ts"
    made=1
    synced=1
  fi

  while [[ $made -lt $target ]]; do
    hour=$((9 + RANDOM % 13)); minute=$((RANDOM % 60)); second=$((RANDOM % 60))
    printf -v hms "%02d:%02d:%02d" "$hour" "$minute" "$second"
    ts="$day $hms +0000"
    echo "Last update: $ts" > timestamp.txt
    git add timestamp.txt
    GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" git -c commit.gpgsign=false commit -m "Rewrite: backfill $ts"
    made=$((made+1))
  done

  echo "${day}: created ${made}/${target} commits"
  day_ts=$((day_ts + 86400))
done

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "rewrite-curvy" ]]; then
  echo "Unexpected branch $current_branch" >&2
  exit 1
fi

git push -f origin rewrite-curvy:main

echo "Force push complete."


