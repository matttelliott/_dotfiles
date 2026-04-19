# Show pending dotfiles auto-update changelog on first new shell after each update
if [[ -r "$HOME/.cache/dotfiles-pending-update.md" ]]; then
  cat "$HOME/.cache/dotfiles-pending-update.md"
  rm -f "$HOME/.cache/dotfiles-pending-update.md"
fi
