# Phase 10: Documentation - Research

**Researched:** 2026-01-23
**Domain:** Technical documentation, risk documentation, operational procedures, testing guidance
**Confidence:** HIGH

## Summary

This phase documents operational risks and procedures for the _dotfiles repository, completing the v0.3 Security & Documentation milestone. The focus is on three specific documentation requirements: (1) documenting the nvm curl-to-shell risk and mitigation options, (2) creating rollback/recovery procedures for common failure scenarios, and (3) adding theme system testing guidance to CLAUDE.md for maintainers.

Phase 9 successfully pinned or documented all curl-to-shell scripts. Now Phase 10 captures the "why" and "how to fix it if it breaks" knowledge that a maintainer needs. The documentation should be practical, findable, and focused on operational reality rather than comprehensive coverage.

**Primary recommendation:** Add a new "Security Considerations" section to README.md for nvm risk documentation, create a new "Troubleshooting" section in README.md for rollback/recovery procedures, and extend CLAUDE.md's existing "Nerd Font / Powerline Characters" section with theme testing guidance.

## Current State Analysis

### Existing Documentation Structure

| File | Purpose | Current Sections | Maintainer-Focused? |
|------|---------|------------------|---------------------|
| README.md | User-facing guide | Quick Start, Secrets, What's Included, Themes, Project Structure | Mixed (user + dev) |
| CLAUDE.md | AI assistant instructions | Tech Stack, Commands, Patterns, Code Style, Version Policy, Claude Code Config, Nerd Fonts | Yes (dev-focused) |
| .planning/ | GSD planning artifacts | PROJECT.md, ROADMAP.md, REQUIREMENTS.md, phase docs | Yes (planning) |
| Phase docs | Implementation details | RESEARCH, PLAN, SUMMARY, VERIFICATION per phase | Yes (historical) |

**Key findings:**
- README.md has no "Troubleshooting" or "Security" sections currently
- CLAUDE.md already has a "Nerd Font / Powerline Characters" section that discusses theme system complexity
- Phase 9 added security comments inline in playbooks but no centralized risk documentation
- No recovery procedures exist anywhere in the codebase

### DOC-01: nvm Curl-to-Shell Risk

**Current state:**
- nvm is pinned to v0.40.1 in `tools/node/install_node.yml` (line 46)
- No security comments exist on the nvm task (unlike rustup/starship which Phase 9 documented)
- nvm is mentioned in README.md and CLAUDE.md as a dependency for Node.js
- Phase 9 research (09-RESEARCH.md) identified nvm as "already pinned" but noted it should be updated to v0.40.3

**What needs documenting:**
1. Why nvm uses curl-to-shell pattern (official installation method)
2. Why it's pinned to a specific version (supply chain risk mitigation)
3. What the risk is if compromised (code execution during setup)
4. Mitigation options available (Homebrew on macOS, manual binary install, accept risk with pinning)
5. How to update the pinned version

### DOC-02: Rollback/Recovery Procedures

**Common failure scenarios identified:**

From architecture analysis and codebase exploration:

1. **Theme changes break terminal display** - Nerd Font glyphs not rendering, colors unreadable
2. **Ansible playbook fails mid-run** - Partial installation, broken dependencies
3. **Version pinning becomes outdated** - Pinned scripts/binaries unavailable or insecure
4. **GPG key expiration** - APT updates fail (GitHub CLI key expires September 2026)
5. **SOPS decryption fails** - Age key missing or incorrect
6. **Tool installation fails on OS** - Conditional logic error, package unavailable

**Recovery needs:**
- How to revert theme to defaults
- How to rerun failed playbook safely (idempotency guarantees)
- How to update pinned versions
- How to rotate expired GPG keys
- How to restore from backup or rebuild from scratch
- When to use `--check` mode to preview changes

### DOC-03: Theme System Testing Guidance

**Current theme system complexity:**

