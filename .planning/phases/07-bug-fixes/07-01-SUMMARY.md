---
phase: 07-bug-fixes
plan: 01
subsystem: infra
tags: [ssh, ansible, idempotency, known_hosts]

# Dependency graph
requires:
  - phase: 06-idempotency-guards
    provides: guard patterns for existing tools
provides:
  - Idempotent SSH known_hosts management using ssh-keygen -F
affects: [05-portability]

# Tech tracking
tech-stack:
  added: []
  patterns: ["ssh-keygen -F host check before ssh-keyscan append"]

key-files:
  created: []
  modified: ["tools/ssh/install_ssh.yml"]

key-decisions:
  - "Use ansible.builtin.command for ssh-keygen -F (no shell features needed)"
  - "Use changed_when: true on ssh-keyscan since it always changes known_hosts"
  - "Use failed_when: false instead of ignore_errors for lint compliance"

patterns-established:
  - "ssh-keygen -F pattern: register check results, then conditional append with when: item.rc != 0"

# Metrics
duration: 2min
completed: 2026-01-22
---

# Phase 7 Plan 01: SSH known_hosts Idempotency Fix Summary

**SSH known_hosts now uses ssh-keygen -F to verify host presence before adding, preventing duplicate entries on re-runs**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-22T21:29:25Z
- **Completed:** 2026-01-22T21:31:06Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Replaced marker file pattern with proper ssh-keygen -F verification
- SSH playbook is now truly idempotent - hosts already in known_hosts are skipped
- Removed orphaned .known_hosts_* marker files from idempotency mechanism
- Lint compliance improved (command vs shell, changed_when, failed_when)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace marker file pattern with ssh-keygen -F check** - `e18ab80` (fix)
2. **Task 2: Verify idempotency logic** - verification only, no code changes

**Plan metadata:** pending

## Files Created/Modified
- `tools/ssh/install_ssh.yml` - Known_hosts tasks now use ssh-keygen -F verification pattern

## Decisions Made
- **ansible.builtin.command for ssh-keygen:** ssh-keygen -F doesn't need shell features (no pipes, redirects), so using command module satisfies lint rule
- **changed_when: true for ssh-keyscan:** When the task runs (host missing), it always adds to known_hosts, so changed is accurate
- **failed_when: false over ignore_errors:** Lint prefers explicit failed_when condition over ignore_errors for better control

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed ansible-lint violations in new tasks**
- **Found during:** Task 1 (after initial implementation)
- **Issue:** Three lint violations: command-instead-of-shell (line 55), ignore-errors (line 66), no-changed-when (line 66)
- **Fix:** Changed shell to command for ssh-keygen, added changed_when: true, replaced ignore_errors with failed_when: false
- **Files modified:** tools/ssh/install_ssh.yml
- **Verification:** ansible-lint passes for new tasks (only pre-existing issue at line 90 remains)
- **Committed in:** e18ab80 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug - lint compliance)
**Impact on plan:** Necessary for code quality. The plan provided the general pattern but lint compliance required refinements.

## Issues Encountered
None - plan executed as specified with lint refinements.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- BUG-01 resolved: SSH known_hosts idempotency fixed
- Ready for Phase 8 (Documentation)
- Pre-existing lint issue at line 90 (1Password task no-changed-when) tracked but not in scope for this bug fix

---
*Phase: 07-bug-fixes*
*Completed: 2026-01-22*
