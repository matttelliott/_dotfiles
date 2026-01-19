# Architecture: Claude Code Configuration Layering

**Domain:** Claude Code configuration system for dotfiles repo
**Researched:** 2026-01-18
**Confidence:** HIGH (verified against official documentation)

## Executive Summary

Claude Code uses a well-defined hierarchical configuration system with clear precedence rules. The architecture supports three distinct scopes: **user** (`~/.claude/`), **project** (`.claude/`), and **managed** (system-level). Portable configurations like GSD work by installing commands and agents into the user-level directories, making them available across all projects.

## Configuration Hierarchy

### Load Order (Lowest to Highest Precedence)

```
1. Defaults (built-in)
       |
2. User Settings (~/.claude/settings.json)
       |
3. Shared Project Settings (.claude/settings.json)
       |
4. Local Project Settings (.claude/settings.local.json)
       |
5. Command Line Arguments (--flag)
       |
6. Managed Settings (system-level, IT-deployed)
```

**Key principle:** Higher-precedence settings override lower-precedence settings for scalar values. Arrays are MERGED across scopes.

### Settings File Locations

| Scope | Location | Shared | Git | Purpose |
|-------|----------|--------|-----|---------|
| Managed | `/etc/claude-code/` (Linux) or `/Library/Application Support/ClaudeCode/` (macOS) | Yes (IT) | N/A | Org-wide policies, cannot be overridden |
| User | `~/.claude/settings.json` | No | No | Personal defaults for all projects |
| Project | `.claude/settings.json` | Yes | Committed | Team-shared settings |
| Local | `.claude/settings.local.json` | No | Gitignored | Personal project-specific overrides |

### CLAUDE.md Memory Files

CLAUDE.md files provide context and instructions to Claude. They load in this order:

```
1. ~/.claude/CLAUDE.md           # User-level (all projects)
       |
2. CLAUDE.md (project root)      # Project-level (team shared)
       |
3. .claude/CLAUDE.md             # Alternative project location
       |
4. .claude/CLAUDE.local.md       # Local project (gitignored)
       |
5. Parent directory CLAUDE.md    # Inherited from parent dirs (monorepo)
       |
6. Subdirectory CLAUDE.md        # On-demand when accessing files
```

**Parent directory loading:** Claude searches upward from CWD toward root, loading every CLAUDE.md it finds. This enables monorepo patterns.

**Subdirectory loading:** CLAUDE.md files in subdirectories load on-demand when Claude accesses files in those directories.

## Configuration Component Locations

### Complete Directory Structure

```
~/.claude/                           # User-level configuration
├── CLAUDE.md                        # Global instructions (all projects)
├── settings.json                    # Global settings
├── agents/                          # User subagents (available everywhere)
│   ├── code-reviewer.md
│   └── debugger.md
├── commands/                        # User slash commands (available everywhere)
│   ├── gsd/                         # Namespaced portable commands (GSD)
│   │   ├── new-project.md
│   │   └── execute-phase.md
│   └── init-project.md
├── hooks/                           # Global hooks scripts
│   └── auto-commit.sh
├── output-styles/                   # Output style definitions
├── get-shit-done/                   # Portable config data (GSD example)
│   ├── VERSION
│   ├── templates/
│   ├── references/
│   └── workflows/
└── plugins/                         # Installed plugins
    └── marketplaces/

.claude/                             # Project-level configuration
├── CLAUDE.md                        # Project instructions (team shared)
├── CLAUDE.local.md                  # Local project instructions (gitignored)
├── settings.json                    # Project settings (committed)
├── settings.local.json              # Local settings (gitignored)
├── agents/                          # Project subagents
├── commands/                        # Project slash commands
├── hooks/                           # Project hook scripts
└── skills/                          # Project skills
```

## Merge Behavior

### Arrays (MERGED)

Arrays in settings files are combined across scopes:

```json
// User settings (~/.claude/settings.json)
{
  "permissions": {
    "allow": ["Bash(npm:*)", "Read(.env.example)"]
  }
}

// Project settings (.claude/settings.json)
{
  "permissions": {
    "allow": ["Bash(git:*)", "Edit(src/**)"]
  }
}

// Result (merged)
{
  "permissions": {
    "allow": ["Bash(npm:*)", "Read(.env.example)", "Bash(git:*)", "Edit(src/**)"]
  }
}
```

### Scalars (REPLACED)

Non-array settings use highest-precedence value:

```json
// User settings
{ "model": "claude-sonnet-4-5-20250929" }

// Project settings
{ "model": "claude-opus-4-5-20251101" }

// Result: Project wins
{ "model": "claude-opus-4-5-20251101" }
```

## Portable Config Pattern (GSD Example)

GSD demonstrates the portable configuration pattern:

### Installation Structure

```
~/.claude/
├── agents/                    # Agents are installed here
│   ├── gsd-planner.md
│   ├── gsd-executor.md
│   └── gsd-verifier.md
├── commands/
│   └── gsd/                   # Commands namespaced in subdirectory
│       ├── new-project.md
│       ├── execute-phase.md
│       └── help.md
├── hooks/
│   └── gsd-check-update.js    # Hooks for GSD functionality
└── get-shit-done/             # Supporting data files
    ├── VERSION
    ├── templates/
    ├── references/
    └── workflows/
```

