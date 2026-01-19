# Pitfalls Research: Git Worktree Multi-agent Isolation

**Domain:** Multi-agent Claude Code with git worktree isolation
**Researched:** 2026-01-19
**Confidence:** HIGH (official git docs, community experiences, Claude Code specific articles)

## Worktree-Specific Pitfalls

Issues inherent to git worktree mechanics.

### Pitfall W1: Branch Already Checked Out Error

**What goes wrong:** `fatal: 'branch' is already checked out at '/path/to/other/worktree'`

**Why it happens:** Git enforces that each branch can only be checked out in one worktree at a time. This is a safety feature to prevent conflicting edits, but surprises developers trying to work on the same branch.

**Warning signs:**
- Attempting to create worktree for existing branch
- Forgetting which worktree has which branch

**Prevention:**
```bash
# Always check existing worktrees first
git worktree list

# Create worktrees with NEW branches (preferred pattern)
git worktree add -b feat/agent-1-auth ../agent-1-auth main
git worktree add -b feat/agent-2-api ../agent-2-api main

# Never reuse branches - each worktree gets a fresh branch
```

**Recovery:**
```bash
# If you need to move a branch to a different worktree
git worktree remove /old/path
git worktree add /new/path existing-branch
```

**Phase to address:** Phase 1 (Setup) - build this check into worktree creation scripts

