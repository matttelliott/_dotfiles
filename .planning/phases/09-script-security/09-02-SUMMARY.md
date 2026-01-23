---
phase: 09-script-security
plan: 02
subsystem: infra
tags: [ansible, gpg, checksum, security, apt, sops]

# Dependency graph
requires:
  - phase: 09-script-security
    provides: Research identifying 10 high-concern scripts needing verification
provides:
  - Checksum-verified sops binary download
  - GPG fingerprint documentation for 9 APT repository tools
affects: [future-tool-additions, security-audits]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ansible.builtin.get_url with checksum for binary downloads"
    - "GPG fingerprint comments above repository key tasks"

key-files:
  created: []
  modified:
    - tools/sops/install_sops.yml
    - tools/1password/install_1password.yml
    - tools/1password_cli/install_1password_cli.yml
    - tools/docker/install_docker.yml
    - tools/gh/install_gh.yml
    - tools/wezterm/install_wezterm.yml
    - tools/edge/install_edge.yml
    - tools/gcloud/install_gcloud.yml
    - tools/vivaldi/install_vivaldi.yml
    - tools/opera/install_opera.yml

key-decisions:
  - "Use ansible.builtin.get_url with checksum instead of curl for binary downloads"
  - "Document GPG fingerprints as YAML comments with verification URLs"
  - "Include key expiration notes where known (e.g., gh key expires Sep 2026)"

patterns-established:
  - "Binary downloads: Use get_url with sha256 checksum from official checksums.txt"
  - "APT repos: Add GPG fingerprint comment with verify URL above key download task"

# Metrics
duration: 4min
completed: 2026-01-23
---

# Phase 9 Plan 02: Download Verification Summary

**SHA256 checksum verification for sops binary and GPG fingerprint documentation for 9 APT repository signing keys**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-23T09:55:08Z
- **Completed:** 2026-01-23T09:59:38Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- sops binary download now uses ansible.builtin.get_url with SHA256 checksum verification
- All 9 APT repository tools have GPG key fingerprint comments with verification URLs
- Established patterns for future tool additions requiring secure downloads

## Task Commits

Each task was committed atomically:

1. **Task 1: Add checksum verification to sops download** - `04425fe` (feat)
2. **Task 2: Add GPG fingerprint comments to APT repository tasks** - `3ccb3fe` (docs)
3. **Task 3: Add GPG fingerprint comments to remaining APT tools** - `2817aed` (docs)

## Files Created/Modified

- `tools/sops/install_sops.yml` - Added checksum verification via get_url, updated to v3.11.0
- `tools/1password/install_1password.yml` - Added GPG fingerprint comment
- `tools/1password_cli/install_1password_cli.yml` - Added GPG fingerprint comment
- `tools/docker/install_docker.yml` - Added GPG fingerprint comment
- `tools/gh/install_gh.yml` - Added GPG fingerprint comment with expiration note
- `tools/wezterm/install_wezterm.yml` - Added GPG Key ID comment
- `tools/edge/install_edge.yml` - Added GPG fingerprint comment
- `tools/gcloud/install_gcloud.yml` - Added GPG Key ID comment
- `tools/vivaldi/install_vivaldi.yml` - Added GPG fingerprint comment
- `tools/opera/install_opera.yml` - Added GPG fingerprint comment

## GPG Fingerprints Documented

| Tool | GPG Fingerprint/Key ID | Verify URL |
|------|------------------------|------------|
| 1password | 3FEF9748469ADBE15DA7CA80AC2D62742012EA22 | support.1password.com/install-linux/ |
| 1password_cli | 3FEF9748469ADBE15DA7CA80AC2D62742012EA22 | support.1password.com/install-linux/ |
| docker | 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88 | docs.docker.com/engine/install/ubuntu/ |
| gh | 2C6106201985B60E6C7AC87323F3D4EA75716059 | github.com/cli/cli/blob/trunk/docs/install_linux.md |
| wezterm | D7BA31CF90C4B319 | apt.fury.io/wez/ |
| edge | BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF | microsoft.com/en-us/edge/download |
| gcloud | 3746 C208 A731 7B0F | cloud.google.com/sdk/docs/install |
| vivaldi | CB63 144F 1BA3 1BC3 9E27 79A8 FEB6 023D C27A A466 | vivaldi.com/download/ |
| opera | 6C86BE214648376680CA957B11EE8C00B693A745 | opera.com/download |

## Decisions Made

- **get_url over curl:** ansible.builtin.get_url is idempotent by default and supports native checksum verification, eliminating need for stat checks
- **Comment format:** GPG fingerprints documented as YAML comments directly above shell tasks since they're metadata for humans, not configuration values
- **Key expiration tracking:** Added expiration note for gh key (September 2026) as it's the only key with known near-term expiration

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Pre-existing lint warnings:** ansible-lint reports command-instead-of-shell and no-changed-when violations on modified files, but these are pre-existing issues from shell tasks using pipes/redirects (which require shell) - not introduced by GPG comment additions

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Download verification improvements complete
- Ready for next v0.3 phase (documentation)
- No blockers

---
*Phase: 09-script-security*
*Completed: 2026-01-23*
