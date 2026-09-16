#!/usr/bin/env bash
# Install tools from ~/_dotfiles/tools on this machine.
#
#   dotfiles-install                 pick tools with fzf (tab marks several)
#   dotfiles-install chrome firefox  install the named tools, no picker
#   dotfiles-install chrome --check  flags pass through to ansible-playbook
#
# In the picker, typing matches the tool name and its README text, so
# "browser" lists firefox, chrome, ... Reads ~/.config/dotfiles/self-update.env
# (written by tools/self-update) so --limit, -i and --skip-tags match
# self-update.sh.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/_dotfiles}"
cd "$DOTFILES_DIR"

DOTFILES_LIMIT=""
DOTFILES_INVENTORY=""
DOTFILES_SKIP_TAGS=""
# shellcheck source=/dev/null
[[ -f "$HOME/.config/dotfiles/self-update.env" ]] && source "$HOME/.config/dotfiles/self-update.env"

ARGS=(--connection=local --limit "${DOTFILES_LIMIT:-$(hostname -s)}")
[[ -n "$DOTFILES_INVENTORY" && -f "$DOTFILES_INVENTORY" ]] && ARGS+=(-i "$DOTFILES_INVENTORY")
[[ -n "$DOTFILES_SKIP_TAGS" ]] && ARGS+=(--skip-tags "$DOTFILES_SKIP_TAGS")

# Split argv: tool names vs. everything else (forwarded to ansible-playbook).
TOOLS=()
for a in "$@"; do
	if [[ $a == -* ]]; then
		ARGS+=("$a")
	elif [[ -f "tools/$a/install_$a.yml" ]]; then
		TOOLS+=("$a")
	else
		echo "dotfiles-install: no such tool: $a" >&2
		exit 1
	fi
done

pick() {
	local f t
	for f in tools/*/install_*.yml; do
		t="${f%/*}"
		t="${t#tools/}"
		printf '%-18s\t%s\n' "$t" "$(sed '1{/^#/d;}' "tools/$t/README.md" 2>/dev/null | tr -s '\n ' '  ')"
	done |
		fzf --exact --no-hscroll --multi --delimiter='\t' \
			--prompt='install> ' --header='tab: mark   enter: install' \
			--preview 'bat --color=always --style=plain -l md tools/{1}/README.md 2>/dev/null || cat tools/{1}/README.md 2>/dev/null' \
			--preview-window=right:50%:wrap |
		cut -f1
}

if [[ ${#TOOLS[@]} -eq 0 ]]; then
	while read -r t; do TOOLS+=("$t"); done < <(pick || true)
fi
[[ ${#TOOLS[@]} -eq 0 ]] && exit 0

for t in "${TOOLS[@]}"; do
	echo "==> $t"
	ansible-playbook "tools/$t/install_$t.yml" "${ARGS[@]}"
done
