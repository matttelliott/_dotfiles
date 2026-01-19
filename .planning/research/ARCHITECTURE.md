# Architecture Research: GSD + Worktree Integration

**Domain:** Multi-agent safety through git worktree isolation
**Researched:** 2026-01-19
**Confidence:** HIGH (verified against GSD source, git documentation, and community patterns)

## Executive Summary

Git worktrees provide filesystem-level isolation for parallel agent execution. Each executor agent operates in a dedicated worktree on its own branch, preventing the file conflicts that occur when multiple agents edit the same working directory simultaneously. The integration with GSD requires modifications at specific orchestrator points: worktree creation during execute-phase setup, coordination during wave execution, and squash-merge cleanup at plan/phase completion.

## Current GSD Flow

### Execute-Phase Architecture (Today)

```
/gsd:execute-phase {phase}
    |
    +-- 1. Validate phase exists
    |
    +-- 2. Discover plans (find *-PLAN.md, check for *-SUMMARY.md)
    |
    +-- 3. Group by wave (read frontmatter wave: N)
    |
    +-- 4. Execute waves
    |       |
    |       +-- For each wave:
    |           +-- Spawn gsd-executor for each plan (parallel Task calls)
    |           +-- Task blocks until completion
    |           +-- Verify SUMMARYs created
    |           +-- Proceed to next wave
    |
    +-- 5. Commit orchestrator corrections
    |
    +-- 6. Spawn gsd-verifier
    |
    +-- 7-10. Update roadmap, state, requirements
    |
    +-- 11. Offer next steps
```

### Current Commit Pattern

Each gsd-executor creates per-task atomic commits directly on the current branch:
```
feat(01-01): implement auth middleware
feat(01-01): add user session types
docs(01-01): complete authentication plan
```

This works for single-agent execution but creates conflicts when Wave 1 spawns multiple executors simultaneously.

### The Problem with Parallel Execution Today

When Wave 1 contains plans 01-01 and 01-02 executing in parallel:

1. Both executors start from same HEAD commit
2. Both modify files, create commits
3. One executor pushes successfully
4. Second executor fails: "Updates were rejected because the tip of your current branch is behind"

Current mitigation: Plans in the same wave must not touch overlapping files. This is fragile and limits parallelization.

## Proposed Integration Points

### Modified Execute-Phase Flow

```
/gsd:execute-phase {phase}
    |
    +-- 1-3. (unchanged) Validate, discover, group
    |
    +-- 4. Execute waves (MODIFIED)
    |       |
    |       +-- For each wave:
    |           |
    |           +-- 4a. CREATE WORKTREES
    |           |       For each plan in wave:
    |           |         git worktree add .trees/{phase}-{plan} -b agent/{phase}-{plan}
    |           |
    |           +-- 4b. SPAWN EXECUTORS WITH WORKTREE PATH
    |           |       Task(..., working_dir=".trees/{phase}-{plan}")
    |           |
    |           +-- 4c. WAIT FOR COMPLETION
    |           |
    |           +-- 4d. MERGE WORKTREE BRANCHES (squash)
    |           |       For each completed plan:
    |           |         git checkout master
    |           |         git merge --squash agent/{phase}-{plan}
    |           |         git commit -m "{type}({phase}-{plan}): {one-liner from SUMMARY}"
    |           |
    |           +-- 4e. CLEANUP WORKTREES
    |           |       git worktree remove .trees/{phase}-{plan}
    |           |       git branch -D agent/{phase}-{plan}
    |           |
    |           +-- Proceed to next wave
    |
    +-- 5-11. (unchanged) Verify, update state, offer next
```

### Integration Points Summary

| Point | Location | Action |
|-------|----------|--------|
| Worktree setup | execute-phase step 4a (new) | Create `.trees/{phase}-{plan}/` with dedicated branch |
| Executor spawn | execute-phase step 4b (modified) | Pass worktree path to Task tool |
| Executor work | gsd-executor (modified) | All git operations use worktree path |
| Squash merge | execute-phase step 4d (new) | Merge with --squash to master |
| Cleanup | execute-phase step 4e (new) | Remove worktrees and temp branches |

