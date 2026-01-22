# Phase 5: Architecture Portability - Research

**Researched:** 2026-01-21
**Domain:** Ansible multi-architecture support (x86_64/AMD64, ARM64/aarch64)
**Confidence:** HIGH

## Summary

Research focused on making Ansible playbooks architecture-portable for ARM64 Debian systems (Raspberry Pi) while maintaining x86_64 support. The core challenge is mapping between Ansible's architecture fact naming (`x86_64`, `aarch64`) and package ecosystem naming conventions (Debian/Ubuntu use `amd64`, `arm64`; Go uses `amd64`, `arm64`).

The standard approach is creating architecture mapping dictionaries that normalize `ansible_facts.architecture` values to ecosystem-specific names, then using these mapped values in repository URLs, download URLs, and package names.

Critical limitation discovered: 1Password and Microsoft Edge do not provide ARM64 APT repositories. Tasks must conditionally skip on ARM64 or use alternative installation methods.

**Primary recommendation:** Use architecture mapping dictionaries with conditional task execution for unsupported architectures.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ansible_facts | Built-in | Architecture detection | Core Ansible system facts, universally available |
| ansible.builtin.apt_repository | Built-in | Repository management | Official module for Debian repository configuration |
| Jinja2 conditionals | Built-in | Dynamic value selection | Native templating engine in Ansible |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dpkg --print-architecture | System command | Direct dpkg architecture query | When Ansible facts are unavailable (rare) |
| ansible.builtin.stat | Built-in | Check file existence | Idempotency for conditional installations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dictionary mapping | Inline conditionals | Dictionaries are more maintainable for 3+ architectures |
| ansible_architecture fact | dpkg command | Facts are more portable (work on all OSes, not just Debian) |
| kenmoini.kemo collection | Custom mapping | External dependency vs. simple inline solution |

**Installation:**
No additional packages required - uses Ansible built-ins.

## Architecture Patterns

### Recommended Project Structure
Variables defined at playbook level or in vars/ directory:
```
tools/<tool>/
├── install_<tool>.yml   # Playbook with architecture mapping
└── vars/
    └── main.yml         # Optional: shared architecture vars
```

### Pattern 1: Architecture Mapping Dictionary
**What:** Define mapping from Ansible architecture names to ecosystem-specific names
**When to use:** Any task requiring architecture-specific URLs or package names
**Example:**
```yaml
# Source: https://dev.to/rimelek/using-facts-and-the-github-api-in-ansible-4i00
vars:
  # Map ansible_architecture values to Debian package architecture names
  deb_arch_map:
    x86_64: amd64
    amd64: amd64      # Some systems report amd64 directly
    aarch64: arm64
    arm64: arm64      # Some systems report arm64 directly

  # Map ansible_architecture values to Go download architecture names
  go_arch_map:
    x86_64: amd64
    aarch64: arm64

  # Resolved architecture for current system
  deb_arch: "{{ deb_arch_map[ansible_facts.architecture] }}"
  go_arch: "{{ go_arch_map[ansible_facts.architecture] }}"

tasks:
  - name: Add Docker repository (Debian)
    ansible.builtin.apt_repository:
      repo: "deb [arch={{ deb_arch }} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
      state: present
```

### Pattern 2: Simple Inline Conditional (Two Architectures Only)
**What:** Use inline Jinja2 conditional for simple binary choice
**When to use:** Only supporting x86_64 and ARM64, no other architectures planned
**Example:**
```yaml
# Source: https://github.com/geerlingguy/ansible-role-docker (docker_apt_arch pattern)
vars:
  deb_arch: "{{ 'arm64' if ansible_facts.architecture == 'aarch64' else 'amd64' }}"
```

### Pattern 3: OS-Specific Architecture Mapping
**What:** Different architecture naming per OS (Darwin vs. Linux)
**When to use:** Downloads from sources that use different conventions per OS (like Go)
**Example:**
```yaml
vars:
  go_version: "1.23.4"

  # Map OS + architecture combinations to Go's download naming
  go_os_map:
    Darwin: darwin
    Debian: linux
    Archlinux: linux

  go_arch_map:
    x86_64: amd64
    aarch64: arm64

  go_os: "{{ go_os_map[ansible_facts.os_family] }}"
  go_arch: "{{ go_arch_map[ansible_facts.architecture] }}"

tasks:
  - name: Download Go tarball (Linux)
    ansible.builtin.get_url:
      url: "https://go.dev/dl/go{{ go_version }}.{{ go_os }}-{{ go_arch }}.tar.gz"
      dest: /tmp/go.tar.gz
```

