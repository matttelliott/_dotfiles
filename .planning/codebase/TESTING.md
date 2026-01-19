# Testing Patterns

**Analysis Date:** 2026-01-18

## Test Framework

**Current State:**
- No automated test framework configured
- No unit tests, integration tests, or E2E tests present
- Manual testing via Ansible check mode (dry-run)

**Validation Tools:**
- `ansible-lint` - Static analysis for Ansible playbooks
- `shellcheck` - Static analysis for shell scripts (referenced in CLAUDE.md)
- No TypeScript/JavaScript test runner for infrastructure code

**Run Commands:**
```bash
# Dry-run (check mode) - preview changes without applying
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff

# Lint all playbooks
ansible-lint setup.yml
ansible-lint tools/*/install_*.yml
```

## Test File Organization

**Location:**
- No dedicated test directories
- No `tests/`, `spec/`, or `__tests__/` directories
- No `*.test.*` or `*.spec.*` files

**Recommended Structure (if adding tests):**
```
_dotfiles/
├── tests/
│   ├── molecule/           # Ansible molecule tests
│   │   ├── default/
│   │   │   ├── molecule.yml
│   │   │   ├── converge.yml
│   │   │   └── verify.yml
│   └── infrastructure/     # Pulumi tests (if needed)
└── tools/
    └── <tool>/
        └── molecule/       # Per-tool molecule tests
```

## Manual Testing Strategy

**Ansible Check Mode:**
```bash
# Preview all changes
ansible-playbook setup.yml --connection=local --limit $(hostname -s) --check --diff

# Test single tool
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s) --check --diff
```

**Check mode shows:**
- What tasks would run
- What files would change (with `--diff`)
- Any syntax or variable errors

**Limitations:**
- Some shell tasks cannot be checked (no `creates:` prediction)
- External API calls still execute in some modules
- Does not verify actual functionality

## Linting

**Ansible Lint:**
```bash
# Lint main playbook
ansible-lint setup.yml

# Lint all tool playbooks
ansible-lint tools/*/install_*.yml

# Lint specific file
ansible-lint tools/git/install_git.yml
```

**Common rules enforced:**
- Tasks must have names
- Use FQCN for modules (e.g., `ansible.builtin.copy`)
- Avoid deprecated modules
- Idempotency requirements

**Shell Lint:**
```bash
# Check shell scripts
shellcheck bootstrap.sh
shellcheck setup-all.sh
```

## Mocking

**Framework:** None implemented

**What would need mocking for tests:**
- 1Password CLI responses
- Package manager operations
- Network requests (curl, git clone)
- File system state

**Ansible Molecule approach (recommended):**
```yaml
# molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: debian-test
    image: debian:12
  - name: arch-test
    image: archlinux:latest
provisioner:
  name: ansible
verifier:
  name: ansible
```

## Fixtures and Factories

**Test Data:**
- No test fixtures defined
- Production secrets in `group_vars/all/personal-info.sops.yml`
- Would need test-specific vars files for CI

**Example test vars file:**
```yaml
# tests/vars/test-vars.yml
git_user_name: "Test User"
git_user_email: "test@example.com"
git_signing_key: ""
ssh_public_key: "ssh-rsa AAAA... test@test"
ssh_default_user: "testuser"
github_username: "testuser"
```

## Coverage

**Requirements:** None enforced

**Current gaps:**
- No coverage metrics
- No CI/CD pipeline to enforce coverage
- All testing is manual

**What would be measured:**
- Percentage of tools with molecule tests
- OS variants covered (macOS, Debian, Arch)
- Host group coverage (with_login_tools, with_gui_tools, etc.)

## Test Types

**Unit Tests:**
- Not implemented
- Would test individual playbooks in isolation
- Use molecule with single-tool converge

**Integration Tests:**
- Not implemented
- Would test full `setup.yml` on clean systems
- Requires VM or container environment

**E2E Tests:**
- Not implemented
- Would verify tools work after installation
- Example: Run `nvim --version`, `docker --version`, etc.

**Smoke Tests (manual):**
```bash
# After running playbook, verify key tools
nvim --version
git --version
tmux -V
starship --version
```

## Common Patterns

**Idempotency Testing:**
```bash
# Run twice - second run should show no changes
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
ansible-playbook setup.yml --connection=local --limit $(hostname -s)
# Expect: "changed=0" on second run
```

**Cross-Platform Testing (manual):**
```bash
# Test on each platform
# macOS
ansible-playbook setup.yml --connection=local --limit macbookair

# Debian (remote)
ansible-playbook setup.yml --limit miniserver

# Arch (remote)
ansible-playbook setup.yml --limit desktop
```

**Template Verification:**
```bash
# Check template renders correctly
ansible-playbook tools/git/install_git.yml --check --diff
# Review diff output for template files
```

## Recommended Testing Improvements

**1. Add Ansible Molecule:**
```bash
pip install molecule molecule-plugins[docker]
cd tools/git
molecule init scenario
```

**2. Add CI Pipeline:**
```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ansible-lint
        run: |
          pip install ansible-lint
          ansible-lint setup.yml
```

**3. Add Per-Tool Verification:**
```yaml
# tools/git/molecule/default/verify.yml
- name: Verify git installation
  hosts: all
  tasks:
    - name: Check git is installed
      command: git --version
      register: git_version
      changed_when: false

    - name: Verify git version
      assert:
        that:
          - git_version.rc == 0
```

## Infrastructure Testing (Pulumi)

**Current State:**
- No tests for `infrastructure/index.ts`
- Pulumi has built-in preview functionality

**Preview Changes:**
```bash
cd infrastructure
pulumi preview
```

**Recommended: Add Pulumi Tests:**
```typescript
// infrastructure/index.test.ts
import * as pulumi from "@pulumi/pulumi";
import * as testing from "@pulumi/pulumi/testing";

describe("Infrastructure", () => {
  it("should create a droplet", async () => {
    // Unit test for droplet configuration
  });
});
```

## Project Rules for Testing

From `.claude/rules/tests.md`:
- Focus on test coverage and edge cases
- Use project's existing test patterns
- Mock external dependencies
- For Ansible, consider using molecule for testing playbooks

---

*Testing analysis: 2026-01-18*
