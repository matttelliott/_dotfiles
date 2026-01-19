# Codebase Concerns

**Analysis Date:** 2026-01-19

## Tech Debt

**Hardcoded Version Numbers in Install Scripts:**
- Issue: Multiple playbooks have pinned versions that will become outdated
- Files:
  - `tools/node/install_node.yml:46` - nvm v0.40.1
  - `tools/procs/install_procs.yml:17` - procs v0.14.8
  - `tools/obsidian/install_obsidian.yml:15` - Obsidian v1.5.12
  - `tools/sops/install_sops.yml:17` - sops v3.9.4
- Impact: Tools don't get security/feature updates; requires manual version bumps
- Fix approach: Use GitHub API to fetch latest release, or use `@latest` where supported

**Inconsistent Boolean Style (become: yes vs become: true):**
- Issue: All 218 occurrences use `become: yes`, none use `become: true`
- Files: All 93 playbooks in `tools/*/install_*.yml`
- Impact: Not broken, but inconsistent with YAML 1.2 spec which prefers `true/false`
- Fix approach: Standardize using ansible-lint rule and mass replace

**Missing Test Directory Install Playbook:**
- Issue: `tools/test/` directory exists but has no `install_test.yml` playbook
- Files: `tools/test/`
- Impact: Test tool not installed during setup
- Fix approach: Either remove empty directory or add proper playbook

**Heavy Use of Shell Module Instead of Native Modules:**
- Issue: 83 playbooks use `shell:` module, often for tasks that could use native Ansible modules
- Files: Most `tools/*/install_*.yml` playbooks
- Impact: Less idempotent, harder to test, platform-specific issues
- Fix approach: Replace with `get_url`, `unarchive`, `package` modules where possible

**Diffview Plugin Marked as TODO:**
- Issue: Plugin added but explicitly marked incomplete
- Files: `tools/neovim/nvim/lua/custom/plugins/diffview.lua:2`
- Impact: Plugin may not be properly configured for user's workflow
- Fix approach: Evaluate needs and configure or remove

## Known Bugs

**SSH Known Hosts Creates Marker Files But Uses Wrong Check:**
- Symptoms: `creates:` argument checks for `.known_hosts_{{ item }}` but marker files are only created after the scan
- Files: `tools/ssh/install_ssh.yml:55-64`
- Trigger: Re-running the playbook may re-scan hosts unnecessarily
- Workaround: Works correctly, just inefficient

**Keyboard Remap May Fail Silently:**
- Symptoms: `failed_when: false` on keyboard tasks means failures go unnoticed
- Files: `tools/keyboard/install_keyboard.yml:22,106`
- Trigger: Running on system without X11/Wayland active
- Workaround: Manual verification after setup

## Security Considerations

**Curl Pipe to Bash/Shell Pattern:**
- Risk: Remote code execution from potentially compromised sources
- Files:
  - `tools/node/install_node.yml:46` - nvm install script
  - `tools/python/install_python.yml:14` - uv install script
  - `tools/rust/install_rust.yml:8` - rustup install script
  - `tools/starship/install_starship.yml:20` - starship install script
  - `tools/pulumi/install_pulumi.yml:14` - pulumi install script
  - `bootstrap.sh:159` - Homebrew install
- Current mitigation: HTTPS only, reputable sources
- Recommendations: Pin script hashes, use package managers where available, or vendor scripts

**1Password Service Account Token Storage:**
- Risk: Token stored in plaintext at `~/.config/op/service-account-token`
- Files: `bootstrap.sh:38-76`, `tools/ssh/install_ssh.yml:77-95`
- Current mitigation: File permissions 600, directory 700
- Recommendations: Consider credential helpers, shorter token lifetimes

**Age Private Key in Known Location:**
- Risk: Key at `~/.config/sops/age/keys.txt` is predictable target
- Files: `bootstrap.sh:80-146`
- Current mitigation: File permissions 600
- Recommendations: Consider hardware key storage (YubiKey + age-plugin-yubikey)

**Hardcoded Network Hostnames:**
- Risk: Exposes internal network topology
- Files:
  - `tools/nas/install_nas.yml:5` - `nas.home.lan`
  - `tools/ssh/config.j2` - `*.home.lan` hostnames
  - `tools/ssh/install_ssh.yml:56-63` - host scanning
  - `inventory.yml` - all internal hosts
