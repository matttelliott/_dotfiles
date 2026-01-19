# Feature Landscape: Claude Code Configuration

**Domain:** Claude Code configuration for dotfiles management
**Researched:** 2026-01-18
**Overall Confidence:** HIGH (based on official documentation at code.claude.com)

## Table Stakes

Features users expect from a dotfiles-managed Claude Code configuration.

| Feature                       | Why Expected                            | Complexity | Notes                                |
| ----------------------------- | --------------------------------------- | ---------- | ------------------------------------ |
| Global CLAUDE.md              | Defines AI behavior across all projects | Low        | Template with Jinja2 for host groups |
| User settings.json            | Permission rules, environment vars      | Low        | Static JSON deployed via Ansible     |
| Project .claude/ structure    | Standard project config location        | Low        | Already exists in this repo          |
| Git-aware permissions         | Allow git commands, protect secrets     | Low        | Permission rules in settings.json    |
| Shell tool permissions        | Allow common CLI tools                  | Low        | Bash patterns in allow list          |
| Gitignore settings.local.json | Personal overrides not committed        | Low        | Claude Code handles automatically    |

## Differentiators

Features that enhance the configuration beyond basics.

| Feature               | Value Proposition               | Complexity | Notes                               |
| --------------------- | ------------------------------- | ---------- | ----------------------------------- |
| Custom slash commands | Codify common workflows         | Low        | Markdown files in .claude/commands/ |
| Custom subagents      | Specialized AI assistants       | Medium     | Requires prompt engineering         |
| Pre/Post hooks        | Automated linting, formatting   | Medium     | Shell scripts with JSON stdin       |
| Conditional rules     | File-type-specific instructions | Low        | YAML frontmatter with paths         |
| MCP servers           | External tool integrations      | Medium     | Depends on which servers needed     |
| Context injection     | Dynamic session context         | Medium     | SessionStart hooks                  |
| Host-specific config  | Different configs per machine   | Medium     | Ansible templating with group_names |
| Agent Skills          | Modular, reusable capabilities  | Medium     | SKILL.md with frontmatter           |

## Anti-Features

Features to explicitly NOT build. Common mistakes in this domain.

| Anti-Feature             | Why Avoid                      | What to Do Instead                    |
| ------------------------ | ------------------------------ | ------------------------------------- |
| Overly permissive rules  | Security risk, defeats purpose | Specific tool patterns with wildcards |
| Hardcoded absolute paths | Breaks across machines         | Use $CLAUDE_PROJECT_DIR, $HOME        |
| Complex hook chains      | Hard to debug, fragile         | Simple, focused scripts               |
| Duplicated instructions  | Context bloat, conflicts       | Import syntax in CLAUDE.md            |
| Secrets in settings      | Security vulnerability         | Environment vars, apiKeyHelper        |
| bypassPermissions mode   | Removes safety guardrails      | Use specific allow rules instead      |
| Managed settings locally | Requires admin, overkill       | Use user/project settings             |
| MCP in settings.json     | Wrong file, won't work         | Use .mcp.json instead                 |

---

## Configuration Hierarchy Overview

Claude Code uses a multi-tier configuration system with clear precedence rules. Configuration flows from most general (enterprise) to most specific (local project), with higher specificity taking precedence.

| Priority    | Level               | Location                      | Shared          | Purpose                    |
| ----------- | ------------------- | ----------------------------- | --------------- | -------------------------- |
| 1 (highest) | Managed/Enterprise  | System directories            | Org-wide        | IT policies, compliance    |
| 2           | Project Local       | `.claude/settings.local.json` | No (gitignored) | Personal project overrides |
| 3           | Project (committed) | `.claude/settings.json`       | Team via git    | Shared team config         |
| 4           | User                | `~/.claude/settings.json`     | No              | Personal preferences       |

**For dotfiles three-layer goal:**

