# Project Research Summary

**Project:** Dotfiles Claude Code Configuration
**Domain:** Developer tools configuration and automation
**Researched:** 2026-01-18
**Confidence:** HIGH

## Executive Summary

Claude Code uses a well-documented hierarchical configuration system with three primary scopes: user (`~/.claude/`), project (`.claude/`), and managed (system-level). For a dotfiles-managed deployment, Ansible should own the user-level configuration while respecting that project-level configs are repo-specific and portable configs (like GSD) have their own installers. The configuration stack is entirely YAML, JSON, and Markdown with no external runtime dependencies.

The recommended approach is to implement a three-layer architecture: (1) Ansible-templated user config deployed to all machines via host groups, (2) portable configs installed independently to `~/.claude/<name>/`, and (3) repo-specific configs committed to each project. Settings files merge arrays across scopes but replace scalars, meaning user-level permission rules combine with project rules while model preferences are overridden. Memory files (CLAUDE.md) combine additively with later files having higher precedence.

Key risks center on hook implementation (exit code 2 required for blocking, not exit code 1), git automation (Claude bypasses pre-commit hooks with --no-verify), and multi-agent conflicts (parallel sessions corrupt shared files). All risks have well-documented mitigations: test hooks thoroughly, deny direct git commit access, and use git worktrees for parallel work.

## Key Findings

### Recommended Stack

Claude Code configuration uses native formats with no build step required.

**Core technologies:**
- **JSON**: `settings.json` for permissions, hooks, environment vars, and behavior
- **Markdown**: `CLAUDE.md` for memory/instructions, commands in `.claude/commands/`, agents in `.claude/agents/`
- **Shell scripts**: Hook executables that receive JSON via stdin
- **Ansible**: Template-based deployment with Jinja2 conditionals for host groups

**Critical version requirements:** None. Configuration format is stable across Claude Code versions.

### Expected Features

**Must have (table stakes):**
- Global `CLAUDE.md` with host-group-aware templating
- User `settings.json` with common permission rules (git, npm, shell tools)
- Existing project `.claude/` structure maintained
- Gitignored `settings.local.json` for personal overrides

**Should have (competitive):**
- Custom slash commands for common workflows
- Custom subagents for specialized tasks
- Pre/Post hooks for automated linting and formatting
- Conditional rules via YAML frontmatter with path patterns
- Host-specific config via Ansible group_names

**Defer (v2+):**
- MCP server integration (project-specific, not dotfiles concern)
- Complex hook chains (start simple, add as needed)
- Portable config management (GSD has its own installer)
- Skills directory (commands/agents suffice initially)

### Architecture Approach

The architecture follows Claude Code's native hierarchy: user config provides defaults, project config overrides for team sharing, and local config handles personal preferences. Arrays merge (permissions accumulate), scalars replace (model preference wins).

**Major components:**
1. **User layer (`~/.claude/`)** — Ansible-deployed global defaults: CLAUDE.md template, settings.json, user commands/agents
2. **Project layer (`.claude/`)** — Repo-committed team config: project-specific rules, hooks, commands
3. **Local layer (`settings.local.json`, `CLAUDE.local.md`)** — Personal overrides, auto-gitignored

**Key patterns:**
- Commands in subdirectories create namespaces: `~/.claude/commands/gsd/` becomes `/gsd:command`
- Agents use flat naming with prefixes: `gsd-planner.md`, `gsd-executor.md`
- Hooks configured in settings.json, scripts stored in `~/.claude/hooks/`
- Supporting data for portables in `~/.claude/<name>/`

### Critical Pitfalls

1. **Hook exit code 2 required for blocking** — Exit code 1 does NOT block operations; use exit 2 or return `{"decision": "block"}` JSON with exit 0
2. **Claude bypasses pre-commit hooks** — Uses `--no-verify` to force commits; deny direct git commit and use controlled flow
3. **Multi-agent file conflicts** — Parallel sessions overwrite each other; use git worktrees for isolation
4. **Permission bypass bug** — Git commands may ignore "ask" rules; use "deny" for critical operations during affected versions
5. **Bloated CLAUDE.md** — Over 100-150 lines dilutes instructions; keep minimal, use subdirectory CLAUDE.md for context-specific rules

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: User Layer Foundation

**Rationale:** User-level config must exist before project configs can reference or override it. This establishes the base layer that all other configs build upon.

**Delivers:**
- Ansible playbook for `~/.claude/` directory structure
- Templated `CLAUDE.md` with host-group conditionals
- Base `settings.json` with common permission rules
- Directory scaffolding for commands/, agents/, hooks/

