#!/usr/bin/env bash
# Claude-Desktop-style tmux session picker.
# Left-anchored popup, all sessions expanded, windows indented underneath.
set -eu

BOLD=$'\033[1m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
RESET=$'\033[0m'

SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

build_list() {
  # Format per line: target|display (fzf 0.60+ searches the displayed field)
  local current_sess
  current_sess=$(tmux display-message -p '#S' 2>/dev/null || echo "")
  tmux list-sessions -F '#{session_name}' | LC_ALL=C sort | while read -r sess; do
    attached=$(tmux display -p -t "$sess" '#{session_attached}' 2>/dev/null || echo 0)
    if [ "$sess" = "$current_sess" ]; then
      marker="${CYAN}▸${RESET}"
    elif [ "$attached" != "0" ]; then
      marker="${GREEN}●${RESET}"
    else
      marker=" "
    fi
    window_names=$(tmux list-windows -t "$sess" -F '#{window_name}' | paste -sd ' · ' -)
    printf '%s|%s %s%s%s   %s%s%s\n' "$sess" "$marker" "$BOLD" "$sess" "$RESET" "$DIM" "$window_names" "$RESET"
    if [ "$sess" = "$current_sess" ]; then
      tmux list-windows -t "$sess" -F "#{session_name}:#{window_index}|#{?#{window_active}, ${CYAN}▸${RESET} ,   }${DIM}#{session_name} · #{window_index}: #{window_name}${RESET}"
    else
      tmux list-windows -t "$sess" -F "#{session_name}:#{window_index}|   ${DIM}#{session_name} · #{window_index}: #{window_name}${RESET}"
    fi
  done
}

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
  --preview "$SCRIPT --preview {1}" \
  --preview-window='right:75%:border-left' \
  --bind 'j:down,k:up,h:first,l:last' \
  --bind '/:show-input+enable-search' \
  --bind "esc:transform:if [ \"\$FZF_INPUT_STATE\" = \"enabled\" ]; then echo 'hide-input+disable-search+clear-query'; else echo abort; fi" \
  --bind "ctrl-x:execute-silent(case {1} in *:*) tmux kill-window -t {1} ;; *) tmux kill-session -t {1} ;; esac)+reload($SCRIPT --list)" \
  --bind "ctrl-n:execute(printf '\nnew session name: ' > /dev/tty; read -r n < /dev/tty; [ -n \"\$n\" ] && tmux new-session -ds \"\$n\" -c \"\$HOME\" 2>/dev/null)+reload($SCRIPT --list)" \
  --footer=$' enter switch\n j/k up/down\n / search\n ctrl-x kill\n ctrl-n new\n esc back/cancel ' \
  --footer-border=top \
  --color='footer:italic:dim') || exit 0

target="${selected%%|*}"
[ -n "$target" ] && tmux switch-client -t "$target"
