# Codebase Concerns

**Analysis Date:** 2026-01-18

## Tech Debt

**Massive Ansible-lint Violations:**

- Issue: 1135+ violations reported by ansible-lint across the codebase
- Files: All files in `tools/*/install_*.yml`
- Impact: Code quality degradation, potential deprecation issues
- Fix approach: Address violations incrementally:
  1. Use FQCN for all builtin modules (`ansible.builtin.shell` not `shell`)
  2. Replace `yes` with `true` for YAML truthy values
  3. Use `command` instead of `shell` where shell features not needed
  4. Add `pipefail` option for shell commands with pipes
  5. Replace `curl | gpg` patterns with `get_url` + `apt_key` modules

**Non-FQCN Module References:**

- Issue: All playbooks use short module names (`apt`, `pacman`, `shell`) instead of FQCN
- Files: All `tools/*/install_*.yml` playbooks (90+ files)
- Impact: Deprecation warnings, will break in Ansible-core 2.23+
- Fix approach: Replace `shell:` with `ansible.builtin.shell:`, etc.

**Deprecated Action Mapping Syntax:**

- Issue: Using mapping for `action` is deprecated
- Files: `setup.yml:48`, tasks using `module:` with `path:`
- Impact: Will break in ansible-core 2.23
- Fix approach: Use string value for `action` or switch to explicit module calls

**Shell Commands Instead of Modules:**

- Issue: 188 shell/command usages where Ansible modules exist
- Files: Throughout `tools/*/install_*.yml`
- Impact: Non-idempotent tasks, poor error handling, less portable
- Fix approach: Replace with equivalent modules:
  - `curl ... | gpg` -> `ansible.builtin.get_url` + `ansible.builtin.apt_key`
  - `brew install` -> `community.general.homebrew`

**Hardcoded NVM Version:**

- Issue: NVM version `v0.40.1` hardcoded in install script
- Files: `tools/node/install_node.yml:46`
- Impact: Version drift, manual updates needed
- Fix approach: Parameterize version or use latest tag detection

**Unused Test File:**

- Issue: Empty `test.txt` file in repository root
- Files: `/home/matt/_dotfiles/test.txt`
- Impact: Clutter, appears accidentally committed
- Fix approach: Delete file

## Known Bugs

**SSH known_hosts Creates Marker File:**

- Symptoms: Uses `.known_hosts_{{ item }}` marker files but `creates:` points to non-marker file
- Files: `tools/ssh/install_ssh.yml:56-64`
- Trigger: Running SSH install task
- Workaround: Works, but creates unnecessary marker files

**Homebrew Path Assumptions:**

- Symptoms: Assumes `/opt/homebrew/bin/brew` exists on all macOS
- Files: Multiple playbooks including `setup.yml:14`, `tools/node/install_node.yml:9`
- Trigger: Running on Intel Mac (uses `/usr/local/bin/brew`)
- Workaround: Only affects older Intel Macs

## Security Considerations

**Piped Curl Commands:**

- Risk: 18+ instances of `curl | bash` or `curl | sh` patterns download and execute remote code
- Files:
  - `tools/rust/install_rust.yml:8`
  - `tools/node/install_node.yml:46`
  - `tools/pulumi/install_pulumi.yml:14`
  - `tools/starship/install_starship.yml:20`
  - `tools/python/install_python.yml:14`
  - `bootstrap.sh` (documented bootstrap pattern)
- Current mitigation: Uses HTTPS, trusted sources
- Recommendations:
  1. Pin to specific versions where possible
  2. Verify checksums after download
  3. Consider using package managers where available

**GPG Key Downloads Without Verification:**

- Risk: GPG keys downloaded via curl without fingerprint verification
- Files:
  - `tools/docker/install_docker.yml:42`
  - `tools/1password/install_1password.yml:21`
  - `tools/gh/install_gh.yml:21`
  - `tools/edge/install_edge.yml:21`
  - `tools/brave/install_brave.yml`
- Current mitigation: Uses HTTPS from official sources
- Recommendations: Add fingerprint verification for GPG keys

**1Password Token Storage:**

- Risk: Service account token stored in plaintext file
- Files: `~/.config/op/service-account-token` (created by `bootstrap.sh:62`)
- Current mitigation: File permissions set to 600, directory to 700
- Recommendations: Consider using encrypted storage or environment-only token

**Secrets in Ansible Variables:**