**Addresses:** Global CLAUDE.md, user settings.json, git-aware permissions, shell tool permissions

**Avoids:** Hardcoded paths (use $HOME variables), secrets in settings (use environment vars)

### Phase 2: Permission and Hook System

**Rationale:** Permissions and hooks provide the safety layer that prevents the critical pitfalls. Must be in place before automating any git operations.

**Delivers:**
- Permission rules for git, npm, common CLIs
- Pre/Post hook scripts with proper exit codes
- Hook validation testing approach
- Attribution configuration for commit messages

**Uses:** settings.json hooks configuration, shell scripts

**Implements:** Hook architecture from ARCHITECTURE.md

**Avoids:** Exit code 1 confusion (test with exit 2), hook template variable bugs (use stdin JSON parsing)

### Phase 3: Custom Commands and Agents

**Rationale:** Commands and agents build on the permission/hook foundation. They provide workflow automation that respects the safety guardrails.

**Delivers:**
- User-level slash commands for common workflows
- User-level subagents for specialized tasks
- Command namespace conventions
- Agent naming conventions

**Addresses:** Custom slash commands, custom subagents differentiators

**Avoids:** Flat command namespace (use subdirectories), poor commit messages (explicit format in commit command)

### Phase 4: Host-Specific Configuration

**Rationale:** Once the base config is stable, add host-group variations for different machine types (macs, debian, arch, with_gui_tools, etc.).

**Delivers:**
- Jinja2 conditionals in CLAUDE.md template
- Host-group-specific permission rules
- Machine-type-aware defaults

**Uses:** Ansible group_names, existing inventory structure

### Phase 5: Project Config Enhancement

**Rationale:** Finally, enhance the existing `.claude/` in this dotfiles repo as the reference implementation.

**Delivers:**
- Enhanced project settings.json with hooks
- Project-specific commands for dotfiles workflows
- Documentation for other repos to follow pattern

**Addresses:** Project .claude/ structure, existing project enhancement

### Phase Ordering Rationale

- **Phases 1-2 first:** Must establish user config and safety layer before any automation
- **Phase 2 before 3:** Hooks enforce safety that commands rely on
- **Phase 3 before 4:** Base commands work before adding host variations
- **Phase 4 before 5:** User config complete before using as reference for project config

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 2 (Hooks):** Test exit code behavior extensively; known bugs in PostToolUse blocking
- **Phase 3 (Commands/Agents):** Subagent prompt engineering requires iteration

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation):** Well-documented file locations and formats
- **Phase 4 (Host-Specific):** Standard Ansible templating, no Claude-specific complexity
- **Phase 5 (Project Config):** Same patterns as Phase 1-3, applied to project scope

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official documentation, JSON schema available |
| Features | HIGH | Official docs, community consensus on best practices |
| Architecture | HIGH | Official hierarchy documented, verified precedence rules |
| Pitfalls | HIGH | GitHub issues confirm bugs, community experiences validate |

**Overall confidence:** HIGH

### Gaps to Address

- **Hook exit code bugs:** Known issues (#4809, #2814) may affect behavior; test thoroughly and monitor for fixes
- **Permission bypass bug (#13009):** Verify if resolved before relying on "ask" for critical operations
- **Portable config interaction:** GSD and Ansible-managed configs must not conflict; namespace carefully

## Sources

### Primary (HIGH confidence)
- [Claude Code Settings](https://code.claude.com/docs/en/settings) — permissions, hooks, hierarchy
- [Claude Code Memory](https://code.claude.com/docs/en/memory) — CLAUDE.md loading order
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — exit codes, stdin format
- [Claude Code Slash Commands](https://code.claude.com/docs/en/slash-commands) — command format
- [Claude Code Sub-agents](https://code.claude.com/docs/en/sub-agents) — agent configuration
- [JSON Schema](https://json.schemastore.org/claude-code-settings.json) — settings.json structure

### Secondary (MEDIUM confidence)
- GitHub Issues #2814, #4809, #4834, #13009 — known bugs and workarounds
- [Anthropic Engineering Blog](https://www.anthropic.com/engineering/claude-code-best-practices) — best practices
- [GitButler Blog](https://blog.gitbutler.com/parallel-claude-code) — multi-agent isolation

### Tertiary (LOW confidence)
- Community guides (eesel.ai, alexop.dev) — CLAUDE.md best practices, needs validation against official docs

---
*Research completed: 2026-01-18*
*Ready for roadmap: yes*
