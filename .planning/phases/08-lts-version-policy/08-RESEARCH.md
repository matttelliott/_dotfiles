# Phase 8: LTS Version Policy - Research

**Researched:** 2026-01-22
**Requirement:** LTS-01

## Executive Summary

**Node.js is already using LTS** - the current `install_node.yml` playbook uses `nvm install --lts` and `nvm alias default lts/*`. This is the primary LTS-capable tool in the codebase, and it's already configured correctly.

**Minimal changes needed** - most tools either (a) already use LTS/stable via package managers, (b) don't offer LTS channels, or (c) use stable releases by default. The main action is to **document the policy** and potentially adjust 2-3 tools.

## Current State Analysis

### Tools Already Following LTS Policy

| Tool | Method | Current Behavior | Status |
|------|--------|-----------------|--------|
| Node.js | nvm | `--lts` flag, `lts/*` alias | Correct |
| Neovim | GitHub | Downloads `stable` release (NOT apt - apt versions are outdated) | Correct |
| Docker | APT repo | Uses `stable` channel | Correct |
| Vivaldi | APT repo | Uses `stable` channel | Correct |
| Opera | APT repo | Uses `stable` channel | Correct |
| Chrome | Direct DEB | Downloads `stable` build | Correct |
| Edge | APT repo | Uses `stable` channel | Correct |
| Brave | APT repo | Uses `stable` channel | Correct |
| gh CLI | APT repo | Uses `stable` channel | Correct |
| 1Password | APT repo | Uses `stable` channel | Correct |
| All Homebrew | brew | Formulae provide stable | Correct |
| All pacman | pacman | Repos provide stable | Correct |
| All apt | apt | Repos provide stable | Correct |

### Tools with Explicit Version Pinning

These tools pin to specific versions (not LTS, but intentional):

| Tool | Pinned Version | Notes |
|------|---------------|-------|
| Go | `1.23.4` | Current stable, no LTS concept |
| lazygit | `0.44.1` | Debian only, latest release |
| doctl | `1.104.0` | Debian only, latest release |
| nvm script | `v0.40.1` | Latest release at time of writing |

**Note:** Go, lazygit, and doctl don't have LTS programs. Their current versions are appropriate.

### Tools That Use "Latest"

| Tool | Method | Behavior | Change Needed? |
|------|--------|----------|----------------|
| Rust | rustup.rs | Uses stable toolchain | No - rustup defaults to stable |
| Python (uv) | uv installer | Installs latest uv | No - uv itself doesn't have LTS |
| Pulumi | installer | Latest version | No - no LTS program |
| Starship | installer | Latest version | No - no LTS program |
| Claude Code | installer | Latest version | No - no LTS program |
| MCP servers | npx @latest | Latest version | Intentional - always want newest |

### Tools with Version Manager Support

| Tool | Version Manager | LTS Support | Current Behavior |
|------|----------------|-------------|------------------|
| Node.js | nvm | Yes | `--lts` flag used |
| Python | uv/pyenv | Partial | uv installs tools, not Python itself |
| Rust | rustup | Stable only | Uses stable by default |

## Key Finding: Node.js Already Correct

The `tools/node/install_node.yml` playbook already implements LTS policy:

```yaml
- name: Install Node.js LTS (macOS)
  ansible.builtin.shell: |
    export NVM_DIR="$HOME/.nvm"
    . /opt/homebrew/opt/nvm/nvm.sh
    nvm install --lts
    nvm alias default lts/*
```

The shell configuration (`node.zsh`) also correctly handles LTS alias resolution:

```zsh
elif [[ "$alias" == lts/* ]]; then
  local lts_name="${alias#lts/}"
  target="$NVM_DIR/alias/lts/$lts_name"
```

## Python Analysis

**uv** is used as the Python package/tool manager, not a Python version manager. Looking at `install_python.yml`:

```yaml
- name: Install uv via Homebrew
  ansible.builtin.shell: /opt/homebrew/bin/brew install uv

- name: Install Python dev tools (macOS)
  ansible.builtin.shell: /opt/homebrew/bin/uv tool install ruff && ...
```

**Key insight:** The codebase doesn't manage Python interpreter versions - it relies on system Python (from Homebrew/apt/pacman) and uses uv only for Python tools (ruff, black, isort). This is the correct pattern for this dotfiles repo.

Python itself from package managers is typically the stable release, which follows the policy.

## Rust Analysis

Rustup defaults to the stable toolchain. From `install_rust.yml`:

```yaml
- name: Install Rust via rustup.rs
  ansible.builtin.shell: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

The `-y` flag accepts defaults, which is the stable toolchain. Rust's release model is:
- `stable` - released every 6 weeks
- `beta` - next stable release
- `nightly` - bleeding edge

There is no LTS in Rust; `stable` is the correct choice. No changes needed.

## Recommendations

### No Code Changes Required

1. **Node.js** - Already uses LTS correctly
2. **Neovim** - Already downloads stable release
3. **Rust** - Already uses stable toolchain
4. **Python** - System Python from package managers is stable
5. **Package managers** - Homebrew/apt/pacman provide stable by default

### Documentation Only

The success criteria includes "Policy documented: LTS > stable > latest". This should be added to CLAUDE.md.

### Policy Documentation Template

```markdown
## Version Policy

Tools use the most stable available version:

1. **LTS preferred** - Use LTS when available (e.g., `nvm install --lts`)
2. **Stable fallback** - Use stable channel when no LTS (e.g., Rust, Neovim)
3. **Latest acceptable** - Use latest when no LTS/stable distinction (e.g., Pulumi)

Package managers (Homebrew, apt, pacman) provide stable versions by default.
```

## Tools Without LTS Programs

These common tools do **not** have LTS release models:

- **Go** - Supports latest two major versions, but no LTS designation
- **Rust** - Six-week release cycle with stable/beta/nightly only
- **Docker** - Follows semver, provides stable channel in repos
- **Kubernetes (kubectl)** - Supports latest 3 minor versions
- **Pulumi** - Standard semver releases
- **Starship** - Standard semver releases

## Implementation Estimate

| Task | Effort |
|------|--------|
| Verify Node.js LTS (already done) | None |
| Add policy documentation to CLAUDE.md | 5 min |
| Total | 5 min |

## Success Criteria Verification

| Criteria | Current Status | Action |
|----------|---------------|--------|
| Node.js via nvm uses `--lts` flag | Already done | None |
| Python version managers use LTS/stable | uv doesn't manage Python versions; system Python is stable | None |
| Homebrew/apt packages use defaults (stable) | Already done | None |
| Policy documented | Not yet | Add to CLAUDE.md |

## Summary for Planning

**This phase is essentially a documentation task.** The codebase already follows the LTS > stable > latest policy:

1. Node.js uses `--lts` flag
2. Rust uses stable toolchain
3. All package managers provide stable versions
4. Direct downloads (Neovim) use stable release

The only deliverable is adding the policy documentation to CLAUDE.md so future maintainers understand the version selection philosophy.

---

*Research completed: 2026-01-22*
*Phase: 08-lts-version-policy*
*Requirement: LTS-01*
