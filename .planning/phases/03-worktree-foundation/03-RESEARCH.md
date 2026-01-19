# Phase 3: Worktree Foundation - Research

**Researched:** 2026-01-19
**Domain:** Git worktree shell commands for multi-agent isolation
**Confidence:** HIGH

## Summary

Phase 3 implements shell commands for git worktree management. The target is Zsh functions that provide a simple interface for creating, listing, removing, and merging git worktrees. These commands will enable the parallel feature development workflow in later phases.

Prior research in `.planning/research/WORKTREE-STACK.md` and `PITFALLS.md` extensively covers the git worktree domain. This phase-specific research focuses on **implementation details**: how to structure the shell commands within this dotfiles repo's patterns, cross-platform compatibility, and conflict detection mechanisms.

**Primary recommendation:** Create a new `tools/gsd-worktree/` directory with:
- `gsd-worktree.zsh` containing the four shell functions
- `install_gsd-worktree.yml` Ansible playbook to deploy the config
- Follow existing tool patterns from `git.zsh`, `lazygit.zsh`

## Standard Stack

The established tools for this implementation:

### Core (No External Dependencies)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| git worktree | 2.5+ (current: 2.52) | Worktree operations | Built into git, no deps |
| Zsh functions | Native | Shell interface | Target shell per CLAUDE.md |
| Ansible blockinfile | Native | Deploy config | Per dotfiles convention |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `git merge-base` | Find common ancestor | Conflict detection |
| `git diff --quiet` | Check for uncommitted changes | Pre-merge validation |
| `git merge --squash --no-commit` | Test merge | Dry-run conflict detection |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Zsh functions | Bash scripts | Less portable; dotfiles uses Zsh |
| Built-in git | workmux | Extra dependency; overkill for this use case |
| Sibling dirs | .trees/ subdirectory | Prior research recommends sibling; better isolation |

**Installation:** No installation needed - shell functions sourced via zshrc.

## Architecture Patterns

### Recommended Project Structure

```
tools/
  gsd-worktree/
    gsd-worktree.zsh           # Shell functions (4 commands)
    install_gsd-worktree.yml   # Ansible deployment playbook
```

### Pattern 1: Zsh Function with Local Variables

