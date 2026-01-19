# Roadmap: _dotfiles v0.1

## Overview

Clean up ansible-lint violations and add tooling to prevent regressions. Three phases: bulk lint fixes, validation that nothing broke, then a Claude Code hook to catch future issues. Mechanical work that clears technical debt and establishes quality gates.

## Phases

- [ ] **Phase 1: Lint Cleanup** - Fix all 856 ansible-lint violations
- [ ] **Phase 2: Validation** - Verify syntax and full deployment works
- [ ] **Phase 3: Tooling** - Add Claude Code post-write hook for ansible-lint

## Phase Details

### Phase 1: Lint Cleanup
**Goal**: All playbooks pass ansible-lint with zero violations
**Depends on**: Nothing (first phase)
**Requirements**: LINT-01, LINT-02, LINT-03, LINT-04, LINT-05, LINT-06
**Success Criteria** (what must be TRUE):
  1. `ansible-lint setup.yml` returns exit code 0
  2. `ansible-lint tools/*/install_*.yml` returns exit code 0
  3. All `ansible.builtin.*` FQCNs used (no bare module names)
  4. All booleans use `true`/`false` (no `yes`/`no`)
  5. All plays have names
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md — Fix FQCN and truthy violations across all playbooks
- [ ] 01-02-PLAN.md — Add names to all plays (import_playbook directives)
- [ ] 01-03-PLAN.md — Fix line-length and latest[git] violations

### Phase 2: Validation
**Goal**: Confirm lint fixes didn't break anything
**Depends on**: Phase 1
**Requirements**: VALID-01, VALID-02
**Success Criteria** (what must be TRUE):
  1. `ansible-playbook --syntax-check setup.yml` passes
  2. `ansible-playbook --syntax-check tools/*/install_*.yml` passes for all tools
  3. `./setup-all.sh` completes successfully on all hosts
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Tooling
**Goal**: Claude Code automatically validates YAML changes
**Depends on**: Phase 2 (want clean baseline before adding hook)
**Requirements**: TOOL-01, TOOL-02
**Success Criteria** (what must be TRUE):
  1. Saving a .yml file in tools/ triggers ansible-lint automatically
  2. Lint errors appear in Claude Code output with file/line info
  3. Clean files produce no output (silent success)
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Lint Cleanup | 0/3 | Planned | - |
| 2. Validation | 0/? | Not started | - |
| 3. Tooling | 0/? | Not started | - |

---
*Roadmap created: 2026-01-19*
