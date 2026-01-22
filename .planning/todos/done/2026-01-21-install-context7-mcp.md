---
created: 2026-01-21T03:46
title: Install Context7 MCP for live documentation in Claude Code
area: config
files:
  - ~/.claude/settings.json
---

## Problem

GSD research phases (/gsd:research-phase) currently rely on Claude's training data, which may be outdated. When researching how to implement features, having access to current documentation instead of stale knowledge improves plan quality.

Context7 MCP provides a documentation-as-context pipeline that fetches live, current documentation during research and planning, ensuring Claude uses up-to-date API references, framework guides, and best practices.

This pairs well with GSD workflows where research quality directly impacts execution success.

## Solution

Install Context7 MCP server:

1. Find the Context7 MCP package/repository
2. Add to ~/.claude/settings.json mcpServers configuration
3. Test with /gsd:research-phase to verify it fetches current docs

Expected benefits:
- More accurate technology research during phase planning
- Up-to-date framework/library documentation
- Better implementation approaches based on current best practices

Reference: Recommended as top MCP for GSD workflows (2026 research)