## Agent Coordination

### Isolation Model

```
master branch
    |
    +-- agent/01-01 (worktree: .trees/01-01/)
    |       |
    |       +-- commit: feat(01-01): task 1
    |       +-- commit: feat(01-01): task 2
    |       +-- commit: docs(01-01): complete plan
    |
    +-- agent/01-02 (worktree: .trees/01-02/)
    |       |
    |       +-- commit: feat(01-02): task 1
    |       +-- commit: test(01-02): task 2
    |       +-- commit: docs(01-02): complete plan
    |
    (after wave completes)
    |
    +-- squash merge: feat(01-01): JWT auth with refresh rotation
    +-- squash merge: feat(01-02): User profile CRUD endpoints
```

### Why This Works

1. **Filesystem isolation**: Each worktree has its own directory (`.trees/01-01/`, `.trees/01-02/`)
2. **Git isolation**: Each worktree is on a dedicated branch (`agent/01-01`, `agent/01-02`)
3. **No cross-contamination**: Agents cannot see or modify each other's uncommitted changes
4. **Shared .git**: All worktrees share the same `.git` directory (disk efficient)
5. **Sequential merge**: Orchestrator merges worktrees one at a time (no race condition)

### Coordination Flow

```
Wave 1 Start:
  Orchestrator: Creates worktrees for plans 01-01, 01-02, 01-03
  Orchestrator: Spawns 3 executors in parallel

  [Executors work independently - no coordination needed]

  Executor-01: Commits to agent/01-01
  Executor-02: Commits to agent/01-02
  Executor-03: Commits to agent/01-03

Wave 1 Complete:
  Orchestrator: Checkout master
  Orchestrator: Squash merge agent/01-01 -> master
  Orchestrator: Squash merge agent/01-02 -> master
  Orchestrator: Squash merge agent/01-03 -> master
  Orchestrator: Remove worktrees

Wave 2 Start:
  [Repeat with fresh worktrees based on new master]
```

### Handling Merge Conflicts

If squash merge encounters conflicts:

1. **Stop and report**: Don't auto-resolve (could corrupt code)
2. **Present to user**: Show conflicting files, both versions
3. **User resolves**: Manual merge resolution
4. **Continue**: Once resolved, proceed to next plan merge

```markdown
## Merge Conflict Detected

**Plan:** 01-02 (User profile CRUD)
**Conflicting with:** Previous merge from 01-01

### Conflicts

| File | Status |
|------|--------|
| src/types/user.ts | Both modified |
| src/utils/validation.ts | Both modified |

### Resolution Options

1. Keep 01-01 version
2. Keep 01-02 version
3. Manual merge (open in editor)

Which approach?
```

## Branch/Merge Strategy

### Branch Naming Convention

```
master                      # Production-ready code
  |
  +-- agent/{phase}-{plan}  # Temporary executor branches
      |
      Examples:
      +-- agent/01-01
      +-- agent/01-02
      +-- agent/02-01
```

### Why `agent/` Prefix

1. **Clear namespace**: Distinguishes from feature branches
2. **Easy cleanup**: `git branch --list 'agent/*'` finds all
3. **Signals temporary**: These branches are deleted after merge
4. **Avoids collision**: Won't conflict with user branches

### Squash Merge Benefits

**Before (current atomic commits):**
```
abc1234 feat(01-01): implement auth middleware
def5678 feat(01-01): add session types
ghi9012 fix(01-01): correct token expiration
jkl3456 test(01-01): add auth tests
mno7890 docs(01-01): complete authentication plan
```

**After (squash merge):**
```
pqr2468 feat(01-01): JWT auth with refresh rotation using jose library
```

**Benefits:**
- Clean master history (one commit per plan)
- Easy to revert entire plan
- Commit message from SUMMARY.md one-liner (substantive)
- Git bisect still effective (plan-level granularity)
- Detailed history preserved in SUMMARY.md

