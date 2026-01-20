# Plan 01-02: Fix name[play] violations

**Status:** ✅ Complete
**Completed:** 2026-01-20

## Objective

Fix name[play] violations by adding descriptive names to all plays, especially import_playbook directives.

## What Was Done

### Findings

Initial audit showed only **2 violations** (not the expected ~100):
- Most import_playbook directives in setup.yml already had names from previous work
- Only 2 tool playbooks had unnamed import_playbook directives

### Files Modified

Fixed 2 unnamed import_playbook directives:

1. **tools/claude-code/install_claude-code.yml:2**
   - Added: `name: Install Node.js (dependency)`
   - For: `import_playbook: ../node/install_node.yml`

2. **tools/codex/install_codex.yml:2**
   - Added: `name: Install Node.js (dependency)`
   - For: `import_playbook: ../node/install_node.yml`

Both files import node.js as a dependency before installing their respective npm packages.

## Verification

```bash
$ ansible-lint setup.yml 2>&1 | grep -c 'name\[play\]'
0
```

**Results:**
- ✅ Zero name[play] violations (was 2)
- ✅ All import_playbook directives have descriptive names
- ✅ All playbooks remain valid YAML

## Decisions Made

1. **Naming convention for dependency imports**: Used "Install {tool} (dependency)" to clearly indicate the import is for a prerequisite
2. **No changes to setup.yml needed**: All import_playbook entries already had names from previous maintenance

## Impact

- **Before:** 2 name[play] violations
- **After:** 0 violations
- **Reduction:** 100% of violations eliminated
- **Files changed:** 2
- **Breaking changes:** None - purely additive metadata

## Notes

This plan was much simpler than expected because setup.yml already had comprehensive play names. The plan description anticipated ~100 violations, but the codebase was already mostly compliant. Only the two AI tool playbooks (claude-code and codex) had unnamed dependency imports.

## Next Steps

Violations eliminated. Ready for Plan 01-03.
