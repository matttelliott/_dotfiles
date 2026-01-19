# Codebase Concerns

**Analysis Date:** 2026-01-19

## Tech Debt

**Hardcoded amd64 Architecture in APT Repositories:**
- Issue: Several Debian repository configurations hardcode `arch=amd64`, breaking ARM64/aarch64 support
- Files:
  - `tools/docker/install_docker.yml:50`
  - `tools/1password/install_1password.yml:22`
  - `tools/edge/install_edge.yml:22`
- Impact: Debian ARM devices (e.g., Raspberry Pi) cannot use these tools
- Fix approach: Use `$(dpkg --print-architecture)` dynamically like `tools/1password_cli/install_1password_cli.yml:18` does

**Hardcoded darwin-arm64 and linux-amd64 in Go Installation:**
- Issue: Go installer assumes ARM for macOS and x86_64 for Linux
- Files: `tools/go/install_go.yml:14,29`
- Impact: Intel Macs and ARM Linux devices get wrong binaries
- Fix approach: Use `ansible_architecture` fact to select correct binary

**Pinned Versions Without Update Strategy:**
- Issue: Multiple tools pin specific versions without automated update mechanism
- Files:
  - `tools/go/install_go.yml:5` (go_version: "1.23.4")
  - `tools/lazygit/install_lazygit.yml:5` (lazygit_version: "0.44.1")
  - `tools/doctl/install_doctl.yml:7` (doctl_version: "1.104.0")
  - `tools/node/install_node.yml:46` (nvm v0.40.1)
  - `tools/sops/install_sops.yml:17` (sops v3.9.4)
  - `tools/procs/install_procs.yml:17` (procs v0.14.8)
  - `tools/obsidian/install_obsidian.yml:15` (Obsidian v1.5.12)
- Impact: Security updates and new features missed; manual effort to bump versions
- Fix approach: Consider using "latest" releases or add Dependabot/Renovate for version tracking

**Shell Commands Without Idempotency Guards:**
- Issue: Many shell tasks lack `creates:` or `changed_when:` making them non-idempotent
- Files:
  - `tools/go/install_go.yml:49-53` (go install commands)
  - `tools/neovim/install_neovim.yml:53-56` (mason install)
  - `tools/node/install_node.yml:59-73` (npm install -g)
  - `tools/ansible/install_ansible.yml:20-26` (uv tool install)
- Impact: These tasks always show "changed" or run unnecessarily
- Fix approach: Add `creates:` pointing to expected binary output path

**Large Monolithic Files:**
- Issue: Theme color file is 580 lines with repetitive replace tasks
- Files: `themes/_color.yml` (580 lines)
- Impact: Hard to maintain; changes require editing many similar blocks
- Fix approach: Consider templating or loop-based approach for color replacements

## Known Bugs

**SSH known_hosts Marker File Bug:**
- Symptoms: `creates:` checks for `.known_hosts_{{ item }}` but ssh-keyscan appends to `~/.ssh/known_hosts`
- Files: `tools/ssh/install_ssh.yml:55-58`
- Trigger: Marker file exists but known_hosts doesn't have the host
- Workaround: Delete `.known_hosts_*` marker files and rerun
- Fix approach: Either check inside known_hosts or use `ssh-keygen -F` to verify host presence

**Debian Non-Free Repos Modification is Destructive:**
- Symptoms: Blindly appends "contrib non-free non-free-firmware" to sources.list
- Files: `tools/gpu/install_gpu.yml:112-115`
- Trigger: Running on a system with existing non-free config
- Workaround: Manual sources.list review
- Fix approach: Use `apt_repository` module or more robust sed pattern

## Security Considerations

**Curl-to-Shell Installation Pattern:**
- Risk: Remote code execution if upstream compromised; no verification of downloaded scripts
- Files:
  - `tools/node/install_node.yml:46` (nvm)
  - `tools/rust/install_rust.yml:8` (rustup)
  - `tools/python/install_python.yml:14` (uv)
  - `tools/starship/install_starship.yml:20` (starship)
  - `tools/pulumi/install_pulumi.yml:14` (pulumi)
- Current mitigation: HTTPS ensures transit security; using official URLs
- Recommendations: Pin to specific commits/versions where possible; add checksum verification

**GPG Keys Downloaded Without Verification:**
- Risk: MITM or compromised keys could allow malicious packages
- Files:
  - `tools/docker/install_docker.yml:42`
  - `tools/1password/install_1password.yml:21`
  - `tools/gh/install_gh.yml:21`
  - `tools/wezterm/install_wezterm.yml:25`
- Current mitigation: HTTPS connection
- Recommendations: Verify GPG key fingerprints in playbook comments or assertions

