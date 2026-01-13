---
globs: ["**/*.yml", "**/*.yaml", "!infrastructure/**"]
---
# Ansible Playbook Rules

- Use 2-space indentation for YAML
- Every task must have a descriptive `name:`
- Use OS family detection for cross-platform support:
  - macOS: `ansible_facts['os_family'] == "Darwin"`
  - Debian/Ubuntu: `ansible_facts['os_family'] == "Debian"`
  - Arch: `ansible_facts['os_family'] == "Archlinux"`
- Package manager tasks on Linux require `become: yes`
- Homebrew shell commands need `creates:` parameter for idempotency
- Prefer modules over shell commands when available
- Follow the existing per-tool playbook pattern in `tools/*/install_*.yml`
