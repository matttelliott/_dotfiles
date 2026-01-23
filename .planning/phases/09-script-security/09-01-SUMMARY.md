---
phase: 09-script-security
plan: 01
subsystem: infra
tags: [curl-pipe, supply-chain, security, ansible, homebrew, pulumi, uv, rust, starship]

# Dependency graph
requires: []
provides:
  - Pinned Homebrew installer to commit SHA
  - Pinned Pulumi installer with version flag
  - Pinned uv installer with versioned URL
  - Security comments for unpinnable scripts (rust, starship)
affects: [bootstrap, tools-maintenance, security-audits]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pin curl-pipe installers to commit SHA when possible"
    - "Use --version flag when installer supports it"
    - "Document unpinnable scripts with security comments and alternatives"

key-files:
  created: []
  modified:
    - bootstrap.sh
    - tools/homebrew/install_homebrew.yml
    - tools/pulumi/install_pulumi.yml
    - tools/python/install_python.yml
    - tools/rust/install_rust.yml
    - tools/starship/install_starship.yml

key-decisions:
  - "Pin to latest Homebrew commit SHA (90fa3d5) for reproducibility"
  - "Use version flags for Pulumi (3.216.0) and uv (0.9.26)"
  - "Document unpinnable scripts with alternatives rather than removing them"

patterns-established:
  - "Security comment pattern: # SECURITY: [tool] installer cannot be pinned - [reason]"
  - "Update comment pattern: # Verify/update at: [URL]"

# Metrics
duration: 2min
completed: 2026-01-23
---

# Phase 9 Plan 1: Script Security Summary

**Pinned 4 curl-pipe installers (Homebrew, Pulumi, uv) and documented 2 unpinnable scripts (Rust, Starship) with security comments**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-23T09:55:14Z
- **Completed:** 2026-01-23T09:57:17Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Pinned Homebrew installer to commit SHA 90fa3d5881cedc0d60c4a3cc5babdb867ef42e5a (both bootstrap.sh and playbook)
- Pinned Pulumi installer with --version 3.216.0 flag
- Pinned uv installer with versioned URL /uv/0.9.26/
- Added security comments to Rust and Starship playbooks explaining why they cannot be pinned

## Task Commits

Each task was committed atomically:

1. **Task 1: Pin Homebrew installer to commit SHA** - `a17763c` (fix)
2. **Task 2: Pin Pulumi and uv installers with version flags** - `fea14be` (fix)
3. **Task 3: Add security comments to unpinnable scripts** - `7d1a1e9` (docs)

## Files Created/Modified
- `bootstrap.sh` - Pinned Homebrew installer URL from HEAD to commit SHA
- `tools/homebrew/install_homebrew.yml` - Pinned Homebrew installer URL with update comment
- `tools/pulumi/install_pulumi.yml` - Added --version 3.216.0 flag to Linux installer
- `tools/python/install_python.yml` - Changed to versioned URL path /uv/0.9.26/
- `tools/rust/install_rust.yml` - Added security comment explaining rustup cannot be pinned
- `tools/starship/install_starship.yml` - Added security comment explaining starship cannot be pinned

## Decisions Made
- Used commit SHA instead of tags for Homebrew (Homebrew/install repo doesn't use version tags)
- Kept Rust and Starship curl-pipe scripts with documentation rather than removing functionality
- Added verification URLs in comments so future maintainers can check for updates

## Deviations from Plan

None - plan executed exactly as written.

**Note:** ansible-lint shows pre-existing violations in these files (curl usage, file permissions, etc.) that existed before this phase. My changes only added comments and modified URLs - no new lint violations were introduced.

## Issues Encountered

None - all changes applied cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All curl-pipe scripts now either pinned or documented
- Ready for Phase 10 (Secrets Documentation) or any follow-up security hardening
- Version numbers (Pulumi 3.216.0, uv 0.9.26, Homebrew commit 90fa3d5) should be periodically updated

---
*Phase: 09-script-security*
*Completed: 2026-01-23*
