---
description: Create boilerplate for a new tool in the dotfiles
argument-hint: <tool-name>
---

Create a new tool in the dotfiles with proper structure and conventions.

## Arguments

- `$ARGUMENTS` = tool name (required, lowercase, e.g., "ripgrep", "lazygit")

## Step 1: Create Directory Structure

```
tools/$ARGUMENTS/
├── install_$ARGUMENTS.yml   # Required: Ansible playbook
├── $ARGUMENTS.zsh           # Optional: Shell config (if tool needs PATH, aliases, etc.)
└── README.md                # Optional: Only if tool has special setup notes
```

## Step 2: Create the Playbook

Create `tools/$ARGUMENTS/install_$ARGUMENTS.yml` using this pattern:

```yaml
---
- name: Install $ARGUMENTS
  hosts: all
  gather_facts: true

  tasks:
    - name: Install $ARGUMENTS (macOS)
      community.general.homebrew:
        name: $ARGUMENTS
        state: present
      when: ansible_facts['os_family'] == "Darwin"

    - name: Install $ARGUMENTS (Debian)
      apt:
        name: $ARGUMENTS
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Debian"

    - name: Install $ARGUMENTS (Arch)
      pacman:
        name: $ARGUMENTS
        state: present
      become: yes
      when: ansible_facts['os_family'] == "Archlinux"
```

Adjust package names per OS if they differ (e.g., `fd` on Homebrew vs `fd-find` on Debian).

## Step 3: Create Shell Config (if needed)

Only create `tools/$ARGUMENTS/$ARGUMENTS.zsh` if the tool needs:
- PATH modifications
- Aliases
- Environment variables
- Shell completions
- Lazy loading

Example pattern:
```zsh
# tools/$ARGUMENTS/$ARGUMENTS.zsh

# Aliases
alias short='$ARGUMENTS --common-flags'

# Environment
export TOOL_HOME="$HOME/.tool"
```

If created, add sourcing to zshrc by adding this task to the playbook:
```yaml
    - name: Source $ARGUMENTS config in zshrc
      lineinfile:
        path: ~/.zshrc
        line: 'source ~/\_dotfiles/tools/$ARGUMENTS/$ARGUMENTS.zsh'
        create: yes
```

## Step 4: Add to setup.yml

Add import to `/Users/matt/_dotfiles/setup.yml` in the appropriate section:

```yaml
- import_playbook: tools/$ARGUMENTS/install_$ARGUMENTS.yml
```

Group with similar tools (CLI tools, GUI apps, etc.).

## Step 5: Test

Determine current hostname and run in check mode:
```bash
ansible-playbook tools/$ARGUMENTS/install_$ARGUMENTS.yml --connection=local --limit $(hostname -s) --check
```

Then apply:
```bash
ansible-playbook tools/$ARGUMENTS/install_$ARGUMENTS.yml --connection=local --limit $(hostname -s)
```
