# Phase 6: Idempotency Guards - Research

**Researched:** 2026-01-21
**Domain:** Ansible idempotency for shell-based tool installations
**Confidence:** HIGH

## Summary

This phase addresses false "changed" status when re-running playbooks that use `ansible.builtin.shell` for tool installations. The `creates:` argument provides a simple, effective guard by checking for the existence of a file (typically the installed binary) before running the command.

The codebase already uses `creates:` guards extensively for Homebrew, cargo, and some uv/go installs. However, several shell-based installations are missing guards:
- Go dev tools in `install_go.yml` (gofumpt, goimports, gopls)
- Python dev tools in `install_python.yml` (ruff, black, isort via uv)
- Claude Code in `install_claude-code.yml` (npm global)
- Various MCP server installs and GSD in `install_claude-code.yml`

**Primary recommendation:** Add `creates:` guards pointing to the installed binary location for each shell-based tool installation. Use the standard binary paths documented below.

## Standard Stack

This phase uses only built-in Ansible features - no additional libraries required.

### Core
| Feature | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ansible.builtin.shell` | Built-in | Execute shell commands | Standard module for commands requiring shell features |
| `creates:` argument | Built-in | Idempotency guard | Skips task if specified file exists |

### Supporting
| Feature | Purpose | When to Use |
|---------|---------|-------------|
| `removes:` argument | Opposite of creates | When task should run only if file exists |
| `changed_when:` | Custom change detection | When output parsing needed (e.g., npm's "up to date") |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `creates:` | `when:` with `stat` | More verbose but identical functionality |
| `creates:` | `changed_when:` | Requires parsing command output, more brittle |

## Architecture Patterns

### Binary Location Map

Standard binary locations for each tool type:

```yaml
# Go binaries (go install)
~/go/bin/<binary>

# npm global binaries (nvm-managed)
~/.nvm/versions/node/*/bin/<binary>

# uv tool binaries (symlinked)
~/.local/bin/<binary>
# Or underlying tool location:
~/.local/share/uv/tools/<tool>/bin/<binary>

# Mason binaries (neovim)
~/.local/share/nvim/mason/bin/<binary>

# Cargo binaries
~/.cargo/bin/<binary>

# Homebrew binaries (macOS)
/opt/homebrew/bin/<binary>
```

### Pattern 1: Simple Creates Guard

**What:** Single binary installation with creates guard
**When to use:** Installing a single tool via shell command
**Example:**
```yaml
# Source: Existing pattern in install_yamlfmt.yml
- name: Install yamlfmt via go install (Debian)
  ansible.builtin.shell: /usr/local/go/bin/go install github.com/google/yamlfmt/cmd/yamlfmt@latest
  args:
    creates: ~/go/bin/yamlfmt
  when: ansible_facts['os_family'] == "Debian"
```

### Pattern 2: Multiple Tool Installation

**What:** Installing multiple tools in a single task
**When to use:** When tools are related and installed together
**Example:**
```yaml
# Current pattern in install_go.yml (MISSING guards)
- name: Install Go dev tools
  ansible.builtin.shell: |
    export PATH=$PATH:/usr/local/go/bin
    go install mvdan.cc/gofumpt@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install golang.org/x/tools/gopls@latest

# Recommended: Split into separate tasks OR guard on first binary
- name: Install Go dev tools
  ansible.builtin.shell: |
    export PATH=$PATH:/usr/local/go/bin
    go install mvdan.cc/gofumpt@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install golang.org/x/tools/gopls@latest
  args:
    creates: ~/go/bin/gofumpt
```

### Pattern 3: Glob Pattern for NVM

**What:** Using wildcard in creates path for version-independent checking
**When to use:** When binary path contains version number
**Example:**
```yaml
# Source: Existing pattern in install_node.yml
- name: Install global npm packages (macOS)
  ansible.builtin.shell: |
    export NVM_DIR="$HOME/.nvm"
    . /opt/homebrew/opt/nvm/nvm.sh
    npm install -g typescript @fsouza/prettierd eslint_d
  args:
    creates: ~/.nvm/versions/node/*/bin/tsc
  when: ansible_facts['os_family'] == "Darwin"
