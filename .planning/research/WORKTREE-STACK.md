# Stack Research: Git Worktree Multi-agent Isolation

**Domain:** Multi-agent development isolation for Claude Code
**Researched:** 2026-01-19
**Overall Confidence:** HIGH

## Executive Summary

Git worktree is the right tool for multi-agent isolation. It's built into Git (available since v2.5, current is v2.52), requires no additional dependencies, and provides true filesystem isolation while sharing Git history. The ecosystem has matured significantly in 2024-2025 with AI coding assistants driving adoption.

**Recommendation:** Use native git worktree commands with a thin shell wrapper for consistency. Avoid heavy tooling like workmux unless you need tmux integration. The GSD integration should handle worktree lifecycle (create on phase start, merge on completion).

## Core Technology

### Git Worktree (Built-in)

| Property | Value |
|----------|-------|
| Minimum Version | Git 2.5+ |
| Current Version | Git 2.52 (installed) |
| Documentation | `man git-worktree` |

**What it provides:**
- Multiple checked-out branches in separate directories
- Shared `.git` directory (history, remotes, hooks)
- Independent working directory, index, HEAD per worktree
- Automatic prevention of checking out same branch in multiple worktrees

**What it shares across worktrees:**
- Object database (commits, blobs, trees)
- Refs (branches, tags) - except `refs/bisect`, `refs/worktree`, `refs/rewritten`
- Remote configuration
- Git hooks (from `.git/hooks`)
- Global and repo-level config

**What is per-worktree:**
- Working directory (files)
- Index (staging area)
- HEAD (current branch reference)
- `config.worktree` (if `extensions.worktreeConfig` enabled)

## Key Commands

### Worktree Lifecycle

```bash
# Create worktree with new branch (most common)
git worktree add ../project-feature -b feature/my-feature

# Create worktree from existing branch
git worktree add ../project-bugfix bugfix-123

# Create worktree at specific commit (detached HEAD)
git worktree add -d ../project-experiment HEAD

# List all worktrees
git worktree list

# Remove worktree (must be clean)
git worktree remove ../project-feature

# Force remove dirty worktree
git worktree remove -f ../project-feature

# Clean up stale worktree metadata
git worktree prune
```

### Merge Strategies

```bash
# Squash merge (recommended for clean history)
cd /path/to/main/repo
git merge --squash feature/my-feature
git commit -m "feat: implement my feature"

# Regular merge with merge commit
git merge --no-ff feature/my-feature

# After merge, cleanup
git worktree remove ../project-feature
git branch -d feature/my-feature
```

### Full Workflow Example

```bash
# 1. Create isolated worktree for agent
TASK="auth-refactor"
git worktree add "../$(basename $(pwd))-${TASK}" -b "agent/${TASK}"

# 2. Agent works in worktree
cd "../$(basename $(pwd))-${TASK}"
claude  # Agent works here with autocommit

# 3. After completion, squash merge to master
cd /path/to/main/repo
git merge --squash "agent/${TASK}"
git commit -m "feat: ${TASK} - squashed from agent work"

# 4. Cleanup
git worktree remove "../$(basename $(pwd))-${TASK}"
git branch -d "agent/${TASK}"
```

## Directory Structure Recommendation

**Pattern:** Sibling directories with consistent naming

```
~/projects/
  _dotfiles/                    # Main worktree (master)
  _dotfiles-agent-auth/         # Agent worktree 1
  _dotfiles-agent-config/       # Agent worktree 2
```

**Naming convention:** `{repo}-agent-{task-slug}`

This pattern:
- Keeps worktrees adjacent to main repo (easy navigation)
- Self-documents what each worktree is for
- Avoids nested directories (prevents confusion)
- Uses slugified task names (no spaces, lowercase)

## Helper Tooling

### Recommended: Thin Shell Wrapper

Create a simple shell function rather than adopting heavy tooling. This integrates naturally with your existing Ansible/zsh setup.