### Pattern 4: Conditional Execution for Unsupported Architectures
**What:** Skip tasks when package not available for current architecture
**When to use:** Third-party repositories that don't support all architectures
**Example:**
```yaml
# Source: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_conditionals.html
tasks:
  - name: Check if 1Password is installed (Debian)
    ansible.builtin.stat:
      path: /usr/bin/1password
    register: onepassword_check
    when: ansible_facts['os_family'] == "Debian"

  - name: Add 1Password apt repository (Debian x86_64 only)
    ansible.builtin.shell: |
      curl -sS https://downloads.1password.com/linux/keys/1password.asc \
        | gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] \
        https://downloads.1password.com/linux/debian/amd64 stable main" \
        | tee /etc/apt/sources.list.d/1password.list > /dev/null
    become: true
    when:
      - ansible_facts['os_family'] == "Debian"
      - ansible_facts.architecture == "x86_64"
      - not onepassword_check.stat.exists

  - name: Install 1Password via apt (Debian x86_64 only)
    ansible.builtin.apt:
      name: 1password
      state: present
      update_cache: true
    become: true
    when:
      - ansible_facts['os_family'] == "Debian"
      - ansible_facts.architecture == "x86_64"

  - name: Warn about unsupported architecture (Debian ARM64)
    ansible.builtin.debug:
      msg: "1Password APT repository not available for ARM64. Manual installation required from https://downloads.1password.com/linux/tar/stable/aarch64/"
    when:
      - ansible_facts['os_family'] == "Debian"
      - ansible_facts.architecture == "aarch64"
```

### Anti-Patterns to Avoid
- **Hardcoded architecture in repository URLs:** Use variables and mapping dictionaries instead
- **Assuming ansible_architecture matches package naming:** Always map to ecosystem-specific names
- **Using dpkg commands in playbooks:** Prefer Ansible facts for portability across OS families
- **Failing on unsupported architectures:** Use conditionals to gracefully skip or warn

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Architecture detection | Custom shell script parsing `uname -m` | `ansible_facts.architecture` | Ansible facts handle edge cases, work across OSes, cached |
| Debian arch conversion | String replacement with sed/awk | Dictionary mapping | Handles multiple architectures, bidirectional, self-documenting |
| Multi-arch repository management | Multiple playbooks per architecture | Conditional execution with `when` | Single source of truth, easier maintenance |
| Detecting if repository exists | Parsing `/etc/apt/sources.list.d/` | `ansible.builtin.stat` on expected files | Idempotent, handles manual changes |

**Key insight:** Architecture portability requires translation layers, not just detection. Ansible provides all primitives needed; avoid shell commands.

## Common Pitfalls

### Pitfall 1: Architecture Naming Confusion
**What goes wrong:** Using `aarch64` in Debian repository URLs when `arm64` is required, or vice versa for Go downloads
**Why it happens:** Different ecosystems use different names for the same architecture
**How to avoid:** Always use mapping dictionaries that explicitly translate from Ansible's naming
**Warning signs:**
- APT errors: "Unable to find expected entry 'main/binary-aarch64/Packages'"
- 404 errors when downloading Go: "go1.23.4.linux-aarch64.tar.gz not found"

### Pitfall 2: Repository Arch Parameter Not Interpolated
**What goes wrong:** Repository line contains literal `{{ deb_arch }}` instead of resolved value
**Why it happens:** Incorrect quoting in apt_repository repo parameter
**How to avoid:** Use double quotes around the entire repo string when including variables
**Warning signs:**
- Repository file contains Jinja2 template syntax
- APT fails to parse sources list

### Pitfall 3: Assuming All Third-Party Repositories Support ARM64
**What goes wrong:** Playbook fails on ARM64 systems when repository doesn't exist
**Why it happens:** Not all vendors provide ARM64 packages (1Password, Edge, many proprietary tools)
**How to avoid:**
1. Research vendor ARM64 support before adding architecture detection
2. Use architecture conditionals to skip unsupported combinations
3. Add debug messages explaining why task was skipped
**Warning signs:**
- APT update fails with "repository does not have a Release file"
- Package not found errors only on ARM64 systems

