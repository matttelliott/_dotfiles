# Roadmap: Claude Code Configuration

## Milestones

- ✅ **v1.0 Config Cleanup** — Phases 1-2 (shipped 2026-01-19)
- 🚧 **v1.1 Multi-agent Safety** — Phases 3-5 (in progress)

## Phases

<details>
<summary>✅ v1.0 Config Cleanup (Phases 1-2) — SHIPPED 2026-01-19</summary>

### Phase 1: Cleanup
**Goal**: Remove legacy Claude configs and establish clean slate
**Plans**: 2 plans (completed)

### Phase 2: Structure
**Goal**: Implement three-layer config architecture
**Plans**: 1 plan (completed)

</details>

### 🚧 v1.1 Multi-agent Safety (In Progress)

**Milestone Goal:** Make multi-agent work safe through worktree isolation, support parallel feature development with planning distillation on merge.

- [ ] **Phase 3: Worktree Foundation** — Shell commands for worktree management
- [ ] **Phase 4: Parallel Features** — GSD features in isolated worktrees
- [ ] **Phase 5: Merge Workflow** — Squash merge with planning distillation

## Phase Details

### Phase 3: Worktree Foundation

**Goal**: Users can manage git worktrees through simple shell commands
**Depends on**: Nothing (first phase of v1.1)
**Requirements**: WT-01, WT-02, WT-03, WT-04, WT-05, WT-06
**Success Criteria** (what must be TRUE):
  1. User can create a worktree with `gsd-worktree-add {name}` and branch is created
  2. User can list all active worktrees with `gsd-worktree-list`
  3. User can remove a worktree with `gsd-worktree-remove {name}` (cleans metadata)
  4. User can squash merge with `gsd-worktree-merge {name}` (checks for conflicts first)
  5. Worktree directories follow sibling pattern: `../{repo}-{name}/`
**Plans**: TBD

### Phase 4: Parallel Features

**Goal**: Multiple GSD features can be developed in parallel, each in its own worktree
**Depends on**: Phase 3 (worktree commands must exist)
**Requirements**: PF-01, PF-02, PF-03, PF-04
**Success Criteria** (what must be TRUE):
  1. Each feature worktree has its own `.planning/` directory (automatic via git)
  2. Running `/gsd:new-project` in a worktree creates independent project state
  3. Two features can progress simultaneously without state conflicts
  4. Workflow documentation exists for starting a feature worktree
**Plans**: TBD

### Phase 5: Merge Workflow

**Goal**: Completed features merge cleanly to master, preserving valuable planning context
**Depends on**: Phase 4 (parallel features provide the use case)
**Requirements**: MW-01, MW-02, MW-03, MW-04, MW-05, CMT-01
**Success Criteria** (what must be TRUE):
  1. `gsd-feature-complete {name}` squash merges code to master
  2. Key decisions from feature's `.planning/` are extracted to master's PROJECT.md
  3. Validated requirements are added to master's PROJECT.md
  4. Ephemeral planning files (phase details) are archived or discarded
  5. Claude checks `git status` before commit attempts (no retry loops)
**Plans**: TBD

## Progress

**Execution Order:** Phases execute in numeric order: 3 → 4 → 5

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Cleanup | v1.0 | 2/2 | Complete | 2026-01-19 |
| 2. Structure | v1.0 | 1/1 | Complete | 2026-01-19 |
| 3. Worktree Foundation | v1.1 | 0/TBD | Not started | - |
| 4. Parallel Features | v1.1 | 0/TBD | Not started | - |
| 5. Merge Workflow | v1.1 | 0/TBD | Not started | - |

---
*Roadmap created: 2026-01-19*
*Last updated: 2026-01-19 after scope refinement*
