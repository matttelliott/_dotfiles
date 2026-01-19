# Features Research: Multi-agent Worktree Workflow

**Domain:** Git worktree-based multi-agent isolation for Claude Code
**Researched:** 2026-01-19
**Overall Confidence:** HIGH (based on official Claude Code docs + extensive community patterns)

## User Journey

### Current State (The Problem)

Multiple Claude Code agents working in the same directory create git conflicts:
1. Agent A makes changes, commits
2. Agent B makes changes, commits
3. Agent A reverts its work (fixing a bug) - accidentally undoes Agent B's work
4. Git history becomes a tangled mess of interleaved commits
5. Squash merging is impossible because commits aren't grouped by feature

### Target State (The Solution)

Each Claude agent operates in an isolated worktree:
1. User initiates GSD phase execution
2. GSD creates worktree with feature branch (`git worktree add ../project-feature-x -b feature/phase-01-x`)
3. Agent works in complete isolation - all commits on its own branch
4. When phase completes, GSD squash-merges the feature branch to master
5. Clean history: one squashed commit per phase, traceable to the work done

### Workflow Sequence

```
User: /gsd:execute-phase phase-01-auth

GSD Orchestrator:
  1. Check if worktree needed (yes for execution phases)
  2. Create branch: feature/phase-01-auth
  3. Create worktree: ../_dotfiles-phase-01-auth/
  4. Change working directory to worktree
  5. Execute phase plan
  6. On completion: squash-merge to master
  7. Clean up worktree
  8. Return user to main directory

Result: Clean commit on master like:
  "feat(phase-01): implement auth system [squashed from 47 commits]"
```

---

## Table Stakes

Must-have features for this to be usable. Missing = workflow broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Automatic worktree creation** | Core isolation mechanism | Medium | `git worktree add` with branch naming convention |
| **Automatic worktree cleanup** | Prevent directory sprawl | Low | `git worktree remove` + `git worktree prune` |
| **Squash merge on completion** | Clean history goal | Low | `git merge --squash` + commit with summary |
| **Branch per phase** | Isolate phase work | Low | Naming: `feature/phase-{id}` |
| **Directory naming convention** | Predictable locations | Low | Sibling dirs: `../{project}-{phase}/` |
| **Graceful failure handling** | Recovery from crashes | Medium | Detect orphaned worktrees, offer cleanup |
| **Conflict detection before merge** | Prevent bad squashes | Medium | Check for conflicts, pause if found |
| **Works without node_modules** | Dotfiles is Ansible, no deps | Low | No npm install step needed |

### Critical Path Features

1. **Worktree creation** - Without this, no isolation
2. **Branch naming** - Without this, can't track what's what
3. **Squash merge** - Without this, history stays messy
4. **Cleanup** - Without this, directories accumulate

---

## Differentiators

Nice-to-have workflow improvements. Enhance the experience but not blocking.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Pre-merge conflict preview** | See conflicts before they happen | Medium | `git diff main...feature` analysis |
| **Commit message aggregation** | Generate squash message from individual commits | Medium | Parse `git log` for commit messages |
| **Session renaming in worktrees** | Claude Code `/rename` auto-set | Low | Name session after phase |
| **Worktree status dashboard** | See all active worktrees | Low | `git worktree list` with phase mapping |
| **Auto-stash main changes** | Don't lose uncommitted work | Low | `git stash` before worktree switch |
| **Parallel phase execution** | Multiple phases at once | High | Multiple worktrees simultaneously |
| **Hook-based branch isolation** | GitButler-style auto-branching | High | Lifecycle hooks for per-session branches |
| **Worktree health checks** | Detect stale or broken worktrees | Low | Part of GSD startup |
| **Phase-specific CLAUDE.md** | Customize behavior per phase | Low | Copy/symlink base config |

### High-Value Differentiators (Recommend for v1.1)

1. **Commit message aggregation** - Makes squash messages meaningful
2. **Worktree status dashboard** - Visibility into parallel work
3. **Auto-stash main changes** - Prevents accidental data loss

---

## Anti-Features

Things to deliberately NOT build. Either dangerous, complex, or wrong approach.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Automatic rebase** | Risk of history rewriting, data loss | Use squash merge only (forward-only) |
| **Force push to remote** | Destructive, affects other users | Only push with `--force-with-lease` if at all |
| **Auto-delete branches on remote** | Can't recover if merge fails | Manual cleanup after verification |
| **Shared worktrees between agents** | Defeats isolation purpose | One worktree per agent, always |
| **npm install in worktrees** | Not needed for this project, adds complexity | Skip for Ansible-based project |
| **Complex merge strategies** | Hard to debug, unpredictable | Simple squash merge only |
| **Interactive rebase** | Not automatable, requires user input | Use `--squash` flag instead |
| **Worktrees inside project dir** | Git confusion, nested repos | Sibling directories only |
| **Global worktree manager** | Scope creep, over-engineering | GSD-specific, project-local |
| **Auto-resolve conflicts** | AI conflict resolution is error-prone | Stop and notify user |

