# Claude Code Configuration Stack

**Project:** Dotfiles Claude Code Configuration
**Researched:** 2026-01-18
**Confidence:** HIGH (verified against official documentation)

## Configuration File Hierarchy

Claude Code uses a hierarchical configuration system where more specific scopes override broader ones.

### Complete File Locations

| Priority | File | Location | Scope | Git Status |
|----------|------|----------|-------|------------|
| 1 (highest) | Managed settings | `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS)<br>`/etc/claude-code/managed-settings.json` (Linux)<br>`C:\Program Files\ClaudeCode\managed-settings.json` (Windows) | Enterprise IT | N/A |
| 2 | Managed MCP | Same paths with `managed-mcp.json` | Enterprise IT | N/A |
| 3 | Managed memory | Same paths with `CLAUDE.md` | Enterprise IT | N/A |
| 4 | Local project settings | `.claude/settings.local.json` | Personal (this project) | Auto-gitignored |
| 5 | Project settings | `.claude/settings.json` | Team (this project) | Committed |
| 6 | Project memory | `.claude/CLAUDE.md` or `./CLAUDE.md` | Team (this project) | Committed |
| 7 | Project rules | `.claude/rules/*.md` | Team (this project) | Committed |
| 8 | Project MCP | `.mcp.json` | Team (this project) | Committed |
| 9 | Local memory | `./CLAUDE.local.md` | Personal (this project) | Auto-gitignored |
| 10 | User settings | `~/.claude/settings.json` | Personal (all projects) | N/A |
| 11 | User settings local | `~/.claude/settings.local.json` | Personal (all projects) | N/A |
| 12 (lowest) | User memory | `~/.claude/CLAUDE.md` | Personal (all projects) | N/A |

### Additional Directories

| Directory | Location | Purpose |
|-----------|----------|---------|
| User commands | `~/.claude/commands/` | Personal slash commands (all projects) |
| Project commands | `.claude/commands/` | Team slash commands (this project) |
| User agents | `~/.claude/agents/` | Personal subagents (all projects) |
| Project agents | `.claude/agents/` | Team subagents (this project) |
| User rules | `~/.claude/rules/` | Personal rules (all projects) |
| Project rules | `.claude/rules/` | Team rules (this project) |

### Environment Variable Override

```bash
CLAUDE_CONFIG_DIR=/custom/path  # Changes all ~/.claude/ references
```

---

## settings.json Schema

### Complete Schema Reference

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",

  "permissions": {
    "allow": ["Tool(pattern:*)"],
    "ask": ["Tool(pattern:*)"],
    "deny": ["Tool(pattern:*)"],
    "additionalDirectories": ["../other-dir/"],
    "defaultMode": "acceptEdits",
    "disableBypassPermissionsMode": "disable"
  },

  "env": {
    "VAR_NAME": "value"
  },

  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "UserPromptSubmit": [],
    "PermissionRequest": [],
    "Stop": [],
    "SubagentStop": [],
    "PreCompact": [],
    "SessionStart": [],
    "SessionEnd": [],
    "Notification": []
  },

  "model": "claude-sonnet-4-5-20250929",
  "alwaysThinkingEnabled": false,
  "language": "english",
  "outputStyle": "Explanatory",

  "sandbox": {
    "enabled": false,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["docker", "git"],
    "allowUnsandboxedCommands": true,
    "network": {
      "allowUnixSockets": ["/var/run/docker.sock"],
      "allowLocalBinding": false,
      "httpProxyPort": 8080,
      "socksProxyPort": 8081
    },
    "enableWeakerNestedSandbox": false
  },

  "attribution": {
    "commit": "message",
    "pr": "message"
  },

  "apiKeyHelper": "/path/to/script",
  "otelHeadersHelper": "/path/to/script",
  "awsAuthRefresh": "aws sso login --profile name",
  "awsCredentialExport": "/path/to/script",

  "statusLine": {
    "type": "command",
    "command": "/path/to/script"
  },
  "fileSuggestion": {
    "type": "command",
    "command": "/path/to/script"
  },

  "cleanupPeriodDays": 30,
  "plansDirectory": "./plans",
  "respectGitignore": true,
  "showTurnDuration": true,
  "spinnerTipsEnabled": true,
  "terminalProgressBarEnabled": true,
  "autoUpdatesChannel": "stable",

  "forceLoginMethod": "claudeai",
  "forceLoginOrgUUID": "uuid-here",
  "companyAnnouncements": ["Message"],

  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": ["server-name"],
  "disabledMcpjsonServers": ["server-name"],
  "allowedMcpServers": [{"serverName": "name"}],
  "deniedMcpServers": [{"serverName": "name"}],

  "enabledPlugins": {
    "plugin-name@marketplace": true
  },
  "extraKnownMarketplaces": {},
  "strictKnownMarketplaces": [],

  "disableAllHooks": false,
  "allowManagedHooksOnly": false
}
```

### Permission Rule Syntax

| Pattern | Position | Behavior | Example |
|---------|----------|----------|---------|
| `:*` | End only | Prefix matching | `Bash(npm run:*)` matches `npm run test` |
| `*` | Anywhere | Glob matching | `Bash(git * main)` matches `git checkout main` |

**Tool specifiers:**
- `Tool` - All uses of tool
- `Tool(command:*)` - Bash commands matching pattern
- `Tool(path/pattern)` - Read/Write/Edit file patterns
- `Tool(domain:example.com)` - WebFetch domain restrictions

**Evaluation order:** Deny > Ask > Allow

---

## Hooks Configuration

### Hook Types and Triggers

| Hook | Trigger | Can Block | Can Modify |
|------|---------|-----------|------------|
| `PreToolUse` | Before tool execution | Yes (exit 2) | Yes (updatedInput) |
| `PostToolUse` | After tool completes | Yes (decision: block) | No |
| `PermissionRequest` | Permission dialog shown | Yes | Yes |
| `UserPromptSubmit` | User submits prompt | Yes | No (add context only) |
| `Stop` | Agent finishes responding | Yes (continue) | N/A |
| `SubagentStop` | Subagent finishes | Yes (continue) | N/A |
| `PreCompact` | Before context compacting | Yes | No |
| `SessionStart` | Session begins/resumes | No | Yes (context, env) |
| `SessionEnd` | Session ends | No | No |
| `Notification` | Claude sends notification | No | No |

### Hook Configuration Format

```json
{
  "hooks": {
    "HookType": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

**Matcher patterns:**
- Exact: `Write`
- Regex: `Edit|Write|MultiEdit`
- All tools: `*` or `""` or omit matcher
- MCP tools: `mcp__server__tool`

### Hook stdin Format (JSON)

```json
{
  "session_id": "string",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default|plan|acceptEdits|dontAsk|bypassPermissions",
  "hook_event_name": "EventName",
  "tool_name": "ToolName",
  "tool_input": { /* tool-specific */ },
  "tool_response": { /* PostToolUse only */ },
  "tool_use_id": "toolu_..."
}
```

**Tool-specific inputs:**

```json
// Bash
{ "command": "...", "description": "...", "timeout": 120000 }