From analysis of `themes/` directory and CLAUDE.md:
- Theme playbooks modify 9 config files: tmux, starship, neovim, wezterm, lazygit, fzf, bat, lazydocker
- Uses regex replacements with Nerd Font escape sequences
- Three dimensions: color (8 schemes), font (multiple), style (6 powerline styles + none)
- CLAUDE.md already warns about Nerd Font character editing problems
- `themesetting` interactive command for applying themes

**Testing guidance needed:**
1. How to test theme changes before committing
2. What to check after theme playbook runs (visual validation across tools)
3. How to verify Nerd Font glyphs don't get corrupted during edits
4. How to test theme playbooks in `--check` mode
5. Common mistakes when editing theme playbooks (e.g., editing special characters directly)
6. How to verify all affected tools updated correctly

## Standard Stack

This phase uses existing tools and documentation formats from the codebase. No new libraries required.

### Documentation Format

| Format | Location | Purpose | Tool |
|--------|----------|---------|------|
| Markdown | README.md | User-facing documentation | Plain markdown |
| Markdown | CLAUDE.md | AI/maintainer instructions | Plain markdown |
| Markdown | .planning/ | Planning artifacts (optional reference) | Plain markdown |
| YAML comments | playbooks | Inline security notes | Ansible comments |

### Information Architecture

**Principle:** Documentation should be findable in expected locations.

| Audience | Question | Look in |
|----------|----------|---------|
| New user | "How do I install this?" | README.md Quick Start |
| User | "Something broke, how do I fix it?" | README.md Troubleshooting (NEW) |
| Security auditor | "What are the risks?" | README.md Security (NEW) |
| Maintainer | "How do I modify this safely?" | CLAUDE.md |
| AI assistant | "What patterns should I follow?" | CLAUDE.md |
| Developer | "Why was this decision made?" | .planning/ (optional) |

## Architecture Patterns

### Pattern 1: Risk Documentation with Mitigation Matrix

**What:** Document each identified risk with severity, impact, and mitigation options

**Structure:**
```markdown
## Security Considerations

### Curl-to-Shell Installation Patterns

**Risk:** Some tools use `curl | bash` installation (downloading and executing remote scripts).

**Affected Tools:**
- nvm (Node Version Manager) - pinned to v0.40.1
- rustup (Rust toolchain) - unpinnable, official installer only
- starship (shell prompt) - unpinnable, binary alternative available

**Mitigation:**
| Tool | Status | Mitigation | Alternative |
|------|--------|------------|-------------|
| nvm | Pinned | Version locked to v0.40.1 | Homebrew on macOS |
| rustup | Documented | Accept risk with HTTPS verification | Standalone installer with GPG |
| starship | Documented | Accept risk | Direct binary download with checksum |

**How to update pinned versions:**
1. Check for new releases: `curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name`
2. Review changelog for security fixes
3. Update version in `tools/node/install_node.yml`
4. Test installation on clean VM or with `--check` mode
```

### Pattern 2: Scenario-Based Recovery Procedures

**What:** Document recovery steps for specific failure scenarios, not generic troubleshooting

**Structure:**
```markdown
## Troubleshooting

### Scenario: Theme Change Broke Terminal Display

**Symptoms:**
- Powerline separators show as boxes or question marks
- Colors are unreadable
- Tmux statusline corrupted

**Recovery:**
1. Restore defaults: `ansible-playbook themes/apply_defaults.yml`
2. Reload tmux: `tmux source-file ~/.tmux.conf`
3. Restart terminal

**Prevention:** Always test theme in `--check` mode first:
\`\`\`bash
ansible-playbook themes/_color.yml -e color=dracula --check --diff
\`\`\`

### Scenario: Ansible Playbook Failed Mid-Run

**Symptoms:**
- Playbook stopped with error
- Some tools installed, others not
- Unclear what state system is in

**Recovery:**
1. Ansible is idempotent - safe to rerun: `ansible-playbook setup.yml`
2. If specific tool failed, run just that tool: `ansible-playbook tools/neovim/install_neovim.yml`
3. Check logs for actual error (dependency missing, network failure, etc.)

**Note:** All tool playbooks use `creates:` guards - will skip if already installed.
```

