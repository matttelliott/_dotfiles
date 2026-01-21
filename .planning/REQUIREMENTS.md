# Requirements: _dotfiles v0.1

**Defined:** 2026-01-19
**Core Value:** One command gets you your environment on any new machine

## v1 Requirements

### Lint Fixes

- [x] **LINT-01**: Fix all `fqcn[action-core]` violations (413) — use `ansible.builtin.*`
- [x] **LINT-02**: Fix all `yaml[truthy]` violations (264) — use `true`/`false` not `yes`/`no`
- [x] **LINT-03**: Fix all `name[play]` violations (100) — add names to plays
- [x] **LINT-04**: Fix all `fqcn[action]` violations (64) — use fully qualified collection names
- [x] **LINT-05**: Fix all `yaml[line-length]` violations (12) — wrap long lines
- [x] **LINT-06**: Fix all `latest[git]` violations (3) — pin git versions

### Validation

- [x] **VALID-01**: All playbooks pass `ansible-playbook --syntax-check`
- [x] **VALID-02**: `setup.yml` runs successfully on all hosts (`./setup-all.sh`)

### Tooling

- [x] **TOOL-01**: Claude Code post-write hook runs ansible-lint on YAML files
- [x] **TOOL-02**: Hook reports lint errors clearly

## v2 Requirements

Deferred to future milestones:

### v0.2 — Test Infrastructure
- Test infrastructure setup (CI/CD, possibly Molecule)
- Test plan for what needs automated tests

### v0.3+ — Fixes
- SSH known_hosts marker bug
- Debian non-free repos issue
- Hardcoded architectures (amd64/arm64)
- Shell task idempotency (creates:/changed_when:)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full test suite | Deferred to v0.2 |
| Bug fixes | Deferred to v0.3+ |
| Cross-platform container testing | Overkill for lint fixes |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LINT-01 | Phase 1 | Complete |
| LINT-02 | Phase 1 | Complete |
| LINT-03 | Phase 1 | Complete |
| LINT-04 | Phase 1 | Complete |
| LINT-05 | Phase 1 | Complete |
| LINT-06 | Phase 1 | Complete |
| VALID-01 | Phase 2 | Complete |
| VALID-02 | Phase 2 | Complete |
| TOOL-01 | Phase 3 | Complete |
| TOOL-02 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 10 total
- Completed: 10
- Pending: 0

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-21 — All v1 requirements complete*
