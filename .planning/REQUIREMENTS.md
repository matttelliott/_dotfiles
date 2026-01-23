# Requirements: _dotfiles

**Defined:** 2026-01-23
**Core Value:** One command gets you your environment on any new machine

## v0.3 Requirements

Requirements for v0.3 Security & Documentation milestone.

### Script Security

- [ ] **SEC-01**: Curl-to-shell scripts pinned to specific commits/tags
- [ ] **SEC-02**: Checksums verified for downloaded scripts where available
- [ ] **SEC-03**: GPG key fingerprints documented in playbook comments

### Documentation

- [ ] **DOC-01**: nvm dependency risk documented (curl-to-shell pattern)
- [ ] **DOC-02**: Rollback/recovery procedures documented
- [ ] **DOC-03**: Theme system testing guidance added to CLAUDE.md

## Future Requirements

Deferred to future milestones.

### Ephemeral Environments (v0.4)

- **EPH-01**: Container/VPS support for ephemeral development environments
- **EPH-02**: Claude Code sandbox Dockerfile

### Polish (v0.5)

- **POL-01**: Themes refactor
- **POL-02**: Version tracking improvements

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full ansible-lint compliance | 267 non-targeted violations remain; tracked as tech debt |
| CI/CD pipeline | Personal repo tested on real machines |
| Molecule tests | Real machine testing more accurate than containers |
| Parallel installation (PERF-02) | Complexity vs benefit |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | TBD | Pending |
| SEC-02 | TBD | Pending |
| SEC-03 | TBD | Pending |
| DOC-01 | TBD | Pending |
| DOC-02 | TBD | Pending |
| DOC-03 | TBD | Pending |

**Coverage:**
- v0.3 requirements: 6 total
- Mapped to phases: 0
- Unmapped: 6 ⚠️

---
*Requirements defined: 2026-01-23*
*Last updated: 2026-01-23 after initial definition*