- **User layer:** `~/.claude/` (deployed via Ansible)
- **Portable layer:** Symlinked directories or imported files
- **Repo-specific layer:** `.claude/` in each repository

---

## Feature Categories

### 1. Memory Files (CLAUDE.md)

Instructions and context that Claude loads at startup. These are markdown files that Claude treats as suggestions

| Feature                    | User Level             | Project Level                          | Notes                                            |
| -------------------------- | ---------------------- | -------------------------------------- | ------------------------------------------------ |
| `CLAUDE.md`                | `~/.claude/CLAUDE.md`  | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Project overrides user                           |
| `CLAUDE.local.md`          | N/A                    | `./CLAUDE.local.md`                    | Auto-gitignored, personal project prefs          |
| Rules directory            | `~/.claude/rules/*.md` | `.claude/rules/*.md`                   | Modular instructions                             |
| Path-scoped rules          | Both                   | Both                                   | Use `paths:` frontmatter for conditional loading |
| Parent directory recursion | N/A                    | Yes                                    | Walks up from cwd to find CLAUDE.md files        |
| Subdirectory discovery     | N/A                    | Yes                                    | Loads on-demand when accessing files in subtree  |
| Imports (`@path/to/file`)  | Both                   | Both                                   | Max 5 hops depth, relative/absolute paths        |

**Loading order (first loaded = lower priority):**

1. Enterprise policy (system directories)
2. User-level (`~/.claude/CLAUDE.md`)
3. Parent directory CLAUDE.md files (walking up from cwd)
4. Project-level (`./CLAUDE.md` or `.claude/CLAUDE.md`)
5. Rules directory (`.claude/rules/*.md`)
6. Project local (`./CLAUDE.local.md`)
7. Subdirectory CLAUDE.md (on-demand when accessing those files)

---

### 2. Settings Files (settings.json)

JSON configuration for permissions, environment, hooks, and behavior settings.

| File                    | Location     | Shared          | Priority                          |
| ----------------------- | ------------ | --------------- | --------------------------------- |
| `managed-settings.json` | System dirs  | Org-wide        | 1 (highest, cannot be overridden) |
| `settings.local.json`   | `.claude/`   | No (gitignored) | 2                                 |
| `settings.json`         | `.claude/`   | Yes (git)       | 3                                 |
| `settings.json`         | `~/.claude/` | No              | 4                                 |

**System directories for managed settings:**

- macOS: `/Library/Application Support/ClaudeCode/`
- Linux: `/etc/claude-code/`
- Windows: `C:\Program Files\ClaudeCode\`

#### Core Settings

| Setting             | User | Project | Description                          |
| ------------------- | ---- | ------- | ------------------------------------ |
| `model`             | Yes  | Yes     | Override default model               |
| `language`          | Yes  | Yes     | Claude's response language           |
| `env`               | Yes  | Yes     | Environment variables for sessions   |
| `cleanupPeriodDays` | Yes  | Yes     | Session cleanup period (default: 30) |
| `outputStyle`       | Yes  | Yes     | Adjust output verbosity              |

#### Permission Settings

| Setting                                    | User         | Project | Description                   |
| ------------------------------------------ | ------------ | ------- | ----------------------------- |
| `permissions.allow`                        | Yes          | Yes     | Allowed tool patterns         |
| `permissions.ask`                          | Yes          | Yes     | Tools requiring confirmation  |
| `permissions.deny`                         | Yes          | Yes     | Blocked tool patterns         |
| `permissions.additionalDirectories`        | Yes          | Yes     | Extra working directories     |
| `permissions.defaultMode`                  | Yes          | Yes     | Startup permission mode       |
| `permissions.disableBypassPermissionsMode` | Managed only | No      | Disable dangerous bypass flag |

**Permission rule syntax:**

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Read(./.env)",
      "WebFetch(domain:example.com)"
    ],
    "deny": ["Bash(curl:*)", "Read(./.env.*)"]
  }
}
```

