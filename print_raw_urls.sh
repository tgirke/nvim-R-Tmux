#!/bin/bash
# print_raw_urls.sh
# Run from the root of a cloned GitHub repo to print raw URLs for all files.
# Usage: bash print_raw_urls.sh

REMOTE=$(git remote get-url origin 2>/dev/null)
if [ -z "$REMOTE" ]; then
  echo "ERROR: not a git repo or no remote configured" >&2
  exit 1
fi

# Convert SSH remote to HTTPS if needed
# git@github.com:user/repo.git -> https://github.com/user/repo
REMOTE=$(echo "$REMOTE" | sed 's|git@github.com:|https://github.com/|; s|\.git$||')

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -z "$BRANCH" ]; then
  BRANCH="main"
fi

BASE="https://raw.githubusercontent.com/$(echo "$REMOTE" | sed 's|https://github.com/||')/refs/heads/$BRANCH"

echo "# Raw URLs for $REMOTE ($BRANCH branch)"
echo "# Paste these at the start of a Claude session"
echo ""

git ls-files | while read -r file; do
  echo "$BASE/$file"
done