### Pattern 3: Testing Checklist for Theme Changes

**What:** Provide actionable checklist for validating theme changes before commit

**Structure:**
```markdown
## Nerd Font / Powerline Characters

[existing content...]

### Testing Theme Changes

Before committing theme playbook modifications:

**Pre-commit checks:**
- [ ] Run in `--check` mode: `ansible-playbook themes/_color.yml -e color=nord --check`
- [ ] Verify no special characters corrupted (diff should show only hex color changes)
- [ ] Grep for unexpected character replacements: `git diff themes/`

**Post-apply visual validation:**
- [ ] tmux: Powerline separators render correctly in statusline
- [ ] starship: Prompt arrows visible and styled
- [ ] neovim: Statusline arrows present (open nvim, check bottom bar)
- [ ] fzf: Preview window styled correctly (`Ctrl+R` to test)
- [ ] lazygit: Border colors changed (`gg` to launch)

**If glyphs corrupted:**
1. DO NOT commit the broken file
2. Restore from git: `git checkout -- themes/_style.yml`
3. Use escape sequences instead (see "Editing Approaches" section)
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Documentation site | Custom static site generator | Plain markdown in repo | Maintainers read in IDE/GitHub |
| Version tracking | Database of installed versions | Ansible facts + `creates:` guards | Built-in idempotency |
| Backup system | Automated snapshots | Git history + re-run playbooks | Idempotent deployment = recovery |
| GPG key monitoring | Cron job checking expiration | Manual check + calendar reminder | Only 9 keys, checked quarterly |

**Key insight:** This is a personal dotfiles repo, not a product. Documentation serves a single maintainer and AI assistants. Simple markdown in expected locations beats elaborate systems.

## Common Pitfalls

### Pitfall 1: Documenting Implementation Instead of Intent

**What goes wrong:** Documentation explains how code works rather than why decisions were made or how to recover from problems.

**Example of bad documentation:**
```markdown
## nvm Installation
The playbook uses ansible.builtin.shell to curl the nvm install script and pipe to bash.
```

**Example of good documentation:**
```markdown
## nvm Installation Risk
nvm requires curl-to-shell installation (no package manager version). Pinned to v0.40.1 to prevent supply chain attacks. Alternative: Use Homebrew on macOS.
```

**How to avoid:** Document the "why" (risk, decision, tradeoff) and "how to fix" (recovery, alternatives), not the "what" (implementation).

### Pitfall 2: Creating Documentation Users Won't Find

**What goes wrong:** Documentation placed in non-obvious locations like `.planning/docs/SECURITY.md` instead of README.md.

**Why it happens:** Desire to keep README "clean" and avoid clutter.

**How to avoid:** User mental model > organizational purity. Users expect:
- Security info in README.md or SECURITY.md in root
- Troubleshooting in README.md
- Code style in CONTRIBUTING.md or CLAUDE.md

**Warning signs:** If you have to explain where documentation is, it's in the wrong place.

### Pitfall 3: Over-Documenting Edge Cases

**What goes wrong:** Documentation becomes overwhelming with rare scenarios, burying common cases.

**Example:** Documenting every possible Ansible error code instead of the 3 common failure patterns.

**How to avoid:** Document only scenarios that have happened or are likely (>10% probability). Use "Common scenarios" vs "Other issues" structure.

### Pitfall 4: Forgetting to Update After Changes

**What goes wrong:** Phase 9 pins Homebrew to commit SHA, but doesn't document how to update it. Future maintainer doesn't know the process.

**How to avoid:** For every "this is the current state" statement, add "how to update this" guidance.

**Example:**
```markdown
Homebrew pinned to commit 90fa3d58 (2026-01-23).

