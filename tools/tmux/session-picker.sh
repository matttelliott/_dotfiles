#!/usr/bin/env bash
# Claude-Desktop-style tmux session picker.
# Left-anchored popup, sessions collapsible with h / expandable with l.
set -eu

BOLD=$'\033[1m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# Collapse state lives in a tmux global option (in-memory, never a file).
# Value is a newline-separated list of session names currently collapsed.
# Reset to empty on top-level invocation so default is always-expanded.
PICKER_OPT='@picker-collapsed'

is_collapsed() {
  tmux show-options -gv "$PICKER_OPT" 2>/dev/null | grep -qFx "$1"
}

# 1-indexed line number where $1's session header row lands in the current list.
line_of() {
  local target="$1" line=1 s wcount
  while IFS= read -r s; do
    if [ "$s" = "$target" ]; then
      printf '%s' "$line"
      return
    fi
    line=$((line + 1))
    if ! is_collapsed "$s"; then
      wcount=$(tmux list-windows -t "$s" -F '#{window_index}' 2>/dev/null | wc -l | tr -d ' ')
      line=$((line + wcount))
    fi
  done < <(tmux list-sessions -F '#{session_name}' | LC_ALL=C sort)
  printf '1'
}

build_list() {
  # Format per line: target|display (fzf 0.60+ searches the displayed field)
  # Tree marker encodes both collapse state and session status via color:
  #   cyan  = current session       green = attached elsewhere       dim = detached
  local current_sess
  current_sess=$(tmux display-message -p '#S' 2>/dev/null || echo "")
  tmux list-sessions -F '#{session_name}' | LC_ALL=C sort | while read -r sess; do
    attached=$(tmux display -p -t "$sess" '#{session_attached}' 2>/dev/null || echo 0)
    if [ "$sess" = "$current_sess" ]; then
      sess_color="${CYAN}${BOLD}"
      tree_color="$CYAN"
    elif [ "$attached" != "0" ]; then
      sess_color="${GREEN}${BOLD}"
      tree_color="$GREEN"
    else
      sess_color="$BOLD"
      tree_color="$DIM"
    fi
    if is_collapsed "$sess"; then
      glyph="▸"
      collapsed=1
    else
      glyph="▾"
      collapsed=0
    fi
    window_names=$(tmux list-windows -t "$sess" -F '#{window_name}' | paste -sd ' · ' -)
    printf '%s|%s%s%s %s%s%s   %s%s%s\n' "$sess" "$tree_color" "$glyph" "$RESET" "$sess_color" "$sess" "$RESET" "$DIM" "$window_names" "$RESET"
    if [ "$collapsed" = "0" ]; then
      if [ "$sess" = "$current_sess" ]; then
        tmux list-windows -t "$sess" -F "#{session_name}:#{window_index}|  #{?#{window_active},${CYAN},${DIM}}#{session_name} · #{window_index}: #{window_name}${RESET}"
      else
        tmux list-windows -t "$sess" -F "#{session_name}:#{window_index}|  ${DIM}#{session_name} · #{window_index}: #{window_name}${RESET}"
      fi
    fi
  done
}

# `h` handler: collapse $2's session, then emit fzf actions to reload the list
# and place the cursor on the (now-collapsed) session header row.
if [ "${1:-}" = "--h-action" ]; then
  sess="${2:-}"
  sess="${sess%%:*}"
  [ -z "$sess" ] && exit 0
  if ! is_collapsed "$sess"; then
    current=$(tmux show-options -gv "$PICKER_OPT" 2>/dev/null || true)
    if [ -n "$current" ]; then
      tmux set-option -g "$PICKER_OPT" "$(printf '%s\n%s' "$current" "$sess")"
    else
      tmux set-option -g "$PICKER_OPT" "$sess"
    fi
  fi
  printf 'reload(%s --list)+pos(%s)' "$SCRIPT" "$(line_of "$sess")"
  exit 0
fi

# `l` handler: expand $2's session, then emit fzf actions to reload the list
# and place the cursor on the session header row.
if [ "${1:-}" = "--l-action" ]; then
  sess="${2:-}"
  sess="${sess%%:*}"
  [ -z "$sess" ] && exit 0
  current=$(tmux show-options -gv "$PICKER_OPT" 2>/dev/null || true)
  if [ -n "$current" ]; then
    new=$(printf '%s' "$current" | awk -v s="$sess" '$0 != s')
    tmux set-option -g "$PICKER_OPT" "$new"
  fi
  printf 'reload(%s --list)+pos(%s)' "$SCRIPT" "$(line_of "$sess")"
  exit 0
fi

if [ "${1:-}" = "--list" ]; then
  build_list
  exit 0
fi

if [ "${1:-}" = "--preview" ]; then
  target="${2:-}"
  [ -z "$target" ] && exit 0
  python3 - "$target" <<'PY'
import subprocess, sys, re

SGR = re.compile(r'\x1b\[[0-9;]*m')
RESET = "\x1b[0m"
DIM = "\x1b[2m"

target = sys.argv[1]

def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True).stdout

info = tmux("display-message", "-p", "-t", target, "#{window_width} #{window_height}").strip().split()
if len(info) < 2:
    sys.exit(0)
ww, wh = int(info[0]), int(info[1])
if ww <= 0 or wh <= 0:
    sys.exit(0)

