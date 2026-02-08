---
description: Discover, evaluate, and selectively adopt new tools, features, and plugins
argument-hint: <tool or domain, e.g. "nvim", "tmux keybindings", "frontend debugging">
---

# CRITICAL RULES — READ BEFORE DOING ANYTHING

1. You MUST evaluate features ONE AT A TIME. Never install more than one feature at a time. Never offer to install multiple features at once. Never ask "which ones do you want?" — you walk through them sequentially.
2. You MUST NOT modify the dotfiles repo during trial. Only modify live config files. The repo is only touched when the user accepts a feature.
3. You MUST present a changeset and get confirmation BEFORE installing anything.
4. You MUST fully clean up rejected features — uninstall packages, delete created files, restore modified configs.
5. You MUST show existing features BEFORE suggesting new ones.

If you violate any of these rules, you have failed. Re-read them after every phase.

---

If no arguments provided, show usage:
```
Usage: /find-features <tool or domain>
Examples:
  /find-features nvim
  /find-features tmux keybindings
  /find-features frontend debugging
  /find-features fzf
```

## Phase 1: Parse Input

Determine what to explore from: `$ARGUMENTS`

- **Tool name** (e.g., `nvim`, `tmux`, `fzf`): Map to `tools/<tool>/` directory
- **Domain** (e.g., `frontend debugging`): Scan `tools/` to find relevant tools
- **Tool + topic** (e.g., `nvim lint`): Focus on that tool filtered by topic

## Phase 2: Scan Current Config

Read the files in `tools/<tool>/` in this repo:
- Ansible playbooks (`install_*.yml`) — packages and plugins installed
- Shell config (`*.zsh`) — aliases, functions, env vars
- Tool configs (`init.lua`, `tmux.conf.j2`, `starship.toml`, etc.) — plugins, keybindings, settings

## Phase 3: Show Existing Features

Present what's already configured before suggesting anything new:

| Feature | What it does | Key bindings / Commands | Usage example |
|---------|-------------|------------------------|---------------|

## Phase 4: Research

WebSearch for new features, plugins, community recommendations. Use Context7 for official docs. Filter out everything already configured.

## Phase 5: Present Suggestion List

Show 5-10 NEW suggestions:

| # | Feature | What it does | Effort |
|---|---------|-------------|--------|
| 1 | ... | ... | One-liner / Moderate / Significant |

After showing this list, use `AskUserQuestion` to ask which SINGLE feature they want to evaluate FIRST. Include a "None — I'm done" option.

DO NOT offer to install multiple. DO NOT ask "which ones do you want." Ask which ONE to try FIRST.

## Phase 6: Evaluate the Chosen Feature

This phase handles exactly ONE feature. Follow these steps in order:

### Step 1: Show the changeset

BEFORE touching anything, show what will change:

```
Changeset for: [Feature Name]
─────────────────────────────
Packages to install:   [list or "none"]
Files to modify:       [list with what changes]
Files to create:       [list or "none"]
```

Ask for confirmation to proceed.

### Step 2: Apply changes

- Install packages if needed
- Modify LIVE config files only (NOT the dotfiles repo!)
- Reload configs where possible (tmux source-file, etc.)

Track every change:
- Packages installed (exact install command for reversal)
- Files modified (note original source in dotfiles repo)
- Files created (full paths)
- Directories created (full paths)

### Step 3: User tests it

Tell the user how to use the feature. Then ask:

Use `AskUserQuestion` with three options:
- **Accept** — keep it, port to dotfiles repo
- **Tweak** — adjust the configuration
- **Reject** — remove it completely

### Step 4a: If Accept

Port the final config into the dotfiles repo (`tools/<tool>/`):
- Add to existing config files, ansible playbooks, etc.
- Follow existing repo patterns (OS detection, `become: yes`, `creates:`, 2-space YAML)
- Live installation stays in place

Tell user what was added. Remind them changes are unstaged.

### Step 4b: If Tweak

Ask what to change. Apply to live config. Update changeset tracking. Go back to Step 3.

### Step 4c: If Reject

Reverse ALL changes:
1. Uninstall packages (`brew uninstall`, `npm uninstall -g`, etc.)
2. Delete created files and directories
3. Restore modified files from dotfiles repo (copy from `tools/<tool>/` or run the tool's ansible playbook for `.j2` templates)
4. Verify cleanup is complete

## Phase 7: Next Feature

After the feature is accepted or rejected, show the suggestion list again with the evaluated feature marked. Use `AskUserQuestion` to ask which feature to evaluate NEXT. Include "Done" option.

If "Done" or all features evaluated, go to Phase 8.
Otherwise, go back to Phase 6 with the next chosen feature.

## Phase 8: Summary

```
Feature Discovery Summary
═════════════════════════
Accepted:
  - [feature]: added to tools/<tool>/...

Rejected (cleaned up):
  - [feature]: removed

Skipped:
  - [feature]: not evaluated
```

If anything was accepted, remind user to review with `git diff` and commit when ready.

## Additional Rules

- **Nerd Font characters** — Do NOT edit files containing Powerline glyphs directly. Use escape sequences per CLAUDE.md.
- **Clean rejection** — After reject, `git status` in dotfiles repo must be clean and the tool must be gone from the system.
- **User stops anytime** — Always offer "Done" as an option.
