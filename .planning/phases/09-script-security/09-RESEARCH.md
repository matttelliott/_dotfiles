# Phase 9: Script Security - Research

**Researched:** 2026-01-23
**Domain:** Curl-to-shell script security, checksum verification, GPG key management
**Confidence:** HIGH

## Summary

This phase hardens the security of installation scripts by pinning to specific versions instead of HEAD/master branches, adding checksum verification where publishers provide checksums, and documenting GPG key fingerprints for APT repositories.

The codebase currently has 7 curl-piped shell installers, 9 APT repository configurations with GPG keys, and 7 direct binary downloads. Most are already partially secured (HTTPS, creates: guards), but none use checksum verification and only one (nvm) is pinned to a specific version.

**Primary recommendation:** Pin all curl-piped scripts to specific commit SHAs or version tags, add checksum verification for direct binary downloads (sops, k9s, lazydocker, doctl provide checksums), and add GPG fingerprint comments to all APT repository tasks.

## Current State Analysis

### Category 1: Curl-Piped Shell Scripts (SEC-01)

Scripts that pipe remote content directly to bash/sh.

| Tool | Current URL | Pinned? | Version Support | Action |
|------|-------------|---------|-----------------|--------|
| nvm | `https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh` | YES | Supports version tags | Update to v0.40.3 |
| Homebrew | `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh` | NO | Supports commit SHA | Pin to commit |
| rustup | `https://sh.rustup.rs` | NO | No versioning | Cannot pin (see notes) |
| Starship | `https://starship.rs/install.sh` | NO | No versioning | Cannot pin (see notes) |
| Pulumi | `https://get.pulumi.com` | NO | Supports `--version` flag | Pin via flag |
| uv (Python) | `https://astral.sh/uv/install.sh` | NO | Supports version in URL | Pin to version |
| Claude Code | `https://claude.ai/install.sh` | NO | Supports version param | Pin to stable |

**Tools that CANNOT be pinned:**
- **rustup**: The rustup.rs script is canonical and intentionally unversioned. Rust recommends trusting HTTPS + the rustup binary itself. Standalone installers with GPG signatures exist but are more complex.
- **Starship**: No versioned installer exists. Alternative: install via cargo or download binary with checksum.

### Category 2: Direct Binary Downloads (SEC-02)

Downloads that fetch binaries directly from GitHub releases.

| Tool | Current Pattern | Checksum Available? | Action |
|------|-----------------|---------------------|--------|
| Neovim | `/releases/download/stable/nvim-linux-x86_64.tar.gz` | YES (SHA256) | Add verification |
| sops | `/releases/latest/download/sops-v3.9.4.linux.amd64` | YES (SHA256, Cosign) | Add verification, update version |
| k9s | `/releases/latest/download/k9s_Linux_amd64.tar.gz` | YES (SHA256) | Add verification |
| doctl | `/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz` | YES (SHA256) | Add verification |
| lazydocker | `/releases/latest/download/lazydocker_0.24.1_Linux_x86_64.tar.gz` | YES (SHA256) | Add verification, update version |
| procs | `/releases/latest/download/procs-v0.14.8-x86_64-linux.zip` | YES (SHA256) | Add verification |
| awscli | Direct from AWS | AWS provides SHA256 | Add verification |
| Nerd Fonts | `/releases/latest/download/*.tar.xz` | YES (SHA256) | Add verification |

### Category 3: APT Repositories with GPG Keys (SEC-03)

All APT repository configurations should document the expected GPG key fingerprint.

| Tool | Key URL | Fingerprint | Status |
|------|---------|-------------|--------|
| 1Password | `downloads.1password.com/linux/keys/1password.asc` | `3FEF9748469ADBE15DA7CA80AC2D62742012EA22` | Document |
| Docker | `download.docker.com/linux/debian/gpg` | `9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88` | Document |
| GitHub CLI | `cli.github.com/packages/githubcli-archive-keyring.gpg` | `2C6106201985B60E6C7AC87323F3D4EA75716059` | Document |
| WezTerm | `apt.fury.io/wez/gpg.key` | `D7BA31CF90C4B319` (short ID) | Document |
| Microsoft Edge | `packages.microsoft.com/keys/microsoft.asc` | `BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF` | Document |
| Google Cloud | `packages.cloud.google.com/apt/doc/apt-key.gpg` | `3746 C208 A731 7B0F` (short ID) | Document |
| Vivaldi | `repo.vivaldi.com/archive/linux_signing_key.pub` | `CB63 144F 1BA3 1BC3 9E27 79A8 FEB6 023D C27A A466` | Document |
| Opera | `deb.opera.com/archive.key` | `6C86BE214648376680CA957B11EE8C00B693A745` | Document |

## Standard Patterns

### Pattern 1: Pinned Curl-Pipe Script

**Current (insecure):**
```yaml
- name: Install Homebrew
  ansible.builtin.shell: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Secure (pinned to commit):**
```yaml
- name: Install Homebrew
  # Homebrew installer pinned to commit <SHA> from <date>
  # Verify at: https://github.com/Homebrew/install/commits/master
  ansible.builtin.shell: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/<commit-sha>/install.sh)"
