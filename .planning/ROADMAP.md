# Roadmap: Claude Code Configuration

## Overview

This project cleans up legacy Claude Code configuration and establishes a clean three-layer architecture (user / portable / repo-specific). Phase 1 removes accumulated cruft from previous experiments. Phase 2 documents the architecture and scaffolds clean directory structures at each layer.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Cleanup** - Remove old/broken configs, preserve only GSD + credentials
- [ ] **Phase 2: Structure** - Document architecture and scaffold clean directories

## Phase Details

### Phase 1: Cleanup
**Goal**: Remove all legacy Claude configs, leaving only working GSD and credentials
**Depends on**: Nothing (first phase)
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04, CLEAN-05, CLEAN-06, CLEAN-07, CLEAN-08, CLEAN-09, CLEAN-10, CLEAN-11
**Success Criteria** (what must be TRUE):
  1. User-level `~/.claude/` contains only GSD directory and `.credentials.json`
  2. User-level `~/.claude/settings.json` references only GSD hooks (no legacy entries)
  3. Repo-level `.claude/` is empty or contains only placeholder
  4. GSD commands (`/gsd:*`) continue to work after cleanup
**Plans**: TBD

Plans:
- [ ] 01-01: TBD

### Phase 2: Structure
**Goal**: Document three-layer architecture and create clean scaffolds at each layer
**Depends on**: Phase 1
**Requirements**: STRUCT-01, STRUCT-02, STRUCT-03, STRUCT-04
**Success Criteria** (what must be TRUE):
  1. `_dotfiles/CLAUDE.md` documents the three-layer architecture with clear examples
  2. Each layer (user/portable/repo) has documented ownership rules
  3. Ansible playbook creates user-level scaffold on deployment
  4. Repo-level `.claude/` has clean scaffold ready for future work
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Cleanup | 0/? | Not started | - |
| 2. Structure | 0/? | Not started | - |
