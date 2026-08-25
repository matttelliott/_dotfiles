# \_dotfiles

Dotfiles and development environment management using Ansible. Supports macOS, Debian/Ubuntu, and Arch Linux with 90+ tools and applications.

## Tech Stack

- **Ansible** - Primary automation framework for deployment and configuration
- **Bash** - Bootstrap script and shell configurations
- **TypeScript/Pulumi** - Infrastructure as Code in `/infrastructure`
- **YAML** - Ansible playbooks and configurations
- **Lua** - Neovim configuration

## Directory Structure

```
_dotfiles/
├── bootstrap.sh          # Interactive OS detection + setup script
├── setup.yml             # Main Ansible playbook
├── ansible.cfg           # Ansible configuration
├── localhost.yml         # Local machine inventory (generated)
├── inventory.yml         # Remote machines inventory
├── infrastructure/       # Pulumi IaC for DigitalOcean
└── tools/                # 78 tool directories
    └── <tool>/
        ├── install_<tool>.yml   # Ansible playbook (OS-specific)
        ├── <tool>.zsh           # Shell configuration (optional)
        └── <config>.*           # Tool configs (optional)
```

## Commands

### Bootstrap New Machine

```bash
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

### Run Locally

```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
```

### Dry-run (Check Mode)

```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff
```

### Install Specific Tool Locally

```bash
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
```

### Development Workflow

1. Run in check mode with diff to preview changes
2. If issues, run `ansible-lint` to validate
3. Apply changes after review

### Run on All Hosts

```bash
./setup-all.sh
```

Runs `setup.yml` on localhost first, then all remote hosts. Passes any additional arguments to ansible-playbook.

### Run on Remote Host

```bash
ansible-playbook setup.yml --limit macbookair
ansible-playbook setup.yml --limit macmini
ansible-playbook setup.yml --limit desktop
```

### Lint Playbooks

```bash
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml
```

## Host Groups

| Group            | Description                                |
| ---------------- | ------------------------------------------ |
| `macs`           | macOS machines                             |
| `debian`         | Debian/Ubuntu machines                     |
| `arch`           | Arch Linux machines                        |
| `with_gui_tools` | GUI applications                           |
| `with_browsers`  | Browser suite                              |
| `with_ai_tools`  | AI tools (Claude Code)                     |
| `standard_users` | Non-admin accounts on a shared machine     |

## Multi-user Hosts

One machine can carry several accounts, split into two layers:

- **System layer** (`tags: system`) — package installs, services, sudoers,
  account creation, and writes to shared prefixes like `/opt/homebrew`. Run
  once per machine by an admin.
- **User layer** (untagged) — everything under `~`. Run per account.

Standard users run the same playbook with `--skip-tags system`:

```bash
# admin
ansible-playbook setup.yml --connection=local --limit $(hostname -s)