### Most Important Anti-Features

1. **Never auto-resolve conflicts** - Always stop and ask the user
2. **Never force push** - Protect shared history
3. **Never put worktrees inside project** - Causes git confusion

---

## GSD Integration Points

How this integrates with existing GSD workflow.

### Phase Execution Changes

```
Current GSD execute-phase:
  1. Read phase plan
  2. Execute tasks
  3. Commit as you go (in main directory)

New GSD execute-phase with worktrees:
  1. Read phase plan
  2. [NEW] Create worktree for phase
  3. [NEW] cd to worktree
  4. Execute tasks
  5. Commit as you go (in worktree, on feature branch)
  6. [NEW] On completion: squash-merge to master
  7. [NEW] Clean up worktree
  8. [NEW] Return to main directory
```

### GSD Commands Affected

| Command | Change Needed |
|---------|---------------|
| `/gsd:execute-phase` | Add worktree creation/cleanup/merge |
| `/gsd:status` | Show active worktrees |
| `/gsd:cleanup` | Clean orphaned worktrees |

### GSD Files Potentially Affected

| File | Change |
|------|--------|
| `execute-phase.md` | Add worktree orchestration logic |
| `STATE.md` | Track active worktrees per project |
| New: `WORKTREES.md` | Document worktree conventions |

---

## Feature Dependencies

```
Worktree Creation
    └── Branch Naming Convention
        └── Directory Naming Convention

Squash Merge
    └── Conflict Detection
        └── Graceful Failure Handling

Cleanup
    └── Worktree Health Checks
        └── Orphan Detection
```

### Implementation Order

Based on dependencies:

1. **Directory and branch naming conventions** (no code, just decisions)
2. **Worktree creation** (basic `git worktree add`)
3. **Worktree cleanup** (basic `git worktree remove`)
4. **Conflict detection** (check before merge)
5. **Squash merge** (the payoff)
6. **GSD integration** (wire it all together)

---

## MVP Recommendation

For v1.1, prioritize:

1. **Automatic worktree creation** - Core feature
2. **Branch naming convention** - `feature/phase-{id}`
3. **Directory naming** - `../{project}-{phase}/`
4. **Squash merge on completion** - The whole point
5. **Automatic cleanup** - Prevent sprawl
6. **Basic conflict detection** - Stop if conflicts exist

Defer to post-v1.1:

- **Parallel phase execution** - Complex, not urgent
- **Hook-based auto-branching** - GitButler integration is separate
- **Worktree health dashboard** - Nice but not critical
- **Commit message aggregation** - Can manually write squash messages

---

## Sources

### Official Documentation (HIGH confidence)

- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) - Lifecycle events and configuration
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows) - Git worktree patterns
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Anthropic's recommendations

### Community Patterns (MEDIUM confidence, verified with official docs)

- [Nick Mitchinson: Git Worktrees for Multi-Feature Development with AI Agents](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/)
- [Agent Interviews: Parallel AI Coding with Git Worktrees](https://docs.agentinterviews.com/blog/parallel-ai-coding-with-gitworktrees/)
- [Nx Blog: How Git Worktrees Changed My AI Agent Workflow](https://nx.dev/blog/git-worktrees-ai-agents)
- [GitButler: Claude Code Hooks for Branch Management](https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks/)
- [Simon Willison: Embracing the Parallel Coding Agent Lifestyle](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)

### Git Documentation (HIGH confidence)

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Official git reference
- [DataCamp: Git Worktree Tutorial](https://www.datacamp.com/tutorial/git-worktree-tutorial) - Commands and patterns

### Known Limitations Research (MEDIUM confidence)

- [Lobsters Discussion: Git Worktree Issues](https://lobste.rs/s/ikbbnt/how_i_use_git_worktrees) - node_modules and dependency gotchas
- [GitHub Issue #16293](https://github.com/anthropics/claude-code/issues/16293) - Built-in auto-commit safety settings request

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Git worktree mechanics | HIGH | Official git documentation, well-established feature |
| Claude Code hooks | HIGH | Official documentation verified via WebFetch |
| Community patterns | MEDIUM | Multiple sources agree, but not official Anthropic guidance |
| GSD integration points | MEDIUM | Based on understanding of GSD, not yet validated |
| Feature priorities | MEDIUM | Based on stated project goals, may need adjustment |