#### Sandbox Settings

| Setting                            | User | Project | Description                      |
| ---------------------------------- | ---- | ------- | -------------------------------- |
| `sandbox.enabled`                  | Yes  | Yes     | Enable bash sandboxing           |
| `sandbox.autoAllowBashIfSandboxed` | Yes  | Yes     | Auto-approve bash when sandboxed |
| `sandbox.excludedCommands`         | Yes  | Yes     | Commands run outside sandbox     |
| `sandbox.network.*`                | Yes  | Yes     | Network proxy settings           |

---

### 3. Hooks

Shell commands that run at specific lifecycle events.

| Event               | Matcher | Purpose                                          |
| ------------------- | ------- | ------------------------------------------------ |
| `PreToolUse`        | Yes     | Before tool execution, can modify input or block |
| `PostToolUse`       | Yes     | After tool success, can add context              |
| `PermissionRequest` | Yes     | When permission dialog shown                     |
| `UserPromptSubmit`  | No      | When user submits prompt                         |
| `SessionStart`      | Yes     | On session start/resume                          |
| `SessionEnd`        | No      | On session end                                   |
| `Stop`              | No      | When Claude finishes responding                  |
| `SubagentStop`      | No      | When subagent finishes                           |
| `PreCompact`        | Yes     | Before context compaction                        |
| `Notification`      | Yes     | On notifications                                 |

#### Hook Environment Variables

| Variable             | Availability      | Description                       |
| -------------------- | ----------------- | --------------------------------- |
| `CLAUDE_PROJECT_DIR` | All hooks         | Project root path                 |
| `CLAUDE_CODE_REMOTE` | All hooks         | "true" for web environment        |
| `CLAUDE_ENV_FILE`    | SessionStart only | File path for persisting env vars |

#### Hook Exit Codes

| Exit Code | Behavior                               |
| --------- | -------------------------------------- |
| 0         | Success, parse stdout for JSON control |
| 2         | Blocking error, stderr shown to user   |
| Other     | Non-blocking error, logged             |

---

### 4. Custom Slash Commands

Markdown files that define reusable prompts invoked with `/command-name`.

| Location              | Scope            | Priority |
| --------------------- | ---------------- | -------- |
| `.claude/commands/`   | Project (shared) | Higher   |
| `~/.claude/commands/` | User (personal)  | Lower    |

**Project commands override user commands with the same name.**

#### Command Frontmatter Options

| Option          | Description                  |
| --------------- | ---------------------------- |
| `description`   | Brief command description    |
| `argument-hint` | Expected arguments display   |
| `allowed-tools` | Tools the command can use    |
| `model`         | Specific model to use        |
| `context`       | `fork` for sub-agent context |
| `agent`         | Agent type when using fork   |
| `hooks`         | Define execution hooks       |

#### Argument Handling

| Placeholder      | Description                     |
| ---------------- | ------------------------------- |
| `$ARGUMENTS`     | All passed arguments            |
| `$1`, `$2`, etc. | Individual positional arguments |

---

### 5. Custom Subagents

Specialized AI assistants with isolated context and custom tool access.

| Location            | Scope           | Priority    |
| ------------------- | --------------- | ----------- |
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/`   | Project         | 2           |
| `~/.claude/agents/` | User            | 3           |
| Plugin `agents/`    | Plugin scope    | 4 (lowest)  |

#### Subagent Frontmatter Options

| Field             | Required | Description                             |
| ----------------- | -------- | --------------------------------------- |
| `name`            | Yes      | Unique identifier                       |
| `description`     | Yes      | When to delegate to this agent          |
| `tools`           | No       | Allowed tools (inherits all if omitted) |
| `disallowedTools` | No       | Tools to deny                           |
| `model`           | No       | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode`  | No       | Permission handling mode                |
| `skills`          | No       | Skills to load at startup               |
| `hooks`           | No       | Lifecycle hooks scoped to this agent    |