### Commit Message for Squash

```bash
git merge --squash agent/01-01
git commit -m "$(cat <<'EOF'
feat(01-01): JWT auth with refresh rotation using jose library

Phase: 01-auth
Plan: 01-01-authentication
Tasks: 5/5 complete

Key deliverables:
- Auth middleware with token validation
- Session management with refresh rotation
- Type definitions for User and Session
- Integration tests for auth flow

SUMMARY: .planning/phases/01-auth/01-01-SUMMARY.md
EOF
)"
```

### The .trees/ Directory

```
project-root/
  +-- .trees/           # All worktrees (gitignored)
  |     +-- 01-01/      # Worktree for plan 01-01
  |     +-- 01-02/      # Worktree for plan 01-02
  |     +-- 02-01/      # Worktree for plan 02-01
  |
  +-- .gitignore        # Contains: .trees/
  +-- .planning/
  +-- src/
  +-- ...
```

**Why .trees/**:
- Contained within project (no sibling directories)
- Gitignored (worktrees are temporary)
- Short path (reduces typing)
- Matches community convention

## Implementation Approach

### Phase 1: Core Worktree Management

**Deliverables:**
1. Worktree creation helper
2. Worktree cleanup helper
3. .gitignore update for `.trees/`

**Implementation:**

```bash
# Create worktree for plan execution
create_worktree() {
  local plan_id=$1  # e.g., "01-01"
  local base_branch=${2:-master}

  # Create worktree with dedicated branch
  git worktree add ".trees/${plan_id}" -b "agent/${plan_id}" "${base_branch}"

  echo ".trees/${plan_id}"
}

# Cleanup after plan completion
remove_worktree() {
  local plan_id=$1

  # Remove worktree
  git worktree remove ".trees/${plan_id}" --force

  # Delete temporary branch
  git branch -D "agent/${plan_id}"
}

# Squash merge completed plan
squash_merge_plan() {
  local plan_id=$1
  local commit_msg=$2

  # Ensure on master
  git checkout master

  # Squash merge
  git merge --squash "agent/${plan_id}"

  # Commit with message
  git commit -m "${commit_msg}"
}
```

### Phase 2: Execute-Phase Modifications

**Modifications to `/gsd:execute-phase`:**

1. Add worktree setup before wave execution
2. Modify Task spawn to include working directory
3. Add squash merge step after wave completion
4. Add cleanup step after merge

**Key code changes in execute-phase.md:**

```markdown
<step name="execute_waves">
...
For each wave:

1. **Create worktrees for all plans in wave:**
   ```bash
   for plan in $WAVE_PLANS; do
     git worktree add ".trees/${plan}" -b "agent/${plan}" master
   done
   ```

2. **Spawn executors with worktree paths:**
   ```
   Task(
     prompt="Execute plan at {plan_path}...",
     subagent_type="gsd-executor",
     working_dir=".trees/{plan_id}"
   )
   ```

3. **Wait for completion** (unchanged)

4. **Squash merge each completed plan:**
   ```bash
   git checkout master
   for plan in $COMPLETED_PLANS; do
     summary_oneliner=$(head -1 ".trees/${plan}/.planning/phases/.../SUMMARY.md" | grep "^#" | sed 's/^# //')
     git merge --squash "agent/${plan}"
     git commit -m "feat(${plan}): ${summary_oneliner}"
   done
   ```

5. **Cleanup worktrees:**
   ```bash
   for plan in $WAVE_PLANS; do
     git worktree remove ".trees/${plan}" --force
     git branch -D "agent/${plan}"
   done
   ```
</step>
```

### Phase 3: Executor Modifications

**Modifications to `gsd-executor.md`:**

1. Accept working directory from orchestrator
2. All git commands operate relative to worktree
3. No change to commit protocol (still atomic per-task)
4. SUMMARY.md created in worktree's .planning/ directory

**Key insight:** The executor doesn't need to know it's in a worktree. It operates normally; the orchestrator handles isolation.

### Phase 4: Claude Awareness

**Problem:** Claude retries empty commits when nothing changed.

**Solution:** Add pre-commit check to executor:

```bash
# Before attempting commit
if [ -z "$(git status --porcelain)" ]; then
  echo "No changes to commit - skipping"
  return 0
fi

# Proceed with commit
git add ...
git commit ...
```

**Add to gsd-executor deviation rules:**

```markdown
**RULE 0: Never commit nothing**

Before any commit attempt:
1. Run `git status --porcelain`
2. If output is empty, skip commit (not an error)
3. Log: "No changes to commit for task X"
4. Continue to next task

This prevents the "nothing to commit" error loop.
```

## Architectural Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Worktrees over clones | Shared .git saves disk, instant creation | Full clones (slow, wasteful) |
| Squash merge over rebase | Clean history, easy revert, preserves detail in SUMMARY | Rebase (loses merge point), regular merge (cluttered history) |
| .trees/ over ../project-01/ | Contained in project, easy gitignore | Sibling directories (scattered, harder to manage) |
| Per-wave cleanup over end-of-phase | Disk space, reduces stale worktrees | Keep all until phase end (uses more disk, risks stale state) |
| agent/ branch prefix | Clear namespace, easy to identify | No prefix (collision risk), temp/ (less descriptive) |

## Anti-Patterns to Avoid

### 1. Shared Working Directory
**Bad:** Multiple executors write to same directory
**Consequence:** File corruption, merge conflicts, lost work
**Avoided by:** Worktree isolation

### 2. Long-Lived Agent Branches
**Bad:** Keep agent branches after merge
**Consequence:** Branch proliferation, confusion about state
**Avoided by:** Immediate cleanup after squash merge

### 3. Rebasing Agent Branches
**Bad:** Rebase agent branch onto master mid-execution
**Consequence:** Can confuse executor, lose checkpoint state
**Avoided by:** Each wave starts fresh from current master

### 4. Auto-Resolving Merge Conflicts
**Bad:** Automatically pick one side in conflicts
**Consequence:** Silent code loss, bugs
**Avoided by:** Stop and ask user on any conflict

### 5. Worktrees Outside Project
**Bad:** Create worktrees in parent directory (../project-01-01/)
**Consequence:** Scattered directories, hard to cleanup
**Avoided by:** .trees/ directory inside project

## Scalability Considerations

| Concern | At 3 parallel agents | At 10 parallel agents | Mitigation |
|---------|---------------------|----------------------|------------|
| Disk space | ~50MB overhead | ~150MB overhead | Per-wave cleanup |
| Memory | Minimal | Minimal | Worktrees share .git |
| Merge time | ~1 second per plan | ~3 seconds per plan | Sequential, fast |
| Conflict risk | Low (careful planning) | Higher | Better wave assignment |

## Sources

- [Nick Mitchinson: Git Worktrees for Multi-Feature Development](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/) - Practical workflow patterns (HIGH confidence)
- [Nx Blog: Git Worktrees and AI Agents](https://nx.dev/blog/git-worktrees-ai-agents) - Isolation benefits (HIGH confidence)
- [GSD execute-phase.md](~/.claude/commands/gsd/execute-phase.md) - Current orchestrator flow (HIGH confidence, direct source)
- [GSD gsd-executor.md](~/.claude/agents/gsd-executor.md) - Current executor behavior (HIGH confidence, direct source)
- [Building a Multi-Agent Development Workflow](https://itsgg.com/blog/2026/01/08/building-a-multi-agent-development-workflow/) - Advisory locks + worktrees pattern (MEDIUM confidence)
- [ccswarm](https://github.com/nwiizo/ccswarm) - Multi-agent orchestration reference (MEDIUM confidence)
- [GitHub Docs: Squash and Merge](https://docs.github.com/articles/about-pull-request-merges) - Squash merge mechanics (HIGH confidence)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree) - Official git reference (HIGH confidence)
