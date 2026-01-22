# Roadmap: v0.2 Portability & Bugs

**Milestone:** v0.2
**Epic:** Concerns Resolution (v0.2-v0.5)
**Depth:** Quick
**Phases:** 4 (5-8, continuing from v0.1)

## Overview

Fix architecture hardcoding and known bugs so playbooks work on ARM64 (Raspberry Pi) and re-runs are truly idempotent with no false "changed" status. This milestone addresses the most impactful items from CONCERNS.md.

---

## Phase 5: Architecture Portability

**Goal:** Playbooks work correctly on ARM64 Debian (Raspberry Pi) without manual architecture overrides.

**Dependencies:** None (foundation for remaining phases)

**Requirements:** ARCH-01, ARCH-02, ARCH-03

**Plans:** 2 plans

Plans:
- [x] 05-01-PLAN.md — Dynamic architecture mapping for Docker and Go
- [x] 05-02-PLAN.md — ARM64 skip with debug messages for 1Password and Edge

**Success Criteria:**

1. APT repository playbooks (docker, 1password, edge) use `ansible_architecture` or equivalent fact for arch detection
2. Go installation playbook selects correct binary (amd64/arm64) based on detected architecture
3. Running `ansible-playbook setup.yml` on an ARM64 Debian system completes without architecture-related errors
4. No hardcoded `amd64` strings remain in playbook conditionals or URLs

---

## Phase 6: Idempotency Guards

**Goal:** Re-running playbooks shows zero false "changed" status for shell-based tool installations.

**Dependencies:** Phase 5 (architecture detection patterns may influence guard paths)

**Requirements:** IDEM-01, IDEM-02, IDEM-03, IDEM-04, IDEM-05

**Plans:** 1 plan

Plans:
- [x] 06-01-PLAN.md — Add creates guards to Go and Python dev tools

**Success Criteria:**

1. `go install` tasks have `creates:` guards pointing to the installed binary location
2. `mason install` tasks have `creates:` guards for mason-installed tools
3. `npm install -g` tasks have `creates:` guards for globally installed packages
4. `uv tool install` tasks have `creates:` guards for uv-managed tools
5. Running `ansible-playbook setup.yml` twice in succession shows `changed=0` for all guarded tasks

---

## Phase 7: Bug Fixes

**Goal:** Known bugs in SSH known_hosts and Debian non-free repos are fixed.

**Dependencies:** None (independent fixes)

**Requirements:** BUG-01, BUG-02

**Plans:** 2 plans

Plans:
- [x] 07-01-PLAN.md — SSH known_hosts idempotency with ssh-keygen -F
- [x] 07-02-PLAN.md — Debian non-free repos via deb822_repository module

**Success Criteria:**

1. SSH known_hosts task uses `ssh-keygen -F` to check host presence before adding (no duplicate entries)
2. Debian non-free repos modification uses `apt_repository` module instead of raw file editing
3. Re-running SSH playbook does not add duplicate known_hosts entries

---

## Phase 8: LTS Version Policy

**Goal:** Tools with LTS releases use their LTS versions; others use stable or latest.

**Dependencies:** None (independent policy)

**Requirements:** LTS-01

**Success Criteria:**

1. Node.js installed via nvm uses `--lts` flag
2. Python version managers (uv) use LTS/stable versions where applicable
3. Homebrew/apt packages use package manager defaults (typically stable)
4. Policy documented: LTS > stable > latest

---

## Progress

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 5 | Architecture Portability | ARCH-01, ARCH-02, ARCH-03 | Complete |
| 6 | Idempotency Guards | IDEM-01, IDEM-02, IDEM-03, IDEM-04, IDEM-05 | Complete |
| 7 | Bug Fixes | BUG-01, BUG-02 | Complete |
| 8 | LTS Version Policy | LTS-01 | Pending |

**Total:** 11 requirements across 4 phases

---

## Coverage Validation

| Requirement | Phase | Mapped |
|-------------|-------|--------|
| ARCH-01 | 5 | Yes |
| ARCH-02 | 5 | Yes |
| ARCH-03 | 5 | Yes |
| IDEM-01 | 6 | Yes |
| IDEM-02 | 6 | Yes |
| IDEM-03 | 6 | Yes |
| IDEM-04 | 6 | Yes |
| IDEM-05 | 6 | Yes |
| BUG-01 | 7 | Yes |
| BUG-02 | 7 | Yes |
| LTS-01 | 8 | Yes |

**Coverage:** 11/11 (100%)

---
*Roadmap created: 2026-01-21*
*Milestone: v0.2 Portability & Bugs*
