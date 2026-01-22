---
phase: quick
plan: 002
type: execute
wave: 1
depends_on: []
files_modified: []
autonomous: true

must_haves:
  truths:
    - "mosh is installed on desktop"
    - "mosh-server is accessible for incoming connections"
  artifacts:
    - path: "tools/mosh/install_mosh.yml"
      provides: "Mosh installation playbook"
      exists: true
  key_links:
    - from: "setup.yml"
      to: "tools/mosh/install_mosh.yml"
      via: "import_playbook"
---

<objective>
Apply the existing mosh tool to the desktop host.

Purpose: Enable mosh connections to the desktop machine for more resilient remote shell sessions over unreliable networks.

Output: mosh package installed on desktop via Ansible.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@tools/mosh/install_mosh.yml
@inventory.yml
</context>

<tasks>

<task type="auto">
  <name>Task 1: Apply mosh playbook to desktop</name>
  <files>None (existing playbook, no modifications needed)</files>
  <action>
    Run the existing mosh installation playbook against the desktop host.

    The playbook already exists at `tools/mosh/install_mosh.yml` and supports Arch Linux
    via pacman. Desktop is in the `arch` host group.

    Command:
    ```bash
    ansible-playbook tools/mosh/install_mosh.yml --limit desktop
    ```

    Note: The playbook is already included in setup.yml, so this is just applying it
    to a specific host. No code changes required.
  </action>
  <verify>
    1. Run: `ansible-playbook tools/mosh/install_mosh.yml --limit desktop --check`
    2. If check passes, run without --check
    3. Verify: `ssh desktop 'which mosh-server'` returns `/usr/bin/mosh-server`
  </verify>
  <done>
    - mosh package installed on desktop
    - mosh-server binary exists at /usr/bin/mosh-server
    - Ansible reports success (ok or changed, no failures)
  </done>
</task>

</tasks>

<verification>
- `ssh desktop 'mosh-server --version'` returns version info
- `ssh desktop 'pacman -Q mosh'` shows mosh package installed
</verification>

<success_criteria>
- mosh installed on desktop via pacman
- mosh-server accessible for incoming connections
- Playbook execution completes without errors
</success_criteria>

<output>
After completion, create `.planning/quick/002-add-mosh-tool-and-apply-to-desktop/002-SUMMARY.md`
</output>
