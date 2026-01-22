# Phase 7: Bug Fixes - Research

**Researched:** 2026-01-22
**Domain:** SSH known_hosts idempotency, Debian apt repository management
**Confidence:** HIGH

## Summary

This phase addresses two distinct bugs in the codebase:

1. **BUG-01: SSH known_hosts duplicates** - Current marker file pattern (`creates: ~/.ssh/.known_hosts_{{ item }}`) does not actually verify host presence in known_hosts. Solution: Use `ssh-keygen -F` to check host presence before adding, or migrate to `ansible.builtin.known_hosts` module with pipe lookup.

2. **BUG-02: Debian non-free repos fragile sed** - Current approach uses `sed` to modify `/etc/apt/sources.list` which is destructive and fragile. Solution: Use `ansible.builtin.deb822_repository` module for modern Debian (Bookworm+) or add a separate repository file via `apt_repository`.

**Primary recommendations:**
- BUG-01: Replace marker file pattern with `ssh-keygen -F` conditional check
- BUG-02: Use `deb822_repository` to add non-free/contrib as a separate source file

## Standard Stack

### Core
| Feature | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ssh-keygen -F` | OpenSSH (any) | Check host presence in known_hosts | Standard SSH utility, idempotent check |
| `ansible.builtin.deb822_repository` | Ansible 2.15+ | Modern Debian repo management | Official module for deb822 format |
| `ansible.builtin.known_hosts` | Ansible 2.11+ | Manage SSH host keys | Official module, handles deduplication |

### Supporting
| Feature | Purpose | When to Use |
|---------|---------|-------------|
| `ansible.builtin.apt_repository` | Legacy one-line repo format | Older Debian/Ubuntu or simple additions |
| `lookup('pipe', ...)` | Execute command and capture output | Dynamic key retrieval with ssh-keyscan |
| `changed_when` | Custom change detection | When shell command output indicates state |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `ssh-keygen -F` conditional | `ansible.builtin.known_hosts` module | Module is cleaner but requires key value upfront |
| `deb822_repository` | Manual sed on sources.list | Sed is fragile, module is declarative |
| `deb822_repository` | `apt_repository` with full repo line | Works but deb822 is modern Debian standard |

## Architecture Patterns

### Pattern 1: SSH known_hosts with ssh-keygen -F Check

**What:** Check if host exists in known_hosts before running ssh-keyscan
**When to use:** When you want simple shell-based idempotency
**Example:**
```yaml
# Solution: Check host presence with ssh-keygen -F before adding
- name: Check if host already in known_hosts
  ansible.builtin.shell: ssh-keygen -F {{ item }}.home.lan
  register: host_check
  changed_when: false
  failed_when: false
  loop:
    - macbookair
    - macmini
    - desktop
    - miniserver

- name: Add host keys to known_hosts
  ansible.builtin.shell: ssh-keyscan -H {{ item.item }}.home.lan >> ~/.ssh/known_hosts 2>/dev/null
  loop: "{{ host_check.results }}"
  when: item.rc != 0  # ssh-keygen -F returns 0 if found, non-zero if not found
  ignore_errors: true
```

### Pattern 2: SSH known_hosts with ansible.builtin.known_hosts Module

**What:** Use Ansible's built-in module for declarative known_hosts management
**When to use:** When you want module-based idempotency with proper state management
**Example:**
```yaml
# Solution: Use known_hosts module with pipe lookup for ssh-keyscan
- name: Add host keys to known_hosts
  ansible.builtin.known_hosts:
    name: "{{ item }}.home.lan"
    key: "{{ lookup('pipe', 'ssh-keyscan -q -H ' + item + '.home.lan 2>/dev/null') }}"
    path: ~/.ssh/known_hosts
    state: present
  loop:
    - macbookair
    - macmini
    - desktop
    - miniserver
  ignore_errors: true