# standard user
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --skip-tags system
```

**When adding a task that needs `become: true`, or that writes anywhere
outside `$HOME`, tag it `system`.** Untagged means "safe for any account". Two
rules keep the split working:

1. A privileged task must not `register:` a variable an untagged task reads —
   the untagged task would fail on an undefined variable when the run skips
   the tag. Tag both, or make the consumer tolerate it.
2. `become: true` is not the only privileged marker. Homebrew needs no sudo
   but writes a single shared prefix (`/opt/homebrew`) that only the `admin`
   group can touch, so **every `brew install` / `brew tap` / `brew services`
   / `mas install` task is tagged `system`** even though none of them use
   `become`. Same for anything else writing outside `$HOME`:
   `softwareupdate` (`tools/homebrew`), the fortune data files
   (`tools/fortune`), and Nerd Font casks (`themes/_font.yml`). `yay` is the
   same trap on Arch — it must _not_ run under `become`, but it calls `sudo`
   itself, so every `yay -S` task is tagged too.

   The `creates:` guard is not a substitute — it only skips the task once the
   formula is already installed. On the first run, or for any formula the
   admin has not installed yet, an untagged brew task fails for a standard
   user.

Read-only probes (`Check if <tool> is installed`) stay untagged: they need no
privileges, and their registered values are read by tasks on both sides.

Accounts are declared per host via `host_users` in `inventory.yml` and
provisioned by `tools/users/install_users.yml`. See `tools/users/README.md`.

### Variable Precedence Gotcha

`group_vars/all.yml` (playbook group_vars/all) **outranks** a `vars:` block
written inline under a group in `inventory.yml`. `dotfiles_user_role` for the
`standard_users` group therefore lives in `group_vars/standard_users.yml` —
playbook `group_vars/<group>` beats `group_vars/all`, and a per-host value in
`inventory.yml` beats both.

For the same reason, `host_users` and `user_passwords` are defaulted in
`group_vars/all.yml` and never in a play's `vars:` block: play vars outrank
inventory host vars and would silently discard the per-host list.

## Ansible Patterns

### Per-Tool Playbook Structure

Each tool uses OS detection via `gather_facts`:

```yaml
- name: Install <tool>
  hosts: all
  gather_facts: true

  tasks:
    - name: macOS (Homebrew)
      when: ansible_facts['os_family'] == "Darwin"

    - name: Debian (apt)
      when: ansible_facts['os_family'] == "Debian"

    - name: Arch (pacman)
      when: ansible_facts['os_family'] == "Archlinux"
