# Requirements: Claude Code Configuration v1.1

**Defined:** 2026-01-19
**Core Value:** Clean, organized config structure that makes it obvious where things belong

## v1 Requirements

Requirements for v1.1 Multi-agent Safety milestone. Each maps to roadmap phases.

### Worktree Management (WT)

- [ ] **WT-01**: Create worktree with dedicated branch for agent work
- [ ] **WT-02**: List active worktrees with status
- [ ] **WT-03**: Remove worktree and cleanup git metadata
- [ ] **WT-04**: Merge worktree branch back to master
- [ ] **WT-05**: Automatic worktree naming conventions (sibling directory pattern)
- [ ] **WT-06**: Conflict detection before merge attempt

### GSD Integration (GSD)

- [ ] **GSD-01**: Execute-phase creates worktree automatically on start
- [ ] **GSD-02**: Executor agent runs in worktree directory
- [ ] **GSD-03**: Phase completion triggers squash merge to master
- [ ] **GSD-04**: Worktree cleanup on successful completion
- [ ] **GSD-05**: Track active worktrees in STATE.md
- [ ] **GSD-06**: Abort/cleanup option without merge

### Commit Hygiene (CMT)

- [ ] **CMT-01**: Squash merge to master with meaningful commit message
- [ ] **CMT-02**: Extract summary from SUMMARY.md for squash commit
- [ ] **CMT-03**: Claude checks `git status` before commit attempts (stop retry loops)

## v2 Requirements

Deferred to future release.

### Applied Repo Strategy

- **APP-01**: Multi-agent strategy for applied repos (dotfiles, k8s)
- **APP-02**: Checkpoint/restore for risky operations
- **APP-03**: Single-agent enforcement for sensitive repos

## Out of Scope

| Feature | Reason |
|---------|--------|
| Feature explorer workflow | Future milestone, unrelated to multi-agent safety |
| MCP server configuration | Complexity; defer until needed |
| workmux or heavy tooling | Shell wrappers sufficient, avoid external deps |
| Auto-resolve merge conflicts | Too risky; conflicts require human review |
| Force push to master | Never; always squash merge |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WT-01 | TBD | Pending |
| WT-02 | TBD | Pending |
| WT-03 | TBD | Pending |
| WT-04 | TBD | Pending |
| WT-05 | TBD | Pending |
| WT-06 | TBD | Pending |
| GSD-01 | TBD | Pending |
| GSD-02 | TBD | Pending |
| GSD-03 | TBD | Pending |
| GSD-04 | TBD | Pending |
| GSD-05 | TBD | Pending |
| GSD-06 | TBD | Pending |
| CMT-01 | TBD | Pending |
| CMT-02 | TBD | Pending |
| CMT-03 | TBD | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 15

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-19 after initial definition*
