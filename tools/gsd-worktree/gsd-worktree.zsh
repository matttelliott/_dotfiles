# GSD Worktree Management Functions
# Shell commands for git worktree parallel development workflow

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

# Create a new worktree with dedicated branch
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

# List all worktrees managed by GSD
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

# Remove a worktree and its branch
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

# Squash merge worktree branch to current branch
gsd-worktree-merge() {
    local name="$1"
    local repo_root repo_name worktree_path branch_name
    local current_branch

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
