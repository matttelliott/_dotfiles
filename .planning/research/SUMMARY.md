# Project Research Summary

**Project:** Claude Code Configuration v1.1
**Domain:** Git worktree multi-agent isolation
**Researched:** 2026-01-19
**Confidence:** HIGH

## Executive Summary

Git worktrees are the right tool for multi-agent isolation in Claude Code workflows. Built into Git since v2.5 (current is v2.52), worktrees provide true filesystem isolation while sharing Git history with zero additional dependencies. The core pattern is straightforward: create a dedicated worktree with feature branch for each executing phase, let agents commit freely within their isolated workspace, then squash-merge to master for clean history. This solves the fundamental problem of parallel agents creating interleaved commits and file conflicts when working in the same directory.

The recommended implementation integrates worktree lifecycle management directly into the GSD execute-phase command. When a phase begins, the orchestrator creates `.trees/{phase-id}/` with a dedicated `agent/{phase-id}` branch. The executor agent works in complete isolation, making atomic commits as it progresses. Upon completion, the orchestrator squash-merges the feature branch to master with a substantive commit message derived from the phase summary, then cleans up the worktree and temporary branch. This preserves detailed work history in SUMMARY.md files while maintaining a clean, bisectable master branch.

The key risks are merge conflicts when parallel agents modify shared files, orphaned worktrees from incomplete cleanups, and the cognitive overhead of managing multiple parallel contexts. These are mitigated by clear file ownership rules in agent CLAUDE.md files, automated cleanup in the GSD workflow, and limiting parallelization to 2-3 agents maximum. The dotfiles project is particularly well-suited for this approach since it has no npm/node dependencies requiring per-worktree installation.

## Key Findings

### Recommended Stack

Native git worktree commands with thin shell wrappers provide the ideal balance of simplicity and capability. Heavy tooling like workmux is unnecessary for this use case. The stack is entirely built-in to Git with no external dependencies.

**Core technologies:**
- **Git worktree (built-in):** Filesystem isolation with shared .git directory - mature, well-documented, zero setup
- **Squash merge:** Clean history with one commit per phase - standard git workflow
- **Shell wrapper functions:** `gsd-worktree-add`, `gsd-worktree-merge`, `gsd-worktree-list` - simple, integrates with existing zsh setup

**Not recommended:**
- workmux (Rust CLI) - overkill for this project, adds tmux dependency
- Custom tooling - native git commands are sufficient
- Bare repository pattern - adds complexity without benefit for single-machine workflows

### Expected Features

**Must have (table stakes):**
- Automatic worktree creation on phase start (`git worktree add .trees/{phase} -b agent/{phase}`)
- Automatic worktree cleanup on phase completion (`git worktree remove` + `git branch -D`)
- Squash merge with meaningful commit messages (derived from SUMMARY.md)
- Branch per phase (naming convention: `agent/{phase-id}`)
- Graceful failure handling (detect orphaned worktrees, offer cleanup)
- Conflict detection before merge (stop and notify user, never auto-resolve)

**Should have (competitive):**
- Commit message aggregation (generate squash message from individual commits)
- Worktree status dashboard (`git worktree list` with phase mapping)
- Auto-stash main changes before worktree creation
- Pre-merge conflict preview (`git diff main...agent/{phase}`)

**Defer (v2+):**
- Parallel phase execution (multiple worktrees simultaneously)
- Hook-based branch isolation (GitButler-style auto-branching)
- Integration with external tools (tmux, workmux)
- Cross-repository worktree management

### Architecture Approach

The architecture centers on modifying GSD execute-phase to manage worktree lifecycle. The orchestrator creates worktrees before spawning executors, passes worktree paths to Task calls, waits for completion, then handles sequential squash-merge and cleanup. This pattern maintains executor simplicity - the executor doesn't need to know it's in a worktree; it operates normally while the orchestrator handles isolation.

**Major components:**
1. **Worktree Creation (execute-phase step 4a):** Create `.trees/{phase-id}/` with dedicated branch before spawning executors
2. **Executor Spawn (execute-phase step 4b):** Pass `working_dir=".trees/{phase-id}"` to Task tool
3. **Squash Merge (execute-phase step 4d):** Sequential merge of completed worktrees to master with substantive commit messages
4. **Cleanup (execute-phase step 4e):** Remove worktrees and temporary branches, run `git worktree prune`

**Directory structure:**
```
project-root/
  +-- .trees/           # All worktrees (gitignored)
  |     +-- 01-01/      # Worktree for plan 01-01
  |     +-- 01-02/      # Worktree for plan 01-02
  +-- .planning/        # GSD planning files
  +-- tools/            # Dotfiles tools
```

### Critical Pitfalls

1. **Same file modified by multiple agents (M1):** Without explicit coordination, agents independently modify shared files (configs, types, utils). Prevent by defining file ownership in each agent's CLAUDE.md and designating shared files as "propose changes, don't commit."

