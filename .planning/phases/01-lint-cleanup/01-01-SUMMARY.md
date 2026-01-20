# Plan 01-01: Fix FQCN and truthy violations

**Status:** ✅ Complete
**Completed:** 2026-01-20

## Objective

Fix FQCN and truthy violations across all playbooks to address 677 violations (413 fqcn[action-core] + 264 yaml[truthy]).

## What Was Done

### Session 1 (Previous Claude - Committed: 24bd0bb)
- Applied FQCN prefixes to 104 files
  - `ansible.builtin.*` for core modules (shell, command, apt, file, stat, copy, etc.)
  - `community.general.*` for community modules (pacman)
- Applied truthy fixes for common fields (become, update_cache, create, force, etc.)
  - Changed `yes` → `true`
  - Changed `no` → `false`
- Session ended due to rate limiting before completion

### Session 2 (Current - Picking up where previous session left off)
- Fixed incorrect `ansible.builtin.gather_facts` changes (gather_facts is a playbook directive, not a module)
- Applied remaining truthy fixes for edge case fields:
  - `ignore_errors: yes` → `true`
  - `remote_src: yes` → `true`
  - `check_mode: no` → `false`
  - `append: yes` → `true`
  - `enabled: yes` → `true`
- Fixed remaining FQCN violation:
  - `tools/1password_cli/install_1password_cli.yml:48` - `stat` → `ansible.builtin.stat` in local_action context

### Files Modified (9 in current session)
- tools/docker/install_docker.yml
- tools/fail2ban/install_fail2ban.yml
- tools/firefox/install_firefox.yml
- tools/firefox_developer/install_firefox_developer.yml
- tools/gpu/install_gpu.yml
- tools/mullvad/install_mullvad.yml
- tools/nas/install_nas.yml
- tools/ssh/install_ssh.yml
- tools/wakeonlan/install_wakeonlan.yml

## Verification

```bash
$ ansible-lint setup.yml 2>&1 | grep -E 'fqcn\[action|yaml\[truthy\]' | wc -l
0
```

**Results:**
- ✅ Zero fqcn[action-core] violations (was 413)
- ✅ Zero fqcn[action] violations (was 64)
- ✅ Zero yaml[truthy] violations (was 264)
- ✅ All playbooks remain valid YAML
- ✅ 677 violations eliminated

## Decisions Made

1. **gather_facts handling**: Reverted incorrect FQCN prefix - this is a playbook-level directive, not an Ansible module
2. **Field coverage**: Extended truthy fix patterns to include all boolean fields (ignore_errors, remote_src, check_mode, append, enabled) beyond the initial common set
3. **local_action modules**: Must use FQCN in `module:` parameter even within local_action context

## Issues Encountered

- Previous session was rate-limited mid-execution
- Initial sed patterns didn't cover all boolean field names, requiring iterative expansion
- gather_facts was incorrectly treated as a module name

## Impact

- **Before:** 677 FQCN and truthy violations
- **After:** 0 violations
- **Reduction:** 100% of targeted violations eliminated
- **Files changed:** 104 total (9 in current session)
- **Breaking changes:** None - all changes are style/format only

## Next Steps

Violations eliminated. Ready for Plan 01-02.