**What:** All functions use `local` for variables to prevent scope pollution
**When to use:** Always in Zsh functions
**Source:** [Zsh Best Practices](https://gist.github.com/ChristopherA/562c2e62d01cf60458c5fa87df046fbd)

```zsh
gsd-worktree-add() {
    local name="$1"
    local repo_root repo_name worktree_path branch_name

    # Validate input
    if [[ -z "$name" ]]; then
        echo "Usage: gsd-worktree-add <name>" >&2
        return 1
    fi

    # Get repo info
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    repo_name=$(basename "$repo_root")
    worktree_path="${repo_root}/../${repo_name}-${name}"
    branch_name="worktree/${name}"

    # Create worktree with new branch
    if git worktree add "$worktree_path" -b "$branch_name"; then
        echo "Created worktree: $worktree_path"
        echo "Branch: $branch_name"
        echo ""
        echo "To start working:"
        echo "  cd $worktree_path"
    else
        return 1
    fi
}
```

### Pattern 2: Conflict Detection Before Merge

**What:** Dry-run merge to detect conflicts before actual merge
**When to use:** Before gsd-worktree-merge
**Source:** [Git Merge Documentation](https://git-scm.com/docs/git-merge)

```zsh
_gsd-worktree-check-conflicts() {
    local branch="$1"
    local has_conflicts=0

    # Stash any uncommitted changes
    git stash push -q -m "gsd-worktree-merge-check" 2>/dev/null

    # Try merge with --no-commit
    if ! git merge --squash --no-commit "$branch" 2>/dev/null; then
        has_conflicts=1
    fi

    # Check for conflict markers in staged files
    if git diff --cached --name-only --diff-filter=U 2>/dev/null | grep -q .; then
        has_conflicts=1
    fi

    # Abort and restore
    git merge --abort 2>/dev/null
    git reset --hard HEAD 2>/dev/null
    git stash pop -q 2>/dev/null

    return $has_conflicts
}
```

### Pattern 3: Ansible blockinfile for Zsh Integration

**What:** Insert shell config into ~/.zshrc using markers
**When to use:** All tool shell configs in this repo
**Source:** Existing pattern in `tools/zsh/install_zsh.yml`

```yaml
- name: Install gsd-worktree shell functions
  blockinfile:
    path: ~/.zshrc
    marker: "# {mark} GSD WORKTREE"
    block: "{{ lookup('file', 'gsd-worktree.zsh') }}"
```

### Anti-Patterns to Avoid

- **Global variables in functions:** Use `local` for all function variables
- **Hardcoded paths:** Use `git rev-parse` to get repo paths dynamically
- **Silent failures:** Always output clear error messages to stderr
- **rm -rf worktrees:** Use `git worktree remove` to preserve metadata

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Find repo root | Parse `.git` manually | `git rev-parse --show-toplevel` | Handles worktrees, bare repos |
| Get branch name | Parse HEAD file | `git branch --show-current` | Handles detached HEAD |
| Check dirty state | Parse `git status` output | `git diff --quiet HEAD` | Exit code is reliable |
| List worktrees | Scan directories | `git worktree list --porcelain` | Machine-parseable format |
| Remove worktree | `rm -rf` directory | `git worktree remove` | Cleans metadata |

**Key insight:** Git has commands for almost everything. Parsing output is fragile; use exit codes and `--porcelain` flags.

## Common Pitfalls

### Pitfall 1: Branch Already Checked Out

**What goes wrong:** `fatal: 'branch' is already checked out at '/path'`
**Why it happens:** Git prevents checking out the same branch in multiple worktrees
**How to avoid:** Check `git worktree list` before creating; use unique branch names
**Warning signs:** User tries to create worktree for existing branch name

```zsh
# Prevention: Check if branch exists
if git show-ref --verify --quiet "refs/heads/worktree/${name}"; then
    echo "Error: Branch 'worktree/${name}' already exists" >&2
    echo "Use a different name or remove the existing worktree first" >&2
    return 1
fi
```

### Pitfall 2: Orphaned Worktree Metadata

**What goes wrong:** `git worktree list` shows stale entries after manual directory deletion
**Why it happens:** Using `rm -rf` instead of `git worktree remove`
**How to avoid:** Always use `git worktree remove`; run `git worktree prune` in removal function
**Warning signs:** "(error)" or "prunable" in worktree list

```zsh
# In gsd-worktree-remove
git worktree remove "$worktree_path" --force
git worktree prune  # Clean any orphaned metadata
```

### Pitfall 3: Merge Conflicts Not Detected

**What goes wrong:** User runs merge, conflicts arise, state is now dirty
**Why it happens:** No pre-check for conflicts
**How to avoid:** Dry-run merge with `--no-commit`, check for conflicts, abort
**Warning signs:** User has to manually resolve conflicts unexpectedly

### Pitfall 4: Wrong Current Directory

**What goes wrong:** Merge command run from worktree instead of main repo
**Why it happens:** User confusion about which directory to be in
**How to avoid:** Detect if in worktree, warn or switch automatically
**Warning signs:** Merge goes to wrong branch

```zsh
# Detect if in worktree vs main
_gsd-is-main-worktree() {
    local git_dir common_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    [[ "$git_dir" == "$common_dir" ]]
}
```

### Pitfall 5: Uncommitted Changes in Main Before Merge

**What goes wrong:** Squash merge fails or includes unintended changes
**Why it happens:** Main repo has uncommitted changes when merge attempted
**How to avoid:** Check for clean state before merge
**Warning signs:** Unexpected files in merge commit

## Code Examples

Verified patterns from official sources and existing codebase:

### Complete gsd-worktree-add

```zsh
# Source: git worktree documentation + zsh best practices
gsd-worktree-add() {
    local name="$1"
    local repo_root repo_name worktree_path branch_name

    if [[ -z "$name" ]]; then
        echo "Usage: gsd-worktree-add <name>" >&2
        echo "Creates: ../{repo}-{name}/ with branch worktree/{name}" >&2
        return 1
    fi

    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    repo_name=$(basename "$repo_root")
    worktree_path="${repo_root}/../${repo_name}-${name}"
    branch_name="worktree/${name}"

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        echo "Error: Branch '${branch_name}' already exists" >&2
        echo "Use 'gsd-worktree-list' to see active worktrees" >&2
        return 1
    fi

    # Check if directory already exists
    if [[ -d "$worktree_path" ]]; then
        echo "Error: Directory already exists: $worktree_path" >&2
        return 1
    fi

    # Create worktree with new branch from current HEAD
    if git worktree add "$worktree_path" -b "$branch_name"; then
        echo "Created worktree: $worktree_path"
        echo "Branch: $branch_name"
        echo ""
        echo "To start working:"
        echo "  cd \"$worktree_path\""
    else
        echo "Error: Failed to create worktree" >&2
        return 1
    fi
}
```

### Complete gsd-worktree-list

```zsh
# Source: git worktree list --porcelain format
gsd-worktree-list() {
    local repo_root repo_name

    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    repo_name=$(basename "$repo_root")

    echo "Worktrees for $repo_name:"
    echo ""

    # Filter to show only worktree/* branches (our managed ones)
    git worktree list | while read -r line; do
        if [[ "$line" == *"worktree/"* ]] || [[ "$line" == *"$repo_root "* ]]; then
            echo "  $line"
        fi
    done

    echo ""
    echo "Main: $repo_root"
}
```

### Complete gsd-worktree-remove

```zsh
# Source: git worktree remove documentation
gsd-worktree-remove() {
    local name="$1"
    local repo_root repo_name worktree_path branch_name

    if [[ -z "$name" ]]; then
        echo "Usage: gsd-worktree-remove <name>" >&2
        return 1
    fi

    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    repo_name=$(basename "$repo_root")
    worktree_path="${repo_root}/../${repo_name}-${name}"
    branch_name="worktree/${name}"

    # Check if worktree exists
    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Worktree not found: $worktree_path" >&2
        echo "Use 'gsd-worktree-list' to see active worktrees" >&2
        return 1
    fi

    # Remove worktree (--force to handle uncommitted changes)
    if git worktree remove "$worktree_path" --force; then
        echo "Removed worktree: $worktree_path"
    else
        echo "Error: Failed to remove worktree" >&2
        return 1
    fi

    # Delete the branch
    if git branch -D "$branch_name" 2>/dev/null; then
        echo "Deleted branch: $branch_name"
    fi

    # Clean up any stale metadata
    git worktree prune

    echo "Cleanup complete"
}
```

### Complete gsd-worktree-merge

```zsh
# Source: git merge --squash documentation + conflict detection pattern
gsd-worktree-merge() {
    local name="$1"
    local repo_root repo_name worktree_path branch_name
    local current_branch stash_created=0

    if [[ -z "$name" ]]; then
        echo "Usage: gsd-worktree-merge <name>" >&2
        echo "Squash merges worktree/{name} to current branch" >&2
        return 1
    fi

    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$repo_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    repo_name=$(basename "$repo_root")
    worktree_path="${repo_root}/../${repo_name}-${name}"
    branch_name="worktree/${name}"
    current_branch=$(git branch --show-current)

    # Warn if running from a worktree (not main repo)
    if ! _gsd-is-main-worktree; then
        echo "Warning: Running from a linked worktree, not the main repo" >&2
        echo "Merge will target current branch: $current_branch" >&2
        echo ""
        read -q "REPLY?Continue? [y/N] "
        echo ""
        [[ "$REPLY" == "y" ]] || return 1
    fi

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/${branch_name}"; then
        echo "Error: Branch '${branch_name}' not found" >&2
        echo "Use 'gsd-worktree-list' to see active worktrees" >&2
        return 1
    fi

    # Check for uncommitted changes
    if ! git diff --quiet HEAD 2>/dev/null; then
        echo "Error: You have uncommitted changes" >&2
        echo "Commit or stash them before merging" >&2
        return 1
    fi

    # Conflict detection (dry-run merge)
    echo "Checking for conflicts..."
    if ! _gsd-worktree-check-conflicts "$branch_name"; then
        echo "Error: Merge would cause conflicts" >&2
        echo ""
        echo "Conflicting files:"
        git merge --squash --no-commit "$branch_name" 2>/dev/null
        git diff --cached --name-only --diff-filter=U 2>/dev/null | sed 's/^/  /'
        git merge --abort 2>/dev/null
        git reset --hard HEAD 2>/dev/null
        echo ""
        echo "Resolve conflicts manually in the worktree first, or rebase" >&2
        return 1
    fi

    # Perform the actual squash merge
    echo "No conflicts detected, proceeding with merge..."
    if git merge --squash "$branch_name"; then
        echo ""
        echo "Squash merge staged. Review and commit:"
        echo "  git status"
        echo "  git commit -m 'feat: {description}'"
        echo ""
        echo "After committing, clean up with:"
        echo "  gsd-worktree-remove $name"
    else
        echo "Error: Merge failed" >&2
        return 1
    fi
}

# Helper: Check if in main worktree (not a linked worktree)
_gsd-is-main-worktree() {
    local git_dir common_dir
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    [[ "$git_dir" == "$common_dir" ]]
}

# Helper: Dry-run merge to check for conflicts
_gsd-worktree-check-conflicts() {
    local branch="$1"

    # Try merge with --no-commit to detect conflicts
    if ! git merge --squash --no-commit "$branch" 2>/dev/null; then
        git merge --abort 2>/dev/null
        git reset --hard HEAD 2>/dev/null
        return 1
    fi

    # Check for unmerged files (conflict markers)
    if git diff --cached --name-only --diff-filter=U 2>/dev/null | grep -q .; then
        git merge --abort 2>/dev/null
        git reset --hard HEAD 2>/dev/null
        return 1
    fi

    # Clean up - abort the test merge
    git merge --abort 2>/dev/null
    git reset --hard HEAD 2>/dev/null
    return 0
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multiple clones | Git worktrees | Git 2.5 (2015) | Shared .git, instant creation |
| Manual branch switching | Worktree per branch | Git 2.5+ | True parallel development |
| rsync/copy directories | `git worktree add` | Native support | Proper metadata tracking |

**Deprecated/outdated:**
- `git-new-workdir` (contrib script): Replaced by built-in `git worktree`
- Submodule workarounds: Now use `git worktree` with `--recurse-submodules`

## Open Questions

Things that couldn't be fully resolved:

1. **Tab completion for worktree names**
   - What we know: Zsh completion system supports custom completions
   - What's unclear: Whether it's worth the complexity for 4 commands
   - Recommendation: Defer to later enhancement if users request it

2. **Cross-platform path handling**
   - What we know: macOS, Linux use forward slashes; dotfiles targets both
   - What's unclear: Edge cases with spaces in repo names
   - Recommendation: Quote all paths; test with repo names containing spaces

## Sources

### Primary (HIGH confidence)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Official reference
- [Git Merge Documentation](https://git-scm.com/docs/git-merge) - Squash merge mechanics
- `.planning/research/WORKTREE-STACK.md` - Prior domain research
- `.planning/research/PITFALLS.md` - Comprehensive pitfall analysis
- `tools/git/git.zsh` - Existing pattern in this codebase
- `tools/zsh/install_zsh.yml` - Ansible deployment pattern

### Secondary (MEDIUM confidence)
- [Zsh Functions Documentation](https://zsh.sourceforge.io/Doc/Release/Functions.html) - Shell function reference
- [Zsh Best Practices](https://gist.github.com/ChristopherA/562c2e62d01cf60458c5fa87df046fbd) - Variable scoping
- [Graphite: Git Merge Squash](https://graphite.com/guides/git-merge-squash) - Merge patterns
- [Azure DevOps Merge Strategies](https://learn.microsoft.com/en-us/azure/devops/repos/git/merging-with-squash) - Conflict handling

### Tertiary (LOW confidence)
- WebSearch results for Zsh error handling patterns - General guidance only

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Uses only built-in git and Zsh
- Architecture patterns: HIGH - Follows existing dotfiles conventions exactly
- Pitfalls: HIGH - Prior research in PITFALLS.md is comprehensive
- Code examples: HIGH - Based on official git documentation

**Research date:** 2026-01-19
**Valid until:** 60+ days (git worktree is a stable, mature feature)