---

### 6. MCP Server Configuration

External tool servers that extend Claude's capabilities.

| File               | Location         | Scope                    |
| ------------------ | ---------------- | ------------------------ |
| `.claude.json`     | `~/.claude.json` | User (all projects)      |
| `.mcp.json`        | Project root     | Project (shared via git) |
| `managed-mcp.json` | System dirs      | Managed (org-wide)       |

**IMPORTANT:** MCP servers are NOT configured in `settings.json`. They use separate files.

#### MCP Configuration Structure

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio|http|sse",
      "command": "/path/to/executable",
      "args": ["--flag", "value"],
      "env": {
        "API_KEY": "value"
      }
    }
  }
}
```

---

## Feature Dependencies

```
User settings.json
    └── Project settings.json (overrides user)
        └── settings.local.json (overrides both)

User CLAUDE.md
    └── Project CLAUDE.md (combines with user)
        └── .claude/rules/*.md (combines with both)
            └── CLAUDE.local.md (combines with all)

Hooks require:
    └── Executable scripts with proper permissions
    └── JSON stdin parsing capability
    └── Error handling for exit codes

Subagents require:
    └── Well-crafted system prompts
    └── Appropriate tool restrictions
    └── Clear delegation triggers (description field)
```

---

## MVP Recommendation

For MVP, prioritize:

1. **User-level CLAUDE.md** - Template with host group conditions
2. **User-level settings.json** - Common permission rules
3. **Enhance existing project .claude/** - Add missing pieces

Defer to post-MVP:

- **Portable configs**: Complex, may not be needed
- **MCP servers**: Project-specific, not dotfiles concern
- **Complex hooks**: Start simple, add as needed
- **Skills directory**: Start with commands/agents first

---

## Three-Layer Strategy for Dotfiles

### Layer 1: User Config (`~/.claude/`)

Deployed via Ansible to all machines:

```
~/.claude/
├── CLAUDE.md              # User-wide instructions
├── settings.json          # User permissions, model prefs
├── commands/              # Personal slash commands
├── agents/                # Personal subagents
└── rules/                 # Personal rules
```

### Layer 2: Portable Config (Symlinked or Imported)

Shareable configurations (like GSD) that can be added to any repo:

**Option A: Symlinks**

```bash
ln -s ~/portable-configs/gsd-agents .claude/agents/gsd
ln -s ~/portable-configs/gsd-commands .claude/commands/gsd
```

**Option B: Imports in CLAUDE.md**

```markdown
# Project Instructions

@~/portable-configs/gsd/instructions.md
```

### Layer 3: Repo-Specific Config (`.claude/`)

Checked into each repository:

```
.claude/
├── settings.json          # Project hooks, permissions
├── settings.local.json    # Personal project overrides (gitignored)
├── commands/              # Project-specific commands
├── agents/                # Project-specific subagents
└── rules/                 # Project-specific rules
```

---

## Key Limitations

1. **MCP servers use separate files** - Cannot be configured in `settings.json`
2. **Skills don't inherit to subagents** - Must explicitly list in `skills:` field
3. **Rules `paths:` field uses globs** - Not regex patterns
4. **Hook timeout default is 60 seconds** - Configurable per hook
5. **Import depth limited to 5 hops** - Prevent circular dependencies

---

## Sources

- [Claude Code Settings](https://code.claude.com/docs/en/settings) - Official settings reference
- [Claude Code Memory](https://code.claude.com/docs/en/memory) - CLAUDE.md and rules documentation
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks) - Hooks reference
- [Claude Code Slash Commands](https://code.claude.com/docs/en/slash-commands) - Commands documentation
- [Claude Code Sub-agents](https://code.claude.com/docs/en/sub-agents) - Custom subagents reference
- [Claude Code MCP](https://code.claude.com/docs/en/mcp) - MCP server configuration
