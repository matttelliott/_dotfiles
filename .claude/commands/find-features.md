---
description: Discover, evaluate, and selectively adopt new tools, features, and plugins
argument-hint: <tool or domain, e.g. "nvim", "tmux keybindings", "frontend debugging">
---

# MANDATORY BEHAVIOR

- Every suggestion must be a SINGLE, SPECIFIC, CONCRETE feature — not a category, not a group.
  - GOOD: "oil.nvim — file explorer that works like a buffer"
  - BAD: "File Management Plugins" or "Linting Improvements"
- You MUST use `AskUserQuestion` to let the user choose which feature to evaluate. Do not just list features and ask in prose.
- You MUST evaluate ONE feature at a time. Install it, let the user test it, get their verdict, then move on.
- You MUST show a changeset and get confirmation BEFORE installing anything.
- You MUST NOT touch the dotfiles repo until the user accepts a feature.

---

If no arguments provided, show usage and stop:
```
Usage: /find-features <tool or domain>
Examples:
  /find-features nvim
  /find-features tmux keybindings
  /find-features fzf
```

---

## Step 1: Understand the scope

Parse `$ARGUMENTS` to determine which `tools/<tool>/` directories are relevant.

## Step 2: Read current config

Read the relevant files in `tools/<tool>/` — playbooks, shell config, tool configs. Understand what's already installed.

## Step 3: Show what's already configured

Before suggesting anything new, show a table of existing features relevant to the query:

| Feature | What it does | Keybinding / Command |
|---------|-------------|---------------------|

This helps the user know what they already have.

## Step 4: Research

WebSearch for new features, plugins, and recommendations. Use Context7 for official docs if useful. Filter out everything already configured.

## Step 5: Let the user pick a feature

Show 5-10 suggestions as a numbered list. Each must be a single concrete feature with a one-sentence description.

Then call `AskUserQuestion` with the features as options (use the feature name as the label, the description as the description). Single select. Include a "Done — no more features" option.

If the user picks "Done", go to Step 8.

## Step 6: Evaluate the chosen feature

### 6a: Show the changeset

Print exactly what will be installed/modified/created. Example:

```
Changeset for: oil.nvim
───────────────────────
Packages to install:  none
Files to modify:      ~/.config/nvim/init.lua (add plugin spec)
Files to create:      none
```

Use `AskUserQuestion` to confirm: "Install this?" with options "Yes" and "Skip this feature".

If skipped, go back to Step 5 with remaining features.

### 6b: Install it

- Install packages if needed
- Modify LIVE config files (NOT the dotfiles repo)
- Reload where possible
- Track everything you changed (packages, files modified, files created)

### 6c: Guide the user

Tell the user:
1. What the feature does
2. Exactly how to try it (specific commands, keybindings, or actions)
3. What to look for

Then call `AskUserQuestion` with exactly these options:
- **Accept** — "Keep it and add to dotfiles repo"
- **Tweak** — "Adjust the configuration"
- **Reject** — "Remove it completely"

### 6d: Handle the verdict

**If Accept:**
- Port the config into `tools/<tool>/` in the dotfiles repo
- Update ansible playbooks if new packages were added
- Follow existing repo patterns (OS detection, `become: yes`, 2-space YAML)
- Tell user what was added, remind them it's unstaged

**If Tweak:**
- Ask what to change
- Apply changes to live config
- Go back to 6c

**If Reject:**
- Uninstall any packages that were installed
- Delete any files that were created
- Restore any modified files from the dotfiles repo (`tools/<tool>/`)
- For `.j2` templates, run the ansible playbook instead
- Confirm cleanup is complete

## Step 7: Next feature

Go back to Step 5. Show the remaining features (mark evaluated ones as accepted/rejected). Let the user pick the next one or choose "Done".

## Step 8: Summary

```
Session Summary
═══════════════
Accepted:  [list what was kept]
Rejected:  [list what was removed]
Skipped:   [list what wasn't tried]
```

If anything was accepted, remind user to `git diff` and commit.

---

## Additional rules

- **Nerd Font characters** — use escape sequences, never edit glyphs directly (see CLAUDE.md)
- **Clean rejection** — `git status` must be clean and the tool gone from the system after reject
