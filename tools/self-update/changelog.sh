#!/usr/bin/env bash
# Dotfiles changelog tool.
#
# Subcommands:
#   update OLD_SHA NEW_SHA   Generate an AI summary for OLD..NEW, prepend it
#                             to ~/.cache/dotfiles-changelog.md, and reset the
#                             pending-notification file the shell hook reads.
#   backfill                  Regenerate ~/.cache/dotfiles-changelog.md from
#                             the full git history — one entry per day with
#                             commits, newest first.
#   summarize OLD_SHA NEW_SHA Print an AI summary for OLD..NEW to stdout.
#
# Internal:
#   _day DAY WORKDIR         (used by backfill's parallel workers)
set -euo pipefail

# Make claude CLI findable under cron/launchd's minimal PATH
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/changelog-prompt.txt"
DOTFILES_DIR="$HOME/_dotfiles"
CHANGELOG="$HOME/.cache/dotfiles-changelog.md"
PENDING="$HOME/.cache/dotfiles-pending-update.md"

mkdir -p "$HOME/.cache"

# ─── summary generation ─────────────────────────────────────────────────────

summarize_range() {
  local old="$1" new="$2" context summary
  context=$(
    cd "$DOTFILES_DIR"
    echo "Commits:"
    git log --pretty=format:'%h %s%n%b' "$old..$new"
    echo
    echo "Files changed:"
    git diff --stat "$old..$new"
  )
  summary=""
  if command -v claude >/dev/null 2>&1; then
    summary=$(printf '%s\n' "$context" | claude -p "$(cat "$PROMPT_FILE")" 2>/dev/null || true)
  fi
  if [[ -z "$summary" ]]; then
    cd "$DOTFILES_DIR"
    summary=$(git log --pretty=format:'- %s' "$old..$new")
  fi
  printf '%s\n' "$summary"
}

summarize_initial_commit() {
  # For the very first commit in the repo (no parent), fall back to a
  # file-listing context so claude can describe what got set up.
  local sha="$1" context summary
  context=$(
    cd "$DOTFILES_DIR"
    echo "Commits (initial repo):"
    git log --pretty=format:'%h %s%n%b' "$sha"
    echo
    echo "Files at this point:"
    git ls-tree -r --name-only "$sha" | head -100
  )
  summary=""
  if command -v claude >/dev/null 2>&1; then
    summary=$(printf '%s\n' "$context" | claude -p "$(cat "$PROMPT_FILE")" 2>/dev/null || true)
  fi
  if [[ -z "$summary" ]]; then
    cd "$DOTFILES_DIR"
    summary=$(git log --pretty=format:'- %s' "$sha")
  fi
  printf '%s\n' "$summary"
}

format_entry() {
  local header="$1" old="$2" new="$3" summary="$4"
  echo "## $header — ${old:0:7}..${new:0:7}"
  echo
  echo "$summary"
  echo
}

prepend_entry() {
  local entry="$1" tmp
  tmp=$(mktemp)
  {
    printf '%s\n' "$entry"
    [[ -f "$CHANGELOG" ]] && cat "$CHANGELOG"
  } > "$tmp"
  mv "$tmp" "$CHANGELOG"
}

reset_pending() {
  local summary="$1"
  {
    echo "dotfiles auto-updated $(date '+%Y-%m-%d %H:%M'):"
    echo
    echo "$summary"
    echo
  } > "$PENDING"
}

# ─── subcommands ────────────────────────────────────────────────────────────

cmd_update() {
  local old="$1" new="$2" summary entry
  summary=$(summarize_range "$old" "$new")
  entry=$(format_entry "$(date '+%Y-%m-%d %H:%M:%S')" "$old" "$new" "$summary")
  prepend_entry "$entry"
  reset_pending "$summary"
}

cmd_summarize() {
  summarize_range "$1" "$2"
}

# Worker: summarize one day into $workdir/$day.md. Invoked in parallel by
# cmd_backfill via xargs. Defensive — always writes a file and always exits 0
# so one bad day never kills the batch.
cmd_day() {
  set +e
  local day="$1" workdir="$2"
  local outfile="$workdir/$day.md"
  local first_sha last_sha parent summary
  cd "$DOTFILES_DIR" || { echo "  ✗ $day (cd failed)" >&2; return 0; }
  first_sha=$(git log --since="$day 00:00:00" --until="$day 23:59:59" --pretty=format:'%H' | tail -1)
  last_sha=$(git log --since="$day 00:00:00" --until="$day 23:59:59" --pretty=format:'%H' | head -1)
  if [[ -z "$first_sha" || -z "$last_sha" ]]; then
    echo "  ✗ $day (no commits resolved)" >&2
    return 0
  fi

  parent=$(git rev-parse --verify "${first_sha}^^{commit}" 2>/dev/null)
  if [[ -n "$parent" ]]; then
    summary=$(summarize_range "$parent" "$last_sha")
  else
    summary=$(summarize_initial_commit "$last_sha")
  fi

  # Last-resort fallback — never let an empty summary silently drop the entry
  if [[ -z "$summary" ]]; then
    summary=$(git log --since="$day 00:00:00" --until="$day 23:59:59" --pretty=format:'- %s')
  fi
  [[ -z "$summary" ]] && summary="- (no summary available)"

  format_entry "$day" "$first_sha" "$last_sha" "$summary" > "$outfile"
  echo "  ✓ $day" >&2
  return 0
}

cmd_backfill() {
  cd "$DOTFILES_DIR"
  local workdir days total
  workdir=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf '$workdir'" EXIT

  days=$(git log --pretty=format:'%ad' --date=short | sort -u)
  total=$(echo "$days" | wc -l | tr -d ' ')
  echo "Backfilling $total day(s) in parallel (6 workers)..." >&2

  # Re-invoke this script as the worker command. Avoids `export -f` quirks.
  echo "$days" | xargs -P 6 -I{} "$0" _day "{}" "$workdir" || true

  echo >&2
  echo "Assembling reverse-chronological into $CHANGELOG..." >&2
  : > "$CHANGELOG"
  echo "$days" | sort -r | while read -r day; do
    [[ -f "$workdir/$day.md" ]] && cat "$workdir/$day.md" >> "$CHANGELOG"
  done
  echo "Wrote $(grep -c '^## ' "$CHANGELOG") entries to $CHANGELOG" >&2
}

# ─── dispatch ───────────────────────────────────────────────────────────────

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \?//' | sed '$d'
  exit 1
}

case "${1:-}" in
  update)    [[ $# -ge 3 ]] || usage; cmd_update "$2" "$3" ;;
  backfill)  cmd_backfill ;;
  summarize) [[ $# -ge 3 ]] || usage; cmd_summarize "$2" "$3" ;;
  _day)      [[ $# -ge 3 ]] || usage; cmd_day "$2" "$3" ;;
  *)         usage ;;
esac
