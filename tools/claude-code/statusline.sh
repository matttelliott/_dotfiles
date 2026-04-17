#!/usr/bin/env bash
# Claude Code statusline - TokyoNight Storm theme
#
# Reads Claude Code session JSON on stdin, prints a one-line powerline status.
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
ICON_DIR=$(printf '\xef\x81\xbb')     # U+F07B nf-fa-folder

input=$(cat)
model=$(jq -r '.model.display_name // "Claude"' <<<"$input")
cwd=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
out_style=$(jq -r '.output_style.name // empty' <<<"$input")

dir="${cwd/#$HOME/~}"

rgb() {
  local h="${1#\#}"
  printf '%d;%d;%d' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}
seg()    { printf '\033[38;2;%s;48;2;%sm%s' "$(rgb "$1")" "$(rgb "$2")" "$3"; }
arrow()  { printf '\033[38;2;%s;48;2;%sm%s' "$(rgb "$1")" "$(rgb "$2")" "$SEP"; }
tail_()  { printf '\033[0;38;2;%sm%s\033[0m' "$(rgb "$1")" "$SEP"; }

seg "$ACCENT_DARK" "$ACCENT" " $ICON_MODEL  $model "
arrow "$ACCENT"    "$BG_HL"
seg "$FG"          "$BG_HL"  " $ICON_DIR  $dir "
tail_ "$BG_HL"

if [ -n "$out_style" ] && [ "$out_style" != "default" ]; then
  printf '\033[38;2;%sm [%s]' "$(rgb "$FG_DIM")" "$out_style"
fi

printf '\033[0m'
