# Roadmap: _dotfiles v0.1

## Overview

Clean up ansible-lint violations and add tooling to prevent regressions. Three phases: bulk lint fixes, validation that nothing broke, then a Claude Code hook to catch future issues. Mechanical work that clears technical debt and establishes quality gates.

## Phases

- [x] **Phase 1: Lint Cleanup** - Fix all 856 ansible-lint violations
- [x] **Phase 2: Validation** - Verify syntax and full deployment works
- [x] **Phase 3: Tooling** - Add Claude Code post-write hook for ansible-lint
- [x] **Phase 4: Hook Registration** - Wire ansible-lint hook to settings.json

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
- [x] 01-01-PLAN.md — Fix FQCN and truthy violations across all playbooks
- [x] 01-02-PLAN.md — Add names to all plays (import_playbook directives)
- [x] 01-03-PLAN.md — Fix line-length and latest[git] violations

### Phase 2: Validation
**Goal**: Confirm lint fixes didn't break anything
**Depends on**: Phase 1
**Requirements**: VALID-01, VALID-02
**Success Criteria** (what must be TRUE):
  1. `ansible-playbook --syntax-check setup.yml` passes
  2. `ansible-playbook --syntax-check tools/*/install_*.yml` passes for all tools
  3. `./setup-all.sh` completes successfully on all hosts
**Status**: Complete (executed during gap closure, no formal plan)

Results:
- desktop (local): 323 tasks OK, 0 failures
- macmini (remote): 318 tasks OK, 0 failures
- macbookair/miniserver: unreachable (offline)

### Phase 3: Tooling
**Goal**: Claude Code automatically validates YAML changes
**Depends on**: Phase 2 (want clean baseline before adding hook)
**Requirements**: TOOL-01, TOOL-02
**Success Criteria** (what must be TRUE):
  1. Saving a .yml file in tools/ triggers ansible-lint automatically
  2. Lint errors appear in Claude Code output with file/line info
  3. Clean files produce no output (silent success)
**Status**: Complete (hook created and deployed)

Implementation:
- Hook source: `tools/claude-code/hooks/ansible-lint.sh` ✓
- Deployment: Added to `install_claude-code.yml` via ansible.builtin.copy ✓
- Registration: Completed in Phase 4 ✓

### Phase 4: Hook Registration
**Goal**: Wire ansible-lint hook to Claude Code PostToolUse trigger
**Depends on**: Phase 3 (hook must exist before registration)
**Requirements**: TOOL-01, TOOL-02 (completing what Phase 3 started)
**Gap Closure**: Closes gaps from v0.1 audit
**Success Criteria** (what must be TRUE):
  1. `.claude/settings.json` contains PostToolUse entry for ansible-lint.sh
  2. Editing a .yml file in _dotfiles triggers the hook
  3. Hook output (lint errors) appears in Claude Code
**Status**: Complete (verified 2026-01-21)

Plans:
- [x] 04-01-PLAN.md — Add hook registration to repo-level settings.json

Implementation:
- Registration: `.claude/settings.json` with PostToolUse hook (Edit|Write matcher)
- Deviation: Used settings.json (tracked) instead of settings.local.json (gitignored) per project convention

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Lint Cleanup | 3/3 | ✓ Complete | 2026-01-20 |
| 2. Validation | ad-hoc | ✓ Complete | 2026-01-21 |
| 3. Tooling | ad-hoc | ✓ Complete | 2026-01-21 |
| 4. Hook Registration | 1/1 | ✓ Complete | 2026-01-21 |

---
*Roadmap created: 2026-01-19*
*Phase 1 completed: 2026-01-20*
*Phase 2 completed: 2026-01-21*
*Phase 3 completed: 2026-01-21*
*Phase 4 completed: 2026-01-21*
*v0.1 milestone complete: 2026-01-21*
