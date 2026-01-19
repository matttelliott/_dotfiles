# Requirements: Claude Code Configuration v1.1

**Defined:** 2026-01-19
**Core Value:** Clean, organized config structure that makes it obvious where things belong

## v1 Requirements

Requirements for v1.1 Multi-agent Safety milestone.

### Worktree Management (WT)

Shell commands for managing git worktrees (used by both manual agents and GSD features).

- [ ] **WT-01**: Create worktree with dedicated branch (`gsd-worktree-add {name}`)
- [ ] **WT-02**: List active worktrees with status (`gsd-worktree-list`)
- [ ] **WT-03**: Remove worktree and cleanup metadata (`gsd-worktree-remove {name}`)
- [ ] **WT-04**: Squash merge worktree branch to master (`gsd-worktree-merge {name}`)
- [ ] **WT-05**: Sibling directory naming convention (`../{repo}-{name}/`)
- [ ] **WT-06**: Conflict detection before merge attempt

### Parallel Feature Support (PF)

Run multiple GSD features in parallel, each in its own worktree with independent state.

- [ ] **PF-01**: Each feature worktree has its own `.planning/` directory
- [ ] **PF-02**: GSD commands work independently in each worktree
- [ ] **PF-03**: Features can be developed in parallel without state conflicts
- [ ] **PF-04**: Document workflow for starting a new feature worktree

### Merge Workflow (MW)

Bring completed features back to master while preserving valuable planning context.

- [ ] **MW-01**: Squash merge feature code to master
- [ ] **MW-02**: Distill key decisions from feature `.planning/` to master's PROJECT.md
- [ ] **MW-03**: Distill validated requirements to master's PROJECT.md
- [ ] **MW-04**: Archive or discard ephemeral planning files (phase details, task breakdowns)
- [ ] **MW-05**: Command to run full merge workflow (`gsd-feature-complete {name}`)

### Commit Hygiene (CMT)

- [ ] **CMT-01**: Claude checks `git status` before commit attempts (stop retry loops)

## v2 Requirements

Deferred to future release.

### Applied Repo Strategy

- **APP-01**: Multi-agent strategy for applied repos (dotfiles, k8s)
- **APP-02**: Checkpoint/restore for risky operations

### Merge Refinements

- **MR-01**: Smarter distillation (patterns, learnings beyond decisions)
- **MR-02**: Conflict resolution assistance from Claude

## Out of Scope

| Feature | Reason |
|---------|--------|
| Feature explorer workflow | Future milestone, unrelated to multi-agent safety |
| MCP server configuration | Complexity; defer until needed |
| Auto-resolve code conflicts | Too risky; code conflicts require human review |
| Force push to master | Never; always squash merge |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WT-01 | Phase 3 | Pending |
| WT-02 | Phase 3 | Pending |
| WT-03 | Phase 3 | Pending |
| WT-04 | Phase 3 | Pending |
| WT-05 | Phase 3 | Pending |
| WT-06 | Phase 3 | Pending |
| PF-01 | Phase 4 | Pending |
| PF-02 | Phase 4 | Pending |
| PF-03 | Phase 4 | Pending |
| PF-04 | Phase 4 | Pending |
| MW-01 | Phase 5 | Pending |
| MW-02 | Phase 5 | Pending |
| MW-03 | Phase 5 | Pending |
| MW-04 | Phase 5 | Pending |
| MW-05 | Phase 5 | Pending |
| CMT-01 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-19 after scope refinement*
