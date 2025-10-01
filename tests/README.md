# Dotfiles Testing Suite

Comprehensive testing framework for validating Ansible dotfiles configuration across multiple operating systems.

## Quick Start

```bash
# Run all tests
./tests/integration/test_full_setup.sh

# Run specific test category
./tests/syntax/validate_ansible.sh       # Syntax only
./tests/idempotency/test_idempotency.sh  # Idempotency only
./tests/functional/test_installations.sh # Functional only
```

## Test Categories

| Category | Script | Purpose |
|----------|--------|---------|
| **Syntax** | `syntax/validate_ansible.sh` | Validate Ansible YAML syntax and lint |
| **Idempotency** | `idempotency/test_idempotency.sh` | Ensure playbooks are idempotent |
| **Functional** | `functional/test_installations.sh` | Test installed software and configs |
| **OS-Specific** | `os-specific/test_{debian,macos,arch}.sh` | Platform-specific validation |
| **Integration** | `integration/test_full_setup.sh` | End-to-end testing |

## Prerequisites

```bash
# Install required tools
pip install ansible ansible-lint

# Make scripts executable
chmod +x tests/**/*.sh
```

## Running Tests

### Locally

```bash
# Syntax validation
./tests/syntax/validate_ansible.sh

# Idempotency (check mode - safe)
./tests/idempotency/test_idempotency.sh

# Idempotency (actual execution - CAUTION)
ANSIBLE_TEST_ACTUAL=true ./tests/idempotency/test_idempotency.sh

# Functional tests
./tests/functional/test_installations.sh

# OS-specific (auto-detects OS)
./tests/os-specific/test_debian.sh   # On Debian/Ubuntu
./tests/os-specific/test_macos.sh    # On macOS
./tests/os-specific/test_arch.sh     # On Arch Linux

# Full integration suite
./tests/integration/test_full_setup.sh
```

### Via GitHub Actions

Tests run automatically on:
- Push to `main` or `develop`
- Pull requests
- Weekly schedule (Mondays)
- Manual trigger

**Test Matrix**:
- Ubuntu: 20.04, 22.04, 24.04
- Debian: 11, 12
- macOS: latest

## Test Structure

```
tests/
├── README.md                          # This file
├── syntax/
│   └── validate_ansible.sh            # Ansible syntax validation
├── idempotency/
│   └── test_idempotency.sh            # Idempotency testing
├── functional/
│   └── test_installations.sh          # Software installation tests
├── os-specific/
│   ├── test_debian.sh                 # Debian/Ubuntu specific
│   ├── test_macos.sh                  # macOS specific
│   └── test_arch.sh                   # Arch Linux specific
└── integration/
    └── test_full_setup.sh             # End-to-end integration
```

## What Each Test Validates

### Syntax Tests
✅ YAML syntax correctness
✅ Ansible playbook structure
✅ Best practices (via ansible-lint)
✅ Task naming conventions

### Idempotency Tests
✅ Playbook runs without changes on second execution
✅ Tasks are properly idempotent
✅ No unnecessary file modifications

### Functional Tests
✅ Zsh installed and set as default shell
✅ Tmux installed with configuration
✅ Neovim installed with plugins
✅ Git configured properly
✅ Config files in correct locations
✅ Permissions are correct

### OS-Specific Tests

**Debian/Ubuntu**:
✅ APT package manager working
✅ Required repositories enabled
✅ Packages installed via apt

**macOS**:
✅ Homebrew installed and healthy
✅ Formulas installed
✅ Xcode Command Line Tools present

**Arch Linux**:
✅ Pacman working correctly
✅ AUR helper present (yay/paru)
✅ Base-devel group installed

### Integration Tests
✅ Complete setup from start to finish
✅ All components working together
✅ Configuration properly applied

## Exit Codes

- `0`: All tests passed ✅
- `1`: Tests failed ❌

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `ANSIBLE_TEST_ACTUAL` | Run actual execution (not check mode) | `true` |

## Test Logs

Test logs are stored in:
- `/tmp/ansible-syntax-*.log` - Syntax validation
- `/tmp/ansible-idempotency-tests/` - Idempotency runs

## Troubleshooting

### Tests fail locally but pass in CI

**Cause**: Different OS or package versions

**Solution**:
```bash
# Run in container matching CI environment
docker run -it ubuntu:22.04 bash
```

### Idempotency test shows changes

**Cause**: Tasks not properly idempotent

**Solution**: Check for:
- `shell`/`command` without `creates` or `changed_when`
- File modes not explicitly set
- Conditional logic issues

### Permission denied errors

**Solution**:
```bash
chmod +x tests/**/*.sh
```

## Contributing

When adding new features:
1. Add corresponding tests
2. Update this README
3. Ensure all tests pass locally
4. Update CI workflow if needed

## Documentation

See `docs/testing.md` for comprehensive testing documentation.

## Support

- Report issues: [GitHub Issues]
- CI/CD status: [GitHub Actions tab]
- Detailed docs: `docs/testing.md`

---

**Note**: Always run tests in a safe environment (VM, container, or test system) before running on production machines.
