#!/usr/bin/env bash
# Claude Code statusline - TokyoNight Storm theme
#
# Reads Claude Code session JSON on stdin, prints a one-line powerline status.
# Layout: [model] [context %]
# Colors and separators are managed by the theme switcher
# (see themes/_color.yml and themes/_style.yml).

BG="#24283b"
BG_HL="#3b4261"
FG="#c0caf5"
FG_DIM="#565f89"
ACCENT="#7aa2f7"
ACCENT_DARK="#1a1b26"
GREEN="#9ece6a"
RED="#f7768e"

# Powerline separator (UTF-8 for U+E0B0; theme switcher rewrites these bytes)
SEP=$(printf '\xee\x82\xb0')

# Nerd Font icons - written as UTF-8 byte escapes per CLAUDE.md guidance
ICON_MODEL=$(printf '\xef\x95\x84')   # U+F544 nf-fa-robot
ICON_CTX=$(printf '\xef\x88\x80')     # U+F200 nf-fa-pie_chart

input=$(cat)
model=$(jq -r '.model.display_name // "Claude"' <<<"$input")
pct_raw=$(jq -r '.context_window.used_percentage // 0' <<<"$input")
pct=$(awk -v p="$pct_raw" 'BEGIN { printf "%d", p + 0.5 }')

if [ "$pct" -ge 80 ]; then
  CTX_BG="$RED";   CTX_FG="$FG"
else
  CTX_BG="$BG_HL"; CTX_FG="$FG"
fi

rgb() {
  local h="${1#\#}"
  printf '%d;%d;%d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}
seg()    { printf '\033[38;2;%s;48;2;%sm%s' "$(rgb "$1")" "$(rgb "$2")" "$3"; }
arrow()  { printf '\033[38;2;%s;48;2;%sm%s' "$(rgb "$1")" "$(rgb "$2")" "$SEP"; }
tail_()  { printf '\033[0;38;2;%sm%s\033[0m' "$(rgb "$1")" "$SEP"; }

seg   "$ACCENT_DARK" "$ACCENT" " $ICON_MODEL  $model "
arrow "$ACCENT"      "$CTX_BG"
seg   "$CTX_FG"      "$CTX_BG" " $ICON_CTX $pct% "
tail_ "$CTX_BG"

printf '\033[0m'
