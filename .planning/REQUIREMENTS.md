# Requirements: Claude Code Configuration

**Defined:** 2026-01-18
**Core Value:** Clean, organized config structure that makes it obvious where things belong

## v1 Requirements

### Cleanup (CLEAN)

- [ ] **CLEAN-01**: Remove `~/.claude/hooks/auto-commit.sh`
- [ ] **CLEAN-02**: Remove `~/.claude/commands/init-project.md` and `init-project.md.j2`
- [ ] **CLEAN-03**: Remove `~/.claude/output-styles/` directory
- [ ] **CLEAN-04**: Remove `~/.claude/plugins/` directory
- [ ] **CLEAN-05**: Remove `~/.claude/CLAUDE.md`
- [ ] **CLEAN-06**: Update `~/.claude/settings.json` to only reference GSD hooks
- [ ] **CLEAN-07**: Remove `.claude/hooks/` contents (lint-ansible.sh, format-code.sh)
- [ ] **CLEAN-08**: Remove `.claude/rules/` contents (ansible.md, tests.md)
- [ ] **CLEAN-09**: Remove `.claude/agents/` contents (reviewer.md)
- [ ] **CLEAN-10**: Remove `.claude/commands/` contents (add-tool.md, explore-features.md)
- [ ] **CLEAN-11**: Remove `.claude/settings.json` and `settings.local.json`

### Structure (STRUCT)

- [ ] **STRUCT-01**: Document three-layer config architecture in `_dotfiles/CLAUDE.md`
- [ ] **STRUCT-02**: Define what belongs at each layer (user / portable / repo)
- [ ] **STRUCT-03**: Create clean user-level scaffold (`~/.claude/` structure via Ansible)
- [ ] **STRUCT-04**: Create clean repo-level scaffold (`.claude/` ready for future work)

## v2 Requirements

### Autocommit Improvements

- **AUTO-01**: Claude awareness of autocommit hook (skip manual commits)
- **AUTO-02**: Better commit message generation
- **AUTO-03**: Multi-agent git strategy (branch isolation or squashing)

### Feature Explorer Workflow

- **FEAT-01**: Explore existing config and suggest plugins/features
- **FEAT-02**: Propose options based on user request
- **FEAT-03**: Demo by applying to live config
- **FEAT-04**: Configure interactively while testing
- **FEAT-05**: Promote to dotfiles if approved

## Out of Scope

| Feature | Reason |
|---------|--------|
| MCP server configuration | Complexity; defer until needed |
| Plugin marketplace integration | Previous experiment didn't stick |
| Output styles | Not used; can recreate if needed |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CLEAN-01 | Phase 1 | Complete |
| CLEAN-02 | Phase 1 | Complete |
| CLEAN-03 | Phase 1 | Complete |
| CLEAN-04 | Phase 1 | Complete |
| CLEAN-05 | Phase 1 | Complete |
| CLEAN-06 | Phase 1 | Complete |
| CLEAN-07 | Phase 1 | Complete |
| CLEAN-08 | Phase 1 | Complete |
| CLEAN-09 | Phase 1 | Complete |
| CLEAN-10 | Phase 1 | Complete |
| CLEAN-11 | Phase 1 | Complete |
| STRUCT-01 | Phase 2 | Complete |
| STRUCT-02 | Phase 2 | Complete |
| STRUCT-03 | Phase 2 | Complete |
| STRUCT-04 | Phase 2 | Complete |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-01-18*
*Last updated: 2026-01-19 after Phase 2 completion (milestone complete)*
