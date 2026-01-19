---
description: Propose, demo, and evaluate plugins/features for dotfiles tools
argument-hint: <tool> [feature-request]
---

# Feature Explorer

Propose, demo, configure, and evaluate features for a dotfiles tool. Features can be built-in configuration or require plugins. Accepted features are added to dotfiles and deployed; rejected ones are documented and rolled back.

## Arguments

- `$ARGUMENTS` = tool name + optional feature description or count
- Supported tools: neovim, tmux, zsh, starship, git

**Examples**:
```
/explore-features neovim                          # General neovim features
/explore-features neovim 5                        # 5 general features
/explore-features neovim unit testing             # Unit testing features
/explore-features neovim debugging python         # Python debugging features
/explore-features zsh fzf autocomplete            # fzf-based autocomplete
/explore-features tmux session management         # Session/workspace features
/explore-features neovim https://github.com/...   # Try specific plugin
```

## Parsing Arguments

1. First word = tool name (required)
2. If second word is a number = count of general features
3. If URL = try that specific plugin directly
4. Otherwise = feature description to focus research on

## Workflow Overview

```
1. Analyze → Understand existing config deeply (avoid conflicts!)
2. Research → Propose features based on current setup
3. Select → User picks features to try (checklist) or adds their own
4. Test Loop → For each selected feature:
   a. Add to dotfiles
   b. Deploy via Ansible
   c. User tests
   d. Configure (iterate with re-deploys)
   e. Keep or skip
5. Commit → Batch commit all accepted changes at end
```

## Tool Configuration Map

| Tool | Dotfiles Config | Ansible Playbook | Deploy Command |
|------|-----------------|------------------|----------------|
| neovim | `tools/neovim/nvim/` | `tools/neovim/install_neovim.yml` | `ansible-playbook tools/neovim/install_neovim.yml --connection=local --limit $(hostname -s)` |
| tmux | `tools/tmux/tmux.conf.j2` | `tools/tmux/install_tmux.yml` | `ansible-playbook tools/tmux/install_tmux.yml --connection=local --limit $(hostname -s)` |
| zsh | `tools/zsh/` | `tools/zsh/install_zsh.yml` | `ansible-playbook tools/zsh/install_zsh.yml --connection=local --limit $(hostname -s)` |
| starship | `tools/starship/starship.toml` | `tools/starship/install_starship.yml` | `ansible-playbook tools/starship/install_starship.yml --connection=local --limit $(hostname -s)` |
| git | `tools/git/gitconfig.j2` | `tools/git/install_git.yml` | `ansible-playbook tools/git/install_git.yml --connection=local --limit $(hostname -s)` |

## Step 1: Analyze Existing Configuration (CRITICAL)

**Thoroughly read and understand the current setup before proposing anything.**

### 1a. Read All Relevant Config Files

| Tool | Files to Read |
|------|---------------|
| neovim | `init.lua`, all files in `lua/kickstart/plugins/`, all files in `lua/custom/plugins/`, check for `lazy-lock.json` |
| tmux | `tmux.conf.j2`, check TPM plugins list |
| zsh | `zshrc`, all sourced `*.zsh` files in tools/ |
| starship | `starship.toml` |
| git | `gitconfig.j2` |

### 1b. Document What's Already Installed

Create a mental inventory of:
- **Plugins/packages** already installed
- **Keybindings** already mapped (especially `<leader>` keys)
- **Features** already configured
- **Dependencies** and their versions

### 1c. Identify Potential Conflicts

Watch for:
- **Keybinding conflicts**: Check which-key groups, existing `<leader>` mappings
- **Plugin conflicts**: Some plugins don't work together (e.g., multiple completion frameworks)
- **Version requirements**: Check nvim version, tmux version, etc.
- **Overlapping functionality**: Don't propose what's already covered

**For Neovim specifically**:
- Read the which-key spec to see all `<leader>` group definitions
- Check telescope keymaps (usually `<leader>s*`)
- Check LSP keymaps (usually `<leader>c*` or `g*`)
- Check diagnostic keymaps (usually `<leader>d*` or `[d`/`]d`)
- Note the plugin manager (lazy.nvim) and its conventions

### 1d. Present Summary to User

Before proposing features, briefly summarize:
```
Current setup:
- Plugin manager: lazy.nvim
- 15 plugins installed
- Leader key groups: s (search), c (code), d (diagnostics), g (git)
- Available leader keys: a, b, e, f, h, i, j, k, l, m, n, o, p, q, r, t, u, v, w, x, y, z
```

## Step 2: Propose Features

If user provided a **feature description**, use WebSearch to find solutions for that use case. Search for:
- `"<tool> <feature> 2025"` (e.g., "neovim unit testing 2025")
- `"best <tool> <feature>"` (e.g., "best zsh fzf integration")
- Check awesome-neovim, awesome-tmux, etc. lists

If **no feature specified**, propose general-purpose features that complement existing setup.

For each feature (default 5, or user-specified count), indicate whether it's **built-in** or requires a **plugin**:

```markdown
### [N]. **feature-name** - One-line description
**Type**: 🔧 Built-in | 📦 Plugin
**Why**: How it addresses the requested feature / complements current setup
**Repo**: https://github.com/... (if plugin)
**Keybindings**: Proposed keys (confirm no conflicts!)
**Demo**: How to test it
```

