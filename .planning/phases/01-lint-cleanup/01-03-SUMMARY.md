---
phase: 01-lint-cleanup
plan: 03
subsystem: lint
tags: [ansible-lint, yaml, line-length, git]

# Dependency graph
requires:
  - phase: 01-01
    provides: FQCN and truthy fixes
  - phase: 01-02
    provides: name[play] fixes
provides:
  - Zero yaml[line-length] violations
  - Zero latest[git] violations
  - Shell commands formatted with line continuations
  - Git module calls pinned to explicit version
affects: [future-ansible-playbooks]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shell line continuations with backslash for long curl/echo commands"
    - "Git module version: master for tracking default branch"
    - "YAML multiline (>-) for long variables"

key-files:
  created: []
  modified:
    - tools/1password/install_1password.yml
    - tools/1password_cli/install_1password_cli.yml
    - tools/brave/install_brave.yml
    - tools/edge/install_edge.yml
    - tools/gcloud/install_gcloud.yml
    - tools/gh/install_gh.yml
    - tools/keyboard/install_keyboard.yml
    - tools/lazygit/install_lazygit.yml
    - tools/nas/install_nas.yml
    - tools/neovim/install_neovim.yml
    - tools/opera/install_opera.yml
    - tools/vivaldi/install_vivaldi.yml
    - setup.yml
    - tools/yay/install_yay.yml

key-decisions:
  - "Use version: master for git module (HEAD not recognized by ansible-lint)"
  - "Shell line continuations preserve pipe chains readability"
  - "YAML multiline vars for long lists (mason_packages)"

patterns-established:
  - "Shell commands: wrap at pipe with backslash continuation"
  - "Git module: always specify version: master for tracking HEAD"

# Metrics
duration: 20min
completed: 2026-01-20
---

# Phase 01 Plan 03: Line Length and Git Version Fixes Summary

**Wrapped 13 long shell command lines and pinned 3 git module calls to version: master**

## Performance

- **Duration:** 20 min
- **Started:** 2026-01-20T22:39:52Z
- **Completed:** 2026-01-20T22:59:51Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- Eliminated all 13 yaml[line-length] violations by wrapping long shell commands
- Eliminated all 3 latest[git] violations by adding explicit version: master
- Established pattern for shell line continuations that preserves readability
- Learned that ansible-lint requires version: master, not version: HEAD

## Task Commits

Each task was committed atomically (via auto-commit):

1. **Task 1: Wrap long lines in playbooks** - `5af2909`, `5ba15c6`, `3847e58` (fix)
2. **Task 2: Pin git versions** - `ca71413`, `d2ae277` (fix)

_Note: Auto-commit mechanism created multiple commits during execution_

## Files Created/Modified
- `tools/1password/install_1password.yml` - Wrap apt repository shell commands
- `tools/1password_cli/install_1password_cli.yml` - Wrap apt repository shell commands
- `tools/brave/install_brave.yml` - Wrap apt repository shell commands
- `tools/edge/install_edge.yml` - Wrap apt repository shell commands
- `tools/gcloud/install_gcloud.yml` - Wrap apt repository shell commands
- `tools/gh/install_gh.yml` - Wrap apt repository shell commands
- `tools/keyboard/install_keyboard.yml` - Wrap hidutil command with YAML folded style
- `tools/lazygit/install_lazygit.yml` - Use variable for long URL
- `tools/nas/install_nas.yml` - Wrap autofs config template lines
- `tools/neovim/install_neovim.yml` - Use YAML multiline var for mason packages list
- `tools/opera/install_opera.yml` - Wrap apt repository shell commands
- `tools/vivaldi/install_vivaldi.yml` - Wrap apt repository shell commands
- `setup.yml` - Add version: master to dotfiles clone tasks
- `tools/yay/install_yay.yml` - Add version: master to yay clone task

## Decisions Made
- **version: master instead of HEAD**: ansible-lint does not recognize `version: HEAD` as a valid pin. Using `version: master` explicitly states we want to track the default branch, satisfying the latest[git] rule.
- **Shell line continuation pattern**: Used backslash at line end to continue long shell commands, keeping pipe operators at the start of continuation lines for readability.
- **YAML multiline vars for lists**: For the neovim mason packages, used YAML folded style (`>-`) to define a multi-line variable, then reference it with Jinja filter.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Initial attempt used `version: HEAD` which ansible-lint did not recognize as valid. Changed to `version: master` which resolved the violations.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 01 (Lint Cleanup) complete
- yaml[line-length] and latest[git] violations eliminated
- Other lint violations remain (command-instead-of-shell, no-changed-when, etc.) - these are for future phases
- Ready for Phase 02 when planned

---
*Phase: 01-lint-cleanup*
*Completed: 2026-01-20*