```

### Shell Configuration Pattern

Tools with shell config source their `<tool>.zsh` file in the zshrc.

## Code Style

- YAML: 2-space indentation
- Lua: 2-space indentation, single quotes (see `tools/neovim/nvim/.stylua.toml`)
- Shell: Use `shellcheck` for linting
- Playbooks: Use `ansible-lint` for validation
- Always use `become: yes` for package manager tasks on Linux
- Use `creates:` for idempotent Homebrew shell commands

## Version Policy

Tools use the most stable available version:

1. **LTS preferred** - Use LTS when available (e.g., `nvm install --lts`)
2. **Stable fallback** - Use stable channel when no LTS (e.g., Rust, Neovim)
3. **Latest acceptable** - Use latest when no LTS/stable distinction (e.g., Pulumi)

Package managers (Homebrew, apt, pacman) provide stable versions by default.

### Current Implementation

| Tool             | Version Strategy | Method                                                |
| ---------------- | ---------------- | ----------------------------------------------------- |
| Node.js          | LTS              | `nvm install --lts`, `nvm alias default lts/*`        |
| Rust             | Stable           | rustup defaults to stable toolchain                   |
| Neovim           | Latest stable    | GitHub `stable` tag (NOT apt - apt versions are old)  |
| Go               | Current stable   | Pinned version (Go has no LTS)                        |
| fastfetch, k9s   | Latest stable    | Resolved at run time from the releases API            |
| Pinned releases  | Latest stable    | `<tool>_version` var, Linux paths only                |
| All Homebrew     | Stable           | Formulae provide stable versions                      |
| All apt/pacman   | Stable           | Repos provide stable versions                         |

### Updating Pinned Versions

Every pinned tool declares a `<tool>_version` play var: `doctl`, `go`,
`lazygit`, `stylua` (in `tools/lua`), `tea`, `glab`, `sops`, `procs`,
`lazydocker`, `helm`, `nvm` (in `tools/node`), `uv` (in `tools/python`),
`pulumi`, `obsidian`, `chatgpt`, `yazi`. Apart from Go — which uses a `.pkg` on
macOS — these govern the Linux paths only; macOS goes through Homebrew.

**Bumping the var must actually upgrade the host.** Guard installs on the
*installed version*, never on mere existence — `creates:` and
`stat` + `not X.stat.exists` pin a machine to whatever it first installed:

```yaml
- name: Check installed procs version (Debian)
  ansible.builtin.command: /usr/local/bin/procs --version
  register: procs_installed
  changed_when: false
  failed_when: false      # not installed yet -> empty stdout -> install
  check_mode: false       # or --check reports everything as missing
  when: ansible_facts['os_family'] == "Debian"

- name: Download and install procs (Debian)
  ...
  when: >-
    ansible_facts['os_family'] == "Debian"
    and ("procs " ~ procs_version) not in (procs_installed.stdout | default(""))
```

Build the match with `~` concatenation, not `{{ }}` — `when:` is already a
Jinja context and ansible-lint flags `no-jinja-when`. Match a delimiter too
(`"procs " ~ version`, `"version=" ~ version ~ ","`) so `1.16.0` cannot match
inside `1.16.05`. Dropping `creates:` also means adding `changed_when:`.

Tools with no queryable version use a checksum instead — `get_url` re-downloads
when the recorded checksum no longer matches what is at `dest`, which makes
`sops`, `stylua`, and the `obsidian` AppImage version-aware for free. The
`chatgpt-desktop` AppImage records its version in a `.version` stamp file.

Node is special: it tracks the LTS *line*, not a pin. `nvm install --lts` runs
on every pass (no `creates:`) so a new LTS is picked up; global npm packages
are checked against the **active** Node, since a glob over
`~/.nvm/versions/node/*/bin/` would match the previous one and silently skip.

Current versions:

```bash
gh release view --repo <owner>/<repo> --json tagName -q .tagName
curl -s "https://go.dev/dl/?mode=json" | jq -r '.[] | select(.stable) | .version' | head -1
curl -s "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases" | jq -r '.[0].tag_name'   # glab
curl -s "https://gitea.com/api/v1/repos/gitea/tea/releases?limit=1" | jq -r '.[0].tag_name'      # tea
```

After bumping, **verify the asset URL still resolves** — upstreams rename
assets between releases. lazygit switched `Linux_x86_64` to `linux_x86_64`
after 0.44.1, which silently 404s:

```bash
curl -sIL -o /dev/null -w '%{http_code}\n' "<download url>"
```

Never write `releases/latest/download/<file-with-a-version-in-it>` — the
`latest` redirect resolves to the newest release, which by definition no
longer contains an older version's filename, so it 404s the moment upstream
publishes. Use an explicit tag, or a genuinely version-free asset name.

`sops` additionally verifies a checksum; update `sops_checksum` from the
release's `checksums.txt` in the same commit as `sops_version`.

## Claude Code Configuration

### Three-Layer Architecture Overview

Claude Code configuration follows a three-layer architecture, each with distinct ownership:

1. **User Layer (`~/.claude/`)** - Global defaults deployed by Ansible, applies to all repos
2. **Portable Layer (`~/.claude/<name>/`)** - Self-contained packages with their own installers (e.g., GSD)
3. **Repo Layer (`.claude/`)** - Project-specific config committed to each repository

### Layer Ownership Rules

| Layer    | Location            | Ownership           | Examples                             |
| -------- | ------------------- | ------------------- | ------------------------------------ |
| User     | `~/.claude/`        | Ansible (this repo) | Global CLAUDE.md, base settings.json |
| Portable | `~/.claude/<name>/` | Package installer   | GSD workflows, Context7              |
| Repo     | `.claude/`          | Per-repository      | Project rules, custom commands       |

### Current User-Level Structure

```
~/.claude/
├── settings.json         # Global settings (hooks, permissions)
├── CLAUDE.md             # Global instructions (if created)
├── commands/             # User-level slash commands
│   └── gsd/              # GSD namespace (from portable)
├── agents/               # User-level subagents
│   └── gsd-*.md          # GSD agents (from portable)
└── hooks/                # Hook scripts
   └── *.js              # GSD hooks (from portable)