### Key Patterns

1. **Commands in subdirectory:** `/gsd:new-project` vs `/new-project`
   - Prevents naming collisions
   - Clear namespace identification

2. **Agents at user level:** Available in all projects
   - Agents named `gsd-*.md` for namespace clarity
   - No directory namespacing for agents (flat structure)

3. **Supporting data separate:** `~/.claude/get-shit-done/`
   - Templates, references, workflows stored here
   - Not in commands/agents directories
   - Accessed by commands via known paths

4. **Hooks for integration:**
   - SessionStart hook checks for updates
   - PostToolUse hooks for auto-commit

## Component Precedence

### Slash Commands

```
Priority (highest to lowest):
1. --commands CLI flag (session only)
2. .claude/commands/ (project)
3. ~/.claude/commands/ (user)
4. Plugin commands (namespaced)
```

**When same name exists:** Project command takes precedence; user command silently ignored.

**Subdirectory behavior:** Commands in subdirectories create namespaced commands. `/frontend/test.md` creates `/test` shown as "(project:frontend)".

### Subagents

```
Priority (highest to lowest):
1. --agents CLI flag (session only)
2. .claude/agents/ (project)
3. ~/.claude/agents/ (user)
4. Plugin agents
```

**When same name exists:** Highest priority location wins.

### Hooks

```
Hooks from settings.json are merged:
1. Managed hooks (if allowManagedHooksOnly is set)
2. User hooks (~/.claude/settings.json)
3. Project hooks (.claude/settings.json)
4. Local hooks (.claude/settings.local.json)
```

## Recommended Architecture for Dotfiles

### Three-Layer Design

```
Layer 1: User Config (~/.claude/)
├── CLAUDE.md                 # Global instructions via Ansible template
├── settings.json             # Managed by Ansible, contains hooks
├── agents/                   # User agents (copied by Ansible)
├── commands/                 # User commands (copied by Ansible)
├── hooks/                    # Hook scripts (copied by Ansible)
└── output-styles/            # Output styles (copied by Ansible)

Layer 2: Portable Configs (~/.claude/<name>/)
└── get-shit-done/            # Example: GSD data
    └── (managed by npm package, not Ansible)

Layer 3: Repo Config (.claude/)
├── CLAUDE.md                 # Project-specific instructions (committed)
├── settings.json             # Project settings (committed)
├── settings.local.json       # Personal overrides (gitignored)
├── commands/                 # Project commands (committed)
├── agents/                   # Project agents (committed)
└── hooks/                    # Project hook scripts (committed)
```

### Ansible Responsibilities

**Ansible should manage:**
- `~/.claude/CLAUDE.md` (templated based on host groups)
- `~/.claude/settings.json` (user-level settings)
- `~/.claude/agents/` (user agents)
- `~/.claude/commands/` (user commands, excluding portable)
- `~/.claude/hooks/` (hook scripts)
- `~/.claude/output-styles/` (output styles)

**Ansible should NOT manage:**
- Portable configs (they have their own installers)
- Project-level configs (repo-specific)
- `settings.local.json` (personal overrides)
- `CLAUDE.local.md` (personal overrides)

### Portable Config Guidelines

For portable configurations like GSD:

1. **Use dedicated installer:** npm package, script, etc.
2. **Commands in subdirectory:** `~/.claude/commands/<name>/`
3. **Agents with prefix:** `~/.claude/agents/<name>-*.md`
4. **Data in dedicated directory:** `~/.claude/<name>/`
5. **Avoid name collisions:** Namespace everything
6. **Version tracking:** Store version in data directory

## Anti-Patterns to Avoid

### 1. Mixing Scopes

**Bad:** Putting personal settings in project `.claude/settings.json`
**Good:** Use `.claude/settings.local.json` for personal overrides

### 2. Hardcoding Paths

**Bad:** `~/.claude/hooks/my-hook.sh` hardcoded in settings
**Good:** Use `$CLAUDE_PROJECT_DIR` or `$HOME` variables

### 3. Committing Secrets

**Bad:** API keys in `.claude/settings.json`
**Good:** Use environment variables or `.local` files

### 4. Flat Command Namespace

**Bad:** All portable commands in `~/.claude/commands/` root
**Good:** Group in subdirectories: `~/.claude/commands/gsd/`

### 5. Ignoring Precedence

**Bad:** Assuming user settings always apply
**Good:** Document that project settings can override

## Sources

- [Claude Code Settings Documentation](https://code.claude.com/docs/en/settings) (Official, HIGH confidence)
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents) (Official, HIGH confidence)
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins.md) (Official, HIGH confidence)
- [Claude Code Slash Commands Documentation](https://code.claude.com/docs/en/slash-commands) (Official, HIGH confidence)
- [Claude Blog: Using CLAUDE.md Files](https://claude.com/blog/using-claude-md-files) (Official, HIGH confidence)
- [Settings Hierarchy Guide](https://deepwiki.com/zebbern/claude-code-guide/4.1-settings-hierarchy) (Community, MEDIUM confidence)
