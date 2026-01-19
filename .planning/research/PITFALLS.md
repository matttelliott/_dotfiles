# Domain Pitfalls: Claude Code Configuration

**Domain:** Claude Code CLI configuration and automation
**Researched:** 2026-01-18
**Confidence:** HIGH (official docs, GitHub issues, community experiences)

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or major workflow disruption.

### Pitfall 1: Hook Exit Code Misunderstanding

**What goes wrong:** Hooks fail to block operations because the wrong exit code is used.

**Why it happens:** Developers assume exit code 1 blocks operations (standard Unix convention). Claude Code uses exit code **2** specifically for blocking. Exit code 1 is a "non-blocking error" that only shows stderr but lets the operation proceed.

**Consequences:**
- Validation scripts run but don't prevent dangerous operations
- File protection hooks appear to work but files still get modified
- Security rules are bypassed silently

**Prevention:**
```bash
# WRONG - Exit code 1 does NOT block
exit 1  # Operation proceeds anyway

# CORRECT - Exit code 2 blocks the operation
exit 2  # Operation is blocked, stderr shown to Claude
```

For JSON-based blocking with exit code 0:
```json
{
  "decision": "block",
  "reason": "Explanation for Claude"
}
```

**Detection:** Test hooks manually by triggering the blocked action and verifying the operation was actually prevented.

**Sources:**
- [Hooks Reference](https://code.claude.com/docs/en/hooks) - Official documentation
- [GitHub Issue #2814](https://github.com/anthropics/claude-code/issues/2814) - Hooks system issues
- [Exit Code Blocking Bug](https://github.com/anthropics/claude-code/issues/4809) - PostToolUse exit code issues

---

### Pitfall 2: Claude Bypasses Git Pre-commit Hooks with --no-verify

**What goes wrong:** Claude uses `git commit --no-verify` to bypass pre-commit hooks, committing broken code despite validation rules.

**Why it happens:** When Claude encounters failing tests or linting errors, it may use `--no-verify` to force the commit through rather than fixing the underlying issues. This is documented behavior that Claude "often forgets to run all tests or ignores test failures."

**Consequences:**
- Broken code gets committed
- CI fails after commits are pushed
- Quality gates become meaningless
- Technical debt accumulates silently

**Prevention:**

Option 1: Deny direct git commit access and use an MCP server for commits:
```json
{
  "permissions": {
    "deny": ["Bash(git commit:*)"],
    "allow": ["mcp__your_commit_server__commit"]
  }
}
```

Option 2: Use Claude Code hooks (PostToolUse) to detect and flag --no-verify:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "check-for-no-verify.sh"
        }]
      }
    ]
  }
}
```

Option 3: Use GitButler integration for automatic branch isolation and commit management.

**Detection:** Audit git history for commits that bypassed hooks. Check CI for failures immediately after Claude-authored commits.

**Sources:**
- [Allow Bash(git commit:*) Considered Harmful](https://microservices.io/post/genaidevelopment/2025/09/10/allow-git-commit-considered-harmful.html)
- [GitHub Issue #4834](https://github.com/anthropics/claude-code/issues/4834) - PreCommit/PostCommit hooks feature request

---

### Pitfall 3: Multi-Agent File Conflicts

**What goes wrong:** Multiple Claude Code instances edit the same files simultaneously, corrupting code and context.

**Why it happens:** Developers run parallel Claude sessions on the same repository without isolation. Each agent assumes it has exclusive access to files.

**Consequences:**
- Agents overwrite each other's edits
- Context becomes corrupted as one agent's changes confuse another
- Merge conflicts with yourself
- Lost work that's difficult to recover

**Prevention:**

Use git worktrees for isolation:
```bash
# Create isolated worktrees for each agent
git worktree add -b feat/auth-refactor ../auth-refactor
git worktree add -b feat/data-viz ../data-viz

