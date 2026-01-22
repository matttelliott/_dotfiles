---
phase: 08-lts-version-policy
verified: 2026-01-22T23:15:00Z
status: passed
score: 4/4 must-haves verified
---

# Phase 8: LTS Version Policy Verification Report

**Phase Goal:** Tools with LTS releases use their LTS versions; others use stable or latest.

**Verified:** 2026-01-22
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Future maintainers understand version selection philosophy | ✓ VERIFIED | Version Policy section added to CLAUDE.md (lines 132-151) with clear LTS > stable > latest hierarchy |
| 2 | Policy is discoverable in project documentation | ✓ VERIFIED | Section appears after Code Style and before Claude Code Configuration, properly placed in documentation structure |
| 3 | Node.js uses LTS via nvm | ✓ VERIFIED | install_node.yml runs `nvm install --lts` and `nvm alias default lts/*` for both macOS and Linux |
| 4 | Tools follow stated version strategies | ✓ VERIFIED | Rust (rustup default stable), Go (pinned 1.23.4), Neovim (GitHub stable release), package managers default to stable |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `CLAUDE.md` | Version Policy section with LTS > stable > latest | ✓ VERIFIED | Lines 132-151: Section contains three-tier hierarchy and implementation table with actual tool strategies |
| `tools/node/install_node.yml` | Uses `--lts` flag for Node.js | ✓ VERIFIED | Lines 39, 54: Both macOS and Linux tasks run `nvm install --lts` with `nvm alias default lts/*` |
| `tools/rust/install_rust.yml` | Uses rustup default (stable) | ✓ VERIFIED | Line 8: Installs rustup which defaults to stable toolchain without manual override needed |
| `tools/go/install_go.yml` | Pinned to current stable (1.23.4) | ✓ VERIFIED | Line 5: `go_version: "1.23.4"` hardcoded as current stable |
| `tools/neovim/install_neovim.yml` | Uses GitHub stable release | ✓ VERIFIED | Line 17: Downloads from `github.com/neovim/neovim/releases/download/stable/` |
| `tools/python/install_python.yml` | Uses uv (package manager) defaults | ✓ VERIFIED | Uses `uv tool install` which defaults to stable versions for tools |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| CLAUDE.md Version Policy | install_node.yml | Documentation references actual implementation | ✓ WIRED | Policy section explicitly mentions `nvm install --lts` as example |
| CLAUDE.md Version Policy | install_rust.yml | Documentation references actual implementation | ✓ WIRED | Policy section mentions "Rust: Stable" with "rustup defaults to stable toolchain" |
| CLAUDE.md Version Policy | install_go.yml | Documentation references actual implementation | ✓ WIRED | Policy section mentions "Go: Current stable" with "Pinned version" |
| CLAUDE.md Version Policy | install_neovim.yml | Documentation references actual implementation | ✓ WIRED | Policy section mentions "Neovim: Latest stable" with "GitHub releases" |
| Implementation Reality | Documentation | Git commit 2caff6a | ✓ WIRED | All playbooks already implemented LTS/stable strategies before documentation was added |

### Requirements Coverage

| Requirement | Status | Details |
|-------------|--------|---------|
| LTS-01 | ✓ SATISFIED | Tools use LTS versions where available (nvm --lts, uv stable, package manager defaults) |
| Success Criteria #1 | ✓ SATISFIED | Node.js installed via nvm uses `--lts` flag in install_node.yml (lines 39, 54) |
| Success Criteria #2 | ✓ SATISFIED | Python version managers (uv) use stable by default; no override needed |
| Success Criteria #3 | ✓ SATISFIED | Homebrew/apt/pacman use package manager defaults (documented in install playbooks) |
| Success Criteria #4 | ✓ SATISFIED | Policy documented in CLAUDE.md with clear hierarchy: LTS > stable > latest |

### Anti-Patterns Scan