**To update:**
1. Check latest commit: https://github.com/Homebrew/install/commits/master
2. Update SHA in `bootstrap.sh` and `tools/homebrew/install_homebrew.yml`
3. Update date in comment
```

## Code Examples

### Example 1: Security Considerations Section (README.md)

```markdown
## Security Considerations

### Curl-to-Shell Installation Patterns

Some tools use `curl | bash` installation patterns (downloading and executing remote scripts). This is a known security risk but sometimes unavoidable when package managers don't provide the tool.

**Mitigation strategies:**
- **Pinned versions:** nvm locked to v0.40.1 (see `tools/node/install_node.yml`)
- **Documented risk:** rustup and starship cannot be pinned (see playbook comments)
- **GPG verification:** Package repositories use documented key fingerprints (see Phase 9)
- **Checksum verification:** Binary downloads verified with SHA256 (sops, k9s, etc.)

**Tools using curl-pipe:**
| Tool | Status | Mitigation | Last Updated |
|------|--------|------------|--------------|
| nvm | Pinned to v0.40.1 | Version locked | 2026-01-23 |
| Homebrew | Pinned to commit 90fa3d58 | Git commit SHA | 2026-01-23 |
| Pulumi | Pinned to v3.216.0 | `--version` flag | 2026-01-23 |
| uv | Pinned to v0.9.26 | Versioned URL | 2026-01-23 |
| rustup | Cannot pin | HTTPS + official domain | N/A |
| starship | Cannot pin | Alternative: binary download | N/A |

**To update pinned versions:**
1. Check for latest release: `curl -s https://api.github.com/repos/<org>/<repo>/releases/latest | jq -r .tag_name`
2. Review changelog for security fixes
3. Update version in corresponding `tools/<tool>/install_<tool>.yml`
4. Test with `ansible-playbook tools/<tool>/install_<tool>.yml --check`

**Unpinnable tools:**
- **rustup:** Official installer at https://sh.rustup.rs has no versioning. Alternative: standalone installers with GPG signatures (see https://forge.rust-lang.org/infra/other-installation-methods.html)
- **starship:** Installer has no versioning. Alternative: download binary directly from GitHub releases with SHA256 checksum verification
```

### Example 2: Troubleshooting Section (README.md)

```markdown
## Troubleshooting

### Theme Changes

#### Powerline Separators Show as Boxes

**Cause:** Terminal doesn't have a Nerd Font installed.

**Fix:**
1. Install a Nerd Font (playbook installs JetBrainsMono Nerd Font automatically)
2. Set terminal font to "JetBrainsMono Nerd Font"
3. Reload terminal

#### Colors Unreadable After Theme Change

**Cause:** Theme doesn't match terminal background or personal preference.

**Fix:**
1. Restore defaults: `ansible-playbook themes/apply_defaults.yml`
2. Try different theme: `themesetting` (interactive selector)

#### Theme Playbook Corrupted Special Characters

**Cause:** Nerd Font glyphs edited directly instead of using escape sequences.

**Fix:**
1. Restore from git: `git checkout -- themes/_style.yml themes/_color.yml`
2. Review CLAUDE.md "Nerd Font / Powerline Characters" section
3. Use escape sequences for edits (`\uE0B0` not literal character)

### Playbook Failures

#### Playbook Stopped with Error

**Recovery:**
1. Read the error message - usually indicates missing dependency or network issue
2. Rerun the playbook - Ansible is idempotent: `ansible-playbook setup.yml`
3. If single tool fails, run just that tool: `ansible-playbook tools/<tool>/install_<tool>.yml`

**Common causes:**
- Network timeout - rerun playbook
- Missing dependency - install manually first
- Permission denied - check `become: yes` in task

#### GPG Key Expired (APT Update Fails)

**Symptoms:**
```
Err:1 https://cli.github.com/packages stable InRelease
  The following signatures were invalid: EXPKEYSIG ...
```