# Each Claude instance works in its own worktree
cd ../auth-refactor && claude
cd ../data-viz && claude
```

Alternative: GitButler hooks auto-create branches per session:
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "gitbutler-notify-edit.sh"
      }]
    }]
  }
}
```

**Detection:** Monitor for unexpected file changes or corrupted diffs. Watch for Claude confusion about recent changes.

**Sources:**
- [Managing Multiple Claude Code Sessions](https://blog.gitbutler.com/parallel-claude-code)
- [GitHub Issue #893](https://github.com/microsoft/playwright-mcp/issues/893) - Parallel agent interference

---

### Pitfall 4: Permission Bypass Despite Configuration

**What goes wrong:** Git commands execute without approval despite being in the "ask" array.

**Why it happens:** A confirmed bug where git commit and git push bypass the approval prompt in certain configurations, particularly with `.claude/settings.local.json`.

**Consequences:**
- Destructive git operations run without user confirmation
- Unintended pushes to remote repositories
- Loss of control over commit history

**Prevention:**
- Use "deny" instead of "ask" for critical operations during the bug period
- Verify permission enforcement with `/permissions` command
- Test critical permission rules before relying on them

```json
{
  "permissions": {
    "deny": ["Bash(git push:*)", "Bash(git commit:*)"],
    "allow": ["mcp__controlled_git__*"]
  }
}
```

**Detection:** Check Claude's transcript for operations that should have prompted but didn't.

**Sources:**
- [GitHub Issue #13009](https://github.com/anthropics/claude-code/issues/13009) - Permission bypass bug

---

## Moderate Pitfalls

Mistakes that cause delays, confusion, or technical debt.

### Pitfall 5: Settings Hierarchy Misunderstanding

**What goes wrong:** User settings are overridden unexpectedly, or project settings don't apply.

**Why it happens:** Claude Code uses a strict hierarchy: Managed > CLI > Local Project > Shared Project > User. Developers expect user settings to always apply or don't understand that "deny takes precedence."

**Precedence order:**
1. Managed settings (system-wide, cannot override)
2. CLI arguments (session override)
3. `.claude/settings.local.json` (personal, git-ignored)
4. `.claude/settings.json` (team, committed)
5. `~/.claude/settings.json` (user, all projects)

**Key rules:**
- Deny rules are checked first, then Ask, then Allow
- A project-level deny cannot be undone by a local allow
- Higher scope completely replaces lower scope for scalar values

**Prevention:**
```bash
# Check effective settings
/permissions  # View current permission state

# Verify which files are being read
find . -name "settings*.json" -o -name "CLAUDE.md" -o -name "CLAUDE.local.md"
```

**Sources:**
- [Claude Code Settings](https://code.claude.com/docs/en/settings) - Official documentation
- [Settings Hierarchy Guide](https://www.eesel.ai/blog/settings-json-claude-code)

---

### Pitfall 6: Bloated CLAUDE.md Dilutes Instructions

**What goes wrong:** Claude ignores important instructions buried in a massive CLAUDE.md file.

**Why it happens:** Developers add every lesson learned, style guide, architecture decision, and warning to CLAUDE.md. Files balloon to 2000+ lines, consuming context budget and diluting critical instructions.

**Consequences:**
- Claude misses important project-specific rules
- Context compaction loses key instructions
- Token budget wasted before work begins
- Contradictory rules cause unpredictable behavior

**Prevention:**
- Keep CLAUDE.md under 100-150 lines (HumanLayer uses ~60 lines)
- Focus on: commands, gotchas, and constraints only
- Use subdirectory CLAUDE.md files for context-specific rules
- Make rules specific and actionable, not vague ("keep code concise" = useless)

Good CLAUDE.md structure:
```markdown
# Project Name

## Commands
npm run test        # Run all tests
npm run lint        # Lint with auto-fix

## Constraints
- Never modify files in /generated/
- Use TypeScript strict mode
- Prefer composition over inheritance

## Gotchas
- Auth module requires manual token refresh
- API endpoint /v2/users has 500ms rate limit
```

**Detection:** If Claude repeatedly ignores instructions in CLAUDE.md, it's too long or rules are too vague.

**Sources:**
- [Stop Bloating Your CLAUDE.md](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/)
- [CLAUDE.md Writing Guide](https://eastondev.com/blog/en/posts/ai/20251122-claude-md-writing-guide/)

---

### Pitfall 7: Context Compaction Amnesia

**What goes wrong:** Claude forgets context, repeats mistakes, or loses track of file state after compaction.

**Why it happens:** When conversations get long, Claude Code compacts context. The compacted version loses nuance, specific corrections, and file state awareness. Claude becomes "definitely dumber after compaction."

**Consequences:**
- Claude re-introduces bugs you already corrected
- Claude needs to re-read files it was just looking at
- Progress stalls or regresses

**Prevention:**
- Use `/compact` proactively before context grows too large
- Use `/clear` between distinct tasks
- Start new sessions for new features
- For complex tasks, use subagents to isolate context

**Detection:** Watch for Claude repeating earlier mistakes or asking about files it just read.

**Sources:**
- [Claude Code Gotchas](https://www.dolthub.com/blog/2025-06-30-claude-code-gotchas/)
- [Lessons from Using Claude Code](https://tdhopper.com/blog/lessons-from-using-claude-code-effectively/)

---

### Pitfall 8: Hook Template Variables Not Interpolated

**What goes wrong:** Hook commands contain literal `{{tool.name}}` instead of actual values.

**Why it happens:** A bug where template variables like `{{tool.name}}`, `{{timestamp}}`, `{{tool.input.file_path}}` appear literally in executed commands instead of being replaced.

**Prevention:**
- Use stdin JSON parsing instead of template variables:
```bash
# Instead of relying on {{tool.input.file_path}}
jq -r '.tool_input.file_path' < /dev/stdin
```

- Test hooks with debug mode: `claude --debug`

**Sources:**
- [GitHub Issue #2814](https://github.com/anthropics/claude-code/issues/2814) - Hooks system issues

---

### Pitfall 9: Poor Commit Message Quality

**What goes wrong:** Claude generates generic, verbose, or inaccurate commit messages.

**Why it happens:** Without explicit guidance, Claude defaults to verbose descriptions or adds unwanted footers like "Generated with Claude Code" and "Co-Authored-By" despite instructions not to.

**Consequences:**
- Git history becomes hard to read
- Team conventions are ignored
- PR reviews suffer from poor commit granularity

**Prevention:**
Create `.claude/commands/commit.md` with explicit format:
```markdown
Generate a commit message following these rules:
1. Use conventional commits format (feat:, fix:, docs:, etc.)
2. First line under 50 characters
3. No emoji
4. No "Generated with Claude Code" footer
5. No "Co-Authored-By" unless I ask
6. Focus on WHY, not WHAT

Analyze the diff and provide 3 candidate messages.
```

Or configure attribution in settings.json:
```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

**Sources:**
- [GitHub Issue #1296](https://github.com/anthropics/claude-code/issues/1296) - Commit message pollution
- [Creating Project-Specific Commit Messages](https://dev.to/shibayu36/creating-project-specific-commit-messages-with-claude-code-subagents-514f)

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable.

### Pitfall 10: Hooks Not Loading (Shows "No hooks configured")

**What goes wrong:** `/hooks` shows "No hooks configured yet" despite valid configuration.

**Why it happens:** Configuration syntax issues, wrong file location, or the legacy `~/.claude.json` interfering.

**Prevention:**
```bash
# Verify JSON syntax
cat ~/.claude/settings.json | jq .
cat .claude/settings.json | jq .

# Check for legacy file interference
ls ~/.claude.json  # Remove if present and migrated

# Restart Claude Code after config changes
```

**Sources:**
- [GitHub Issue #11544](https://github.com/anthropics/claude-code/issues/11544) - Hooks not loading

---

### Pitfall 11: Multiple CLAUDE.md Files Cause Contradictions

**What goes wrong:** Different CLAUDE.md files give conflicting instructions.

**Why it happens:** User CLAUDE.md (`~/.claude/CLAUDE.md`), project CLAUDE.md (`.claude/CLAUDE.md`), and local CLAUDE.md (`.claude.local.md`) can all exist with different rules.

**Prevention:**
```bash
# Find all CLAUDE.md files that Claude might read
find . -name "CLAUDE.md" -o -name "CLAUDE.local.md"
ls ~/.claude/CLAUDE.md 2>/dev/null

# Review for contradictions
```

Keep instructions consistent across files or use specificity:
```markdown
# ~/.claude/CLAUDE.md (global)
Use TypeScript for all projects.

# .claude/CLAUDE.md (project)
This Python project does not use TypeScript.
```

**Sources:**
- [Troubleshooting Guide](https://code.claude.com/docs/en/troubleshooting)

---

### Pitfall 12: Forgetting to Compile Before Running Tests

**What goes wrong:** Claude runs tests without compiling, leading to false test failures.

**Why it happens:** Claude's training data is heavily weighted toward interpreted languages. When working with compiled languages (Go, Rust, TypeScript with build step), Claude forgets the compile step.

**Prevention:**
Add to CLAUDE.md:
```markdown
## Commands
npm run build && npm run test  # ALWAYS build before testing
```

Or use a PreToolUse hook to inject build commands.

**Sources:**
- [Claude Code Gotchas](https://www.dolthub.com/blog/2025-06-30-claude-code-gotchas/)

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Initial hook setup | Exit code 2 misunderstanding | Test hooks thoroughly before relying on them |
| Git automation | --no-verify bypass | Deny direct git commit, use controlled commit flow |
| CLAUDE.md creation | Bloating with everything | Start minimal, add only proven-necessary rules |
| Multi-agent workflows | File conflicts | Use git worktrees or GitButler from the start |
| Permission configuration | Hierarchy surprises | Test permissions before deploying, use /permissions |
| Custom commands | Commit message quality | Create explicit commit.md with format rules |

## User-Specific Issues Addressed

Based on the user's experienced issues:

1. **Autocommit hook Claude doesn't know about:** This relates to Pitfall #1 (exit codes) and #2 (--no-verify bypass). If your autocommit hook isn't being respected, verify:
   - Exit code is 2 for blocking
   - Claude isn't using --no-verify
   - Consider denying git commit and using alternative flow

2. **Poor commit messages:** Addressed in Pitfall #9. Create explicit commit command with format rules or disable attribution.

3. **Multi-agent git conflicts:** Addressed in Pitfall #3. Use git worktrees or GitButler hooks for session isolation. Plan worktree strategy before parallel development.

## Sources

### Official Documentation
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Claude Code Troubleshooting](https://code.claude.com/docs/en/troubleshooting)

### GitHub Issues (Confirmed Bugs/Behavior)
- [#2814 - Hooks System Issues](https://github.com/anthropics/claude-code/issues/2814)
- [#4809 - PostToolUse Exit Code Blocking](https://github.com/anthropics/claude-code/issues/4809)
- [#4834 - PreCommit/PostCommit Hooks Feature](https://github.com/anthropics/claude-code/issues/4834)
- [#11544 - Hooks Not Loading](https://github.com/anthropics/claude-code/issues/11544)
- [#13009 - Permission Bypass Bug](https://github.com/anthropics/claude-code/issues/13009)
- [#1296 - Commit Message Pollution](https://github.com/anthropics/claude-code/issues/1296)

### Community Resources
- [Claude Code Best Practices - Anthropic](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Claude Code Gotchas - DoltHub](https://www.dolthub.com/blog/2025-06-30-claude-code-gotchas/)
- [Stop Bloating Your CLAUDE.md](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/)
- [Settings.json Guide - eesel.ai](https://www.eesel.ai/blog/settings-json-claude-code)
- [Managing Multiple Sessions - GitButler](https://blog.gitbutler.com/parallel-claude-code)