```

### Pattern 2: Binary Download with Checksum Verification

**Current (no verification):**
```yaml
- name: Download and install k9s (Debian)
  ansible.builtin.shell: |
    curl -Lo /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz"
    tar xf /tmp/k9s.tar.gz -C /tmp k9s
    install /tmp/k9s /usr/local/bin
```

**Secure (with checksum):**
```yaml
vars:
  k9s_version: "0.50.18"
  k9s_checksum: "sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

- name: Download k9s binary (Debian)
  ansible.builtin.get_url:
    url: "https://github.com/derailed/k9s/releases/download/v{{ k9s_version }}/k9s_Linux_amd64.tar.gz"
    dest: /tmp/k9s.tar.gz
    checksum: "{{ k9s_checksum }}"
  when: ansible_facts['os_family'] == "Debian"

- name: Extract and install k9s (Debian)
  ansible.builtin.shell: |
    tar xf /tmp/k9s.tar.gz -C /tmp k9s
    install /tmp/k9s /usr/local/bin
    rm -f /tmp/k9s /tmp/k9s.tar.gz
  become: true
  when: ansible_facts['os_family'] == "Debian"
```

### Pattern 3: GPG Key with Fingerprint Comment

**Current (no fingerprint documented):**
```yaml
- name: Add Docker GPG key (Debian)
  ansible.builtin.shell: curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

**Secure (fingerprint documented):**
```yaml
- name: Add Docker GPG key (Debian)
  # GPG Key Fingerprint: 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88
  # Verify at: https://docs.docker.com/engine/install/ubuntu/
  ansible.builtin.shell: curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Checksum verification | Shell script with curl + sha256sum | `ansible.builtin.get_url` with `checksum:` | Built-in, tested, handles errors |
| GPG key download | Piping curl to gpg | `ansible.builtin.get_url` + `gpg --dearmor` | Atomic download, can verify |
| Version pinning | Hardcoded URLs | Ansible vars + templates | Centralized, easier to update |

## Common Pitfalls

### Pitfall 1: Using `/latest/` in URLs
**What goes wrong:** The "latest" redirect can change at any time, breaking idempotency and potentially installing untested versions.
**How to avoid:** Always pin to specific version tags (e.g., `/download/v1.2.3/` instead of `/latest/download/`).

### Pitfall 2: Trusting HTTPS Alone
**What goes wrong:** HTTPS protects transport but not content integrity. A compromised server can serve malicious content over valid HTTPS.
**How to avoid:** Verify checksums for all binary downloads. GPG signatures are better but less commonly available.

### Pitfall 3: Expired GPG Keys
**What goes wrong:** GPG keys expire and break apt update. GitHub CLI key expires September 2026, 1Password key was extended to 2032.
**How to avoid:** Document key fingerprints and expiration dates. Monitor for key rotation announcements.

### Pitfall 4: Checksum File vs Inline Checksum
**What goes wrong:** Downloading checksum file from same server as binary defeats the purpose if server is compromised.
**How to avoid:** Pin checksum values in playbook vars (not downloaded at runtime) or use separate trusted source.

## Verification Methods by Tool

### Tools with Official Checksums

| Tool | Checksum File Pattern | Verification Command |
|------|----------------------|---------------------|
| sops | `sops-vX.Y.Z.checksums.txt` | `sha256sum -c checksums.txt --ignore-missing` |
| k9s | `checksums.sha256` | `sha256sum -c checksums.sha256 --ignore-missing` |
| lazydocker | `checksums.txt` | `sha256sum -c checksums.txt --ignore-missing` |
| doctl | `checksums.txt` | `sha256sum -c checksums.txt --ignore-missing` |
| uv | `.sha256` files per binary | Individual file verification |
| Starship | `.sha256` files per binary | Individual file verification |
| Neovim | `nvim-linux-x86_64.tar.gz.sha256sum` | Individual file verification |

### Tools Without Official Checksums

| Tool | Alternative Verification |
|------|------------------------|
| rustup | None (trust HTTPS + official domain) |
| Homebrew | Pin to Git commit SHA (content-addressable) |
| Claude Code | Built-in SHA256 verification in installer |

## Implementation Priority

Based on risk and effort:

### High Priority (Do First)
1. **Pin Homebrew installer** - Most foundational, runs on every macOS setup
2. **Add checksum to sops** - Handles secrets, high-value target
3. **Document GPG fingerprints** - Low effort, prevents surprise key failures

### Medium Priority
4. **Pin Pulumi/uv installers** - Easy with version flags
5. **Add checksums to k9s, doctl, lazydocker** - Direct binary downloads
6. **Update nvm to v0.40.3** - Already pinned, just update version

### Lower Priority (Diminishing Returns)
7. **Neovim checksum** - Complex multi-file extraction
8. **Nerd Fonts checksum** - Multiple fonts, frequently updated
9. **AWS CLI checksum** - AWS provides but complex install process

## Version Discovery

For future updates, here's how to find current versions:

| Tool | Version Discovery Command/URL |
|------|------------------------------|
| nvm | `curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \| jq -r .tag_name` |
| Homebrew | Pin to commit, not version. Check `https://github.com/Homebrew/install/commits/master` |
| sops | `curl -s https://api.github.com/repos/getsops/sops/releases/latest \| jq -r .tag_name` |
| k9s | `curl -s https://api.github.com/repos/derailed/k9s/releases/latest \| jq -r .tag_name` |
| doctl | `curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest \| jq -r .tag_name` |
| uv | `curl -s https://api.github.com/repos/astral-sh/uv/releases/latest \| jq -r .tag_name` |
| Pulumi | `curl -s https://api.github.com/repos/pulumi/pulumi/releases/latest \| jq -r .tag_name` |