**Recovery:**
1. Check playbook for key fingerprint comment (e.g., `tools/gh/install_gh.yml`)
2. Re-download key: `curl -fsSL <KEY_URL> | sudo gpg --dearmor -o /etc/apt/keyrings/<tool>.gpg`
3. Rerun apt update: `sudo apt update`

**Known expirations:**
- GitHub CLI key expires September 2026 (check https://github.blog/changelog for rotation)

#### SOPS Decryption Failed

**Symptoms:**
```
Failed to get the data key required to decrypt the SOPS file.
```

**Recovery:**
1. Check Age key exists: `ls ~/.config/sops/age/keys.txt`
2. If missing, restore from 1Password:
   ```bash
   op read "op://Automation/Age Key/Private Key" > ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```
3. Rerun playbook

### Starting Over

If everything is broken and you want a clean slate:

```bash
# Backup your customizations
cp ~/.zshrc ~/.zshrc.backup
cp ~/.tmux.conf ~/.tmux.conf.backup

# Remove dotfiles
cd ~
rm -rf _dotfiles

# Re-bootstrap
curl -fsSL https://raw.githubusercontent.com/matttelliott/_dotfiles/master/bootstrap.sh | bash
```

**Note:** Ansible playbooks are idempotent - they won't break existing working setups. Most "failures" are recoverable by rerunning the playbook.
```

### Example 3: Theme Testing Guidance (CLAUDE.md)

```markdown
## Nerd Font / Powerline Characters

[... existing content ...]

### Testing Theme Changes

Theme playbooks modify 9 config files using regex replacements. Because Nerd Font characters are problematic for LLMs and text editors, theme changes require careful testing.

**Before committing theme changes:**

1. **Run in check mode first:**
   ```bash
   ansible-playbook themes/_color.yml -e color=dracula --check --diff
   ```
   Review diff output for unexpected changes.

2. **Verify special characters not corrupted:**
   ```bash
   git diff themes/ | grep -E '\\u[0-9A-F]{4}|nr2char'
   ```
   Should show escape sequences (`\uE0B0`, `nr2char(0xe0b0)`), NOT boxes or spaces.

3. **Visual validation after applying theme:**
   - [ ] **tmux statusline:** Arrows visible between segments (`<C-b> d` to detach and check)
   - [ ] **starship prompt:** Powerline separators visible (type any command, check prompt)
   - [ ] **neovim statusline:** Open nvim, check bottom bar has arrows
   - [ ] **fzf:** `Ctrl+R` for history, check border and preview styling
   - [ ] **lazygit:** Run `gg`, verify border colors changed

4. **Common mistakes checklist:**
   - [ ] Did NOT edit special characters directly in files
   - [ ] Used escape sequences for any manual edits (`\uE0B0`, `nr2char(0xe0b0)`)
   - [ ] Tested on actual machine, not just `--check` mode
   - [ ] Verified tmux reloaded: `tmux source-file ~/.tmux.conf`
   - [ ] Restarted shell for starship/fzf changes

**If theme breaks:**
1. Restore defaults: `ansible-playbook themes/apply_defaults.yml`
2. Check git diff: `git diff themes/` to see what changed
3. Restore corrupted files: `git checkout -- themes/_style.yml`

**Testing new theme definitions:**

When adding a new color scheme to `themes/_color.yml`:
1. Add color definition to `colors:` dict
2. Test on all affected tools: `ansible-playbook themes/_color.yml -e color=newtheme`
3. Check each tool manually (can't automate visual verification)
4. Document in README if theme requires specific terminal settings

**Why this matters:**
Theme playbooks touch multiple config files with special Unicode characters. A single corrupted glyph can break multiple tools. The regex patterns are fragile - they rely on exact character matching. Always test visually before committing.
```

## State of the Art

Documentation best practices have evolved toward "docs as code" and maintainer empathy:

| Old Approach | Current Approach | Why Changed |
|--------------|------------------|-------------|
| Comprehensive wikis | Focused markdown in repo | Wikis go stale, repo docs versioned with code |
| Generic troubleshooting | Scenario-based recovery | Users search for symptoms, not categories |
| "See documentation" | Inline examples | Context switching kills momentum |
| Separate docs repo | Docs alongside code | Single source of truth |

**For dotfiles repos specifically:**
- Users expect README.md to be complete
- Security-conscious users look for SECURITY.md or security section in README
- AI assistants benefit from CLAUDE.md or similar instructions file
- Planning docs (.planning/) are developer artifacts, not user-facing

## Open Questions

### 1. Where to document GPG key rotation procedures?

**What we know:**
- GitHub CLI key expires September 2026 (known future event)
- 9 tools use APT repositories with GPG keys
- Phase 9 added fingerprint comments to all playbooks

**What's unclear:**
- Should there be a centralized "GPG key maintenance" section?
- Or document per-tool in troubleshooting?
- How to track expiration dates proactively?

**Recommendation:** Document in Troubleshooting section under "GPG Key Expired" scenario. Add calendar reminder for September 2026 GitHub CLI key renewal (outside scope of this phase).

### 2. How much detail for rollback procedures?

**What we know:**
- Ansible is idempotent - safe to rerun
- No persistent state except installed files
- Git history provides backup

**What's unclear:**
- Do we need step-by-step "nuclear option" instructions?
- Or is "rerun the playbook" sufficient for most cases?

**Recommendation:** Document "Starting Over" as nuclear option, but emphasize idempotency means most failures recoverable by rerunning. Don't over-document unlikely scenarios.

### 3. Should phase 9 security comments be centralized?

**What we know:**
- Phase 9 added inline comments to rustup/starship playbooks
- Homebrew, Pulumi, uv, nvm have version pinning but no explanatory comments
- Security auditor would have to grep entire codebase

**What's unclear:**
- Is README.md "Security Considerations" section sufficient?
- Or should we add comments to all pinned scripts for discoverability?

**Recommendation:** README.md section is sufficient for overview. Inline comments only needed for unpinnable scripts (rustup/starship) where the comment explains the limitation. Don't duplicate README content in 6 playbooks.

## Sources

### Primary (HIGH confidence)
- [_dotfiles codebase](file:///home/matt/_dotfiles) - Current documentation structure analyzed directly
- [Phase 9 RESEARCH.md](.planning/phases/09-script-security/09-RESEARCH.md) - Security patterns established in prior phase
- [README.md](README.md) - Current user-facing documentation
- [CLAUDE.md](CLAUDE.md) - Current maintainer documentation

### Secondary (MEDIUM confidence)
- [Write the Docs - Documentation Principles](https://www.writethedocs.org/guide/writing/docs-principles/) - Industry best practices for technical documentation
- [GitHub Security Advisories Documentation](https://docs.github.com/en/code-security/security-advisories) - Security documentation patterns
- [Divio Documentation System](https://documentation.divio.com/) - Four types of documentation (tutorial, how-to, reference, explanation)

### Domain Knowledge (HIGH confidence - from prior analysis)
- Ansible idempotency guarantees safe reruns
- Nerd Font characters are Unicode Private Use Area (U+E0xx, U+F0xx)
- Theme system modifies 9 config files via regex replacements
- nvm v0.40.1 pinned in tools/node/install_node.yml
- GPG keys documented with fingerprints in Phase 9

## Metadata

**Confidence breakdown:**
- Documentation structure: HIGH - Direct codebase analysis
- Risk documentation patterns: HIGH - Security best practices well-established
- Recovery procedures: HIGH - Ansible behavior well-understood
- Theme testing: MEDIUM - Complex system, some procedures based on inference

**Research date:** 2026-01-23
**Valid until:** 180 days (documentation patterns stable, codebase context current)

---

*Research completed: 2026-01-23*
*Phase: 10-documentation*
*Requirements: DOC-01, DOC-02, DOC-03*
