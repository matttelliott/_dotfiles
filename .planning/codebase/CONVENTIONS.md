# Coding Conventions

**Analysis Date:** 2026-01-19

## File Organization

**Ansible Playbooks:**
- Location: `tools/<toolname>/install_<toolname>.yml`
- One playbook per tool
- Naming: lowercase with hyphens for multi-word tools (e.g., `build-essential`, `chrome_canary`)

**Shell Configuration:**
- Location: `tools/<toolname>/<toolname>.zsh`
- Sourced from `~/.zshrc` via lineinfile task
- Destination: `~/.config/zsh/<toolname>.zsh`

**Jinja Templates:**
- Location: `tools/<toolname>/<filename>.j2`
- Use for configs requiring variable substitution (gitconfig, tmux.conf)

**Lua (Neovim):**
- Location: `tools/neovim/nvim/`
- Structure follows kickstart.nvim pattern
- Custom plugins: `lua/custom/plugins/*.lua`
- Kickstart plugins: `lua/kickstart/plugins/*.lua`

## Naming Patterns

**Files:**
- Playbooks: `install_<toolname>.yml`
- Shell configs: `<toolname>.zsh`
- Templates: `<filename>.j2`
- Lua modules: lowercase with hyphens or underscores

**Ansible Task Names:**
- Descriptive, action-first: "Install X via Y", "Create Z directory"
- Include OS context in conditional tasks: "(macOS)", "(Debian)", "(Arch)", "(Linux)"

**Variables:**
- snake_case for Ansible variables: `git_user_name`, `nvm_dir`
- SCREAMING_SNAKE_CASE for shell exports: `FZF_DEFAULT_OPTS`, `EZA_COLORS`

**Lua:**
- snake_case for variables and functions
- Descriptive plugin spec names

## Indentation

**YAML (Ansible):** 2 spaces
```yaml
- name: Install package
  apt:
    name: package
    state: present
  become: yes
```

**Lua:** 2 spaces
```lua
require('lazy').setup({
  { 'plugin/name', opts = {} },
})
```

**Bash:** 2 spaces
```bash
if [[ "$OS" == "darwin" ]]; then
  echo "macOS"
fi
```

## Ansible Playbook Structure

**Standard Pattern:**
```yaml
- name: Install <tool>
  hosts: all
  gather_facts: true

  tasks:
    - name: macOS task
      when: ansible_facts['os_family'] == "Darwin"

    - name: Debian task
      when: ansible_facts['os_family'] == "Debian"

    - name: Arch task
      when: ansible_facts['os_family'] == "Archlinux"

    - name: Linux-only task
      when: ansible_facts['os_family'] in ["Debian", "Archlinux"]
```

**OS Detection:**
- Use `gather_facts: true` for OS-conditional tasks
- Use `gather_facts: false` when no OS detection needed
- OS family values: `"Darwin"`, `"Debian"`, `"Archlinux"`

**Package Manager Patterns:**
```yaml
# macOS: Homebrew via shell (not module)
- name: Install via Homebrew
  shell: /opt/homebrew/bin/brew install <package>
  args:
    creates: /opt/homebrew/bin/<binary>
  when: ansible_facts['os_family'] == "Darwin"

# Debian: apt module
- name: Install via apt
  apt:
    name: <package>
    state: present
  become: yes
  when: ansible_facts['os_family'] == "Debian"

# Arch: pacman module
- name: Install via pacman
  pacman:
    name: <package>
    state: present
  become: yes
  when: ansible_facts['os_family'] == "Archlinux"
```

**Idempotency:**
- Use `creates:` for shell commands that install binaries
- Use `stat` + `when` for conditional installs
- Use `changed_when: false` for read-only commands

## Shell Configuration Pattern

**ZSH Config Installation:**
```yaml
- name: Create zsh config directory
  file:
    path: ~/.config/zsh
    state: directory

- name: Install <tool> zsh config
  copy:
    src: <tool>.zsh
    dest: ~/.config/zsh/<tool>.zsh

- name: Source <tool> config in zshrc
  lineinfile:
    path: ~/.zshrc
    line: 'source ~/.config/zsh/<tool>.zsh'
    create: yes
```

**ZSH File Structure:**
```bash
# Comment describing purpose
export VAR="value"
alias name='command'
```

## Lua (Neovim) Conventions

**Plugin Specification:**
```lua
return {
  {
    'author/plugin-name',
    event = 'VimEnter',
    opts = {
      option = value,
    },
  },
}
```

**Keymap Definition:**
```lua
vim.keymap.set('n', '<leader>x', function()
  -- action
end, { desc = '[X] Description' })
```

**Leader Key Descriptions:**
- Use `[X]` pattern for searchable descriptions
- Example: `[S]earch [F]iles`, `[G]oto [D]efinition`

**Formatting (StyLua):**
- Config: `tools/neovim/nvim/.stylua.toml`
- Column width: 160
- Indent: 2 spaces
- Quote style: AutoPreferSingle
- Call parentheses: None

## Error Handling

**Ansible:**
- Use `failed_when: false` for commands that may legitimately fail
- Use `register` + `when` for conditional execution based on results
- Use `ignore_errors: true` sparingly (only for truly optional operations)

**Bash:**
- Always use `set -e` for scripts
- Use `set -euo pipefail` for strict mode
- Check command existence before use: `command -v <cmd> &> /dev/null`

## Comments

**Ansible:**
- Block comments for explaining complex logic
- Inline comments for non-obvious conditionals
```yaml
# Docker Installation
#
# macOS: Uses Colima + docker CLI (free alternative to Docker Desktop)
# Linux: Uses docker-ce (Docker Community Edition)

- name: Install Docker
  # ...
```

**Lua:**
- Use `--[[  ]]--` for multi-line documentation
- Use `-- NOTE:`, `-- WARN:`, `-- TODO:` for annotations
- Document rejected plugins with reasons

## Template Variables

**Jinja2 Templates:**
- Use variables from `group_vars/all/defaults.yml`
- Encrypted overrides in `personal-info.sops.yml`
- Conditional blocks for optional features:
```jinja2
{% if git_signing_key %}
[commit]
	gpgsign = true
{% endif %}
```

## Host Groups

**Group-based feature flags:**
- `with_login_tools`: Git signing, SSH keys, cloud CLIs
- `with_gui_tools`: GUI applications (WezTerm, etc.)
- `with_browsers`: Browser suite
- `with_ai_tools`: AI tools (Claude Code, etc.)

**Usage in playbooks:**
```yaml
when: "'with_login_tools' in group_names"
```

## Theme System

**Color definitions:** `themes/_color.yml`
- Centralized color schemes with semantic names
- Applied via regex replacement to config files

**Special characters:**
- Nerd Font glyphs require special handling
- Use `vim.fn.nr2char(0xe0b0)` in Lua
- Use `\uXXXX` escape sequences in Ansible

---

*Convention analysis: 2026-01-19*
