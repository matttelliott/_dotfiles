#!/usr/bin/env bash
# Bootstrap script for dotfiles installation
# Detects OS, installs Ansible, and runs the playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    exit 1
}

# Check if script is run with sudo
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root or with sudo"
        error_exit "Run as a normal user. The script will prompt for sudo when needed."
    fi
}

# Detect operating system
detect_os() {
    log_info "Detecting operating system..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
    elif [ "$(uname)" == "Darwin" ]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    else
        error_exit "Unable to detect operating system"
    fi

    OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')
    log_success "Detected OS: $OS $OS_VERSION"
}

# Install Ansible based on OS
install_ansible() {
    log_info "Checking if Ansible is installed..."

    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1 | awk '{print $2}')
        log_success "Ansible $ANSIBLE_VERSION is already installed"
        return 0
    fi

    log_warning "Ansible not found. Installing..."

    case "$OS" in
        ubuntu|debian)
            log_info "Installing Ansible on Debian/Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            sudo apt-add-repository --yes --update ppa:ansible/ansible
            sudo apt-get install -y ansible python3-pip
            ;;

        arch|archlinux|manjaro)
            log_info "Installing Ansible on Arch Linux..."
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm ansible python-pip
            ;;

        fedora|rhel|centos)
            log_info "Installing Ansible on Fedora/RHEL/CentOS..."
            sudo dnf install -y ansible python3-pip
            ;;

        macos)
            log_info "Installing Ansible on macOS..."
            if ! command -v brew &> /dev/null; then
                log_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install ansible
            ;;

        *)
            error_exit "Unsupported operating system: $OS"
            ;;
    esac

    if command -v ansible &> /dev/null; then
        log_success "Ansible installed successfully"
    else
        error_exit "Failed to install Ansible"
    fi
}

# Install additional Python dependencies
install_dependencies() {
    log_info "Installing additional dependencies..."

    # Install required Python packages
    if command -v pip3 &> /dev/null; then
        pip3 install --user ansible-core jinja2
        log_success "Python dependencies installed"
    fi
}

# Verify Ansible installation
verify_ansible() {
    log_info "Verifying Ansible installation..."

    if ! command -v ansible-playbook &> /dev/null; then
        error_exit "ansible-playbook command not found"
    fi

    log_success "Ansible verification complete"
}

# Run Ansible playbook
run_playbook() {
    log_info "Running Ansible playbook..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

    cd "$DOTFILES_DIR" || error_exit "Failed to change to dotfiles directory"

    # Check if playbook exists
    if [ ! -f "site.yml" ]; then
        error_exit "Playbook site.yml not found in $DOTFILES_DIR"
    fi

    # Run with sudo and ask for password
    log_info "Running playbook (you may be prompted for sudo password)..."

    if [ -n "$ANSIBLE_TAGS" ]; then
        log_info "Running with tags: $ANSIBLE_TAGS"
        ansible-playbook site.yml --ask-become-pass --tags "$ANSIBLE_TAGS" "$@"
    else
        ansible-playbook site.yml --ask-become-pass "$@"
    fi

    if [ $? -eq 0 ]; then
        log_success "Playbook execution completed successfully"
    else
        error_exit "Playbook execution failed"
    fi
}

# Post-installation tasks
post_install() {
    log_info "Performing post-installation tasks..."

    # Verify installations
    if command -v zsh &> /dev/null; then
        log_success "Zsh installed: $(zsh --version)"
    fi

    if command -v tmux &> /dev/null; then
        log_success "Tmux installed: $(tmux -V)"
    fi

    if command -v nvim &> /dev/null; then
        log_success "Neovim installed: $(nvim --version | head -n1)"
    fi

    echo ""
    log_success "=== Installation Complete! ==="
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: exec \$SHELL"
    echo "  2. If zsh is your new shell, log out and back in"
    echo "  3. Run 'tmux' to start tmux with new configuration"
    echo "  4. Run 'nvim' to start Neovim (plugins will auto-install)"
    echo ""
    echo "Optional:"
    echo "  - Customize ~/.zshrc.local for local zsh settings"
    echo "  - Customize ~/.tmux.conf.local for local tmux settings"
    echo "  - Customize ~/.config/nvim/init.local.lua for local nvim settings"
    echo ""
}

# Display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Bootstrap script for dotfiles installation with Ansible

OPTIONS:
    -h, --help          Show this help message
    -t, --tags TAGS     Run only specified Ansible tags (e.g., "zsh,tmux")
    -v, --verbose       Enable verbose output
    --check             Run Ansible in check mode (dry-run)
    --skip-deps         Skip dependency installation

EXAMPLES:
    $0                      # Full installation
    $0 -t zsh,tmux          # Install only zsh and tmux
    $0 --check              # Dry-run to see what would change
    $0 -v                   # Verbose output

EOF
}

# Parse command line arguments
ANSIBLE_EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--tags)
            ANSIBLE_TAGS="$2"
            shift 2
            ;;
        -v|--verbose)
            ANSIBLE_EXTRA_ARGS="$ANSIBLE_EXTRA_ARGS -v"
            shift
            ;;
        --check)
            ANSIBLE_EXTRA_ARGS="$ANSIBLE_EXTRA_ARGS --check"
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=1
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo ""
    log_info "=== Dotfiles Installation Script ==="
    echo ""

    check_sudo
    detect_os

    if [ -z "$SKIP_DEPS" ]; then
        install_ansible
        install_dependencies
    fi

    verify_ansible
    run_playbook $ANSIBLE_EXTRA_ARGS
    post_install
}

# Run main function
main
