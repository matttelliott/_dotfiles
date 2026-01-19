# Research Summary: Claude Code Configuration

**Domain:** Claude Code configuration management for dotfiles
**Researched:** 2026-01-18
**Overall confidence:** HIGH

## Executive Summary

Claude Code provides a comprehensive hierarchical configuration system with clear precedence rules. Configuration is organized across three main layers: enterprise/managed (highest priority), project-level (team-shared), and user-level (personal). Each layer supports settings files (JSON), memory files (Markdown), hooks, slash commands, subagents, and MCP server configurations.

The system is well-documented and stable. All configuration file formats have official documentation and follow consistent patterns. The settings.json format has a published JSON Schema at schemastore.org. Hooks use a straightforward stdin JSON / exit code pattern that integrates well with shell scripts.

For the dotfiles use case, the three-layer configuration goal (user, portable, repo-specific) aligns well with Claude Code's native hierarchy, with one caveat: there is no native "portable config" concept. The practical solution is to use `CLAUDE_CONFIG_DIR` environment variable or symlink management to achieve portable configurations.

## Key Findings

**Stack:** Claude Code configuration uses JSON for settings, Markdown for memory/commands/agents, and shell scripts for hooks. All formats are well-specified with clear schemas. See `STACK.md` for complete file locations, JSON schemas, and hook interfaces.

**Architecture:** Hierarchical precedence: Managed > Local project > Shared project > User. Deny rules always override allow rules at the same level. See `ARCHITECTURE.md` for component locations and merge behavior.

**Critical pitfall:** Exit code 2 (not 1) blocks operations in hooks. Git --no-verify bypass is a known issue. See `PITFALLS.md` for complete list of gotchas with mitigations.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Phase 1: User-level configuration** - Deploy `~/.claude/` structure via Ansible
   - Addresses: Global CLAUDE.md, user settings.json, personal commands/agents
   - Low risk: Native Claude Code patterns, straightforward Ansible file deployment

2. **Phase 2: Project-level configuration** - Enhance existing `.claude/` in dotfiles repo
   - Addresses: Team settings, hooks, project-specific commands
   - Already partially implemented in this repo

3. **Phase 3: Portable configurations** - Implement config switching mechanism
   - Addresses: Different configs for different contexts (work, personal, client)
   - Higher complexity: Requires custom solution (symlinks or CLAUDE_CONFIG_DIR)
   - Consider: Is this actually needed? User + project config may suffice

**Phase ordering rationale:**
- User-level config provides the foundation that all projects inherit
- Project-level config builds on user defaults with project-specific overrides
- Portable configs are an optional enhancement if user+project separation is insufficient

**Research flags for phases:**
- Phase 1-2: Standard patterns, no additional research needed
- Phase 3: Needs design decision on implementation approach (symlinks vs CLAUDE_CONFIG_DIR vs Ansible variables)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| File locations | HIGH | Verified against official docs |
| settings.json schema | HIGH | Official schema exists at schemastore.org |
| Hook interfaces | HIGH | Comprehensive official documentation |
| Memory/CLAUDE.md | HIGH | Official docs with examples |
| Portable configs | MEDIUM | No native solution; custom implementation needed |

## Files Created

| File | Purpose |
|------|---------|
| `.planning/research/SUMMARY.md` | This file - executive summary with roadmap implications |
| `.planning/research/STACK.md` | Complete technology stack: file locations, JSON schemas, hook interfaces |
| `.planning/research/FEATURES.md` | Feature landscape with table stakes, differentiators, anti-features |
| `.planning/research/ARCHITECTURE.md` | Configuration hierarchy, component precedence, merge behavior |
| `.planning/research/PITFALLS.md` | Domain pitfalls with prevention strategies |

## Gaps to Address

- **Portable config implementation:** Needs design decision on approach
- **Version compatibility:** Research was based on current docs; older Claude Code versions may differ
- **Plugin system:** Not deeply researched; may be relevant for advanced configurations

## Sources

- [Claude Code Settings - Official Docs](https://code.claude.com/docs/en/settings)
- [Claude Code Hooks Reference - Official Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code Memory Management - Official Docs](https://code.claude.com/docs/en/memory)
- [Claude Code MCP Configuration - Official Docs](https://code.claude.com/docs/en/mcp)
- [Claude Code Slash Commands - Official Docs](https://code.claude.com/docs/en/slash-commands)
- [Claude Code Subagents - Official Docs](https://code.claude.com/docs/en/sub-agents)
- [JSON Schema for settings.json](https://json.schemastore.org/claude-code-settings.json)