**Sources:**
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Graph AI Git Worktree Guide](https://www.graphapp.ai/blog/how-to-use-git-worktree-a-step-by-step-example)

---

### Pitfall W2: Bare Repository Remote Fetch Broken

**What goes wrong:** `git fetch` doesn't fetch any branches in a bare repo setup.

**Why it happens:** When cloning with `--bare`, git doesn't set up `remote.origin.fetch` configuration. The standard worktree-with-bare-repo pattern breaks silently.

**Warning signs:**
- Remote branches not appearing after fetch
- `git branch -r` shows nothing despite successful fetch

**Prevention:**
```bash
# After cloning bare, add fetch config
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

# Or use this complete setup script:
git clone --bare git@github.com:user/repo.git .bare
echo "gitdir: ./.bare" > .git
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
```

**Recovery:** Simply add the missing config line and fetch again.

**Phase to address:** Phase 1 (Setup) - include in bare repo initialization automation

**Sources:**
- [Workarounds for Bare Repository Fetch Issues](https://morgan.cugerone.com/blog/workarounds-to-git-worktree-using-bare-repository-and-cannot-fetch-remote-branches/)
- [Git Worktree with Bare Repo Pattern](https://blog.cryptomilk.org/2023/02/10/sliced-bread-git-worktree-and-bare-repo/)

---

### Pitfall W3: Moved Worktree Breaks Links

**What goes wrong:** After moving a worktree directory, git commands fail with confusing errors about missing paths.

**Why it happens:** Worktrees maintain symlinks/references to the main `.git` directory. Moving the directory breaks these references without updating the metadata.

**Warning signs:**
- Errors about `.git/worktrees/<name>/gitdir` after mv
- `git status` fails in moved worktree

**Prevention:**
```bash
# ALWAYS use git worktree move, never mv
git worktree move ../old-location ../new-location
```

**Recovery:**
```bash
# Run from inside the moved worktree
git worktree repair

# Or run from main worktree to repair all
git worktree repair /path/to/moved/worktree
```

**Phase to address:** Documentation - include in usage guidelines

**Sources:**
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)

---

### Pitfall W4: .git is a File, Not a Directory

**What goes wrong:** Scripts that assume `.git` is a directory break in worktrees.

**Why it happens:** In worktrees, `.git` is a file containing `gitdir: /path/to/.git/worktrees/<name>`. Scripts using `cat .git/config` or modifying `.git/hooks` directly fail.

**Warning signs:**
- Scripts error with "Not a directory"
- Hooks installed in worktree don't work

**Prevention:**
```bash
# Use git rev-parse to get correct paths
GIT_DIR=$(git rev-parse --git-dir)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir)

# For hooks (shared across worktrees):
HOOKS_DIR=$(git rev-parse --git-path hooks)

# For worktree-specific data:
git rev-parse --git-dir  # Returns worktree-specific dir
```

**Recovery:** Update scripts to use `git rev-parse` instead of hardcoded paths.

**Phase to address:** Phase 2 (Integration) - audit any existing git automation scripts

**Sources:**
- [DataCamp Git Worktree Tutorial](https://www.datacamp.com/tutorial/git-worktree-tutorial)

---

### Pitfall W5: Orphaned Worktree Metadata

**What goes wrong:** Deleted worktree directories leave stale metadata, cluttering `git worktree list` and causing confusion.

**Why it happens:** Using `rm -rf` on a worktree directory instead of `git worktree remove` leaves metadata in `.git/worktrees/`.

**Warning signs:**
- `git worktree list` shows "(error)" or "prunable" entries
- Confusion about which worktrees actually exist

**Prevention:**
```bash
# ALWAYS use proper removal
git worktree remove ../worktree-path

# For worktrees with uncommitted changes
git worktree remove --force ../worktree-path

# Run periodic cleanup
git worktree prune --dry-run  # Preview
git worktree prune            # Actually clean
```

**Recovery:**
```bash
git worktree prune
```

**Phase to address:** Phase 3 (Completion) - include prune in merge-back workflow

**Sources:**
- [Git Worktree Management](https://blog.alyssaholland.me/git-worktree)

---

### Pitfall W6: Per-Worktree Dependency Installation

**What goes wrong:** Running npm/pip/etc in new worktree fails or uses wrong versions because dependencies aren't installed.

**Why it happens:** Each worktree is an independent file tree. Node modules, Python venvs, and build artifacts don't carry over.

**Warning signs:**
- `node_modules` missing in new worktree
- Import errors for installed packages
- Tests fail with "module not found"

**Prevention:**
```bash
# Create a setup script that runs after worktree creation
#!/bin/bash
# setup-worktree.sh
WORKTREE_PATH=$1
cd "$WORKTREE_PATH"
npm install
# or: pip install -e .
# or: bundle install
```

**Recovery:** Just run dependency installation in the worktree.

**Optimization for large projects:**
```bash
# Share node_modules between worktrees (npm workspaces)
# Or use pnpm which deduplicates automatically
```

**Phase to address:** Phase 1 (Setup) - automate post-worktree setup

**Sources:**
- [Nick Nisi on Git Worktrees](https://nicknisi.com/posts/git-worktrees/)

---

### Pitfall W7: Submodule State Not Shared

**What goes wrong:** Submodules aren't initialized in new worktrees, causing missing files or build failures.

**Why it happens:** Git documents worktrees as "experimental" with submodules. Each worktree needs its own `git submodule update --init`.

**Warning signs:**
- Empty submodule directories in new worktree
- Build errors referencing submodule paths

**Prevention:**
```bash
# After creating worktree, initialize submodules
git worktree add ../new-worktree branch
cd ../new-worktree
git submodule update --init --recursive
```

**Note:** If your project uses submodules extensively, worktrees may not be the best isolation strategy.

**Phase to address:** Phase 1 (Setup) - detect submodules and warn/automate

**Sources:**
- [Git Worktree Documentation - Bugs section](https://git-scm.com/docs/git-worktree)

---

### Pitfall W8: Hooks Not Running in Worktrees

**What goes wrong:** Pre-commit hooks run in main worktree but not in linked worktrees.

**Why it happens:** Some hook managers (pre-commit, husky) install hooks to `.git/hooks`, but worktrees look for hooks via `git rev-parse --git-path hooks` which may resolve differently.

**Warning signs:**
- Hooks work in main checkout, silent in worktrees
- Linting/formatting bypassed in worktree commits

**Prevention:**
```bash
# Set core.hooksPath to shared location
git config core.hooksPath .githooks

# Or reinstall hooks in each worktree
cd ../new-worktree
pre-commit install
```

**Phase to address:** Phase 2 (Integration) - verify hook behavior across worktrees

**Sources:**
- [Pre-commit Issue #808](https://github.com/pre-commit/pre-commit/issues/808)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks/2.10.5)

---

## Multi-agent Coordination Pitfalls

Issues when multiple Claude agents work in parallel.

### Pitfall M1: Same File Modified by Multiple Agents

**What goes wrong:** Two agents edit the same file, creating conflicting changes that are hard to merge.

**Why it happens:** Without explicit coordination, agents independently decide to modify shared files (configs, utils, types).

**Warning signs:**
- Merge conflicts on shared files
- Agents referencing each other's uncommitted changes
- Context corruption when one agent's changes confuse another

**Prevention:**
```markdown
## Agent Assignment (include in each agent's CLAUDE.md)

This agent (agent-1) owns:
- /src/auth/**
- /tests/auth/**

DO NOT modify files owned by other agents:
- /src/api/** (agent-2)
- /src/ui/** (agent-3)

Shared files require coordination:
- /src/types.ts - propose changes, don't commit
- /src/config.ts - read-only
```

**Recovery:**
- Stop both agents
- Manually resolve conflicts
- Recommit with clear history

**Phase to address:** Phase 1 (Setup) - define file ownership in worktree CLAUDE.md

**Sources:**
- [Running Multiple Claude Code Sessions](https://dev.to/datadeer/part-2-running-multiple-claude-code-sessions-in-parallel-with-git-worktree-165i)
- [Managing Parallel Coding Agents](https://metacircuits.substack.com/p/managing-parallel-coding-agents-without)

---

### Pitfall M2: Outdated Worktrees Create Redundant Work

**What goes wrong:** Agent A completes a utility function. Agent B, in an outdated worktree, implements the same thing differently.

**Why it happens:** Worktrees isolate changes by design. Without explicit syncing, agents don't see each other's work.

**Warning signs:**
- Duplicate implementations discovered at merge time
- Conflicting approaches to same problem
- Wasted effort on already-solved problems

**Prevention:**
```bash
# Regularly sync worktrees with main
cd ../agent-1-worktree
git fetch origin
git rebase origin/main  # Or merge, depending on strategy

# Or: designate an "integration agent" that merges frequently
```

**Alternative strategy:** Use short-lived worktrees for small tasks, merge frequently.

**Phase to address:** Phase 2 (Integration) - define sync cadence

**Sources:**
- [Parallel AI Development Experiment](https://dev.to/aviad_rozenhek_cba37e0660/parallel-ai-development-can-5-claude-code-agents-work-independently-4a5)

---

### Pitfall M3: Review Bottleneck Negates Parallelization

**What goes wrong:** Three agents produce code in parallel, but human review becomes the bottleneck.

**Why it happens:** "AI-generated code needs to be reviewed." Multiple parallel outputs create a review pile-up that can't be processed faster than serial work would have.

**Warning signs:**
- Review queue growing faster than completion
- Merge conflicts accumulating in review
- Quality suffering due to review fatigue

**Prevention:**
- Start with 2 agents, not 10
- Use parallel agents for well-specified, low-risk tasks
- Have agents produce tests that reduce review burden
- Consider "scout" agents that explore but don't land code

**Phase to address:** Phase planning - right-size parallelization

**Sources:**
- [Simon Willison - Parallel Coding Agents](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)

---

### Pitfall M4: Cognitive Overhead Exceeds Time Savings

**What goes wrong:** Managing parallel agents takes more mental effort than serial development.

**Why it happens:** "It's like moderating two separate meetings in neighboring conference rooms - you're endlessly ping-ponging between rooms."

**Warning signs:**
- Constant context switching between agent outputs
- Missing important decisions one agent made
- Feeling overwhelmed rather than productive

**Prevention:**
- Reserve parallel work for long-running tasks where one agent can run unattended
- Use async agents (headless Claude) for background research
- Don't parallelize tasks under 30 minutes
- Let one agent run while reviewing another's output

**Phase to address:** Documentation - set expectations for when to use

**Sources:**
- [Running Multiple Claude Sessions](https://dev.to/datadeer/part-2-running-multiple-claude-code-sessions-in-parallel-with-git-worktree-165i)

---

### Pitfall M5: Token Costs Multiply

**What goes wrong:** Running three Claude sessions consumes 3x the API tokens/subscription capacity.

**Why it happens:** Each agent reads context, makes decisions, generates code. Parallelization multiplies this cost.

**Warning signs:**
- Hitting API rate limits
- Subscription quota exhausted mid-project
- Unexpected billing spikes

**Prevention:**
- Budget tokens per-agent before starting
- Use smaller tasks that complete before context grows large
- Consider cost/benefit before parallelizing

**Phase to address:** Documentation - note cost implications

**Sources:**
- [Running Multiple Claude Sessions](https://dev.to/datadeer/part-2-running-multiple-claude-code-sessions-in-parallel-with-git-worktree-165i)

---

## Merge/Conflict Pitfalls

Issues when bringing parallel work back together.

### Pitfall C1: Squash Merge Loses Granular History

**What goes wrong:** `git bisect` lands on a 2000-line squashed commit, making bug hunting impossible.

**Why it happens:** Squash merge combines all commits into one. The detailed progression is lost.

**Warning signs:**
- Large squashed commits in history
- `git bisect` becoming useless
- Difficulty understanding why changes were made

**Prevention:**
```bash
# For small features: squash is fine
git merge --squash feature-branch

# For large features: consider merge or rebase
# Or: break large features into smaller squash-mergeable chunks

# Preserve detail in PR/commit message
git merge --squash feature-branch
git commit -m "feat(auth): implement OAuth flow

Squashed commits:
- Add OAuth client configuration
- Implement token exchange
- Add refresh token handling
- Add logout flow
- Add tests for all flows

PR #123 has full commit history."
```

**Phase to address:** Phase 3 (Completion) - define when to squash vs merge

**Sources:**
- [The Agony and Ecstasy of Git Squash](https://medium.com/@gasrios/the-agony-and-the-ecstasy-of-git-squash-7f91c8da20af)
- [Squash, Merge, or Rebase?](https://mattrickard.com/squash-merge-or-rebase)

---

### Pitfall C2: Reusing Squashed Branches

**What goes wrong:** Continuing work on a branch after it's been squash-merged creates duplicate commit conflicts.

**Why it happens:** After squash merge, the feature branch commits still exist but main doesn't know about them (different SHA). Rebasing or merging that branch again replays the same changes.

**Warning signs:**
- "Already applied" conflicts during rebase
- Same changes appearing twice in history
- Confusion about what's merged

**Prevention:**
```bash
# RULE: Delete feature branches after squash merge
git merge --squash feature-branch
git commit -m "feat: the feature"
git branch -D feature-branch
git push origin --delete feature-branch

# For continued work: create NEW branch from main
git checkout -b feature-v2 main
```

**Recovery:**
```bash
# If you've already continued on a squashed branch
git checkout main
git checkout -b feature-fresh
git cherry-pick <only-new-commits>
```

**Phase to address:** Phase 3 (Completion) - enforce branch deletion after merge

**Sources:**
- [DNSimple - Two Years of Squash Merge](https://blog.dnsimple.com/2019/01/two-years-of-squash-merge/)

---

### Pitfall C3: Long-Running Branches Accumulate Conflicts

**What goes wrong:** Agent works on feature branch for days. By merge time, main has diverged significantly, creating extensive conflicts.

**Warning signs:**
- Large diff between feature branch and main
- Many files changed on both branches
- Complex merge conflicts

**Prevention:**
```bash
# Sync frequently (daily or more)
git fetch origin
git rebase origin/main
# OR
git merge origin/main

# Better: keep agent work short
# Merge daily, continue on fresh branch if needed
```

**Phase to address:** Phase 2 (Integration) - define max branch age

**Sources:**
- [Azure DevOps Merge Strategies](https://learn.microsoft.com/en-us/azure/devops/repos/git/merging-with-squash)

---

### Pitfall C4: Merge Conflicts in Shared Config Files

**What goes wrong:** Multiple agents modify package.json, tsconfig.json, or similar, creating semantic conflicts that git can't auto-resolve.

**Why it happens:** Config files are modified by many features (adding dependencies, changing settings). These are inherently shared.

**Warning signs:**
- package.json conflicts on every merge
- Lock file (package-lock.json) conflicts

**Prevention:**
- Designate one agent as "integration owner" for config files
- Other agents propose config changes, don't commit them
- Or: merge config changes first, before feature work

```markdown
## Shared File Policy

These files are integration-only:
- package.json
- tsconfig.json
- .eslintrc.js

To add a dependency:
1. Document needed dependency in your PR description
2. Integration phase will add it before your branch merges
```

**Phase to address:** Phase 1 (Setup) - define shared file policy

**Sources:**
- [Managing Parallel Coding Agents](https://metacircuits.substack.com/p/managing-parallel-coding-agents-without)

---

## Claude-Specific Pitfalls

Issues specific to Claude Code agents in worktrees.

### Pitfall CL1: Claude Doesn't Know About Other Agents

**What goes wrong:** Claude in worktree-1 doesn't know worktree-2 exists or what it's working on.

**Why it happens:** Each Claude instance has isolated context. There's no built-in inter-agent communication.

**Warning signs:**
- Agents implementing conflicting approaches
- Agents duplicating effort
- No awareness of overall project state

**Prevention:**
```markdown
## Multi-Agent Context (include in each CLAUDE.md)

You are agent-1 working on authentication.

Other agents currently active:
- agent-2: Working on API endpoints in ../agent-2-worktree
- agent-3: Working on UI components in ../agent-3-worktree

Coordination:
- Shared types go in /src/shared/ - propose, don't commit
- If you need API changes, note in HANDOFF.md
- Check HANDOFF.md for pending coordination items
```

**Phase to address:** Phase 1 (Setup) - include multi-agent context in worktree CLAUDE.md

---

### Pitfall CL2: Worktree Setup Overhead Discourages Use

**What goes wrong:** Developers skip worktree isolation because setup is tedious.

**Why it happens:** Creating worktree + installing deps + configuring Claude takes time. For 10-minute tasks, it's not worth it.

**Warning signs:**
- Running parallel agents in same directory anyway
- File conflicts despite knowing better
- "I'll just be careful" thinking

**Prevention:**
```bash
# Create a script that automates everything
#!/bin/bash
# new-agent-worktree.sh
BRANCH_NAME=$1
WORKTREE_PATH="../$BRANCH_NAME"

git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" main
cd "$WORKTREE_PATH"
npm install
cp ../main/.claude/settings.local.json .claude/

echo "Worktree ready at $WORKTREE_PATH"
```

**Phase to address:** Phase 1 (Setup) - create automation scripts

---

### Pitfall CL3: Claude Makes Git Commits in Wrong Worktree

**What goes wrong:** Claude commits to wrong branch or pushes from wrong worktree.

**Why it happens:** With multiple terminal windows open, it's easy to run Claude in the wrong directory.

**Warning signs:**
- Commits appearing on wrong branch
- Work mixed between agents

**Prevention:**
- Include branch name in terminal prompt
- Use tmux/terminal titles showing worktree
- Add worktree path to Claude's CLAUDE.md context

```bash
# In .bashrc/.zshrc
export PS1='$(git branch --show-current 2>/dev/null || echo "no-git") \$ '
```

**Phase to address:** Documentation - include terminal setup recommendations

---

### Pitfall CL4: Claude --no-verify Bypasses Worktree Hooks

**What goes wrong:** Claude uses `git commit --no-verify`, bypassing pre-commit hooks even in worktrees.

**Why it happens:** This is existing Claude behavior (Pitfall #2 from v1.0 research). Worktrees don't change this.

**Warning signs:**
- CI failures after Claude commits
- Linting errors in committed code

**Prevention:** Same as v1.0 research - deny direct git commit, use controlled commit flow.

```json
{
  "permissions": {
    "deny": ["Bash(git commit:*)"]
  }
}
```

**Phase to address:** Phase 2 (Integration) - apply existing controls to worktree workflow

---

## GSD Integration Pitfalls

Issues specific to GSD workflow integration.

### Pitfall GSD1: Phase Execution Without Worktree Creation

**What goes wrong:** Agent starts execute-phase in main directory, making changes directly to main branch.

**Why it happens:** GSD workflow doesn't currently create worktrees automatically.

**Warning signs:**
- Phase commits going to main instead of feature branch
- Multiple phases interfering with each other

**Prevention:**
```markdown
## GSD Workflow Rule

BEFORE starting execute-phase:
1. Create worktree: git worktree add -b phase-N ../phase-N main
2. cd ../phase-N
3. THEN run execute-phase
```

Or: modify execute-phase command to auto-create worktree.

**Phase to address:** Phase 2 (Integration) - modify GSD execute-phase

---

### Pitfall GSD2: Phase Completion Without Proper Merge

**What goes wrong:** Phase completes but changes stay in worktree, never merged to main.

**Why it happens:** Forgetting the merge step, or merge conflicts blocking completion.

**Warning signs:**
- Completed phases with unmerged worktrees
- Growing collection of stale worktrees
- Features "done" but not in main

**Prevention:**
```markdown
## Phase Completion Checklist

1. All tests passing in worktree
2. Code reviewed (if applicable)
3. Merge to main: git checkout main && git merge --squash ../phase-N
4. Delete worktree: git worktree remove ../phase-N
5. Update GSD state
```

**Phase to address:** Phase 3 (Completion) - create completion workflow

---

### Pitfall GSD3: Squash Loses Phase History

**What goes wrong:** After squash merge, can't tell which changes came from which phase.

**Why it happens:** Squash combines all phase commits into one main commit.

**Prevention:**
```bash
# Include phase info in squash commit message
git merge --squash ../phase-auth
git commit -m "feat(auth): implement authentication system

GSD Phase: 01-auth
Plan: .planning/phases/01-auth/PLAN.md

Changes:
- OAuth2 client implementation
- Token refresh handling
- Session management
- Integration tests

Squashed from phase branch: feat/phase-01-auth"
```

**Phase to address:** Phase 3 (Completion) - template for squash commit messages

---

## Prevention Checklist

Summary of how to avoid each issue.

### Setup Phase

- [ ] Configure bare repo with remote.origin.fetch if using bare pattern
- [ ] Create automation script for worktree + deps + Claude config
- [ ] Define file ownership per agent in CLAUDE.md
- [ ] Include multi-agent context in each worktree's CLAUDE.md
- [ ] Set up submodule automation if project uses submodules
- [ ] Verify hooks work across worktrees

### During Development

- [ ] Never `mv` worktrees - use `git worktree move`
- [ ] Never `rm -rf` worktrees - use `git worktree remove`
- [ ] Sync worktrees with main regularly (daily minimum)
- [ ] Use `git worktree list` to track active worktrees
- [ ] Keep parallel agents to 2-3 maximum
- [ ] Don't parallelize tasks under 30 minutes

### Completion Phase

- [ ] Run `git worktree prune` after removing worktrees
- [ ] Delete feature branches after squash merge
- [ ] Include phase/context in squash commit messages
- [ ] Update GSD state after merge
- [ ] Clear orphaned worktree metadata

### General

- [ ] Use git rev-parse for paths, not hardcoded .git
- [ ] Budget tokens before parallelizing
- [ ] Right-size parallelization for review capacity
- [ ] Designate integration owner for shared files

## Sources

### Official Documentation
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Authoritative reference
- [Git Merge Documentation](https://git-scm.com/docs/git-merge)

### Worktree Patterns
- [Nick Nisi - How I Use Git Worktrees](https://nicknisi.com/posts/git-worktrees/)
- [Morgan Cugerone - Git Worktree in a Clean Way](https://morgan.cugerone.com/blog/how-to-use-git-worktree-and-in-a-clean-way/)
- [Chris Dzombak - Tool for Working with Git Worktrees](https://www.dzombak.com/blog/2025/10/a-tool-for-working-with-git-worktrees/)
- [Safia Rocks - Git Worktrees for Fun and Profit](https://blog.safia.rocks/2025/09/03/git-worktrees/)

### Multi-Agent Development
- [Running Multiple Claude Code Sessions in Parallel](https://dev.to/datadeer/part-2-running-multiple-claude-code-sessions-in-parallel-with-git-worktree-165i)
- [Simon Willison - Parallel Coding Agent Lifestyle](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)
- [Managing Parallel Coding Agents](https://metacircuits.substack.com/p/managing-parallel-coding-agents-without)
- [Parallel AI Development Experiment](https://dev.to/aviad_rozenhek_cba37e0660/parallel-ai-development-can-5-claude-code-agents-work-independently-4a5)
- [Steve Kinney - Git Worktrees for Parallel AI Development](https://stevekinney.com/courses/ai-development/git-worktrees)
- [Git Worktrees for Multiple AI Agents](https://medium.com/@mabd.dev/git-worktrees-the-secret-weapon-for-running-multiple-ai-coding-agents-in-parallel-e9046451eb96)

### Merge Strategies
- [DNSimple - Two Years of Squash Merge](https://blog.dnsimple.com/2019/01/two-years-of-squash-merge/)
- [The Agony and Ecstasy of Git Squash](https://medium.com/@gasrios/the-agony-and-the-ecstasy-of-git-squash-7f91c8da20af)
- [Atlassian - Merge Strategy Options](https://www.atlassian.com/git/tutorials/using-branches/merge-strategy)
- [Azure DevOps - Merge Strategies](https://learn.microsoft.com/en-us/azure/devops/repos/git/merging-with-squash)

### GitHub Issues / Known Problems
- [Pre-commit Issue #808 - Hooks in Worktrees](https://github.com/pre-commit/pre-commit/issues/808)
- [Claude Code Issue #4963 - Worktree Orchestration Request](https://github.com/anthropics/claude-code/issues/4963)
- [Claude Code Issue #10599 - Multi-Agent Workflows Request](https://github.com/anthropics/claude-code/issues/10599)
