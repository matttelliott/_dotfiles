# Requirements: Concerns Resolution Epic

**Defined:** 2026-01-21
**Core Value:** One command gets you your environment on any new machine
**Epic Scope:** v0.2-v0.5 (addressing all items from CONCERNS.md)

## v0.2 Requirements: Portability & Bugs

Requirements for v0.2. Focus: ARM64 support, idempotency, bug fixes.

### Architecture Portability

- [x] **ARCH-01**: APT repositories use dynamic architecture detection (docker, 1password, edge)
- [x] **ARCH-02**: Go installation detects architecture via ansible_architecture fact
- [x] **ARCH-03**: All playbooks work on ARM64 Debian (Raspberry Pi compatible)

### Idempotency

- [x] **IDEM-01**: go install commands have creates: guards
- [x] **IDEM-02**: mason install commands have creates: guards
- [x] **IDEM-03**: npm install -g commands have creates: guards
- [x] **IDEM-04**: uv tool install commands have creates: guards
- [x] **IDEM-05**: Re-runs show no false "changed" status

### Bug Fixes

- [x] **BUG-01**: SSH known_hosts uses ssh-keygen -F to verify host presence
- [x] **BUG-02**: Debian non-free repos use apt_repository module safely

### Performance

- [ ] **PERF-01**: Homebrew update skips if recently updated (timestamp check)

## v0.3 Requirements: CI/CD & Testing

Deferred to next milestone. Tracked for roadmap continuity.

### CI/CD Pipeline

- **CI-01**: GitHub Actions workflow for ansible-lint on PR
- **CI-02**: GitHub Actions workflow for YAML syntax validation
- **CI-03**: CI blocks merge on lint failures

### Test Infrastructure

- **TEST-01**: Molecule test framework configured
- **TEST-02**: Molecule tests for ssh playbook
- **TEST-03**: Molecule tests for git playbook
- **TEST-04**: Molecule tests for zsh playbook

## v0.4 Requirements: Security & Documentation

Deferred. Tracked for roadmap continuity.

### Security Hardening

- **SEC-01**: Curl-to-shell scripts pinned to specific commits
- **SEC-02**: Checksums verified for downloaded scripts where available
- **SEC-03**: GPG key fingerprints documented in playbook comments

### Documentation

- **DOC-01**: Theme system testing guidance in CLAUDE.md
- **DOC-02**: nvm dependency risk documented in playbook
- **DOC-03**: Rollback/recovery procedures documented
- **DOC-04**: Bootstrap script OS detection improved with /etc/os-release

## v0.5 Requirements: Polish

Deferred. Tracked for roadmap continuity.

### Refactoring

- **REF-01**: themes/_color.yml refactored (loop-based or templated)
- **REF-02**: Renovate configured for version tracking

## Out of Scope

Explicitly excluded with rationale (WONTFIX items from CONCERNS.md):

| ID | Feature | Reason |
|----|---------|--------|
| SEC-03 | Service account token encryption | Already mitigated (600 perms, gitignored) |
| SEC-04 | SSH key handling changes | Already mitigated (no_log, 600 perms) |
| PERF-03 | Neovim init.lua split | Kickstart pattern works; has lua/custom/plugins/ |
| FRAG-02 | Nerd font handling changes | Already documented in CLAUDE.md |
| SCALE-01 | Dynamic inventory | 4 hosts is fine for personal dotfiles |
| SCALE-02 | Tag-based tool selection | 7 groups sufficient |
| DEP-02 | Replace yay/AUR | Standard Arch practice |
| MISS-03 | System package version locking | Rolling releases preferred |

## Deferred

Acknowledged but deferred indefinitely:

| ID | Feature | Reason |
|----|---------|--------|
| PERF-02 | Parallel tool installation | Complexity vs benefit; current runtime acceptable |
| TEST-03 | Cross-platform CI matrix | Platform runners expensive; manual testing sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | Phase 5 | Complete |
| ARCH-02 | Phase 5 | Complete |
| ARCH-03 | Phase 5 | Complete |
| IDEM-01 | Phase 6 | Complete |
| IDEM-02 | Phase 6 | Complete |
| IDEM-03 | Phase 6 | Complete |
| IDEM-04 | Phase 6 | Complete |
| IDEM-05 | Phase 6 | Complete |
| BUG-01 | Phase 7 | Complete |
| BUG-02 | Phase 7 | Complete |
| PERF-01 | Phase 8 | Pending |

**Coverage:**
- v0.2 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0

---
*Requirements defined: 2026-01-21*
*Epic: Concerns Resolution (v0.2-v0.5)*
*Traceability updated: 2026-01-22*