2. **Orphaned worktree metadata (W5):** Using `rm -rf` instead of `git worktree remove` leaves stale metadata. Always use proper git commands; include `git worktree prune` in cleanup workflow.

3. **Squash merge loses granular history (C1):** Large squashed commits make `git bisect` ineffective. Mitigate by keeping phases small enough for meaningful squash commits and preserving detail in SUMMARY.md and squash commit messages.

4. **Branch already checked out error (W1):** Git prevents checking out the same branch in multiple worktrees. Always create NEW branches with worktrees (`git worktree add -b agent/{phase}`), never reuse existing branches.

5. **Phase completion without proper merge (GSD2):** Forgetting the merge step leaves changes stranded in worktrees. Enforce completion checklist in GSD workflow: merge to main, delete worktree, delete branch, update state.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Worktree Foundation

**Rationale:** Core worktree management must exist before GSD integration can use it.
**Delivers:** Shell wrapper functions, directory conventions, .gitignore setup
**Addresses:** Automatic worktree creation, cleanup, branch naming convention
**Avoids:** W1 (branch checkout error), W5 (orphaned metadata) by building checks into helpers

### Phase 2: GSD Execute-Phase Integration

**Rationale:** GSD is the orchestration layer; worktree lifecycle belongs in execute-phase, not executors.
**Delivers:** Modified execute-phase with worktree creation, executor spawn with working_dir, squash merge, cleanup
**Uses:** Shell wrappers from Phase 1
**Implements:** Orchestrator integration architecture from ARCHITECTURE.md
**Avoids:** GSD1 (execution without worktree), GSD2 (completion without merge)

### Phase 3: Squash Merge and History

**Rationale:** Squash merge is the payoff but requires the integration layer to be in place first.
**Delivers:** Commit message generation from SUMMARY.md, conflict detection, proper cleanup sequence
**Addresses:** Clean history goal, meaningful commit messages
**Avoids:** C1 (loses history), C2 (reusing squashed branches)

### Phase 4: Claude Empty Commit Awareness

**Rationale:** Separate concern that can be addressed after core workflow works.
**Delivers:** Pre-commit check in executor to skip empty commits, updated deviation rules
**Addresses:** Stops Claude from retrying "nothing to commit" errors
**Avoids:** CL4 (commit retry loops)

### Phase Ordering Rationale

- **Foundation before integration:** Worktree helpers (Phase 1) must exist before GSD can call them (Phase 2)
- **Integration before payoff:** Squash merge (Phase 3) requires the worktree lifecycle to be wired into GSD
- **Core before polish:** Empty commit handling (Phase 4) is an improvement to existing behavior, not blocking
- **Risk mitigation front-loaded:** Phases 1-2 address the most critical pitfalls (W1, W5, GSD1, GSD2)

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** GSD execute-phase internals need careful review to understand exact modification points
- **Phase 3:** Commit message generation from SUMMARY.md may need iteration on format

Phases with standard patterns (skip research-phase):
- **Phase 1:** Git worktree commands are well-documented; shell wrapper is straightforward
- **Phase 4:** Simple conditional check before commit; well-understood pattern

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official git documentation, no external dependencies |
| Features | HIGH | Community consensus + official Claude Code docs |
| Architecture | HIGH | Direct review of GSD source + established worktree patterns |
| Pitfalls | HIGH | Multiple independent sources with consistent findings |

**Overall confidence:** HIGH

### Gaps to Address

- **Task tool working_dir parameter:** Architecture assumes Task can accept working directory. Verify during Phase 2 planning.
- **Executor path handling:** May need to use absolute paths in executors when spawned in worktree context.
- **SUMMARY.md one-liner extraction:** Need to define exact format for extracting commit message from SUMMARY.md.

## Sources

### Primary (HIGH confidence)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Authoritative command reference
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows) - Official Anthropic worktree guidance
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) - Lifecycle events and configuration

### Secondary (MEDIUM confidence)
- [incident.io: Shipping faster with Claude Code and Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) - Production team workflow
- [Nick Mitchinson: Git Worktrees for Multi-Feature Development](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/) - Practical patterns
- [Simon Willison: Parallel Coding Agent Lifestyle](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/) - Multi-agent coordination
- [DNSimple: Two Years of Squash Merge](https://blog.dnsimple.com/2019/01/two-years-of-squash-merge/) - Squash merge tradeoffs

### Tertiary (LOW confidence)
- [GitHub Issue #16293](https://github.com/anthropics/claude-code/issues/16293) - Autocommit feature request (confirms no built-in feature)
- [GitHub Issue #4963](https://github.com/anthropics/claude-code/issues/4963) - Worktree orchestration request

---
*Research completed: 2026-01-19*
*Ready for roadmap: yes*
