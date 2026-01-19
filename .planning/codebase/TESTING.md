# Testing Patterns

**Analysis Date:** 2026-01-19

## Test Framework

**Runner:** None (no automated test suite)

**Validation Approach:**
- Manual testing via Ansible dry-run (check mode)
- Linting tools for static analysis
- Manual deployment to test machines

**Run Commands:**
```bash
# Dry-run (check mode) - preview changes without applying
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff

# Lint Ansible playbooks
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml

# Lint Lua code (neovim config)
stylua --check tools/neovim/nvim/
```

## Test File Organization

**Location:** No dedicated test files or directories

**Validation Files:**
- Neovim health check: `tools/neovim/nvim/lua/kickstart/health.lua`
- GitHub Actions workflow (upstream kickstart): `tools/neovim/nvim/.github/workflows/stylua.yml`

## Validation Strategy

**Ansible Check Mode:**
```bash
# Preview all changes for local machine
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff

# Preview specific tool
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s) --check --diff
```

**What Check Mode Validates:**
- File creation/modification (shows diff)
- Package installation (shows what would be installed)
- Template rendering (shows resulting content)

**What Check Mode Cannot Validate:**
- Shell commands (marked as changed but not executed)
- Commands with `creates:` (may show false positives)
- Service state after changes

## Linting

**Ansible Lint:**
```bash
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml
```

**StyLua (Lua):**
```bash
# Check formatting
stylua --check tools/neovim/nvim/

# Auto-fix formatting
stylua tools/neovim/nvim/
```

Config: `tools/neovim/nvim/.stylua.toml`

**ShellCheck (Shell):**
```bash
# Manual invocation (no CI integration)
shellcheck bootstrap.sh setup-all.sh
```

## Mocking

**Framework:** Not applicable

**Patterns:** Not applicable

**What to Mock:** Not applicable (infrastructure automation)

**What NOT to Mock:** Not applicable

## Fixtures and Factories

**Test Data:** Not applicable

**Location:** Not applicable

## Coverage

**Requirements:** None enforced

**View Coverage:** Not applicable

## Test Types

**Unit Tests:** None

**Integration Tests:** None (manual validation only)

**E2E Tests:** None

**Manual Validation Process:**
1. Run check mode to preview changes
2. Apply to test machine first (e.g., `miniserver` for headless, `desktop` for GUI)
3. Verify functionality manually
4. Apply to remaining machines

## Common Patterns

**Validating Playbook Syntax:**
```bash
# Syntax check only
ansible-playbook setup.yml --syntax-check
```

**Validating Specific Host:**
```bash
# Target specific host
ansible-playbook setup.yml --limit desktop --check --diff
```

**Validating Host Groups:**
```bash
# All macOS hosts
ansible-playbook setup.yml --limit macs --check --diff

# All hosts with GUI tools
ansible-playbook setup.yml --limit with_gui_tools --check --diff
```

**Testing Idempotency:**
Run playbook twice; second run should show no changes:
```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
# Re-run - should show "changed=0" for all tasks
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
```

## Health Checks

**Neovim:**
```vim
:checkhealth
```
Uses: `tools/neovim/nvim/lua/kickstart/health.lua`

**Ansible:**
```bash
# Verify inventory
ansible-inventory --list

# Ping all hosts
ansible all -m ping
```

## CI/CD Status

**This Repository:** No CI/CD pipeline configured

**Upstream (Kickstart.nvim):**
- GitHub Actions workflow for StyLua checks
- File: `tools/neovim/nvim/.github/workflows/stylua.yml`
- Triggered on pull requests

## Recommended Testing Workflow

**Before Committing:**
1. Run `ansible-lint` on modified playbooks
2. Run `stylua --check` on modified Lua files
3. Run check mode on local machine

**Before Deploying:**
1. Test on least critical machine first
2. Verify idempotency (run twice)
3. Check application functionality manually

**New Tool Playbook:**
1. Create `tools/<tool>/install_<tool>.yml`
2. Run `ansible-lint` on the new file
3. Test with check mode
4. Apply to local machine
5. Verify installation manually
6. Test on other OS variants if cross-platform

---

*Testing analysis: 2026-01-19*