**Service Account Token Stored in Plaintext:**
- Risk: Token at `~/.config/op/service-account-token` grants 1Password access
- Files: `bootstrap.sh:38-76`
- Current mitigation: File permissions set to 600; gitignored
- Recommendations: Document token scope limitations; consider TTL-based tokens

**SSH Private Key Handling:**
- Risk: Private key passes through shell variables briefly
- Files: `tools/ssh/install_ssh.yml:92-110`
- Current mitigation: `no_log: true` prevents Ansible output; permissions 600
- Recommendations: Current approach is reasonable; ensure op CLI permissions are minimal

## Performance Bottlenecks

**Full Homebrew Update on Every Run:**
- Problem: `brew update` runs unconditionally on every playbook execution
- Files: `setup.yml:14`
- Cause: No caching or freshness check
- Improvement path: Add timestamp check or run only when packages need installing

**Serial Tool Installation:**
- Problem: 90+ tools installed one at a time, no parallelism
- Files: `setup.yml` (189 lines of sequential import_playbook)
- Cause: Ansible default serial execution
- Improvement path: Consider grouping independent tools into single playbooks with async/poll

**Neovim init.lua Size:**
- Problem: 1118-line monolithic configuration file
- Files: `tools/neovim/nvim/init.lua`
- Cause: Based on kickstart.nvim single-file approach
- Improvement path: Already has `lua/custom/plugins/` for extensions; continue modularizing

## Fragile Areas

**Theme System String Replacement:**
- Files:
  - `themes/_color.yml`
  - `themes/_style.yml`
  - `themes/_font.yml`
- Why fragile: Relies on exact regex patterns matching config file format
- Safe modification: Test on one tool first; changes to tmux.conf/starship.toml format will break themes
- Test coverage: None; manual testing required

**Nerd Font Glyph Handling:**
- Files:
  - `tools/tmux/tmux.conf.j2`
  - `tools/starship/starship.toml`
  - `tools/neovim/nvim/init.lua`
- Why fragile: Unicode Private Use Area characters display as whitespace in many editors/LLMs
- Safe modification: Use escape sequences; never directly edit glyph characters
- Test coverage: None; visual inspection required

**Bootstrap Script OS Detection:**
- Files: `bootstrap.sh:9-22`
- Why fragile: Only checks specific paths (`/etc/arch-release`, `/etc/debian_version`)
- Safe modification: Add new OS support carefully; test each code path
- Test coverage: None; relies on real hardware testing

## Scaling Limits

**Inventory Management:**
- Current capacity: 4 hosts in `inventory.yml`
- Limit: Manual YAML editing becomes tedious beyond ~10 hosts
- Scaling path: Consider dynamic inventory or inventory scripts

**Group-Based Tool Selection:**
- Current capacity: 7 host groups for tool selection
- Limit: Combinatorial explosion if more granular control needed
- Scaling path: Consider tags or role-based organization

## Dependencies at Risk

**nvm Installation Method:**
- Risk: Bash script from GitHub; version pinned but still network-dependent
- Impact: Node.js installation fails if nvm changes or GitHub unavailable
- Migration plan: Consider using system Node + corepack, or asdf

**yay for AUR Packages:**
- Risk: AUR is community-maintained; packages can disappear or break
- Impact: Arch installation of autofs, browsers, fonts may fail
- Files: `tools/yay/install_yay.yml`, various tools with `yay -S`
- Migration plan: None needed; AUR is standard for Arch. Document expected packages.

## Missing Critical Features

**No Rollback Mechanism:**
- Problem: Failed installations leave partial state
- Blocks: Reliable unattended provisioning; disaster recovery
- Files: All install playbooks lack uninstall counterparts

**No Test Suite:**
- Problem: Zero automated tests for playbooks
- Blocks: Confident refactoring; CI/CD validation
- Current state: No `*.test.*` or `*_test.*` files found

**No Version Locking for System Packages:**
- Problem: `apt`, `pacman`, `brew` install latest versions
- Blocks: Reproducible builds; debugging version-specific issues
- Files: Nearly all install playbooks

## Test Coverage Gaps

**No Playbook Tests:**
- What's not tested: All 99 install playbooks have zero automated tests
- Files: `tools/*/install_*.yml`
- Risk: Regressions unnoticed until manual testing or production failure
- Priority: Medium - consider Molecule for critical playbooks (ssh, git, zsh)

**No CI/CD Pipeline:**
- What's not tested: Syntax validation, lint rules, actual execution
- Files: No `.github/workflows/` for this repo (only nested `tools/neovim/nvim/.github/`)
- Risk: Broken YAML or deprecated Ansible syntax merges to master
- Priority: High - add ansible-lint and syntax-check to CI

**No Cross-Platform Verification:**
- What's not tested: macOS/Debian/Arch compatibility verified only manually
- Risk: OS-specific breakage unnoticed
- Priority: Low - platform matrix testing is expensive; current approach works

---

*Concerns audit: 2026-01-19*
