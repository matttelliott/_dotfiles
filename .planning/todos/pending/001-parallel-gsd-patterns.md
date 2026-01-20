---
id: 001
created: 2026-01-20
source: homelab project discussion
context: Conversation about planner-claude vs worker-claude parallel execution
priority: medium
---

# Explore Parallel GSD Work Patterns

## The Idea

User wants to understand how to run **planner Claude** and **worker Claude** in parallel:

**Example scenario:**
- Worker Claude (Terminal 1): Executing "set up database access"
- Planner Claude (Terminal 2): Designing database schema

## Key Concepts Discussed

### Safe Parallelism Patterns
- **Different phase directories** = minimal conflicts
  - Worker: Phase N execution (touching infrastructure)
  - Planner: Phase N+1 planning (creating PLAN.md files)

### Natural Boundaries
- Worker executes current phase autonomously
- Planner/human designs next phase while worker runs
- When worker completes, next phase plan is ready to execute immediately

### STATE.md Synchronization
- Both sessions may update STATE.md
- Worker updates: "Phase N complete"
- Planner updates: "Phase N+1 planned"
- Resolution: Git merge or sequential commits

### GSD-Native Pattern
This is **exactly** how GSD phases are designed:
- Overlap planning with execution
- Phase boundaries are natural synchronization points
- Plan ahead while previous phase executes

## Task for Future Work

**Don't implement now.** When ready:

1. Document these patterns in GSD workflow guide
2. Test on _dotfiles project (safe scenario):
   - Terminal 1: Execute remaining Phase 1 plans (lint fixes)
   - Terminal 2: Plan Phase 2 (test infrastructure)
3. Create `parallel-workflows.md` in GSD docs covering:
   - When parallel work makes sense
   - Safe vs risky patterns
   - STATE.md conflict handling
   - Branch-based isolation for true parallelism

## Why _dotfiles is Good Test Project

- Clean phase boundaries
- Natural dependencies (tests need clean lint)
- Low risk (can always git reset)
- Good complexity for learning the pattern

## Reference

See homelab project conversation from 2026-01-20 for full discussion context.

---

**Next action when ready:** `/gsd:add-todo` or manually work through the exploration plan above.