```bash
# ~/.zshrc or tools/git-worktree/git-worktree.zsh

# Create agent worktree
gsd-worktree-add() {
    local task="$1"
    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local worktree_path="${repo_root}/../${repo_name}-agent-${task}"
    local branch_name="agent/${task}"

    git worktree add "${worktree_path}" -b "${branch_name}"
    echo "Created worktree at ${worktree_path}"
    echo "Branch: ${branch_name}"
}

# Squash merge and cleanup
gsd-worktree-merge() {
    local task="$1"
    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local worktree_path="${repo_root}/../${repo_name}-agent-${task}"
    local branch_name="agent/${task}"

    # Must be in main worktree
    git merge --squash "${branch_name}"
    git commit -m "feat: ${task} (squashed from agent work)"

    git worktree remove "${worktree_path}"
    git branch -d "${branch_name}"
    echo "Merged and cleaned up ${task}"
}

# List active agent worktrees
gsd-worktree-list() {
    git worktree list | grep "agent/"
}
```

### Optional: workmux (If Using tmux Heavily)

If tmux is central to your workflow, [workmux](https://github.com/raine/workmux) provides:
- Automatic tmux window per worktree
- Configurable pane layouts
- Built-in merge strategies (merge, rebase, squash)
- Post-create lifecycle hooks

Install: `cargo install workmux`

Configuration (`.workmux.yaml`):
```yaml
main_branch: master
merge_strategy: squash
window_prefix: "wm-"
files:
  copy:
    - .env
    - .claude/settings.local.json
  symlink:
    - node_modules
post_create:
  - npm install
```

**However:** For this dotfiles project, a thin wrapper is better because:
1. Less dependencies to manage
2. Clearer integration with GSD
3. No tmux requirement for headless/CI use

### Not Recommended: Heavy Wrappers

Avoid tools that:
- Require complex configuration
- Add abstraction over simple git commands
- Don't expose underlying git operations
- Have external service dependencies

## Integration Points

### GSD Integration

The GSD execute-phase agent should:

1. **On phase start:**
   ```bash
   # Create worktree for agent work
   git worktree add "../repo-agent-phase-N" -b "agent/phase-N-description"
   cd "../repo-agent-phase-N"
   ```

2. **During execution:**
   - Agent autocommits within worktree
   - All changes isolated from master
   - Session state preserved per directory

3. **On phase completion:**
   ```bash
   # Return to main repo
   cd /path/to/main/repo

   # Squash merge
   git merge --squash "agent/phase-N-description"
   git commit -m "Phase N: description (squashed)"

   # Cleanup
   git worktree remove "../repo-agent-phase-N"
   git branch -d "agent/phase-N-description"
   ```

### Git Hooks

Hooks are shared across worktrees (they live in `.git/hooks`). Consider:

**post-checkout hook** for worktree setup:
```bash
#!/bin/bash
# .git/hooks/post-checkout

# $1 = previous HEAD, $2 = new HEAD, $3 = flag (1=branch checkout, 0=file checkout)
# When $1 is 0000... it's a new worktree

if [[ "$1" == "0000000000000000000000000000000000000000" ]]; then
    echo "New worktree detected, running setup..."
    # Copy .env files, run npm install, etc.
    if [[ -f "../$(basename $(pwd) | sed 's/-agent-.*$//')/.env" ]]; then
        cp "../$(basename $(pwd) | sed 's/-agent-.*$//')/.env" .env
    fi
fi
```

**Shared hooks directory** (if using custom hooks path):
```bash
# Set absolute path for hooks (required for worktrees)
git config core.hooksPath "$(git rev-parse --show-toplevel)/_hooks"
```

### Claude Code Session Management

Claude Code tracks sessions per directory. Benefits:
- `/resume` picker shows sessions from same repo including worktrees
- Sessions filter by git branch
- Named sessions (`/rename task-name`) help identify work

**Recommended Claude Code usage:**
```bash
cd ../repo-agent-task
claude
> /rename task-description
# ... agent works ...
```

### Autocommit Awareness

Claude Code does not have built-in autocommit settings (as of 2026-01). The worktree pattern itself provides safety:
- Work in worktrees, not master
- Squash merge means master stays clean
- Agent commits don't clutter master history

If autocommit is needed, use git hooks or wrapper scripts rather than relying on Claude Code settings.

**GitHub Issue #16293** tracks the feature request for built-in autocommit settings. Current workaround options:
1. Custom `PostToolUse` hooks that commit after file changes
2. Periodic commit scripts
3. Session-end hooks that commit pending changes

## What to Avoid

### Anti-Pattern 1: Same Branch in Multiple Worktrees
```bash
# BAD - Git prevents this by default
git worktree add ../other-dir master  # Fails if master is checked out
```
Git protects against this. Don't use `--force` to bypass it.

### Anti-Pattern 2: Nested Worktrees
```bash
# BAD - Creates confusion
cd /repo
git worktree add ./worktrees/feature  # Inside repo directory
```
Always use sibling directories (`../repo-feature`).

### Anti-Pattern 3: Long-Lived Worktrees
Worktrees should be temporary. Create for a task, merge when done, delete.
```bash
# BAD - Stale worktrees accumulate
git worktree list
# Shows worktrees from 3 months ago
```
Clean up after each task completes.

### Anti-Pattern 4: Overlapping File Changes
```bash
# BAD - Two agents editing same files
# Agent 1 in worktree-A edits auth.ts
# Agent 2 in worktree-B edits auth.ts
```
Ensure parallel agents work on **different files**. File overlap creates merge hell.

### Anti-Pattern 5: Forgetting npm install / Setup
Each worktree is a fresh directory. Run setup:
```bash
cd ../repo-agent-task
npm install  # or equivalent
# Then start Claude
```

### Anti-Pattern 6: Manual Deletion Without git worktree remove
```bash
# BAD - Leaves stale metadata
rm -rf ../repo-agent-task

# GOOD
git worktree remove ../repo-agent-task
# or if already deleted:
git worktree prune
```

### Anti-Pattern 7: Force-Pushing from Worktree
Never force-push branches from worktrees. Use regular push or `--force-with-lease`.

### Anti-Pattern 8: Committing to Master from Worktree
```bash
# BAD - Defeats isolation purpose
cd ../repo-agent-task
git checkout master  # Don't do this
```
Stay on the agent branch. Merge happens from main repo.

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Git worktree commands | HIGH | Official git documentation, man pages |
| Directory structure | HIGH | Multiple production teams (incident.io) use this pattern |
| Squash merge workflow | HIGH | Standard git workflow, well-documented |
| Claude Code integration | HIGH | Official Anthropic documentation |
| Autocommit status | HIGH | Verified via GitHub issue #16293 (no built-in feature) |
| Helper tooling | MEDIUM | workmux is good but may be overkill for this use case |

## Sources

### Official Documentation
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Authoritative command reference
- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows) - Anthropic's official worktree guidance