## Files Requiring Changes

### Curl-Piped Scripts (SEC-01)
- `bootstrap.sh` - Homebrew installer (line 159)
- `tools/homebrew/install_homebrew.yml` - Homebrew installer (line 21)
- `tools/rust/install_rust.yml` - Cannot pin, add comment
- `tools/starship/install_starship.yml` - Cannot pin, add comment
- `tools/pulumi/install_pulumi.yml` - Add `--version` flag
- `tools/python/install_python.yml` - Pin uv version in URL
- `tools/claude-code/install_claude-code.yml` - Consider pinning

### Binary Downloads (SEC-02)
- `tools/neovim/install_neovim.yml` - Add checksum
- `tools/sops/install_sops.yml` - Add checksum, update version
- `tools/k9s/install_k9s.yml` - Add checksum
- `tools/doctl/install_doctl.yml` - Add checksum
- `tools/lazydocker/install_lazydocker.yml` - Add checksum
- `tools/procs/install_procs.yml` - Add checksum
- `tools/awscli/install_awscli.yml` - Add checksum

### GPG Key Documentation (SEC-03)
- `tools/1password/install_1password.yml` - Add fingerprint comment
- `tools/1password_cli/install_1password_cli.yml` - Add fingerprint comment
- `tools/docker/install_docker.yml` - Add fingerprint comment
- `tools/gh/install_gh.yml` - Add fingerprint comment
- `tools/wezterm/install_wezterm.yml` - Add fingerprint comment
- `tools/edge/install_edge.yml` - Add fingerprint comment
- `tools/gcloud/install_gcloud.yml` - Add fingerprint comment
- `tools/vivaldi/install_vivaldi.yml` - Add fingerprint comment
- `tools/opera/install_opera.yml` - Add fingerprint comment

## Open Questions

1. **Homebrew commit pinning frequency** - How often to update the pinned commit? Monthly? On breaking changes?
   - Recommendation: Update quarterly or when security advisories are published

2. **rustup/Starship alternatives** - Worth switching to cargo install or direct binaries?
   - Recommendation: Keep curl-pipe for simplicity, add disclaimer comment

3. **Checksum storage** - Store in vars file or inline per task?
   - Recommendation: Inline per task for visibility, with comment linking to source

## Sources

### Primary (HIGH confidence)
- [nvm releases](https://github.com/nvm-sh/nvm/releases) - GPG signed releases
- [sops releases](https://github.com/getsops/sops/releases) - Cosign + SHA256
- [k9s releases](https://github.com/derailed/k9s/releases) - SHA256 checksums
- [uv releases](https://github.com/astral-sh/uv/releases) - SHA256 + GitHub attestations
- [Docker install docs](https://docs.docker.com/engine/install/ubuntu/) - GPG fingerprint
- [1Password Linux install](https://support.1password.com/install-linux/) - GPG fingerprint
- [GitHub CLI changelog](https://github.blog/changelog/2024-09-11-github-cli-renews-gpg-signing-key-for-linux-packages/) - Key rotation

### Secondary (MEDIUM confidence)
- [Homebrew install repo](https://github.com/Homebrew/install) - No releases, pin commits
- [Rustup docs](https://forge.rust-lang.org/infra/other-installation-methods.html) - Standalone installer signatures
- [Starship releases](https://github.com/starship/starship/releases) - SHA256 checksums

### Security Best Practices
- [Operous: Trustworthy curl pipe bash](https://operous.dev/blog/how-to-build-a-trustworthy-curl-pipe-bash-workflow/)
- [Chef: 5 ways to deal with curl pipe bash](https://www.chef.io/blog/5-ways-to-deal-with-the-install-sh-curl-pipe-bash-problem)
- [Sysdig: Friends don't let friends curl bash](https://www.sysdig.com/blog/friends-dont-let-friends-curl-bash)

## Metadata

**Confidence breakdown:**
- Curl-pipe scripts: HIGH - Official docs clearly document version support
- Binary checksums: HIGH - GitHub releases clearly show checksum files
- GPG fingerprints: MEDIUM - Some fingerprints from web search, should verify against official docs

**Research date:** 2026-01-23
**Valid until:** 60 days (GPG keys rotate, versions update)

---

*Research completed: 2026-01-23*
*Phase: 09-script-security*
*Requirements: SEC-01, SEC-02, SEC-03*
