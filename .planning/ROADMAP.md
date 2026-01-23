# Roadmap: _dotfiles v0.3

## Overview

Milestone: v0.3 Security & Documentation
Phases: 2 (phases 9-10, continuing from v0.2)
Requirements: 6

This milestone hardens curl-to-shell script patterns used in bootstrap/tool installation and documents risks and recovery procedures. Phase 9 addresses script security through version pinning, checksum verification, and GPG key documentation. Phase 10 captures operational knowledge in documentation.

## Milestones

- ✅ **v0.1 Lint & Tooling** - Phases 1-4 (shipped 2026-01-21)
- ✅ **v0.2 Portability & Bugs** - Phases 5-8 (shipped 2026-01-22)
- 🚧 **v0.3 Security & Documentation** - Phases 9-10 (in progress)

## Phases

- [x] **Phase 9: Script Security** - Harden curl-to-shell scripts with pinning and verification
- [ ] **Phase 10: Documentation** - Document risks, recovery procedures, and testing guidance

## Phase Details

### Phase 9: Script Security
**Goal**: Curl-to-shell installation scripts are pinned to verifiable versions
**Depends on**: Phase 8 (v0.2 complete)
**Requirements**: SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. All curl-piped scripts reference specific commits or version tags, not master/main branches
  2. Scripts with published checksums have verification steps in playbooks
  3. GPG key fingerprints for package repositories are documented in playbook comments
  4. Running `ansible-lint` still passes after changes
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md - Pin curl-to-shell scripts (Homebrew, Pulumi, uv) + security comments for unpinnable scripts
- [x] 09-02-PLAN.md - Add checksum verification to sops + GPG fingerprint comments to 9 APT tools

### Phase 10: Documentation
**Goal**: Operational risks and procedures are documented for maintainer reference
**Depends on**: Phase 9
**Requirements**: DOC-01, DOC-02, DOC-03
**Success Criteria** (what must be TRUE):
  1. nvm curl-to-shell risk is documented with mitigation options
  2. Rollback/recovery procedures exist for common failure scenarios
  3. Theme system testing guidance is present in CLAUDE.md
  4. Documentation is findable (in expected locations: README, CLAUDE.md, or .planning/)
**Plans**: TBD

Plans:
- [ ] 10-01: [TBD - to be defined by plan-phase]

## Coverage

| Requirement | Phase | Description |
|-------------|-------|-------------|
| SEC-01 | Phase 9 | Curl-to-shell scripts pinned to specific commits/tags |
| SEC-02 | Phase 9 | Checksums verified for downloaded scripts where available |
| SEC-03 | Phase 9 | GPG key fingerprints documented in playbook comments |
| DOC-01 | Phase 10 | nvm dependency risk documented |
| DOC-02 | Phase 10 | Rollback/recovery procedures documented |
| DOC-03 | Phase 10 | Theme system testing guidance added to CLAUDE.md |

All 6/6 v0.3 requirements mapped.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 9. Script Security | v0.3 | 2/2 | Complete | 2026-01-23 |
| 10. Documentation | v0.3 | 0/? | Not started | - |

---
*Roadmap created: 2026-01-23*
*Last updated: 2026-01-23 (Phase 9 complete)*
