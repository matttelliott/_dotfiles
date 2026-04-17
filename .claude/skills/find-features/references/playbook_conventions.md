# Playbook conventions for this dotfiles repo

When promoting an approved feature, author an Ansible playbook that matches
the repo's established style. The CLAUDE.md at the repo root has the
authoritative rules; this reference distills the parts you'll use most.

## Skeleton — simple package + zsh config

Use this shape for most tools (pattern lifted from `tools/bat/install_bat.yml`):

```yaml
- name: Install <tool>
  hosts: all
  gather_facts: true
  tasks:
    - name: Install <tool> via Homebrew
      ansible.builtin.shell: /opt/homebrew/bin/brew install <tool>
      args:
        creates: /opt/homebrew/bin/<tool>
      when: ansible_facts['os_family'] == "Darwin"

    - name: Install <tool> via apt (Debian)
      ansible.builtin.apt:
        name: <tool>
        state: present
      become: true
      when: ansible_facts['os_family'] == "Debian"

    - name: Install <tool> via pacman (Arch)
      community.general.pacman:
        name: <tool>
        state: present
      become: true
      when: ansible_facts['os_family'] == "Archlinux"

    - name: Create zsh config directory
      ansible.builtin.file:
        path: ~/.config/zsh
        state: directory

    - name: Install <tool> zsh config
      ansible.builtin.copy:
        src: <tool>.zsh
        dest: ~/.config/zsh/<tool>.zsh

    - name: Source <tool> config in zshrc
      ansible.builtin.lineinfile:
        path: ~/.zshrc
        line: 'source ~/.config/zsh/<tool>.zsh'
        create: true
```

Drop the zsh block if the tool doesn't need shell config.

## Templated configs

If the config needs variables (e.g. themes, user-specific paths), use a
`.j2` template and `ansible.builtin.template:` instead of `copy:`. See
`tools/tmux/install_tmux.yml` for a working example.

## Key rules (from CLAUDE.md)

- **YAML: 2-space indentation.**
- **`become: yes`** for Linux package manager tasks (not for user-scoped file ops).
- **`creates:` guards** for Homebrew shell installs to stay idempotent.
- **Package names may differ per OS** — verify the apt/pacman names, not
  just the brew name. `bat` and `ripgrep` are famous for this (apt ships
  them as `batcat` / `ripgrep`, some distros rename).
- **Do not edit Nerd Font / Powerline characters directly.** If a config
  contains U+E0xx glyphs, use `\uXXXX` escape sequences in Ansible vars
  (see `themes/style_angle.yml` for the pattern). If the feature you're
  promoting involves these, flag it to the user and let them paste the
  glyphs into the config file themselves.

## Addon playbooks (extending an existing tool)

If the approved feature is an addon to an existing tool (say, a tmux
plugin), prefer extending the existing `tools/<tool>/install_<tool>.yml`
rather than creating a new tool dir. Use `write_mode: "replace"` in the
changeset and include the full new file content. Keep the existing task
names stable so diffs stay readable.

If the addon is big enough to warrant its own dir (multiple new files,
new package dependencies), then a fresh `tools/<new-name>/` is fine.

## Host groups

Tools installed only on certain host classes should live under the matching
group in `setup.yml` — but that wiring is outside the playbook's own file
and is a follow-up for the user, not the skill. Mention it in your
approval summary if the tool is GUI-only or login-only.