```

### When to Use Each Layer

- **User:** Machine-wide defaults (permissions, common tools), shared across all projects
- **Portable:** Reusable workflow packages installed via npx, self-updating
- **Repo:** Project-specific rules, commands, hooks committed with source code

## Nerd Font / Powerline Characters

**IMPORTANT:** The tmux, starship, and neovim configs contain Nerd Font glyphs (Unicode Private Use Area: U+E0xx, U+F0xx, etc.). These characters are problematic for LLMs because they display as whitespace or render inconsistently.

**Files with special characters:**

- `tools/tmux/tmux.conf.j2`
- `tools/starship/starship.toml`
- `tools/neovim/nvim/init.lua`

**DO NOT edit these characters directly.** Use escape sequences by code point instead.

### Powerline Separator Code Points

| Style | Right | Left | Code Points |
| ------ | ----- | ---- | -------------- | ----------------------------------------------------------------------------------------------------------- |
| Angled | `   |` | U+E0B0, U+E0B2 | <-- ALERT! this is an example of what happens when claude tries to edit files with these special characters |
| Round | `   |` | U+E0B4, U+E0B6 | <-- BAD! claude tried to edit this file and the special characters disappeared! |

### Editing Approaches

**For Ansible playbooks** - Use `\uXXXX` escape sequences in variables:

```yaml
vars:
  arrow_right: "\uE0B0"
  round_right: "\uE0B4"
tasks:
  - ansible.builtin.replace:
      regexp: "{{ arrow_right }}"
      replace: "{{ round_right }}"
```

**For Lua (neovim)** - Use `vim.fn.nr2char()`:

```lua
local arrow_right = vim.fn.nr2char(0xe0b0)
```

**For Python** - Use `chr()`:

```python
POWERLINE_RIGHT = chr(0xE0B0)
```

### Reference Examples

See `themes/style_angle.yml` and `themes/style_round.yml` for complete working examples of replacing Nerd Font characters across tmux, starship, and neovim using Ansible.

See `README.md` section "Nerd Font / Powerline Characters" for full documentation.

### Testing Theme Changes

Theme playbooks modify 9 config files (tmux, starship, neovim, wezterm, lazygit, fzf, bat, lazydocker) using regex replacements. Because Nerd Font characters are problematic for LLMs and text editors, theme changes require careful testing before committing.

**Before committing theme changes:**

1. **Run in check mode first:**

   ```bash
   ansible-playbook themes/_color.yml -e color=dracula --check --diff
   ```

   Review the diff output - should show only hex color changes, not character corruption.

2. **Verify special characters not corrupted:**

   ```bash
   git diff themes/ | grep -E '\\u[0-9A-Fa-f]{4}|nr2char'
   ```

   You should see escape sequences like `\uE0B0` or `nr2char(0xe0b0)`, NOT boxes, question marks, or empty strings where characters used to be.

3. **Visual validation after applying theme:**
   - [ ] **tmux statusline:** Powerline arrows visible between segments (detach with `<C-b> d` and reattach to verify)
   - [ ] **starship prompt:** Powerline separators visible (run any command, check prompt renders correctly)
   - [ ] **neovim statusline:** Open nvim, check bottom bar has arrow separators
   - [ ] **fzf:** Press `Ctrl+R` for history, verify border and preview styling
   - [ ] **lazygit:** Run `gg`, verify border colors changed appropriately

4. **Common mistakes checklist:**
   - [ ] Did NOT edit Nerd Font characters directly in files (use escape sequences)
   - [ ] Verified tmux reloaded config: `tmux source-file ~/.tmux.conf`
   - [ ] Restarted shell for starship/fzf changes to take effect
   - [ ] Tested on actual machine, not just `--check` mode

**If theme breaks:**

1. Restore defaults: `ansible-playbook themes/apply_defaults.yml`
2. Check what changed: `git diff themes/`
3. Restore corrupted files: `git checkout -- themes/_style.yml themes/_color.yml`

**Testing new theme definitions:**

When adding a new color scheme to `themes/_color.yml`:

1. Add color definition to the `colors:` dictionary in the playbook
2. Apply the new theme: `ansible-playbook themes/_color.yml -e color=newtheme`
3. Manually verify each affected tool (tmux, starship, neovim, fzf, lazygit, etc.)
4. Document any terminal-specific requirements in README.md if needed

**Why this matters:**

Theme playbooks touch multiple config files with special Unicode characters (Nerd Font glyphs in Private Use Area U+E0xx). A single corrupted glyph can break multiple tools. The regex patterns are fragile - they rely on exact character matching. Visual testing is required because automated tests cannot verify glyph rendering. Always test visually before committing theme changes.
