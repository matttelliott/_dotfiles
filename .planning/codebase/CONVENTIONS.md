# Coding Conventions

**Analysis Date:** 2026-01-19

## Naming Patterns

**Files:**
- Ansible playbooks: `install_<tool>.yml` (lowercase, underscores for compound names)
- Shell configs: `<tool>.zsh` (lowercase, matches tool name)
- Config templates: `<config>.j2` (Jinja2 templates) or `<config>.<ext>` (static)
- Inventory files: `<purpose>.yml` (e.g., `localhost.yml`, `inventory.yml`)

**Directories:**
- Tool directories: `tools/<tool>/` (lowercase, hyphens for compound names like `build-essential`)
- Config dirs: Use singular nouns (`themes/`, `group_vars/`)

**Variables (Ansible):**
- Snake_case for all variables: `git_user_name`, `ssh_public_key`
- Boolean prefixes avoided; use descriptive names: `op_ssh_private_key_ref`
- Registered variables describe content: `docker_ce_check`, `nvim_check`, `tmux_config`

**Functions (Lua):**
- Snake_case for local functions: `set_statusline_hl`, `update_git_branch`
- Global functions use `_G.` prefix: `_G.get_mode_name()`, `_G.get_git_branch()`
- Helper functions defined inline within configs

## Code Style

**YAML (Ansible):**
- 2-space indentation (standard Ansible)
- Document separator `---` at file start (playbooks only, not always used)
- No trailing whitespace
- Quoted strings for shell commands containing special characters
- Unquoted strings for simple values

**Lua (Neovim):**
- 2-space indentation
- Single quotes preferred (per `.stylua.toml`: `quote_style = "AutoPreferSingle"`)
- No call parentheses for single-argument string/table calls (per `.stylua.toml`: `call_parentheses = "None"`)
- 160 character line width limit (per `.stylua.toml`)
- Unix line endings

**Lua Style Config:** `tools/neovim/nvim/.stylua.toml`
```toml
column_width = 160
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "None"
```

**Shell (Bash/Zsh):**
- Use `set -e` for scripts that should fail on error
- Use `set -euo pipefail` for strict error handling: `setup-all.sh`
- Double quotes around variables: `"$HOME"`, `"$OSTYPE"`
- Use `[[ ]]` for conditionals (bash-specific)
- Prefer `$(command)` over backticks

**WezTerm Lua:**
- Tab indentation (differs from neovim style)
- Double quotes for strings
- Concise single-file configuration: `tools/wezterm/wezterm.lua`

## Import Organization

**Lua (Neovim):**
1. Built-in requires (`require 'telescope.builtin'`)
2. Plugin specs in order of loading
3. Local variables at top of functions

**Path Aliases:**
- Neovim custom plugins: `custom.plugins.*` maps to `lua/custom/plugins/*.lua`
- Kickstart plugins: `kickstart.plugins.*` maps to `lua/kickstart/plugins/*.lua`

## Error Handling

**Ansible:**
- Use `failed_when: false` for commands that may legitimately fail
- Use `ignore_errors: yes` for optional operations (e.g., reloading tmux when not running)
- Use `changed_when: false` for read-only commands that should never show as changed
- Use `changed_when: "'text' in result.stdout"` for accurate change detection
- Register results and check `.stat.exists` for file operations
- Use `no_log: true` for tasks handling secrets

**Shell:**
- Use `|| true` to continue on failure: `claude mcp remove ... || true`
- Use `2>/dev/null` to suppress expected errors
- Check command existence with `command -v` before use

**Lua:**
- Use `pcall()` for potentially failing operations: `pcall(require, 'nvim-treesitter.configs')`
- Check for nil before accessing: `if client and client_supports_method(...)`

## Logging

**Framework:** Ansible built-in output

**Patterns:**
- Task names describe the action: `Install git via apt (Debian)`
- Include OS/platform context in task names when OS-specific
- Use comments for documentation, not task names

**Shell scripts:**
- Use `echo` for user feedback
- Section headers with `===`: `echo "=== Dotfiles Bootstrap ==="`

## Comments