// Write
{ "file_path": "/path", "content": "..." }

// Edit
{ "file_path": "/path", "old_string": "...", "new_string": "...", "replace_all": false }

// Read
{ "file_path": "/path", "offset": 0, "limit": 100 }
```

### Hook Exit Codes

| Code | Behavior |
|------|----------|
| 0 | Success. stdout parsed for JSON control. |
| 2 | Blocking error. stderr shown to Claude. Tool blocked. |
| Other | Non-blocking. stderr in verbose mode. Continues. |

### Hook stdout Format (JSON, exit 0)

**PreToolUse decision control:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Explanation",
    "updatedInput": { "field": "new_value" },
    "additionalContext": "Context for Claude"
  }
}
```

**PostToolUse decision control:**
```json
{
  "decision": "block",
  "reason": "Explanation",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Info for Claude"
  }
}
```

**Stop/SubagentStop decision control:**
```json
{
  "decision": "block",
  "reason": "Instructions for Claude to continue"
}
```

**SessionStart context injection:**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Context injected at session start"
  }
}
```

### Environment Variables in Hooks

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Absolute path to project root |
| `CLAUDE_ENV_FILE` | Path to persist env vars (SessionStart only) |
| `CLAUDE_CODE_REMOTE` | "true" if web environment |

---

## CLAUDE.md Memory Format

### File Locations and Loading

| Location | Loaded | Scope |
|----------|--------|-------|
| `/etc/claude-code/CLAUDE.md` | Always (enterprise) | All org users |
| `~/.claude/CLAUDE.md` | Always | All your projects |
| `./CLAUDE.md` or `.claude/CLAUDE.md` | Always | This project |
| `.claude/rules/*.md` | Always | This project |
| `./CLAUDE.local.md` | Always (gitignored) | Personal, this project |
| `subdir/CLAUDE.md` | When reading subdir files | Subdirectory scope |

### Import Syntax

```markdown
See @README for project overview.
See @package.json for available npm commands.
See @docs/git-instructions.md for git workflow.
See @~/.claude/my-preferences.md for personal settings.
```

**Rules:**
- Relative and absolute paths supported
- Max recursion depth: 5 hops
- Not evaluated inside code spans/blocks

### Conditional Rules with Frontmatter

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "lib/**/*.ts"
---

