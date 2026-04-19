alias cc='claude --dangerously-skip-permissions'

# CC: fzf-driven discovery over `claude --help`.
# Surfaces every option and subcommand the CLI exposes, with drill-down into
# subcommand help. This is a *discovery* tool, not a convenience wrapper —
# use `cc` for daily runs.
#
# Usage:
#   CC                  Browse top-level options + subcommands.
#   CC <subcommand>     Browse `claude <subcommand> --help`.
#
# In the picker:
#   Enter      Print the selected line (paste into your terminal).
#   Ctrl-Y     Copy the first token (flag or subcommand name) to clipboard.
#   Ctrl-D     If the selection is a subcommand, drill into its help.
#   Ctrl-O     Open the upstream docs in a browser.
#   Esc        Quit.

CC() {
  local sub="${1:-}" help_text lines
  if [ -n "$sub" ]; then
    help_text=$(claude "$sub" --help 2>&1) || {
      echo "no help for: claude $sub" >&2
      return 1
    }
  else
    help_text=$(claude --help 2>&1) || {
      echo "no help output from claude" >&2
      return 1
    }
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "$help_text"
    return 0
  fi

  # Two-space-indented lines starting with - (options) or a lowercase letter (commands).
  lines=$(printf '%s\n' "$help_text" | grep -E '^  (-|[a-z])')
  if [ -z "$lines" ]; then
    printf '%s\n' "$help_text"
    return 0
  fi

  local header="Enter: print · Ctrl-Y: yank · Ctrl-D: drill subcommand · Ctrl-O: docs"
  printf '%s\n' "$lines" | fzf \
    --ansi \
    --prompt "claude${sub:+ $sub} > " \
    --header "$header" \
    --preview 'printf "%s\n" {} | fold -s -w $FZF_PREVIEW_COLUMNS' \
    --preview-window='up:5:wrap' \
    --bind 'ctrl-y:execute-silent(printf "%s" {} | awk "{print \$1}" | tr -d ",\n" | cut -d"|" -f1 | (pbcopy 2>/dev/null || xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null))+abort' \
    --bind 'ctrl-d:execute(tok=$(printf "%s" {} | awk "{print \$1}" | tr -d "," | cut -d"|" -f1); case "$tok" in -*|prompt) printf "\n(not a subcommand)\n" > /dev/tty; sleep 1 ;; *) zsh -ic "CC $tok" < /dev/tty > /dev/tty 2>&1 ;; esac)' \
    --bind 'ctrl-o:execute-silent(open "https://code.claude.com/docs/en/cli-reference" 2>/dev/null || xdg-open "https://code.claude.com/docs/en/cli-reference" 2>/dev/null)'
}

# ccw / ccs: Git-worktree + tmux launchers for Claude Code sessions.
# Replicate Claude Code Desktop's parallel-session workflow from the CLI by
# creating a worktree under <repo>/.claude/worktrees/<name>, copying paths
# listed in <repo>/.worktreeinclude, then opening the worktree in tmux.
#
#   ccw [name] [claude-args...]   New worktree → new WINDOW in the current session.
#   ccs [name] [claude-args...]   New worktree → new SESSION named <project>-<name>.
#   ccw|ccs ls                    List this repo's worktrees.
#   ccw|ccs rm <name>             Archive a worktree (also kills its tmux targets).
#   ccw|ccs help                  Show help.
#
# Smart naming:
#   - If [name] is omitted, auto-generates `wt<N>` with N = next unused suffix
#     among existing worktree dirs in this repo.
#   - ccw window name = <name>; collisions get -2, -3, ... appended.
#   - ccs session name = <project>-<name>; collisions get -2, -3, ... appended.
#   - The launched tmux target opens cd'd to the worktree root, and claude
#     runs as a child of the shell so the shell stays after claude exits.
#
# Env:
#   CCW_WORKTREE_DIR   override worktree root (default: <repo>/.claude/worktrees)
#   CCW_BRANCH_PREFIX  branch name prefix (default: "claude/")
#
# Branch selection:
#   --branch              Pick an existing branch via fzf (attaches worktree to it).
#   --branch=<name>       Attach worktree to <name> (local, or origin/<name>).