panes = []
for line in tmux("list-panes", "-t", target,
                 "-F", "#{pane_id}|#{pane_left}|#{pane_top}|#{pane_width}|#{pane_height}").strip().splitlines():
    parts = line.split("|")
    if len(parts) != 5:
        continue
    try:
        pid, left, top, w, h = parts[0], int(parts[1]), int(parts[2]), int(parts[3]), int(parts[4])
    except ValueError:
        continue
    panes.append((pid, left, top, w, h))

def parse_cells(line):
    cells = []
    current = ""
    i = 0
    n = len(line)
    while i < n:
        m = SGR.match(line, i)
        if m:
            code = m.group()
            if code in ("\x1b[m", "\x1b[0m"):
                current = ""
            else:
                current += code
            i = m.end()
        elif line[i] == "\x1b":
            i += 1
        else:
            cells.append((current, line[i]))
            i += 1
    return cells

# Grid cells: (style, char)
grid = [[("", " ") for _ in range(ww)] for _ in range(wh)]

for pid, left, top, w, h in panes:
    content = tmux("capture-pane", "-ep", "-t", pid)
    rows = content.splitlines()[:h]
    for i, raw in enumerate(rows):
        cells = parse_cells(raw)[:w]
        while len(cells) < w:
            cells.append(("", " "))
        r = top + i
        if r >= wh:
            break
        for j, cell in enumerate(cells):
            c = left + j
            if c < ww:
                grid[r][c] = cell

right_edges = set()
bottom_edges = set()
for pid, left, top, w, h in panes:
    right = left + w
    bottom = top + h
    if right < ww:
        for r in range(top, min(top + h, wh)):
            right_edges.add((r, right))
    if bottom < wh:
        for c in range(left, min(left + w, ww)):
            bottom_edges.add((bottom, c))

out_lines = []
for r in range(wh):
    last_style = None
    parts = []
    for c in range(ww):
        if (r, c) in right_edges:
            sty = DIM
            if sty != last_style:
                parts.append(RESET + sty)
                last_style = sty
            parts.append("\u2502")
        elif (r, c) in bottom_edges:
            sty = DIM
            if sty != last_style:
                parts.append(RESET + sty)
                last_style = sty
            parts.append("\u2500")
        else:
            sty, ch = grid[r][c]
            if sty != last_style:
                parts.append(RESET + sty)
                last_style = sty
            parts.append(ch)
    parts.append(RESET)
    out_lines.append("".join(parts))

sys.stdout.write("\n".join(out_lines))
PY
  exit 0
fi

# Top-level invocation: start with every session expanded.
tmux set-option -g "$PICKER_OPT" "" 2>/dev/null || true

selected=$(build_list | fzf \
  --ansi \
  --prompt='search> ' \
  --height=100% \
  --layout=reverse \
  --no-info \
  --no-input \
  --input-border=rounded \
  --delimiter='|' \
  --with-nth=2 \
  --no-sort \
  --cycle \
  --preview "$SCRIPT --preview {1}" \
  --preview-window='right:75%:border-left' \
  --bind 'j:down,k:up' \
  --bind "h:transform($SCRIPT --h-action {1})" \
  --bind "l:transform($SCRIPT --l-action {1})" \
  --bind '/:show-input+enable-search' \
  --bind "esc:transform:if [ \"\$FZF_INPUT_STATE\" = \"enabled\" ]; then echo 'hide-input+disable-search+clear-query'; else echo abort; fi" \
  --bind "ctrl-x:execute-silent(case {1} in *:*) tmux kill-window -t {1} ;; *) tmux kill-session -t {1} ;; esac)+reload($SCRIPT --list)" \
  --bind "ctrl-n:execute(printf '\nnew session name: ' > /dev/tty; read -r n < /dev/tty; [ -n \"\$n\" ] && tmux new-session -ds \"\$n\" -c \"\$HOME\" 2>/dev/null)+reload($SCRIPT --list)" \
  --bind "ctrl-r:execute(tgt={1}; case \"\$tgt\" in *:*) kind=window;; *) kind=session;; esac; printf '\nrename %s \"%s\" to: ' \"\$kind\" \"\$tgt\" > /dev/tty; read -r n < /dev/tty; [ -n \"\$n\" ] && if [ \"\$kind\" = window ]; then tmux rename-window -t \"\$tgt\" \"\$n\" 2>/dev/null; else tmux rename-session -t \"\$tgt\" \"\$n\" 2>/dev/null; fi)+reload($SCRIPT --list)" \
  --bind "ctrl-w:execute(sess={1}; sess=\${sess%%:*}; printf '\nnew window name (blank for default): ' > /dev/tty; read -r n < /dev/tty; if [ -n \"\$n\" ]; then tmux new-window -t \"\$sess\" -n \"\$n\" 2>/dev/null; else tmux new-window -t \"\$sess\" 2>/dev/null; fi)+reload($SCRIPT --list)" \
  --footer=$' enter switch\n j/k up/down\n h/l collapse/expand\n / search\n ctrl-n new session\n ctrl-w new window\n ctrl-r rename\n ctrl-x kill\n esc back/cancel ' \
  --footer-border=top \
  --color='footer:italic:dim') || exit 0

target="${selected%%|*}"
[ -n "$target" ] && tmux switch-client -t "$target"
