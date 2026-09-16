# dotfiles-install

Install tools from this repo on the current machine, one at a time.

```
dotfiles-install                  # fzf picker; tab marks several
dotfiles-install chrome firefox   # named tools, no picker
dotfiles-install chrome --check   # flags pass through to ansible-playbook
```

The picker matches on tool name and README text ("browser" lists chrome,
firefox, ...). Reads `~/.config/dotfiles/self-update.env` so `--limit`, `-i`
and `--skip-tags` match `self-update.sh`.