ccw() {
  case "${1:-}" in
    ls|list)          _ccw_list ;;
    rm|archive)       shift; _ccw_archive "$@" ;;
    -h|--help|help)   _ccw_help ;;
    *)                _ccw_spawn window "$@" ;;
  esac
}

ccs() {
  case "${1:-}" in
    ls|list)          _ccw_list ;;
    rm|archive)       shift; _ccw_archive "$@" ;;
    -h|--help|help)   _ccw_help ;;
    *)                _ccw_spawn session "$@" ;;
  esac
}

# CCW / CCS: inverse of ccw / ccs. Run from inside a ccw-created worktree
# to remove the worktree + branch and close the enclosing tmux target.
#   CCW   Kill the current tmux WINDOW (and all subprocesses in it).
#   CCS   Kill the current tmux SESSION (and all subprocesses in it).
# The worktree path is detected from the current shell; must live under
# <main-repo>/.claude/worktrees (or CCW_WORKTREE_DIR).
CCW() { _ccw_self_destruct window ; }
CCS() { _ccw_self_destruct session ; }

_ccw_help() {
  cat <<'EOF'
ccw [name] [claude-args...]   New worktree as tmux WINDOW in current session.
ccs [name] [claude-args...]   New worktree as its own tmux SESSION.

Branch selection (before [name]):
  --branch                    Pick an existing branch via fzf.
  --branch=<name>             Attach to branch <name> (local, or origin/<name>).

Subcommands (same for ccw and ccs):
  ls                 List worktrees in current repo.
  rm <name>          Archive worktree + its tmux targets.

If [name] is omitted, a name like "wt3" is auto-generated, or derived from
the selected branch (slashes replaced with dashes) when --branch is used.
The new shell starts in the worktree root; claude runs as a child.

Env:
  CCW_WORKTREE_DIR   override worktree root (default: <repo>/.claude/worktrees)
  CCW_BRANCH_PREFIX  branch prefix for auto-created branches (default: claude/)

See <repo>/.worktreeinclude to copy gitignored files into each worktree.
EOF
}

_ccw_repo_root() {
  # Always return the *main* worktree, even when invoked from a linked one,
  # so ccw/ccs create siblings under the main repo instead of nesting.
  git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }'
}
_ccw_wt_root()   { echo "${CCW_WORKTREE_DIR:-$1/.claude/worktrees}"; }
_ccw_project()   { basename "$1"; }
_ccw_branch()    { echo "${CCW_BRANCH_PREFIX:-claude/}$1"; }

_ccw_next_name() {
  # Highest numeric suffix of wt<N> among existing worktree dirs, + 1.
  local root="$1" wt_root max=0 n
  wt_root=$(_ccw_wt_root "$root")
  if [ -d "$wt_root" ]; then
    for n in $(ls -1 "$wt_root" 2>/dev/null | sed -nE 's/^wt([0-9]+)$/\1/p'); do
      [ "$n" -gt "$max" ] && max="$n"
    done
  fi
  echo "wt$((max + 1))"
}

_ccw_list() {
  local root; root=$(_ccw_repo_root) || { echo "not in a git repo" >&2; return 1; }
  git -C "$root" worktree list
}

_ccw_apply_worktreeinclude() {
  local src="$1" dst="$2"
  local inc="$src/.worktreeinclude"
  [ -f "$inc" ] || return 0
  local copied=0 pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in ''|'#'*) continue ;; esac
    if [ -e "$src/$pattern" ]; then
      mkdir -p "$dst/$(dirname "$pattern")"
      cp -R "$src/$pattern" "$dst/$pattern"
      copied=$((copied + 1))
    fi
  done < "$inc"
  [ "$copied" -gt 0 ] && echo "ccw: copied $copied entries from .worktreeinclude"
}

