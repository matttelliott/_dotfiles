---
description: Discover, evaluate, and selectively adopt new tools, features, and plugins
argument-hint: <tool or domain, e.g. "nvim", "tmux keybindings", "frontend debugging">
---

Discover new features and plugins for the user's tools. Research what's available, let them trial ONE feature at a time on their live system, and only commit accepted changes to the dotfiles repo.

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

Determine what the user wants to explore from: `$ARGUMENTS`

- **Tool name** (e.g., `nvim`, `tmux`, `fzf`): Map directly to `tools/<tool>/` directory
- **Domain** (e.g., `frontend debugging`, `git workflow`): Scan `tools/` directories to identify which installed tools are relevant to the domain
- **Tool + topic** (e.g., `nvim lint`, `tmux keybindings`): Focus on that tool's config filtered by topic

List the tool directories you'll examine. Confirm with the user if the scope is ambiguous.

## Phase 2: Scan Current Config

For each relevant tool, read the files in `tools/<tool>/` in this repo:
- Ansible playbooks (`install_*.yml`) — what packages and plugins are installed
- Shell config (`*.zsh`) — aliases, functions, environment variables
- Tool configs (e.g., `init.lua`, `tmux.conf.j2`, `starship.toml`) — plugins, keybindings, settings
- Any subdirectories with additional config

Build a mental model of what's already configured.

## Phase 3: Show Existing Features

Before suggesting anything new, present what's already configured that's relevant to the query. Format as:

### Existing: [Tool Name]

| Feature | What it does | Key bindings / Commands | Usage example |
|---------|-------------|------------------------|---------------|
| ... | ... | ... | ... |

Include:
- Installed plugins and what they do
- Relevant keybindings
- Aliases and shell functions
- Brief usage examples or tips

This doubles as a reference — the user may not know everything they already have.

## Phase 4: Research New Features

Use WebSearch to find:
- Recent releases, changelogs, and new features for the tool(s)
- Popular plugins and extensions the user doesn't have
- Community recommendations (Reddit, HN, GitHub trending)
- Best practices and workflow improvements

Use Context7 (`mcp__context7__resolve-library-id` then `mcp__context7__query-docs`) for official documentation when useful.

Filter out everything already configured from Phase 2.

## Phase 5: Present Suggestions

Show 5-10 suggestions, each with a one-line description:

### Suggestions: [Tool Name]

| # | Feature | What it does | Effort |
|---|---------|-------------|--------|
| 1 | ... | ... | One-liner / Moderate / Significant |
| 2 | ... | ... | ... |

Then start evaluating them **one at a time**, beginning with #1. Ask the user which one they want to evaluate first, or if they want to start from the top.

## Phase 6: Evaluate One Feature

For the current feature:

### 6a: Plan the Changeset

Before making ANY changes, document and present the changeset:

```
Changeset for: [Feature Name]
───────────────────────────────
Packages to install:
  - brew install foo

Files to modify:
  - ~/.config/nvim/init.lua (add plugin config)

Files to create:
  - ~/.config/tool/new-config.lua

Directories to create:
  - ~/.config/tool/subdir/
```

Present to user and get confirmation before applying.

### 6b: Apply Changes

- Install packages (brew, npm, pip, cargo, etc.)
- Modify live config files directly (NOT the dotfiles repo)
- Create any new files/directories needed
- Reload configs where possible (e.g., `tmux source-file`, tell user to restart nvim)

**Track everything** — maintain a running record of:
- Packages installed (with exact install command for reversal)
- Files modified (note the original state or source file in dotfiles repo)
- Files created (full paths)
- Directories created (full paths)

### 6c: User Evaluation

Tell the user the feature is ready to test and explain how to use it.

Then ask: Accept / Tweak / Reject

- **Tweak**: Ask what they want changed. Apply changes to the live config. Update the changeset tracking. Return to 6c.
- **Accept**: Go to 6d.
- **Reject**: Go to 6e.

### 6d: Accept — Port to Dotfiles Repo

Port the final (possibly tweaked) configuration into the dotfiles repo:

1. Update the relevant files in `tools/<tool>/`:
   - Add plugin configs, keybindings, settings to existing config files
   - Add new packages to ansible playbooks (`install_*.yml`)
   - Create new config files if needed
2. Follow existing patterns in the repo:
   - Use OS detection (`ansible_facts['os_family']`) in playbooks
   - Use `become: yes` for Linux package manager tasks
   - Use `creates:` for idempotent commands
   - Match existing code style (2-space YAML, etc.)
3. The live local installation stays in place — it's already working

Tell the user what was added to the repo. Remind them these changes are unstaged.

### 6e: Reject — Full Cleanup

Reverse ALL changes from the changeset:

1. **Uninstall packages**: Run the reverse of every install command
   - `brew uninstall foo`
   - `npm uninstall -g bar`
   - `pip uninstall -y baz`
   - `cargo uninstall qux`

2. **Delete created files and directories**:
   - `rm` any files that were created
   - `rmdir` any directories that were created (only if empty)

3. **Restore modified config files**: For each modified file:
   - If the file exists in the dotfiles repo (`tools/<tool>/`), copy it back
   - If it's a template (`.j2`), run the tool's ansible playbook instead:
     ```
     ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
     ```
   - Verify the file matches its pre-trial state

4. **Verify cleanup**: Confirm packages are gone and configs are restored.

Tell the user what was cleaned up.

## Phase 7: Next Feature

After accepting or rejecting, show the remaining suggestions list (with the evaluated one marked as accepted/rejected) and ask which feature to evaluate next. Include a "Done" option to stop.

Repeat Phase 6 for the next chosen feature. Continue until the user says "Done" or all features have been evaluated.

## Phase 8: Wrap Up

Summarize the session:

```
Feature Discovery Summary
═════════════════════════
Accepted:
  - [feature]: added to tools/<tool>/...

Rejected (cleaned up):
  - [feature]: uninstalled and restored
```

If any features were accepted, remind the user:
- Changes are in the dotfiles repo but **not committed**
- They can review with `git diff` and `git status`
- Commit when ready

## Important Rules

- **ONE AT A TIME** — Never trial multiple features simultaneously. The user picks one, evaluates it fully (accept/reject), then optionally picks another.
- **NEVER modify the dotfiles repo during trial** — only modify live configs. The repo is only touched on acceptance.
- **Track every change** — packages, files, directories. Cleanup depends on accurate tracking.
- **Respect Nerd Font characters** — Do NOT edit files containing Powerline glyphs directly. Use escape sequences per CLAUDE.md instructions.
- **Existing features first** — Always show what's already configured before suggesting new things.
- **Clean rejection** — After rejecting, `git status` in the dotfiles repo should be clean and the tool should be gone from the system.
- **Ask before acting** — Present changesets before applying. Let the user drive accept/tweak/reject.
- **User can stop anytime** — Always offer a "Done" option. Don't pressure the user to try more features.