- Risk: Sensitive variables passed through Ansible (SSH keys, signing keys)
- Files: `tools/ssh/install_ssh.yml:92-110`
- Current mitigation: Uses `no_log: true` on sensitive tasks
- Recommendations: Ensure all sensitive tasks have `no_log: true`

## Performance Bottlenecks

**Serial Package Cache Updates:**

- Problem: Each OS-specific update runs separately in setup.yml
- Files: `setup.yml:9-31`
- Cause: `apt update`, `pacman -Sy`, `brew update` run at start
- Improvement path: Already optimized; runs once per OS family

**Many Sequential Playbook Imports:**

- Problem: 80+ sequential `import_playbook` statements
- Files: `setup.yml:32-182`
- Cause: Each tool has separate playbook
- Improvement path: Could group related tools, but current approach aids maintainability

## Fragile Areas

**GPU Driver Detection:**

- Files: `tools/gpu/install_gpu.yml:18-31`
- Why fragile: Relies on `lspci` string matching for GPU detection
- Safe modification: Test on multiple GPU configurations
- Test coverage: None - manual testing only

**Bootstrap Script Group Selection:**

- Files: `bootstrap.sh:30-33`
- Why fragile: User input validation is minimal, typos silently skip groups
- Safe modification: Add input validation, show selected groups for confirmation
- Test coverage: None

**1Password Integration:**

- Files: `tools/ssh/install_ssh.yml:77-116`, `bootstrap.sh:37-78`
- Why fragile: Depends on 1Password CLI availability, token validity, and secret paths
- Safe modification: Test with and without 1Password configured
- Test coverage: None

**SOPS/Age Encryption:**

- Files: `group_vars/all/personal-info.sops.yml`, `bootstrap.sh:80-145`
- Why fragile: Requires Age key to decrypt; bootstrap has fallback but not all paths tested
- Safe modification: Test all three bootstrap options (paste, path, generate)
- Test coverage: None

## Scaling Limits

**Homebrew Cask Installation Pattern:**

- Current capacity: Works for single-user machines
- Limit: Homebrew not designed for multi-user or headless servers
- Scaling path: Not applicable; dotfiles target personal workstations

**Remote Host Configuration:**

- Current capacity: 4 hosts in inventory
- Limit: SSH timeout (60s) may be insufficient for slow connections
- Scaling path: Increase timeout, add connection pooling in `ansible.cfg`

## Dependencies at Risk

**Python 3.14 Compatibility:**

- Risk: Ansible running on Python 3.14 shows deprecation warnings for `ansible.module_utils._text`
- Impact: Will break in ansible-core 2.24
- Migration plan: Update when Ansible releases fix, no user action needed

**AUR Packages (yay):**

- Risk: AUR packages may become unmaintained
- Impact: Arch installations could fail for specific tools
- Migration plan: Monitor for official package availability, have fallback install methods

**External Install Scripts:**

- Risk: Third-party install scripts (`rustup.rs`, `nvm`, `starship`, `pulumi`, `uv`) could change
- Impact: Installations may fail if script URLs or behavior change
- Migration plan: Pin to specific versions, verify checksums

## Missing Critical Features

**No Automated Testing:**

- Problem: No test framework for playbooks
- Blocks: Cannot validate changes without manual testing on each OS
- Recommendation: Add Molecule tests for critical playbooks

**No Rollback Mechanism:**

- Problem: No way to undo failed partial installations
- Blocks: Recovery from failed runs requires manual cleanup
- Recommendation: Document recovery procedures per tool

**No Version Pinning for Most Tools:**

- Problem: Most tools install "latest" without version constraints
- Blocks: Reproducible environments across machines
- Recommendation: Add version variables where stability matters

## Test Coverage Gaps

**Zero Automated Tests:**

- What's not tested: All 90+ playbooks
- Files: All `tools/*/install_*.yml`
- Risk: Breaking changes go undetected until manual run
- Priority: High - consider Molecule for critical paths

**Bootstrap Script Untested:**

- What's not tested: OS detection, user input handling, error paths
- Files: `bootstrap.sh`
- Risk: First-run experience could fail silently
- Priority: Medium - add shellcheck, consider BATS tests

**Multi-OS Compatibility:**

- What's not tested: Cross-platform behavior of conditional tasks
- Files: All playbooks with `when: ansible_facts['os_family'] == "X"`
- Risk: Changes may work on one OS but break another
- Priority: High - need CI matrix testing

---

_Concerns audit: 2026-01-18_