_ccw_cmdstr() {
  local out= arg
  for arg in "$@"; do
    out="${out} $(printf '%q' "$arg")"
  done
  printf '%s' "${out# }"
}

_ccw_ensure_ignored() {
  # Ensure the worktree root is gitignored for this repo. Writes to
  # .git/info/exclude (local-only, no commit) so the safeguard applies in
  # every repo ccw touches without modifying tracked .gitignore files.
  local root="$1" wt_root="$2"
  local rel="${wt_root#$root/}"
  [ "$rel" = "$wt_root" ] && return 0   # outside repo, nothing to ignore

  local pattern="/${rel}/"
  if git -C "$root" check-ignore -q "$wt_root/.__ccw_probe__" 2>/dev/null; then
    return 0
  fi

  local exclude_file
  if [ -d "$root/.git" ]; then
    exclude_file="$root/.git/info/exclude"
  elif [ -f "$root/.git" ]; then
    local gitdir
    gitdir=$(awk '/^gitdir: / {print $2; exit}' "$root/.git")
    exclude_file="${gitdir%/worktrees/*}/info/exclude"
  else
    return 0
  fi

  mkdir -p "$(dirname "$exclude_file")"
  if ! grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
    {
      [ -s "$exclude_file" ] && echo ""
      echo "# Added by ccw: ignore Claude Code worktrees"
      echo "$pattern"
    } >> "$exclude_file"
    echo "ccw: added '$pattern' to $exclude_file (local-only)"
  fi
}

_ccw_prompt_name() {
  # Prompt for a worktree name, defaulting to the next wt<N>. Prints the
  # chosen name on stdout. Falls back to the default if there's no tty.
  local root="$1" default name
  default=$(_ccw_next_name "$root")
  if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
    echo "$default"
    return 0
  fi
  printf "ccw: worktree name [%s]> " "$default" >&2
  if ! IFS= read -r name < /dev/tty 2>/dev/null; then
    echo "" >&2
    echo "$default"
    return 0
  fi
  [ -z "$name" ] && name="$default"
  echo "$name"
}

_ccw_pick_branch() {
  # Interactive branch picker. Lists local branches and prints the selection
  # on stdout. Returns non-zero on no selection / missing fzf.
  local root="$1"
  if ! command -v fzf >/dev/null 2>&1; then
    echo "ccw: --branch (interactive) requires fzf; use --branch=<name> instead" >&2
    return 1
  fi
  local branches
  branches=$(git -C "$root" for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
  if [ -z "$branches" ]; then
    echo "ccw: no local branches found" >&2
    return 1
  fi
  printf '%s\n' "$branches" | fzf \
    --prompt "branch > " \
    --height 40% \
    --reverse \
    --header "pick a branch to attach a new worktree to"
}

_ccw_spawn() {
  local mode="$1"; shift
  local root wt_root name wtdir branch
  local explicit_branch="" pick_branch=0
  local -a rest
  rest=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --branch)
        pick_branch=1
        shift
        ;;
      --branch=*)
        explicit_branch="${1#--branch=}"
        shift
        ;;
      --)
        shift
        while [ $# -gt 0 ]; do rest+=("$1"); shift; done
        ;;
      *)
        rest+=("$1")
        shift
        ;;
    esac
  done
  set -- "${rest[@]}"

  root=$(_ccw_repo_root) || { echo "not in a git repo" >&2; return 1; }
  wt_root=$(_ccw_wt_root "$root")

  if [ "$pick_branch" = 1 ]; then
    explicit_branch=$(_ccw_pick_branch "$root") || return 1
    [ -z "$explicit_branch" ] && { echo "ccw: no branch selected" >&2; return 1; }
  fi

  if [ -n "$explicit_branch" ]; then
    branch="$explicit_branch"
    if [ -n "${1:-}" ]; then
      name="$1"; shift
    else
      name="${branch//\//-}"
    fi
  else
    if [ -n "${1:-}" ]; then
      name="$1"; shift
    else
      name=$(_ccw_prompt_name "$root") || return 1
    fi
    branch="$(_ccw_branch "$name")"
  fi

  wtdir="$wt_root/$name"

  _ccw_ensure_ignored "$root" "$wt_root"

  if [ ! -d "$wtdir" ]; then
    mkdir -p "$(dirname "$wtdir")"
    if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$root" worktree add "$wtdir" "$branch" || return 1
    elif [ -n "$explicit_branch" ] \
         && git -C "$root" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git -C "$root" worktree add -b "$branch" "$wtdir" "origin/$branch" || return 1
    elif [ -n "$explicit_branch" ]; then
      echo "ccw: branch not found: $branch" >&2
      return 1
    else
      git -C "$root" worktree add -b "$branch" "$wtdir" || return 1
    fi
    _ccw_apply_worktreeinclude "$root" "$wtdir"
  fi

  if [ "$mode" = "session" ]; then
    _ccw_new_session "$root" "$wtdir" "$name" "$@"
  else
    _ccw_new_window "$root" "$wtdir" "$name" "$@"
  fi
}