- Current mitigation: Private repo, local-only DNS
- Recommendations: Move hostnames to variables or vault for portability

## Performance Bottlenecks

**Full Playbook Runs All Tools:**
- Problem: `setup.yml` imports 90+ playbooks unconditionally
- Files: `setup.yml`
- Cause: Each playbook runs gather_facts and conditional checks even if not needed
- Improvement path: Add tags, use role-based structure, or create tool groups

**NVM Sourcing on Every Shell Task:**
- Problem: Every npm/node task re-sources nvm configuration
- Files: All playbooks using npm: `tools/node/install_node.yml`, `tools/claude-code/install_claude-code.yml`, `tools/codex/install_codex.yml`
- Cause: Shell tasks don't inherit environment
- Improvement path: Use `environment:` directive with pre-set paths

## Fragile Areas

**Theme System (colors, fonts, styles):**
- Files: `themes/_color.yml`, `themes/_font.yml`, `themes/_style.yml`
- Why fragile: Complex regex replacements across tmux, starship, neovim configs; Nerd Font glyphs render inconsistently
- Safe modification: Test on all three OS types; avoid editing Powerline characters directly
- Test coverage: None

**SSH Key Deployment Chain:**
- Files: `tools/ssh/install_ssh.yml`, `bootstrap.sh`
- Why fragile: Multi-step dependency: 1Password token -> op CLI -> key fetch -> file deployment
- Safe modification: Test with and without 1Password available
- Test coverage: None

**Bootstrap Script:**
- Files: `bootstrap.sh`
- Why fragile: OS detection, interactive prompts, multiple failure modes, runs before any tooling is available
- Safe modification: Test on fresh installs of each OS
- Test coverage: None

## Scaling Limits

**Single Age Recipient:**
- Current capacity: One age key for all hosts
- Limit: Adding users or machines requires re-encrypting with multiple recipients
- Scaling path: Already using `.sops.yaml` with recipient lists; add more recipients

**No Host-Specific Variables:**
- Current capacity: All hosts share same `group_vars/all/` configuration
- Limit: Cannot customize per-machine without conditional logic everywhere
- Scaling path: Add `host_vars/<hostname>/` directories

## Dependencies at Risk

**GSD (Get Shit Done) Package:**
- Risk: External npm package `get-shit-done-cc@latest` installed globally
- Impact: Breaking changes could affect Claude Code workflow
- Files: `tools/claude-code/install_claude-code.yml:68-77`
- Migration plan: Pin version or fork and maintain locally

**External Install Scripts:**
- Risk: nvm, rustup, uv, starship, pulumi scripts could change behavior
- Impact: Setup may break without warning
- Files: See "Curl Pipe to Bash" section above
- Migration plan: Vendor scripts or use package managers exclusively

## Missing Critical Features

**No Test Infrastructure:**
- Problem: No automated testing of playbooks
- Blocks: Safe refactoring, CI/CD validation
- Files: `tools/test/` is empty

**No Rollback Mechanism:**
- Problem: No way to undo changes from a failed or unwanted run
- Blocks: Safe experimentation on production machines

**No Dry-Run Validation:**
- Problem: `--check` mode doesn't work well with shell tasks
- Blocks: Preview of changes before applying

## Test Coverage Gaps

**Zero Test Coverage:**
- What's not tested: All 93 install playbooks, bootstrap script, theme system
- Files: All `tools/*/install_*.yml`, `bootstrap.sh`, `themes/*.yml`
- Risk: Regressions introduced without detection; OS-specific issues go unnoticed
- Priority: High

**No Linting in CI:**
- What's not tested: YAML syntax, Ansible best practices
- Files: All `.yml` files
- Risk: Style drift, deprecated module usage
- Priority: Medium

**No Multi-OS Validation:**
- What's not tested: Cross-platform compatibility (macOS, Debian, Arch)
- Files: All conditional tasks using `when: ansible_facts['os_family']`
- Risk: One OS breaks while others work
- Priority: High

---

*Concerns audit: 2026-01-19*
