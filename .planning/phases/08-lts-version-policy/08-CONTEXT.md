# Phase 8: LTS Version Policy - Context

**Gathered:** 2026-01-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Ensure tools with LTS (Long Term Support) releases use their LTS versions. Tools without LTS use "stable" or equivalent. Tools without either use "latest"/"master". This is about version selection policy, not version pinning or complex management.

</domain>

<decisions>
## Implementation Decisions

### Version Priority Policy
- If tool has LTS → use most recent LTS version
- If no LTS but has "stable" channel → use stable
- Otherwise → use latest/master (default behavior)

### Implementation Approach
- Use built-in LTS support where available (e.g., `nvm install --lts`)
- No complex version detection or pinning required
- Homebrew/apt packages already provide stable versions by default
- Keep it simple: just use the right flags where tools support them

### Tools with Known LTS Support
- **Node.js (nvm):** `nvm install --lts` and `nvm alias default lts/*`
- **uv/Python:** Check if uv has LTS flag; if not, use default (stable)
- **Homebrew/apt:** Already provides stable versions, no changes needed

### Claude's Discretion
- Specific implementation details for each tool
- Whether to add comments documenting the LTS policy in playbooks
- How to handle tools where LTS status is ambiguous

</decisions>

<specifics>
## Specific Ideas

- "nvm supports `nvm use --lts` out of the box"
- Keep it simple - use existing flags, don't build complex version detection
- Package managers (Homebrew, apt) already default to stable, so they're fine as-is

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-lts-version-policy*
*Context gathered: 2026-01-22*