_ccw_new_window() {
  local root="$1" wtdir="$2" name="$3"; shift 3
  local project cmd_str sess wname i
  project=$(_ccw_project "$root")
  cmd_str=$(_ccw_cmdstr claude --dangerously-skip-permissions "$@")

  if ! command -v tmux >/dev/null 2>&1; then
    (cd "$wtdir" && eval "$cmd_str")
    return
  fi

  if [ -n "${TMUX:-}" ]; then
    sess=$(tmux display-message -p '#S')
  else
    sess="$project"
    tmux has-session -t "=$sess" 2>/dev/null || tmux new-session -d -s "$sess" -c "$root"
  fi

  wname="$name"; i=2
  while tmux list-windows -t "=$sess" -F '#{window_name}' 2>/dev/null | grep -qx "$wname"; do
    wname="${name}-${i}"
    i=$((i + 1))
  done

  tmux new-window -t "$sess" -n "$wname" -c "$wtdir"
  tmux send-keys -t "$sess:$wname" "$cmd_str" Enter
  if [ -n "${TMUX:-}" ]; then
    tmux select-window -t "$sess:$wname"
  else
    tmux attach -t "$sess:$wname"
  fi
}

_ccw_new_session() {
  local root="$1" wtdir="$2" name="$3"; shift 3
  local project cmd_str sess i
  project=$(_ccw_project "$root")
  cmd_str=$(_ccw_cmdstr claude --dangerously-skip-permissions "$@")

  if ! command -v tmux >/dev/null 2>&1; then
    (cd "$wtdir" && eval "$cmd_str")
    return
  fi

  sess="${project}-${name}"; i=2
  while tmux has-session -t "=$sess" 2>/dev/null; do
    sess="${project}-${name}-${i}"
    i=$((i + 1))
  done

  tmux new-session -d -s "$sess" -c "$wtdir"
  tmux send-keys -t "$sess" "$cmd_str" Enter
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$sess"
  else
    tmux attach -t "$sess"
  fi
}