```

**Note:** The `-q` flag (OpenSSH 9.8p1+) suppresses comment lines that break idempotency.

### Pattern 3: Debian Non-Free Repos with deb822_repository

**What:** Add non-free and contrib components using modern deb822 format
**When to use:** Debian Bookworm+ systems requiring non-free packages
**Example:**
```yaml
# Solution: Use deb822_repository to add non-free sources
- name: Add Debian non-free repository (Debian)
  ansible.builtin.deb822_repository:
    name: debian-nonfree
    types: deb
    uris: https://deb.debian.org/debian
    suites: "{{ ansible_distribution_release }}"
    components:
      - contrib
      - non-free
      - non-free-firmware
    state: present
  become: true
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false)
```

### Pattern 4: Debian Non-Free via apt_repository (Alternative)

**What:** Add non-free repos using traditional one-line format
**When to use:** When deb822_repository is not available or for simpler setups
**Example:**
```yaml
# Alternative: Use apt_repository with full repo line
- name: Add Debian non-free repository (Debian)
  ansible.builtin.apt_repository:
    repo: >-
      deb http://deb.debian.org/debian {{ ansible_distribution_release }}
      main contrib non-free non-free-firmware
    state: present
    filename: debian-nonfree
  become: true
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false)
```

### Anti-Patterns to Avoid

- **Marker files for known_hosts:** Does not verify actual content, leads to duplicates
- **Raw sed on /etc/apt/sources.list:** Destructive, can corrupt system configuration
- **ssh-keyscan without -q flag (OpenSSH 9.8p1+):** Comment lines break idempotency
- **Hardcoding release names:** Use `ansible_distribution_release` fact instead

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Check host in known_hosts | Marker files | `ssh-keygen -F` | Actually verifies content |
| Manage known_hosts entries | Raw shell append | `ansible.builtin.known_hosts` | Handles deduplication |
| Add Debian repositories | sed on sources.list | `deb822_repository` | Declarative, safe, reversible |
| Parse repo components | grep/awk patterns | `apt_repository` module | Structured management |

**Key insight:** Both bugs stem from using low-level shell manipulation instead of Ansible's purpose-built modules. The `known_hosts` module manages host key state declaratively, and `deb822_repository` handles repository configuration without destructive file edits.

## Common Pitfalls

### Pitfall 1: ssh-keygen -F Return Codes
**What goes wrong:** Assuming ssh-keygen returns boolean-like values
**Why it happens:** Misunderstanding exit codes
**How to avoid:** `ssh-keygen -F` returns 0 if host found, non-zero (typically 1) if not found
**Warning signs:** Conditional logic inverted, hosts always/never added

### Pitfall 2: ssh-keyscan Comment Lines (OpenSSH 9.8p1+)
**What goes wrong:** `known_hosts` module shows "changed" every run
**Why it happens:** OpenSSH 9.8p1+ emits comment lines to stdout that differ each run
**How to avoid:** Use `ssh-keyscan -q` flag to suppress comments
**Warning signs:** Task always shows "changed" status

### Pitfall 3: Hashed vs Non-Hashed Hostnames
**What goes wrong:** `ssh-keygen -F` cannot find hashed entry with plain hostname
**Why it happens:** HashKnownHosts is enabled (Debian default since Debian 9)
**How to avoid:** Use `ssh-keyscan -H` to add hashed AND use `ssh-keygen -H -F` to search
**Warning signs:** Duplicate entries with different hash formats

### Pitfall 4: Debian non-free-firmware Component
**What goes wrong:** Missing firmware packages on Debian Bookworm+
**Why it happens:** non-free-firmware split from non-free in Bookworm
**How to avoid:** Include both `non-free` and `non-free-firmware` components
**Warning signs:** nvidia-driver installs but firmware-misc-nonfree fails

### Pitfall 5: apt_repository Duplicates
**What goes wrong:** Multiple similar repository entries created
**Why it happens:** apt_repository matches exact string, slight differences create new entries
**How to avoid:** Use `filename` parameter to control output file, use consistent formatting
**Warning signs:** Multiple .list files in /etc/apt/sources.list.d/ for same repo

## Code Examples

### Current State Analysis

**File 1: tools/ssh/install_ssh.yml (lines 55-75) - BUG-01**
```yaml
# Current (buggy - marker file doesn't verify content)
- name: Add host keys to known_hosts
  ansible.builtin.shell: ssh-keyscan -H {{ item }}.home.lan >> ~/.ssh/known_hosts 2>/dev/null
  args:
    creates: ~/.ssh/.known_hosts_{{ item }}
  loop:
    - macbookair
    - macmini
    - desktop
    - miniserver
  ignore_errors: true

- name: Mark known_hosts as populated
  ansible.builtin.file:
    path: ~/.ssh/.known_hosts_{{ item }}
    state: touch
    mode: '0600'
  loop:
    - macbookair
    - macmini
    - desktop
    - miniserver
```

**Problem:** If marker file is deleted but host is still in known_hosts, duplicates are added.

**Recommended Fix (Pattern 1 - ssh-keygen -F conditional):**
```yaml
# Fixed: Use ssh-keygen -F to verify host presence
- name: Check if hosts already in known_hosts
  ansible.builtin.shell: ssh-keygen -F {{ item }}.home.lan
  register: known_hosts_check
  changed_when: false
  failed_when: false
  loop:
    - macbookair
    - macmini
    - desktop
    - miniserver

- name: Add missing host keys to known_hosts
  ansible.builtin.shell: ssh-keyscan -H {{ item.item }}.home.lan >> ~/.ssh/known_hosts 2>/dev/null
  loop: "{{ known_hosts_check.results }}"
  loop_control:
    label: "{{ item.item }}"
  when: item.rc != 0
  ignore_errors: true