# API Development Rules

These rules only apply when Claude is working with matching files.

- All API endpoints must include input validation
- Use the standard error response format
```

**Glob patterns:**
- `**/*.ts` - All TypeScript files
- `src/**/*` - All files under src/
- `*.{ts,tsx}` - Multiple extensions
- `{src,lib}/**/*.ts` - Multiple directories

---

## Slash Commands Format

### File Structure

```
.claude/commands/
├── commit.md
├── review.md
└── workflows/
    └── deploy.md
```

### Command File Format

```markdown
---
allowed-tools: Bash(git:*), Read, Grep
argument-hint: [message]
description: Create a git commit
model: claude-3-5-haiku-20241022
context: fork
agent: general-purpose
disable-model-invocation: false
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
          once: true
---

Your command instructions here.

Current git status: !`git status`
File contents: @src/main.ts

Fix issue: $ARGUMENTS
Or individual args: $1, $2, $3
```

### Frontmatter Options

| Option | Purpose | Default |
|--------|---------|---------|
| `allowed-tools` | Tools command can use | Inherits |
| `argument-hint` | Expected arguments | None |
| `description` | Brief description | First line |
| `model` | Specific model | Inherits |
| `context` | `fork` for sub-agent | inline |
| `agent` | Agent type when forked | general-purpose |
| `disable-model-invocation` | Prevent Skill calls | false |
| `hooks` | Command-scoped hooks | None |

### Variable Substitution

- `$ARGUMENTS` - All arguments as string
- `$1`, `$2`, `$3` - Individual arguments
- `!`\`command\`` - Execute bash, insert output
- `@path/to/file` - Insert file contents

### Namespace Conventions

- Project commands: `/project:command-name`
- User commands: `/user:command-name`
- Subdirectory commands: `/project:subdir:command`

---

## Subagents Format

### File Structure

```
.claude/agents/
├── reviewer.md
├── architect.md
└── security/
    └── auditor.md
```

### Agent File Format

```markdown
---
name: code-reviewer
description: Reviews code for quality and security
tools: Read, Grep, Glob
disallowedTools: Write, Edit, Bash
model: sonnet
permissionMode: default
skills: code-review, security
hooks:
  PostToolUse:
    - matcher: "Read"
      hooks:
        - type: command
          command: "./scripts/log-access.sh"
---

You are a senior code reviewer ensuring high standards.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Review immediately

Review checklist:
- Code is clear and readable
- No security vulnerabilities
- Proper error handling
```