_ccw_archive() {
  local name="${1:-}"
  [ -z "$name" ] && { echo "usage: ccw rm <name>" >&2; return 1; }
  local root wtdir project branch
  root=$(_ccw_repo_root) || { echo "not in a git repo" >&2; return 1; }
  wtdir="$(_ccw_wt_root "$root")/$name"
  project=$(_ccw_project "$root")
  branch="$(_ccw_branch "$name")"

  if command -v tmux >/dev/null 2>&1; then
    # Kill any window named $name in the project's umbrella session.
    if tmux list-windows -t "=$project" -F '#{window_name}' 2>/dev/null | grep -qx "$name"; then
      tmux kill-window -t "$project:$name" 2>/dev/null || true
    fi
    # Kill the dedicated per-worktree session, if any.
    tmux kill-session -t "=${project}-${name}" 2>/dev/null || true
  fi

  git -C "$root" worktree remove --force "$wtdir" 2>/dev/null \
    || git -C "$root" worktree remove "$wtdir" 2>/dev/null \
    || rm -rf "$wtdir"
  git -C "$root" worktree prune 2>/dev/null || true
  git -C "$root" branch -D "$branch" 2>/dev/null || true
  echo "archived: $name"
}

_ccw_confirm_clean() {
  # Returns 0 if the worktree is safe to destroy (clean, or user opted to
  # discard). Returns non-zero if the caller should abort.
  local wtdir="$1"
  local uncommitted unpushed ans
  uncommitted=$(git -C "$wtdir" status --porcelain 2>/dev/null)
  unpushed=$(git -C "$wtdir" log --oneline HEAD --not --remotes 2>/dev/null)

  [ -z "$uncommitted" ] && [ -z "$unpushed" ] && return 0

  {
    echo "CCW/CCS: this worktree has unsaved work:"
    [ -n "$uncommitted" ] && echo "  - uncommitted changes"
    [ -n "$unpushed" ] && echo "  - unpushed commits"
    echo ""
    echo "  [c] create a PR — launches claude with /create-pr"
    echo "  [k] kill the worktree anyway (discards unsaved work)"
    printf "[c/k]> "
  } >&2

  if ! read -r ans < /dev/tty; then
    echo "CCW/CCS: no tty available; aborting" >&2
    return 1
  fi

  case "$ans" in
    k|K|kill)
      return 0
      ;;
    c|C|create|pr)
      if ! (cd "$wtdir" && claude -p --dangerously-skip-permissions /create-pr); then
        echo "CCW/CCS: /create-pr failed; aborting" >&2
        return 1
      fi
      # Re-check cleanliness. If /create-pr worked, uncommitted/unpushed are
      # gone and this returns 0 immediately; otherwise the user is re-prompted.
      _ccw_confirm_clean "$wtdir"
      return $?
      ;;
    *)
      echo "CCW/CCS: aborted." >&2
      return 1
      ;;
  esac
}

_ccw_self_destruct() {
  local mode="$1"
  local cur_toplevel main_root wt_root name branch wtdir
  cur_toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "CCW/CCS: not in a git repo" >&2; return 1
  }
  main_root=$(_ccw_repo_root) || { echo "CCW/CCS: not in a git repo" >&2; return 1; }
  wt_root=$(_ccw_wt_root "$main_root")

  case "$cur_toplevel" in
    "$wt_root"/*) ;;
    *) echo "CCW/CCS: not inside a ccw worktree ($cur_toplevel)" >&2; return 1 ;;
  esac

  name=$(basename "$cur_toplevel")
  wtdir="$cur_toplevel"
  branch="$(_ccw_branch "$name")"

  _ccw_confirm_clean "$wtdir" || return 1

  # Move out of the worktree so git can remove it from under us.
  cd "$main_root" || return 1

  git -C "$main_root" worktree remove --force "$wtdir" 2>/dev/null \
    || git -C "$main_root" worktree remove "$wtdir" 2>/dev/null \
    || rm -rf "$wtdir"
  git -C "$main_root" worktree prune 2>/dev/null || true
  git -C "$main_root" branch -D "$branch" 2>/dev/null || true
  echo "removed: $name"

  if command -v tmux >/dev/null 2>&1 && [ -n "${TMUX:-}" ]; then
    if [ "$mode" = "session" ]; then
      tmux kill-session
    else
      tmux kill-window
    fi
  fi
}