```

**Note:** This removes the marker file pattern entirely. The ssh-keygen -F check IS the idempotency mechanism.

---

**File 2: tools/gpu/install_gpu.yml (lines 104-122) - BUG-02**
```yaml
# Current (buggy - fragile sed pattern)
- name: Check if non-free repos enabled (Debian)
  ansible.builtin.shell: grep -E 'non-free|contrib' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true
  register: nonfree_check
  changed_when: false
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false)

- name: Enable non-free and contrib repos (Debian)
  ansible.builtin.shell: |
    sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
  become: true
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false) and 'non-free' not in nonfree_check.stdout
  changed_when: true
```

**Problems:**
1. sed assumes sources.list has "main" at end of line
2. Running twice could corrupt sources.list
3. Doesn't work with deb822 format (modern Debian)
4. grep check is fragile

**Recommended Fix (deb822_repository module):**
```yaml
# Fixed: Use deb822_repository for declarative repo management
- name: Add Debian non-free repository for NVIDIA (Debian)
  ansible.builtin.deb822_repository:
    name: debian-nonfree
    types: deb
    uris: https://deb.debian.org/debian
    suites: "{{ ansible_distribution_release }}"
    components:
      - contrib
      - non-free
      - non-free-firmware
    state: present
  become: true
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false)

- name: Update apt cache after adding non-free repo (Debian)
  ansible.builtin.apt:
    update_cache: true
  become: true
  when: ansible_facts['os_family'] == "Debian" and has_nvidia | default(false)
```

**Note:** The deb822_repository module creates `/etc/apt/sources.list.d/debian-nonfree.sources` in modern deb822 format. This is additive and safe - it does not modify the existing sources.list.

### Files Already Using Correct Patterns

- `tools/docker/install_docker.yml` - Uses `apt_repository` module correctly for Docker repo

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Marker files for known_hosts | `ssh-keygen -F` check or `known_hosts` module | Ansible 2.11 | True idempotency |
| sed on sources.list | `deb822_repository` module | Ansible 2.15 / Debian Bookworm | Safer, declarative |
| One-line apt sources | deb822 format | Debian 12 (Bookworm) | Modern standard |

**Deprecated/outdated:**
- Modifying `/etc/apt/sources.list` directly - systems may use deb822 exclusively
- `HashKnownHosts no` assumption - Debian defaults to hashed since Debian 9

## Decision Points for Planning

### BUG-01: Which pattern to use?

**Option A: ssh-keygen -F conditional (recommended)**
- Pros: Simpler, no external lookups, works with existing ssh-keyscan
- Cons: Two tasks instead of one

**Option B: ansible.builtin.known_hosts module**
- Pros: More Ansible-native, single task
- Cons: Requires pipe lookup, ssh-keyscan runs every time (but module handles deduplication)

**Recommendation:** Option A (ssh-keygen -F) - aligns with prior decision "Guard on first binary pattern" and is simpler to understand.

### BUG-02: apt_repository vs deb822_repository?

**Option A: deb822_repository (recommended)**
- Pros: Modern format, creates separate file, declarative
- Cons: Requires Ansible 2.15+

**Option B: apt_repository with filename**
- Pros: Works on older Ansible
- Cons: Creates .list file (legacy format)

**Recommendation:** Option A (deb822_repository) - Debian Bookworm is current, and this is the modern standard.

## Open Questions

1. **Should marker files be cleaned up?** The fix removes the need for `.known_hosts_*` marker files. Consider adding a cleanup task to remove existing marker files.

2. **What about hosts that don't exist?** Both current and fixed patterns use `ignore_errors: true`. This is appropriate since not all hosts may be reachable.

## Sources

### Primary (HIGH confidence)
- [Ansible known_hosts module documentation](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/known_hosts_module.html) - Official module reference
- [Ansible deb822_repository module documentation](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/deb822_repository_module.html) - Modern repo format
- [Ansible apt_repository module documentation](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_repository_module.html) - Legacy repo format
- [Jeff Geerling: Idempotently adding SSH key to known_hosts](https://www.jeffgeerling.com/blog/2018/idempotently-adding-ssh-key-host-knownhosts-file-bash) - ssh-keygen -F pattern

### Secondary (MEDIUM confidence)
- [Ansible GitHub Issue #83514](https://github.com/ansible/ansible/issues/83514) - OpenSSH 9.8p1 idempotency issue with -q flag
- [Debian Bookworm non-free split](https://joshtronic.com/2023/04/30/repository-debian-bookworm-changed-its-non-free-component-value/) - non-free-firmware explanation

### Tertiary (LOW confidence)
- [GitHub Gist: ssh-keyscan playbook](https://gist.github.com/shirou/6928012) - Community patterns (but note anti-patterns in comments)

## Metadata

**Confidence breakdown:**
- BUG-01 (known_hosts): HIGH - ssh-keygen -F is well-documented SSH standard
- BUG-02 (apt repos): HIGH - deb822_repository is official Ansible module

**Research date:** 2026-01-22
**Valid until:** 2026-03-22 (patterns are stable, 60-day validity)