### Frontmatter Options

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier (lowercase, hyphens) |
| `description` | Yes | When Claude should delegate |
| `tools` | No | Allowed tools (inherits all if omitted) |
| `disallowedTools` | No | Explicitly denied tools |
| `model` | No | `sonnet`, `opus`, `haiku`, or `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `skills` | No | Skills to load at startup |
| `hooks` | No | Agent-scoped hooks |

### Built-in Agents

| Agent | Purpose | Tools |
|-------|---------|-------|
| `Explore` | Fast read-only codebase search | Read, Grep, Glob |
| `Plan` | Research for plan mode | Read-only |
| `general-purpose` | Complex multi-step tasks | All |

---

## MCP Configuration Format

### .mcp.json Schema

```json
{
  "mcpServers": {
    "server-name": {
      "type": "http|stdio|sse",
      "url": "https://...",
      "command": "/path/to/server",
      "args": ["arg1", "arg2"],
      "env": {
        "KEY": "${ENV_VAR}",
        "DEFAULT": "${VAR:-fallback}"
      },
      "headers": {
        "Authorization": "Bearer ${TOKEN}"
      }
    }
  }
}
```

### Transport Types

**HTTP (recommended):**
```json
{
  "type": "http",
  "url": "https://mcp.example.com",
  "headers": { "Authorization": "Bearer ${API_KEY}" }
}
```

**Stdio (local servers):**
```json
{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@package/server"],
  "env": { "CONFIG": "/path/to/config" }
}
```

**SSE (deprecated):**
```json
{
  "type": "sse",
  "url": "https://mcp.example.com/sse",
  "headers": { "X-API-Key": "key" }
}
```

### Environment Variable Expansion

- `${VAR}` - Expand to VAR value
- `${VAR:-default}` - Use default if VAR not set
- Available in: command, args, env, url, headers

### MCP Scope Precedence

1. **Local** (default): `~/.claude.json` under project path
2. **Project**: `.mcp.json` in project root (team-shared)
3. **User**: `~/.claude.json` global section

### CLI Commands

```bash
claude mcp add --transport http name https://url
claude mcp add --transport stdio name -- command args
claude mcp add --scope project name -- command
claude mcp add --scope user name -- command
claude mcp add --env KEY=value name -- command
claude mcp list
claude mcp get name
claude mcp remove name
claude mcp add-from-claude-desktop
```

---

## Three-Layer Configuration Strategy

For the dotfiles project, implement this structure:

### Layer 1: User (~/.claude/)

Deployed via Ansible to all machines. Contains personal preferences that apply globally.

```
~/.claude/
├── CLAUDE.md           # Global instructions (templated by Ansible)
├── settings.json       # User-level permissions and preferences
├── commands/           # Personal slash commands
├── agents/             # Personal subagents
└── rules/              # Personal rules
```

### Layer 2: Portable (~/.claude/<name>/)

**Note:** Claude Code does not natively support named portable configs. Alternative approaches:

1. **Symlink approach**: Symlink `.claude/` to different configs
2. **Git branch approach**: Different branches for different configs
3. **Environment variable**: `CLAUDE_CONFIG_DIR` to switch config dirs

For dotfiles, the practical approach is to manage multiple user-level configs and switch via symlinks or Ansible variables.

### Layer 3: Repo-specific (.claude/)

Project-level configuration checked into each repository.

```
.claude/
├── CLAUDE.md           # Project-specific instructions
├── settings.json       # Team permissions and hooks
├── settings.local.json # Personal overrides (gitignored)
├── commands/           # Project slash commands
├── agents/             # Project subagents
└── rules/              # Project rules
    └── *.md            # Conditional and unconditional rules
```

---

## Sources

- [Claude Code Settings - Official Docs](https://code.claude.com/docs/en/settings)
- [Claude Code Hooks Reference - Official Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code Memory Management - Official Docs](https://code.claude.com/docs/en/memory)
- [Claude Code MCP Configuration - Official Docs](https://code.claude.com/docs/en/mcp)
- [Claude Code Slash Commands - Official Docs](https://code.claude.com/docs/en/slash-commands)
- [Claude Code Subagents - Official Docs](https://code.claude.com/docs/en/sub-agents)
- [JSON Schema for settings.json](https://json.schemastore.org/claude-code-settings.json)
