# Testing Documentation

This document describes the comprehensive testing framework for the dotfiles Ansible repository.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Test Categories](#test-categories)
- [CI/CD Integration](#cicd-integration)
- [Manual Testing](#manual-testing)
- [Troubleshooting](#troubleshooting)

## Overview

The testing framework validates dotfiles configuration across multiple operating systems and ensures idempotency, correctness, and reliability of Ansible playbooks.

### Test Goals

✅ **Syntax Validation**: Ensure all Ansible playbooks are syntactically correct
✅ **Idempotency**: Verify playbooks can run multiple times without changes
✅ **Functionality**: Confirm all software is installed and configured correctly
✅ **Cross-Platform**: Test on Debian, Ubuntu, macOS, and Arch Linux
✅ **CI/CD**: Automated testing on every commit and pull request

## Test Structure

```
tests/
├── syntax/
│   └── validate_ansible.sh       # Ansible syntax checking
├── idempotency/
│   └── test_idempotency.sh       # Idempotency validation
├── functional/
│   └── test_installations.sh     # Software installation tests
├── os-specific/
│   ├── test_debian.sh            # Debian/Ubuntu tests
│   ├── test_macos.sh             # macOS tests
│   └── test_arch.sh              # Arch Linux tests
└── integration/
    └── test_full_setup.sh        # End-to-end integration tests
```

## Running Tests

### Prerequisites

```bash
# Install Ansible
pip install ansible ansible-lint

# Make test scripts executable
chmod +x tests/**/*.sh
```

### Individual Test Suites

#### 1. Syntax Validation

```bash
# Validate Ansible syntax and lint all playbooks
./tests/syntax/validate_ansible.sh
```

**What it checks:**
- YAML syntax correctness
- Ansible playbook structure
- Best practices (via ansible-lint)
- Task naming conventions

#### 2. Idempotency Tests

```bash
# Run playbook twice and verify no changes on second run
./tests/idempotency/test_idempotency.sh

# Test actual execution (modifies system)
ANSIBLE_TEST_ACTUAL=true ./tests/idempotency/test_idempotency.sh
```

**What it checks:**
- Playbook produces same result when run twice
- No unnecessary changes on subsequent runs
- Tasks are properly idempotent

#### 3. Functional Tests

```bash
# Test installed software and configurations
./tests/functional/test_installations.sh
```

**What it checks:**
- ✅ Zsh installed and set as default shell
- ✅ Tmux installed with configuration
- ✅ Neovim installed with plugins
- ✅ Git configured with user settings
- ✅ Configuration files in correct locations
- ✅ File permissions are correct

#### 4. OS-Specific Tests

```bash
# Debian/Ubuntu
./tests/os-specific/test_debian.sh

# macOS
./tests/os-specific/test_macos.sh

# Arch Linux
./tests/os-specific/test_arch.sh
```

**What they check:**
- Package manager functionality (apt/brew/pacman)
- OS-specific package installations
- Repository configurations
- User shell settings
- System-specific features

#### 5. Integration Tests

```bash
# Run complete end-to-end test suite
./tests/integration/test_full_setup.sh
```

**Test phases:**
1. Pre-flight checks (prerequisites)
2. Syntax validation
3. Dry run (check mode)
4. Component tests
5. OS-specific tests
6. Configuration validation
7. Idempotency verification

### Quick Test Commands

```bash
# Run all syntax tests
make test-syntax  # (if Makefile exists)

# Run all tests for current OS
make test-all

# Run only functional tests
make test-functional
```

## Test Categories

### 1. Syntax Tests (`tests/syntax/`)

**Purpose**: Validate Ansible code quality before execution

**Tools Used**:
- `ansible-playbook --syntax-check`
- `ansible-lint` (optional but recommended)

**Exit Codes**:
- `0`: All syntax checks passed
- `1`: Syntax errors found

### 2. Idempotency Tests (`tests/idempotency/`)

**Purpose**: Ensure playbooks don't make unnecessary changes

**Process**:
1. Run playbook in check mode (first run)
2. Run playbook in check mode again (second run)
3. Compare results - second run should show 0 changes

**Environment Variables**:
- `ANSIBLE_TEST_ACTUAL=true`: Run actual execution (not just check mode)

### 3. Functional Tests (`tests/functional/`)

**Purpose**: Verify installed software and configurations work correctly

**Test Coverage**:
- Software installation (zsh, tmux, neovim, git)
- Configuration files (`.zshrc`, `.tmux.conf`, nvim config)
- File permissions and ownership
- Plugin managers (Oh My Zsh, TPM, nvim plugins)
- Shell functionality

### 4. OS-Specific Tests (`tests/os-specific/`)

#### Debian/Ubuntu Tests
- APT package manager checks
- Universe repository enabled
- Required packages installed
- User sudo access

#### macOS Tests
- Homebrew installation and health
- Formula installations
- Cask functionality
- Xcode Command Line Tools
- macOS-specific utilities (pbcopy, pbpaste)

#### Arch Linux Tests
- Pacman functionality
- AUR helper (yay/paru) presence
- Base-devel group installation
- System update status
- Parallel downloads configuration

### 5. Integration Tests (`tests/integration/`)

**Purpose**: End-to-end validation of complete setup

**Phases**:
1. ✅ Prerequisites check
2. ✅ Syntax validation
3. ✅ Dry run execution
4. ✅ Component testing
5. ✅ OS-specific validation
6. ✅ Configuration verification
7. ✅ Idempotency confirmation

## CI/CD Integration

### GitHub Actions Workflow

The repository includes automated testing via GitHub Actions (`.github/workflows/ci.yml`).

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests
- Weekly scheduled runs (Mondays at 00:00 UTC)
- Manual workflow dispatch

**Test Matrix**:
- **Ubuntu**: 20.04, 22.04, 24.04
- **Debian**: 11, 12
- **macOS**: latest

**Jobs**:
1. **syntax-validation**: Runs on all commits
2. **debian-tests**: Tests Debian 11 & 12
3. **ubuntu-tests**: Tests Ubuntu 20.04, 22.04, 24.04
4. **macos-tests**: Tests macOS latest
5. **idempotency-tests**: Validates idempotency
6. **integration-tests**: Full end-to-end testing
7. **test-results**: Publishes summary

### Viewing Results

```bash
# In GitHub Actions tab:
# - Green check: All tests passed
# - Red X: Tests failed
# - Yellow circle: Tests running

# Download test artifacts for detailed logs
```

## Manual Testing Checklist

Use this checklist for manual validation after playbook execution.

### Pre-Installation

- [ ] System meets minimum requirements
- [ ] User has sudo/admin access
- [ ] Internet connection available
- [ ] Git is installed

### Post-Installation

#### Shell (Zsh)
- [ ] Zsh is installed: `zsh --version`
- [ ] Zsh is default shell: `echo $SHELL`
- [ ] `.zshrc` exists and is sourced
- [ ] Custom prompt appears
- [ ] Aliases work correctly
- [ ] Oh My Zsh installed (if applicable)

#### Terminal Multiplexer (Tmux)
- [ ] Tmux is installed: `tmux -V`
- [ ] `.tmux.conf` exists
- [ ] Can start tmux session: `tmux new -s test`
- [ ] Custom keybindings work
- [ ] Status bar configured
- [ ] Tmux Plugin Manager installed (if applicable)

#### Editor (Neovim)
- [ ] Neovim is installed: `nvim --version`
- [ ] Config directory exists: `~/.config/nvim/`
- [ ] Can start nvim: `nvim`
- [ ] Plugins are loaded
- [ ] LSP works (if configured)
- [ ] Color scheme applied

#### Version Control (Git)
- [ ] Git is installed: `git --version`
- [ ] `.gitconfig` exists
- [ ] User name configured: `git config user.name`
- [ ] User email configured: `git config user.email`
- [ ] Git aliases work

#### General Configuration
- [ ] All dotfiles are symlinked/copied correctly
- [ ] File permissions are correct
- [ ] No broken symlinks
- [ ] Backup of old configs created (if applicable)

### Functional Tests

#### Zsh Testing
```bash
# Test command execution
echo "Hello from Zsh"

# Test aliases
alias  # Should show custom aliases

# Test functions
# Run any custom functions defined in .zshrc
```

#### Tmux Testing
```bash
# Start new session
tmux new -s test

# Test prefix key (usually Ctrl+b or custom)
# Create new window: prefix + c
# Split pane: prefix + %
# Detach: prefix + d

# List sessions
tmux ls
```

#### Neovim Testing
```bash
# Open neovim
nvim test.txt

# Check plugin status
:checkhealth

# Test LSP (if configured)
:LspInfo

# Test plugin manager
:PluginStatus  # Or equivalent for your plugin manager
```

## Troubleshooting

### Common Issues

#### 1. Syntax Validation Fails

**Error**: `ERROR! Syntax Error while loading YAML`

**Solution**:
```bash
# Check YAML syntax
yamllint playbook.yml

# Validate specific playbook
ansible-playbook --syntax-check playbook.yml
```

#### 2. Idempotency Test Fails

**Error**: Second run shows changes

**Solution**:
- Check for tasks using `shell` or `command` modules without proper `changed_when`
- Ensure file permissions/modes are explicitly set
- Use `creates` or `removes` parameters for file operations

#### 3. Functional Tests Fail

**Error**: Software not found after installation

**Solution**:
```bash
# Verify package installation
dpkg -l package_name  # Debian/Ubuntu
brew list package_name  # macOS
pacman -Q package_name  # Arch

# Check PATH
echo $PATH

# Reload shell
exec $SHELL
```

#### 4. Permission Errors

**Error**: Permission denied during tests

**Solution**:
```bash
# Make scripts executable
chmod +x tests/**/*.sh

# Check file ownership
ls -la ~/.config/

# Fix ownership if needed
sudo chown -R $USER:$USER ~/.config/
```

### Getting Help

1. **Check logs**: Review test output in `/tmp/ansible-*-tests/`
2. **Verbose mode**: Run ansible with `-vvv` for detailed output
3. **Debug mode**: Add `--step` flag to run playbook interactively
4. **CI logs**: Download artifacts from GitHub Actions for detailed logs

### Test Coverage Report

Generate test coverage report:

```bash
# Run all tests and generate report
./tests/integration/test_full_setup.sh > test_report.txt 2>&1

# View summary
cat test_report.txt | grep -E "✓|✗|PASS|FAIL"
```

## Best Practices

1. **Run tests locally** before pushing to repository
2. **Test on clean system** or use containers/VMs
3. **Keep tests up-to-date** with playbook changes
4. **Document test failures** in issues
5. **Use test-driven development** when possible
6. **Maintain test independence** - tests should not depend on each other
7. **Clean up test artifacts** after runs
8. **Version control test logs** for critical failures

## Contributing to Tests

When adding new features to playbooks:

1. Add corresponding test cases
2. Update this documentation
3. Ensure all existing tests still pass
4. Add OS-specific tests if needed
5. Update CI/CD workflow if necessary

---

**Last Updated**: 2025-10-01
**Maintained By**: Dotfiles Testing Team
