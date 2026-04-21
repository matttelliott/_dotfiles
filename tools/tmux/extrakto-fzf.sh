#!/bin/sh
# Ensure Homebrew's bin is on PATH — tmux popups don't inherit it by default.
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

orig_pane=$(tmux show-environment -g EXTRAKTO_ORIG_PANE 2>/dev/null | cut -d= -f2-)
case "$orig_pane" in
  ""|-*)
    exec fzf "$@"
    ;;
esac

helper="${TMPDIR:-/tmp}/extrakto-scroll-to.sh"
cat > "$helper" <<EOF
#!/bin/sh
tmux copy-mode -t $orig_pane
tmux send-keys -t $orig_pane -X search-backward "\$1"
EOF
chmod +x "$helper"

exec fzf --bind "ctrl-s:execute-silent($helper {})+accept" "$@"
