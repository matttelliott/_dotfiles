---
phase: 07-bug-fixes
plan: 02
subsystem: infra
tags: [ansible, debian, apt, deb822, nvidia, gpu]

# Dependency graph
requires:
  - phase: 05-compatibility
    provides: Cross-platform playbook patterns
provides:
  - Declarative Debian non-free repository management via deb822_repository
  - Idempotent repo addition (sources.list.d file, not sources.list modification)
affects: [gpu, debian-hosts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "deb822_repository for Debian/Ubuntu repository management"

key-files:
  created: []
  modified:
    - tools/gpu/install_gpu.yml

key-decisions:
  - "Use deb822_repository module instead of sed manipulation for idempotent repo management"
  - "Include all three components: contrib, non-free, non-free-firmware for Debian 12+ compatibility"

patterns-established:
  - "deb822_repository: Modern declarative Debian repo management creates .sources files in sources.list.d/"

# Metrics
duration: 1min
completed: 2026-01-22
---

# Phase 7 Plan 2: Debian Non-Free Repo Bug Summary

**Replaced fragile sed-based sources.list manipulation with declarative deb822_repository module for safe, idempotent Debian non-free repo management**

## Performance

- **Duration:** 1 min 10 sec
- **Started:** 2026-01-22T21:29:27Z
- **Completed:** 2026-01-22T21:30:37Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Eliminated fragile sed pattern that could corrupt sources.list on repeated runs
- Implemented modern deb822_repository module for declarative repo management
- Repo now managed as separate file in /etc/apt/sources.list.d/ (debian-nonfree.sources)
- Unconditional apt cache update when NVIDIA detected (module handles idempotency)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace sed pattern with deb822_repository module** - `dd79ec9` (fix)

Task 2 was verification-only (no code changes, no commit needed).

## Files Created/Modified

- `tools/gpu/install_gpu.yml` - Replaced 3 tasks (grep check, sed manipulation, conditional apt update) with 2 declarative tasks (deb822_repository, apt update)

## Decisions Made

- **Use deb822_repository over apt_repository:** deb822_repository is the modern Ansible module that creates proper .sources files in deb822 format, while apt_repository uses the older one-line format. The deb822 format is the Debian standard going forward.
- **Include non-free-firmware component:** Debian 12+ split non-free firmware into separate component, so we include all three (contrib, non-free, non-free-firmware) for compatibility.
- **Unconditional apt update:** Rather than tracking "changed" state from grep, the apt module handles idempotency correctly. Running update_cache when NVIDIA is detected is harmless and ensures cache is current.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - ansible-lint showed pre-existing unrelated warnings (GPU detection grep, macOS system_profiler) but no errors related to the modified tasks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BUG-02 resolved: Debian non-free repos use deb822_repository module
- Ready for any remaining bug fixes in Phase 7
- GPU playbook now safe for repeated runs on Debian systems

---
*Phase: 07-bug-fixes*
*Completed: 2026-01-22*