```

### Anti-Patterns to Avoid

- **Missing guards entirely:** Always add `creates:` for shell installs that produce binaries
- **Guarding on wrong file:** Use the actual binary, not a config file or directory
- **Over-splitting tasks:** If tools are always installed together, one guard is sufficient
- **Using `changed_when: false`:** This masks problems - prefer `creates:` for true idempotency

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Check if binary exists | `stat` + `when:` | `creates:` argument | Built-in, cleaner, same effect |
| Parse npm output | `changed_when:` with regex | `creates:` with binary path | Brittle - npm output format may change |
| Track installation state | External state file | `creates:` with binary path | Binary existence IS the state |

**Key insight:** The `creates:` argument was designed specifically for this use case. Don't implement custom state tracking when Ansible provides it built-in.

## Common Pitfalls

### Pitfall 1: Incorrect Binary Path

**What goes wrong:** Guard checks wrong path, command always runs or never runs
**Why it happens:** Assuming binary location instead of verifying
**How to avoid:** Use documented paths:
- Go: `~/go/bin/<binary>` (not `/usr/local/go/bin`)
- npm/nvm: `~/.nvm/versions/node/*/bin/<binary>` (glob for version)
- uv: `~/.local/bin/<binary>` (symlink) or `~/.local/share/uv/tools/<tool>/bin/<binary>`
- Mason: `~/.local/share/nvim/mason/bin/<binary>`
**Warning signs:** Task shows "changed" on every run

### Pitfall 2: Tilde Expansion in creates

**What goes wrong:** `~` may not expand correctly in all contexts
**Why it happens:** Ansible's `creates:` handles `~` but some edge cases exist
**How to avoid:** Use `~/` consistently (Ansible expands this correctly)
**Warning signs:** Guard never triggers even though file exists

### Pitfall 3: Multiple Binaries, Single Guard

**What goes wrong:** If first binary exists but others don't, they won't be installed
**Why it happens:** Guarding on one binary assumes all-or-nothing installation
**How to avoid:** Either:
1. Accept this behavior (usually fine - tools installed together)
2. Split into separate tasks with individual guards
**Warning signs:** Partial installation after interrupted run

### Pitfall 4: @latest Packages Never Update

**What goes wrong:** Package installed once, never updated despite @latest
**Why it happens:** `creates:` only checks existence, not version
**How to avoid:** This is acceptable behavior - use explicit update tasks if needed
**Warning signs:** None - this is expected behavior for idempotency

## Code Examples

### Current State Analysis

Files requiring changes:

**1. install_go.yml (line 57-62)** - MISSING guard
```yaml
# Current (always runs)
- name: Install Go dev tools
  ansible.builtin.shell: |
    export PATH=$PATH:/usr/local/go/bin
    go install mvdan.cc/gofumpt@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install golang.org/x/tools/gopls@latest

# Fixed (guard on first binary)
- name: Install Go dev tools
  ansible.builtin.shell: |
    export PATH=$PATH:/usr/local/go/bin
    go install mvdan.cc/gofumpt@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install golang.org/x/tools/gopls@latest
  args:
    creates: ~/go/bin/gofumpt
```

**2. install_python.yml (lines 19-25)** - MISSING guards
```yaml
# Current (always runs)
- name: Install Python dev tools (macOS)
  ansible.builtin.shell: >-
    /opt/homebrew/bin/uv tool install ruff &&
    /opt/homebrew/bin/uv tool install black &&
    /opt/homebrew/bin/uv tool install isort
  when: ansible_facts['os_family'] == "Darwin"

# Fixed (guard on first binary)
- name: Install Python dev tools (macOS)
  ansible.builtin.shell: >-
    /opt/homebrew/bin/uv tool install ruff &&
    /opt/homebrew/bin/uv tool install black &&
    /opt/homebrew/bin/uv tool install isort
  args:
    creates: ~/.local/bin/ruff
  when: ansible_facts['os_family'] == "Darwin"
```

**3. install_claude-code.yml (lines 10-26)** - Uses changed_when, could use creates
```yaml
# Current (uses changed_when for idempotency)
- name: Install/update Claude Code via npm (macOS)
  ansible.builtin.shell: |
    export NVM_DIR="$HOME/.nvm"
    . /opt/homebrew/opt/nvm/nvm.sh
    npm install -g @anthropic-ai/claude-code@latest
  register: claude_install_mac
  changed_when: "'added' in claude_install_mac.stdout or 'updated' in claude_install_mac.stderr"
  when: ansible_facts['os_family'] == "Darwin"

# Note: changed_when approach is valid for @latest packages where
# we want to check for updates. creates: would skip entirely.
# Decision: Keep changed_when for claude-code since it uses @latest
```

**4. install_claude-code.yml (MCP servers, lines 48-72)** - Uses changed_when: true
```yaml
# Current (always shows changed)
- name: Add/update Sequential Thinking MCP server (user level)
  ansible.builtin.shell: |
    ...
    claude mcp add --scope user --transport stdio thinking -- npx -y @modelcontextprotocol/server-sequential-thinking@latest
  changed_when: true
  failed_when: false

# Note: MCP servers use npx -y which always downloads latest
# These are intentionally marked as always changed
# Decision: Keep as-is - these are meant to always update
```

### Files Already Properly Guarded

- `install_yamlfmt.yml` - has `creates: ~/go/bin/yamlfmt`
- `install_tldr.yml` - has `creates: ~/.local/share/uv/tools/tldr/bin/tldr`
- `install_ansible.yml` - has `creates:` for both ansible and ansible-lint
- `install_codex.yml` - has `creates: ~/.nvm/versions/node/*/bin/codex`
- `install_node.yml` - has `creates:` for all npm global packages
- `install_neovim.yml` - has `creates: ~/.local/share/nvim/mason/bin/typescript-language-server`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `when:` with `stat` | `creates:` argument | Always available | Cleaner, more idiomatic |
| Ignore changed status | `changed_when:` conditions | Ansible 1.x | Better reporting |
| `creates:` + `removes:` | Same | Stable | No change needed |

**Deprecated/outdated:**
- None - the `creates:` argument has been stable since early Ansible versions

## Open Questions

None - the approach is well-established and the codebase already demonstrates the correct patterns.

## Sources

### Primary (HIGH confidence)
- [Ansible shell module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html) - creates argument behavior
- [uv Storage Documentation](https://docs.astral.sh/uv/reference/storage/) - tool binary locations
- [Go Wiki: GOPATH](https://go.dev/wiki/GOPATH) - GOBIN defaults to $GOPATH/bin
- [Mason.nvim GitHub](https://github.com/williamboman/mason.nvim) - mason binary location structure
- [nvm-sh/nvm GitHub](https://github.com/nvm-sh/nvm) - NVM global package isolation

### Secondary (MEDIUM confidence)
- [Idempotent shell command in Ansible](https://ansibledaily.com/idempotent-shell-command-in-ansible/) - pattern validation
- [Multiple Node.js Installs with NVM](https://www.voitanos.io/blog/multiple-node-installs-nvm-global-packages/) - NVM path structure

### Tertiary (LOW confidence)
- None required - all findings verified with official sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - uses built-in Ansible features
- Architecture: HIGH - binary paths verified from official documentation
- Pitfalls: HIGH - based on codebase analysis and existing patterns

**Research date:** 2026-01-21
**Valid until:** 2026-03-21 (patterns are stable, 60-day validity)
