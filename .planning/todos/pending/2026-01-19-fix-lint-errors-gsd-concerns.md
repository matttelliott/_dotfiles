---
created: 2026-01-19T02:20
title: Fix lint errors and GSD concerns
area: tooling
files:
  - .planning/codebase/CONCERNS.md
---

## Problem

The codebase mapping identified 1135+ ansible-lint violations and various other concerns. The lint hook is currently non-blocking (`|| true`) because fixing these would block all YAML edits until resolved.

Additionally, there may be GSD-related concerns from the codebase analysis that should be addressed.

## Solution

1. Review `.planning/codebase/CONCERNS.md` for full list
2. Prioritize lint errors by severity
3. Fix incrementally (perhaps one category at a time)
4. Consider enabling blocking lint hook once violations are under control
