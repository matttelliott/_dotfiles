# Claude Code

Anthropic's CLI for Claude AI assistant.

https://claude.ai/claude-code

## GSD Cross-Project Patterns

### Knowledge Sharing Between Projects

GSD Claude can create tasks in other projects, enabling knowledge transfer across your workspace:

```bash
# While working in homelab project
# Claude discovers: "This monitoring pattern would be useful in dotfiles"

→ Creates: ~/_dotfiles/.planning/todos/pending/002-monitoring-pattern.md
  with source: "homelab project discussion"

# Later, in dotfiles project
/gsd:check-todos
→ "Found todo from homelab: Add VictoriaMetrics monitoring patterns"
```

### Cross-Project Todo Format

```markdown
---
id: 001
created: 2026-01-20
source: homelab project discussion  ← Traceability!
context: Brief description of origin
priority: low|medium|high
---

# Task Title

## Background
Why this task exists, what triggered it

## What to Do
Specific actionable steps

## Reference
Link back to source project or conversation
```

The `source:` field creates traceability across projects.

### Common Patterns

**Tool Discovery** - Homelab needs new tool → creates todo in _dotfiles:
```markdown
source: homelab project
Task: Add tool X to dotfiles for cluster deployment
```

**Pattern Sharing** - App project finds better approach → shares with infrastructure:
```markdown
source: web-app project
Task: Apply this database migration pattern to infrastructure templates
```

**Bidirectional Learning** - Dotfiles adds new tool → notifies dependent projects:
```markdown
source: _dotfiles provisioning
Task: Tool X now available on all machines, integrate with project Y
```

### When to Use Cross-Project Todos

**Good use cases:**
- ✅ Project A learns something Project B should know
- ✅ Infrastructure change affects multiple dependent projects
- ✅ Tool added to dotfiles → notify projects that requested it
- ✅ Bug found in one project, same pattern exists in others

**Avoid:**
- ❌ Creating todos in projects you don't maintain
- ❌ Cross-project todos for tightly coupled work (use single project)
- ❌ Overusing for simple notes (use project's own todos)

### Implementation

Any GSD Claude session can write to another project's todo directory:

```bash
# From any project
Write: /path/to/other-project/.planning/todos/pending/NNN-task.md

# Future Claude in that project discovers it
/gsd:check-todos
```

No special tooling needed - just markdown files with proper frontmatter.
