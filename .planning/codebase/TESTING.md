# Testing Patterns

**Analysis Date:** 2026-01-19

## Test Framework

**Runner:** None

This codebase has **no automated test framework**. Testing is performed manually via:

1. Ansible check mode (dry-run)
2. ansible-lint for validation
3. Manual execution on target machines

## Validation Commands

**Dry-run (Check Mode):**
```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff
```

**Lint Playbooks:**
```bash
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml
```

**Lua Formatting Check:**
```bash
stylua --check tools/neovim/nvim/
```

**Shell Script Validation:**
```bash
shellcheck bootstrap.sh setup-all.sh
```

## Manual Testing Patterns

**Single Tool Testing:**
```bash
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
```

**Full Setup Testing:**
```bash
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
```

**Remote Testing:**
```bash
ansible-playbook setup.yml --limit macbookair
```

## Idempotency Testing

**Pattern:** Run playbook twice, expect no changes on second run.

**Verification:**
```bash
# First run - expect changes
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)

# Second run - expect "ok" with no "changed"
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
```

**Idempotency Mechanisms:**
- `creates:` argument for shell commands
- `state: present` for package managers
- `stat` + `when` for conditional execution

## Theme Testing

**Color Theme Application:**
```bash
ansible-playbook themes/_color.yml -i "localhost," --connection=local -e "color=nord"
```

**Style Theme Application:**
```bash
ansible-playbook themes/_style.yml -i "localhost," --connection=local -e "style=angle"
```

**Verification:** Visual inspection of:
- tmux status bar
- starship prompt
- neovim colorscheme
- fzf colors
- lazygit colors

## Cross-Platform Testing

**Target Platforms:**
| Platform | Test Host |
|----------|-----------|
| macOS | macbookair, macmini |
| Debian | miniserver |
| Arch Linux | desktop |

**Platform-specific validation:**
```bash
# Test macOS-only tasks
ansible-playbook setup.yml --limit macs --check

# Test Linux-only tasks
ansible-playbook setup.yml --limit 'debian:arch' --check
```

## Neovim Health Checks

**Built-in health check:**
```vim
:checkhealth
```

**LSP verification:**
```vim
:LspInfo
:Mason
```

**Plugin status:**
```vim
:Lazy
```

## Infrastructure Testing

**Pulumi Preview:**
```bash
cd infrastructure
pulumi preview
```

**Pulumi Deployment:**
```bash
pulumi up
```

## Coverage Gaps

**Not Tested:**
- Shell function behavior (zshrc functions)
- Complex conditionals in playbooks
- Template rendering edge cases
- Theme color accuracy

**Partially Tested:**
- Idempotency (manual verification)
- Cross-platform compatibility (per-platform manual runs)

## Test Data

**Test Fixtures:** None

**Test Variables:**
- Defaults in `group_vars/all/defaults.yml`
- Can override with `-e` flag: `-e "git_user_name=Test"`

## Recommended Testing Workflow

1. **Before changes:** Run `ansible-lint` on modified files
2. **Dry-run:** Use `--check --diff` to preview changes
3. **Local test:** Apply to local machine first
4. **Remote test:** Apply to remote hosts after local verification
5. **Idempotency check:** Run twice to verify no unintended changes

## CI/CD

**GitHub Actions:** `tools/neovim/nvim/.github/workflows/stylua.yml`
- Runs StyLua format check on neovim config
- Not a comprehensive CI pipeline

**No automated testing pipeline** for:
- Playbook execution
- Cross-platform validation
- Integration testing

---

*Testing analysis: 2026-01-19*