**When to Comment:**
- Explain WHY, not WHAT (task names explain what)
- Document non-obvious decisions or workarounds
- Explain complex regex patterns
- Mark OS-specific sections

**Ansible Comment Style:**
```yaml
# macOS: Colima + docker CLI + docker-compose
- name: Install Colima and Docker via Homebrew (macOS)
```

**Lua Comment Style:**
```lua
-- Block comments for sections
-- [[ Setting options ]]

-- Inline comments for non-obvious code
local arrow_right = vim.fn.nr2char(0xe0b0) --
```

**JSDoc/TSDoc:** Not applicable (no TypeScript in configs)

## Function Design

**Ansible Tasks:**
- One logical action per task
- Use `block:` sparingly; prefer separate tasks
- Group related tasks without explicit blocks

**Lua Functions:**
- Small, focused functions
- Define helpers inline when used once
- Use callbacks for autocommands

**Shell Functions:**
- Minimal use; prefer scripts
- When used, define at script top

## Module Design

**Ansible Playbook Structure:**
```yaml
- name: Install <tool>
  hosts: all
  gather_facts: true
  vars:  # Optional
    key: value
  tasks:
    - name: macOS task
      when: ansible_facts['os_family'] == "Darwin"
    - name: Debian task
      when: ansible_facts['os_family'] == "Debian"
    - name: Arch task
      when: ansible_facts['os_family'] == "Archlinux"
```

**Standard OS Conditionals:**
- macOS: `ansible_facts['os_family'] == "Darwin"`
- Debian/Ubuntu: `ansible_facts['os_family'] == "Debian"`
- Arch Linux: `ansible_facts['os_family'] == "Archlinux"`
- Linux (both): `ansible_facts['os_family'] in ["Debian", "Archlinux"]`

**Exports (Lua):**
- Plugin specs return tables with lazy.nvim structure
- Custom modules return single tables

**Barrel Files:** Not used

## Ansible-Specific Patterns

**Idempotency:**
- Use `creates:` for shell commands to check if action needed
- Use `stat:` + `register:` to check file existence before actions
- Use package modules (`apt`, `pacman`) over shell when possible

**Homebrew on macOS:**
- Always use full path: `/opt/homebrew/bin/brew`
- Use `creates:` to make shell commands idempotent:
```yaml
- name: Install via Homebrew
  shell: /opt/homebrew/bin/brew install <package>
  args:
    creates: /opt/homebrew/bin/<binary>
```

**Privilege Escalation:**
- Use `become: yes` for package manager tasks on Linux
- Never use `become: yes` for Homebrew (user-level install)
- Use `become: yes` for systemd operations

**File Deployment:**
- Use `copy:` for static files
- Use `template:` for files needing variable interpolation (`.j2` extension)
- Use `lineinfile:` for adding single lines to existing files
- Use `blockinfile:` for multi-line additions with markers

**Shell Configuration Pattern:**
1. Create `~/.config/zsh` directory
2. Copy `<tool>.zsh` to that directory
3. Add `source ~/.config/zsh/<tool>.zsh` to `~/.zshrc`

## Nerd Font Characters

**CRITICAL:** Do not edit Nerd Font glyphs directly. Use escape sequences.

**Files with special characters:**
- `tools/tmux/tmux.conf.j2`
- `tools/starship/starship.toml`
- `tools/neovim/nvim/init.lua`

**Code Point Reference:**
| Style  | Right   | Left    | Code Points    |
| ------ | ------- | ------- | -------------- |
| Angled | U+E0B0  | U+E0B2  | `\uE0B0`, `\uE0B2` |
| Round  | U+E0B4  | U+E0B6  | `\uE0B4`, `\uE0B6` |

**Editing Approaches:**
- Ansible: Use `\uXXXX` escape sequences in variables
- Lua: Use `vim.fn.nr2char(0xe0b0)`
- Python: Use `chr(0xE0B0)`

Example from `tools/neovim/nvim/init.lua`:
```lua
local arrow_right = vim.fn.nr2char(0xe0b0)
local arrow_left = vim.fn.nr2char(0xe0b2)
```

---

*Convention analysis: 2026-01-19*
