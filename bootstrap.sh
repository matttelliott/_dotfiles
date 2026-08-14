#!/bin/bash
set -e

DOTFILES_DIR="$HOME/_dotfiles"

echo "=== Dotfiles Bootstrap ==="
echo

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
	OS="darwin"
	echo "Detected: macOS"
elif [[ -f /etc/arch-release ]]; then
	OS="arch"
	echo "Detected: Arch Linux"
elif [[ -f /etc/debian_version ]]; then
	OS="debian"
	echo "Detected: Debian/Ubuntu"
else
	echo "Unsupported OS"
	exit 1
fi

echo

if [[ "$OS" == "darwin" ]]; then
	if [ ! -f /Library/Developer/CommandLineTools/usr/bin/git ]; then
		echo "Installing Xcode Command Line Tools..."
		touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
		softwareupdate -l | grep -o 'Command Line Tools.*' | head -1 | xargs -I {} softwareupdate -i "{}"
		rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
	fi

	if [ ! -f /opt/homebrew/bin/brew ]; then
		echo "Installing Homebrew..."
		# Homebrew installer pinned to commit 90fa3d5881cedc0d60c4a3cc5babdb867ef42e5a (2026-01-23)
		# Verify/update at: https://github.com/Homebrew/install/commits/master
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/90fa3d5881cedc0d60c4a3cc5babdb867ef42e5a/install.sh)"
	fi

	# Shared multi-user Homebrew: any admin account must be able to install/update.
	# Homebrew uses a single prefix (/opt/homebrew) and macOS's default umask strips
	# group-write, so only the account that first installed it can write. Grant the
	# admin group an inherited ACL (file_inherit,directory_inherit) so every admin
	# account can write to the shared prefix, including files created later.
	if [ -d /opt/homebrew ] && [ ! -w /opt/homebrew ]; then
		echo "Granting admin group write access to shared Homebrew..."
		# Recursion fails on launched .app bundles in the Caskroom (macOS protects
		# them) — those don't need the ACL, so tolerate per-file errors.
		sudo chmod -R +a "group:admin allow list,search,add_file,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" /opt/homebrew 2>/dev/null || true
	fi

	if [ ! -f /opt/homebrew/bin/ansible ]; then
		echo "Installing Ansible..."
		/opt/homebrew/bin/brew install ansible
	fi
fi

if [[ "$OS" == "debian" ]]; then
	echo "Installing dependencies..."
	sudo apt update
	sudo apt install -y git ansible
fi

if [[ "$OS" == "arch" ]]; then
	echo "Installing dependencies..."
	sudo pacman -Sy --noconfirm git ansible
fi

# Install SOPS ansible collection (needed for ansible.cfg plugin)
echo "Installing Ansible SOPS collection..."
ansible-galaxy collection install community.sops

echo "Cloning dotfiles..."
rm -rf $DOTFILES_DIR
git clone https://github.com/matttelliott/_dotfiles.git "$DOTFILES_DIR"

cd "$DOTFILES_DIR"

# Get hostname
CURRENT_HOSTNAME=$(hostname -s)
read -p "Hostname [$CURRENT_HOSTNAME]: " INPUT_HOSTNAME
HOSTNAME=${INPUT_HOSTNAME:-$CURRENT_HOSTNAME}

echo
echo "Generating inventory for $HOSTNAME..."

cat >localhost.yml <<EOF
---
all:
  children:
    macs:
      hosts:
EOF

if [[ "$OS" == "darwin" ]]; then
	cat >>localhost.yml <<EOF
        $HOSTNAME:
          ansible_connection: local
          ansible_python_interpreter: /opt/homebrew/bin/python3
          dotfiles_user_role: $ROLE
EOF
fi

cat >>localhost.yml <<EOF

    debian:
      hosts:
EOF

if [[ "$OS" == "debian" ]]; then
	cat >>localhost.yml <<EOF
        $HOSTNAME:
          ansible_connection: local
          dotfiles_user_role: $ROLE
EOF
fi

cat >>localhost.yml <<EOF

    arch:
      hosts:
EOF

if [[ "$OS" == "arch" ]]; then
	cat >>localhost.yml <<EOF
        $HOSTNAME:
          ansible_connection: local
          dotfiles_user_role: $ROLE
EOF
fi

if [[ "$GUI" =~ ^[Yy]$ ]]; then
	cat >>localhost.yml <<EOF

    with_gui_tools:
      hosts:
        $HOSTNAME:
EOF
fi

if [[ "$BROWSERS" =~ ^[Yy]$ ]]; then
	cat >>localhost.yml <<EOF

    with_browsers:
      hosts:
        $HOSTNAME:
EOF
fi

if [[ "$AI" =~ ^[Yy]$ ]]; then
	cat >>localhost.yml <<EOF

    with_ai_tools:
      hosts:
        $HOSTNAME:
EOF
fi

echo
echo "Generated localhost.yml:"
cat localhost.yml
echo

# Run playbook.
#
# Standard users skip every task tagged `system` — package installs, service
# management, account and sudoers changes — so they never need become at all.
PLAYBOOK_ARGS=()

PLAYBOOK_ARGS+=(--ask-become-pass)

echo "Running Ansible playbook..."
if [[ "$OS" == "darwin" ]]; then
	/opt/homebrew/bin/ansible-playbook -i localhost.yml setup.yml "${PLAYBOOK_ARGS[@]}"
else
	ansible-playbook -i localhost.yml setup.yml "${PLAYBOOK_ARGS[@]}"
fi

echo
echo "=== Bootstrap complete! ==="