**Type indicators**:
- 🔧 **Built-in**: Native functionality, just needs configuration
- 📦 **Plugin**: Requires installing a third-party plugin

**Prefer built-in solutions** when they adequately solve the problem. Only suggest plugins when they provide significant value over built-in options.

**IMPORTANT**: Only propose keybindings that don't conflict with existing mappings!

## Step 3: User Selection

Use `AskUserQuestion` tool with `multiSelect: true` to let user pick which features to try:

```
question: "Which features do you want to try?"
header: "Features"
multiSelect: true
options:
  - label: "feature-name (built-in)"
    description: "One-line description"
  - label: "feature-name (plugin)"
    description: "One-line description"
  ...
  - label: "I have my own"
    description: "Provide a feature idea or plugin URL"
```

If user selects "I have my own", ask them to provide the details.

User can also skip the proposal phase entirely by providing a feature directly:
- `/explore-features neovim https://github.com/user/plugin`
- `/explore-features tmux "feature: vim keybindings"`

## Step 4: Testing Loop

For each selected feature:

### 4a. Add to Dotfiles

Add the feature configuration to dotfiles. Mark with `(TESTING)` comment.

**Neovim plugin**: Create `tools/neovim/nvim/lua/custom/plugins/<name>.lua`
```lua
-- feature-name - Description (TESTING)
return { ... }
```

**Neovim built-in**: Add to `tools/neovim/nvim/init.lua` or appropriate section
```lua
-- feature-name (TESTING)
vim.opt.something = true
```

**Tmux**: Add to `tools/tmux/tmux.conf.j2`
```bash
# feature-name (TESTING)
set -g option value
```

### 4b. Deploy via Ansible

```bash
ansible-playbook tools/<tool>/install_<tool>.yml --connection=local --limit $(hostname -s)
```

### 4c. User Tests

Tell user to restart the application and test. Explain what to try.

### 4d. Configure (Iterate)

User may request changes. For each change:
1. Edit the dotfiles config
2. Re-run Ansible playbook to deploy
3. User tests again

Repeat until satisfied.

### 4e. Decision

**"keep"** or **"keep it"**:
1. Remove `(TESTING)` comment
2. Config stays in dotfiles
3. Move to next feature

**"skip"**:
1. Remove feature config from dotfiles
2. Re-run Ansible playbook to revert
3. Document in rejected features list
4. Move to next feature

## Step 5: Track Rejected Features

Add rejected features to the main config:

**Neovim** (`tools/neovim/nvim/init.lua`):
```lua
-- [[ Rejected Plugins/Features ]]
-- feature-name: Brief reason for rejection
```

**Tmux** (`tools/tmux/tmux.conf.j2`):
```bash
# [[ Rejected Features ]]
# feature-name: Brief reason
```

## Step 6: Final Commit

1. Show summary:
   ```
   Kept: feature1 (built-in), feature2 (plugin)
   Skipped: feature3 (reason)
   ```

2. Review: `git status && git diff --stat`

3. Squash auto-commits if present

4. Create commit:
   ```
   Add <tool> features: feature1, feature2

   - feature1: Brief description (built-in)
   - feature2: Brief description (plugin)
   - Rejected: feature3 (reason)

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
   ```

5. Ask if user wants to push

## Tool-Specific Notes

### Neovim

- Plugins use lazy.nvim spec format in `lua/custom/plugins/<name>.lua`
- Built-in config goes in init.lua or appropriate section
- Follow `[X]` keybinding pattern (e.g., `desc = '[S]earch [F]iles'`)
- **Check telescope mappings** before using `<leader>s*`
- **Check which-key groups** before creating new `<leader>` prefixes
- Add which-key groups for new leader prefixes

### Tmux

- TPM plugins: add to plugins list
- Built-in: add settings directly
- **Check existing prefix mappings** before adding new ones
- User runs `prefix + I` to install TPM plugins
- Test in new session or `prefix + r`

### Zsh

- Measure startup time impact
- Many features are built-in (setopt, bindkey)
- **Check existing aliases** before adding new ones
- Plugin configs sourced from tools/<plugin>/<plugin>.zsh

### Starship

- Most features are built-in (just toml config)
- Changes apply on next prompt
- Check existing modules before adding similar ones

## Example Session

```
User: /explore-features neovim unit testing

Claude: [Reads init.lua, all plugin files, which-key config]

        "Analyzed your setup:
        - lazy.nvim with 20 plugins
        - Leader groups: s (search), c (code), d (diagnostics), g (git)
        - Available: <leader>t is FREE (good for [T]est)
        - You have nvim-dap for debugging already

        Found 5 unit testing features:"

        1. **neotest** - Test runner framework
           Type: 📦 Plugin
           Keybindings: <leader>tt (run nearest), <leader>tf (run file)
        2. **vim-test** - Lightweight test commands
           Type: 📦 Plugin
           Keybindings: <leader>tn (nearest), <leader>tf (file)
        3. **Built-in terminal** - Run tests in split
           Type: 🔧 Built-in
           Keybindings: <leader>ts (open test shell)
        ...

        [Shows AskUserQuestion checklist]

User: [Selects neotest]

Claude: [Adds neotest to dotfiles, runs Ansible]
        "Restart nvim and try <leader>tt to run nearest test"

User: "keep"

Claude: [Removes TESTING comment]
        "Done! Kept: neotest (plugin)"
        [Commits and offers to push]
```
