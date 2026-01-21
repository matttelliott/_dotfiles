---
created: 2026-01-21T03:46
title: Install Sequential Thinking MCP for structured problem-solving in Claude Code
area: config
files:
  - ~/.claude/settings.json
---

## Problem

GSD workflows involve complex problem-solving when breaking down phases and creating execution plans. Claude's default reasoning can miss edge cases or fail to revise approaches when initial assumptions are wrong.

Sequential Thinking MCP introduces a structured, reflective thinking process that mirrors human cognitive patterns - enabling Claude to methodically work through problems, revise approaches when needed, and maintain context across extended reasoning chains.

This pairs well with GSD's planning phases (/gsd:plan-phase, /gsd:research-phase) where better reasoning leads to more complete plans.

## Solution

Install Sequential Thinking MCP server:

1. Find the MCP server package (npm or other)
2. Add to ~/.claude/settings.json mcpServers configuration
3. Test with a GSD planning session to verify improved reasoning

Expected benefits:
- Better phase breakdown during roadmap creation
- More thorough research in /gsd:research-phase
- Improved deviation handling during execution

Reference: Recommended as top MCP for GSD workflows (2026 research)
