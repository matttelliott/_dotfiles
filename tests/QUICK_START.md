# Testing Quick Start Guide

## 🚀 Run All Tests (Recommended)

```bash
./tests/integration/test_full_setup.sh
```

## 📋 Run Individual Test Categories

### 1. Syntax Validation (Always Run First)
```bash
./tests/syntax/validate_ansible.sh
```
✅ Fast, safe, checks YAML syntax and best practices

### 2. Idempotency (Check Mode - Safe)
```bash
./tests/idempotency/test_idempotency.sh
```
✅ Verifies playbook won't make changes on second run

### 3. Functional Tests
```bash
./tests/functional/test_installations.sh
```
✅ Validates installed software and configurations

### 4. OS-Specific Tests (Auto-detects)
```bash
# Runs automatically for your OS
./tests/os-specific/test_debian.sh   # Debian/Ubuntu
./tests/os-specific/test_macos.sh    # macOS
./tests/os-specific/test_arch.sh     # Arch Linux
```
✅ Platform-specific package manager checks

## ⚠️ Actual Execution Tests (CAUTION)

```bash
# This WILL modify your system
ANSIBLE_TEST_ACTUAL=true ./tests/idempotency/test_idempotency.sh
```

## 📊 Test Results

Results are stored in:
- `/tmp/ansible-syntax-*.log`
- `/tmp/ansible-idempotency-tests/`

## 🔧 Prerequisites

```bash
# Install required tools
pip install ansible ansible-lint

# Verify installation
ansible --version
ansible-lint --version
```

## 📖 Full Documentation

See `docs/testing.md` for comprehensive testing documentation.

## 🐛 Troubleshooting

### Permission Denied
```bash
chmod +x tests/**/*.sh
```

### Tests Not Found
```bash
# Run from repository root
cd /home/developer/dotfiles-ansible
./tests/integration/test_full_setup.sh
```

### Ansible Not Found
```bash
pip install --user ansible
# or
sudo apt install ansible  # Debian/Ubuntu
brew install ansible      # macOS
sudo pacman -S ansible    # Arch Linux
```

## 🎯 Quick Test Status Check

```bash
# One-liner to run all safe tests
./tests/syntax/validate_ansible.sh && \
./tests/idempotency/test_idempotency.sh && \
./tests/functional/test_installations.sh
```

## 💡 Tips

- ✅ Always run syntax validation first
- ✅ Use check mode for safe testing
- ✅ Run in VMs/containers for actual execution tests
- ✅ Check CI/CD status in GitHub Actions tab
- ✅ Review logs in `/tmp/` for detailed errors

---

**Need Help?** See `tests/README.md` or `docs/testing.md`