### Pitfall 4: Mixed OS and Architecture Detection
**What goes wrong:** Go installation uses `darwin-amd64` on ARM64 Macs or `linux-arm64` on x86_64 Linux
**Why it happens:** Not mapping both OS and architecture independently
**How to avoid:** Create separate mappings for OS family and architecture, combine in URL
**Warning signs:**
- Wrong binary downloaded (runs but crashes or won't execute)
- Installation succeeds but tool fails with "exec format error"

### Pitfall 5: Inconsistent Mapping Coverage
**What goes wrong:** Dictionary maps `aarch64` but not `arm64`, playbook fails when fact returns unexpected variant
**Why it happens:** Different systems report same architecture with different names
**How to avoid:** Include both common variants in mapping (x86_64 + amd64, aarch64 + arm64)
**Warning signs:**
- KeyError in Jinja2 template evaluation
- "The task includes an option with an undefined variable"

### Pitfall 6: Repository Architecture Doesn't Match System
**What goes wrong:** Adding arm64 repository on x86_64 system or vice versa
**Why it happens:** Copying repository configuration without architecture detection
**How to avoid:** Always use `{{ deb_arch }}` variable in `[arch=...]` parameter
**Warning signs:**
- Wrong packages installed (e.g., arm64 binaries on x86_64)
- "wrong architecture" errors from dpkg

## Code Examples

Verified patterns from official sources:

### Docker Repository with Dynamic Architecture
```yaml
# Pattern from: https://docs.docker.com/engine/install/debian/
# Architecture mapping from: https://github.com/geerlingguy/ansible-role-docker
vars:
  deb_arch_map:
    x86_64: amd64
    aarch64: arm64
  deb_arch: "{{ deb_arch_map[ansible_facts.architecture] }}"

tasks:
  - name: Add Docker repository (Debian)
    ansible.builtin.apt_repository:
      repo: "deb [arch={{ deb_arch }} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian {{ ansible_distribution_release }} stable"
      state: present
    become: true
    when: ansible_facts['os_family'] == "Debian"
```

### Go Installation with OS and Architecture Detection
```yaml
# URL pattern from: https://go.dev/dl/
# Naming conventions verified: https://go.dev/dl/
vars:
  go_version: "1.23.4"

  go_os_map:
    Darwin: darwin
    Debian: linux
    Archlinux: linux

  go_arch_map:
    x86_64: amd64
    aarch64: arm64

  go_os: "{{ go_os_map[ansible_facts.os_family] }}"
  go_arch: "{{ go_arch_map[ansible_facts.architecture] }}"

  # macOS uses .pkg installer, Linux uses .tar.gz
  go_ext: "{{ '.pkg' if ansible_facts.os_family == 'Darwin' else '.tar.gz' }}"

  go_url: "https://go.dev/dl/go{{ go_version }}.{{ go_os }}-{{ go_arch }}{{ go_ext }}"

tasks:
  - name: Download Go installer
    ansible.builtin.get_url:
      url: "{{ go_url }}"
      dest: "/tmp/go{{ go_ext }}"
    when: not go_binary.stat.exists
```

### Conditional Architecture Support with Debug Message
```yaml
# Pattern from: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_conditionals.html
tasks:
  - name: Add Edge repository (Debian x86_64 only)
    ansible.builtin.shell: |
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] \
        https://packages.microsoft.com/repos/edge stable main" \
        | tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
    become: true
    when:
      - ansible_facts['os_family'] == "Debian"
      - ansible_facts.architecture == "x86_64"
      - not edge_check.stat.exists

  - name: Skip Edge on ARM64
    ansible.builtin.debug:
      msg: "Microsoft Edge is not available for ARM64 Linux. Skipping installation."
    when:
      - ansible_facts['os_family'] == "Debian"
      - ansible_facts.architecture == "aarch64"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `arch=amd64` in repository URLs | Dynamic `arch={{ deb_arch }}` with mapping | ~2020-2021 | Playbooks now work on ARM64 without modification |
| Separate playbooks per architecture | Single playbook with conditionals | ~2019-2020 | Reduced maintenance, single source of truth |
| Shell commands like `dpkg --print-architecture` | Ansible facts `ansible_architecture` | Pre-2018 | More portable, works across all OS families |
| Assuming `ansible_architecture` matches package naming | Explicit mapping dictionaries | ~2021-2022 | Handles ecosystem-specific naming conventions |

**Deprecated/outdated:**
- `geerlingguy.docker_arm`: Separate ARM-specific role, now merged into main `geerlingguy.docker` with architecture detection (merged ~2022)
- Manual architecture detection with `uname -m`: Use `ansible_facts.architecture` instead
- `dpkg --print-architecture` in playbooks: Use fact mapping for portability

## Open Questions

Things that couldn't be fully resolved:

1. **1Password ARM64 repository availability**
   - What we know: No ARM64 APT repository exists as of January 2026; only x86_64 (`amd64`) repository available
   - What's unclear: Whether 1Password plans to add ARM64 repository support
   - Recommendation: Use conditional to skip repository setup on ARM64, add debug message pointing to manual tarball installation

2. **Microsoft Edge ARM64 support**
   - What we know: No ARM64 packages for Linux, repository is x86_64 only; GitHub issue was archived in 2024 without resolution
   - What's unclear: Microsoft's plans for ARM64 Linux support
   - Recommendation: Skip Edge installation on ARM64 systems entirely, no alternative installation method exists

3. **Raspberry Pi OS vs. Debian architecture detection**
   - What we know: Raspberry Pi OS is Debian-based, should work with standard Debian patterns
   - What's unclear: Whether `ansible_facts.architecture` behaves identically on Raspberry Pi OS vs. standard Debian
   - Recommendation: Test on actual Raspberry Pi hardware after implementation; expect `aarch64` for 64-bit Raspberry Pi OS

## Sources

### Primary (HIGH confidence)
- [Ansible apt_repository module documentation](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_repository_module.html) - Repository configuration syntax
- [Ansible facts documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html) - Architecture fact information
- [Ansible conditionals documentation](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_conditionals.html) - When clause patterns
- [Go downloads page](https://go.dev/dl/) - Verified architecture naming conventions (amd64, arm64)
- [Docker Engine Debian installation](https://docs.docker.com/engine/install/debian/) - Official repository configuration
- [1Password Linux installation](https://support.1password.com/install-linux/) - Architecture support and limitations

### Secondary (MEDIUM confidence)
- [Using facts and the GitHub API in Ansible](https://dev.to/rimelek/using-facts-and-the-github-api-in-ansible-4i00) - Architecture mapping dictionary pattern
- [Easy Multi-Architecture Ansible](https://kenmoini.com/post/2023/03/easy-multi-arch-ansible/) - Best practices for multi-arch playbooks
- [geerlingguy/ansible-role-docker](https://github.com/geerlingguy/ansible-role-docker) - `docker_apt_arch` pattern implementation
- [geerlingguy/ansible-role-docker Issue #310](https://github.com/geerlingguy/ansible-role-docker/issues/310) - Architecture hardcoding discussion
- [geerlingguy/ansible-role-docker Issue #182](https://github.com/geerlingguy/ansible-role-docker/issues/182) - System-based architecture detection

### Tertiary (LOW confidence)
- [1Password Community: ARM64 Linux](https://1password.community/discussion/120964/1password-for-linux-but-not-on-armv8) - User reports of ARM64 limitations
- [Microsoft Edge ARM64 Linux Issue](https://github.com/MicrosoftEdge/Status/issues/697) - Feature request (archived, no resolution)
- [Go GOOS and GOARCH reference](https://gist.github.com/asukakenji/f15ba7e588ac42795f421b48b8aede63) - Architecture naming patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All patterns use Ansible built-ins, verified in official documentation
- Architecture: HIGH - Patterns verified across multiple authoritative sources (Ansible docs, vendor documentation)
- Pitfalls: HIGH - Based on real GitHub issues and official documentation warnings
- 1Password ARM64: MEDIUM - Verified current limitation, but no official statement on future plans
- Edge ARM64: MEDIUM - GitHub issue archived, no official ARM64 builds found, but could change

**Research date:** 2026-01-21
**Valid until:** 2026-02-21 (30 days for stable ecosystem)