| File | Pattern | Severity | Finding |
|------|---------|----------|---------|
| CLAUDE.md | TODO/FIXME | ✓ NONE | No stub patterns found |
| CLAUDE.md | Placeholder text | ✓ NONE | No placeholder content |
| install_node.yml | Implementation quality | ✓ SUBSTANTIVE | Complete with creates guards, OS detection, and proper nvm sourcing |
| install_rust.yml | Implementation quality | ✓ SUBSTANTIVE | Complete with rustup installation and component setup |
| install_go.yml | Implementation quality | ✓ SUBSTANTIVE | Complete with version pinning, architecture detection, and OS-specific installers |
| install_neovim.yml | Implementation quality | ✓ SUBSTANTIVE | Complete with GitHub stable release download, proper source paths |

**No blocker anti-patterns found.**

### Implementation Verification

**Node.js (nvm):**
- ✓ Exists: `/home/matt/_dotfiles/tools/node/install_node.yml`
- ✓ Substantive: 75 lines, complete implementation with creates guards
- ✓ Wired: Included in setup.yml orchestration chain
- ✓ Implementation: `nvm install --lts` on line 39 (macOS), line 54 (Linux)
- ✓ Default alias: `nvm alias default lts/*` set for both OSes

**Rust (rustup):**
- ✓ Exists: `/home/matt/_dotfiles/tools/rust/install_rust.yml`
- ✓ Substantive: 17 lines, complete rustup installation
- ✓ Wired: Included in setup.yml
- ✓ Implementation: Uses `rustup.rs` official installer (defaults to stable)
- ✓ Components: Adds rustfmt, clippy, rust-analyzer

**Go:**
- ✓ Exists: `/home/matt/_dotfiles/tools/go/install_go.yml`
- ✓ Substantive: 65 lines, complete with architecture detection
- ✓ Wired: Included in setup.yml
- ✓ Implementation: Pinned to `1.23.4` (current stable as of phase implementation)
- ✓ Architecture-aware: Maps x86_64/aarch64 to amd64/arm64 for correct binary selection

**Neovim:**
- ✓ Exists: `/home/matt/_dotfiles/tools/neovim/install_neovim.yml`
- ✓ Substantive: 63 lines, complete with GitHub stable release handling
- ✓ Wired: Included in setup.yml
- ✓ Implementation: Downloads from `releases/download/stable/` on line 17 (Debian)
- ✓ Homebrew: Uses `brew install neovim` on macOS (Homebrew provides stable)

**Python (uv):**
- ✓ Exists: `/home/matt/_dotfiles/tools/python/install_python.yml`
- ✓ Substantive: 30 lines, complete uv installation and tool setup
- ✓ Wired: Included in setup.yml
- ✓ Implementation: Uses `uv tool install` which defaults to stable versions

**Package Managers:**
- ✓ Homebrew: Used via `brew install` throughout (provides stable formulae)
- ✓ apt: Used via `apt` module (provides stable from repos)
- ✓ pacman: Used via `pacman` module (provides stable from repos)

### Policy Documentation Quality

**Section Location:**
- ✓ Placed between "Code Style" (line 123) and "Claude Code Configuration" (line 153)
- ✓ Logically ordered in document structure
- ✓ Discoverable via README or project documentation

**Content Coverage:**
- ✓ Three-tier hierarchy clearly stated: LTS > stable > latest
- ✓ Implementation table includes 6 key tools
- ✓ Examples show actual flags/methods used
- ✓ Rationale for each tier explained
- ✓ Package manager behavior documented

**Maintainability:**
- ✓ Future developers can quickly find policy
- ✓ Each tool's strategy is documented
- ✓ Why (LTS preference) is clear
- ✓ How (specific methods) is shown

## Gaps Summary

**No gaps found.** All phase goals achieved:

1. ✓ Policy is documented and discoverable
2. ✓ Documentation explains the version selection philosophy
3. ✓ All major tools follow the documented strategy
4. ✓ Node.js uses `--lts` flag
5. ✓ Python tools use stable versions
6. ✓ Package managers use defaults (stable)
7. ✓ LTS > stable > latest hierarchy is established

## Re-verification Notes

None — this is initial verification of a completed phase.

---

**Verified:** 2026-01-22T23:15:00Z  
**Verifier:** Claude (gsd-verifier)  
**Status:** PASSED — All must-haves verified, goal achieved