### Production Usage Patterns
- [incident.io: Shipping faster with Claude Code and Git Worktrees](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) - Real team workflow (4-5 parallel agents)
- [Steve Kinney: Git Worktrees for AI Development](https://stevekinney.com/courses/ai-development/git-worktrees) - Best practices guide
- [Bala's Blog: Why Git Worktrees Beat Switching Branches](https://blog.balakumar.dev/2025/09/25/why-git-worktrees-beat-switching-branches-especially-with-ai-cli-agents/) - CLI agent patterns

### Tooling
- [workmux GitHub](https://github.com/raine/workmux) - tmux + worktree manager (Rust CLI)
- [Git Worktree Reference Gist](https://gist.github.com/induratized/49cdedace4a200fa8ae32db9ba3e9a44) - Command reference

### Community Patterns
- [Medium: Parallel Workflows with Multiple AI Agents](https://medium.com/@dennis.somerville/parallel-workflows-git-worktrees-and-the-art-of-managing-multiple-ai-agents-6fa3dc5eec1d) - Multi-agent coordination
- [Claude Code GitHub Issue #16293](https://github.com/anthropics/claude-code/issues/16293) - Autocommit feature request (confirms no built-in feature)
- [DataCamp: Git Worktree Tutorial](https://www.datacamp.com/tutorial/git-worktree-tutorial) - Step-by-step guide
