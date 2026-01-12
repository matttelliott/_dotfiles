#!/bin/bash
set -e

DOTFILES_DIR="$HOME/_dotfiles"

echo "=== Dotfiles Bootstrap ==="
echo

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="darwin"
  echo "Detected: macOS"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
  echo "Detected: Debian/Ubuntu"
else
  echo "Unsupported OS"
  exit 1
fi

echo

# Group selection
echo "Select groups to enable (y/n):"
echo

read -p "with_login_tools (git signing, ssh keys, cloud CLIs)? [y/n]: " LOGIN
read -p "with_gui_tools (WezTerm, 1Password, DBeaver)? [y/n]: " GUI
read -p "with_browsers (Chrome, Firefox, etc)? [y/n]: " BROWSERS
read -p "with_ai_tools (Claude Code)? [y/n]: " AI

echo

# Install dependencies
if [[ "$OS" == "darwin" ]]; then
  if [ ! -f /Library/Developer/CommandLineTools/usr/bin/git ]; then
    echo "Installing Xcode Command Line Tools..."
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    softwareupdate -l | grep -o 'Command Line Tools.*' | head -1 | xargs -I {} softwareupdate -i "{}"
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  fi

  if [ ! -f /opt/homebrew/bin/brew ]; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# Clone dotfiles if not present
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles..."
  git clone https://github.com/matttelliott/dotphiles.git "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Generate inventory
HOSTNAME=$(hostname -s)
echo "Generating inventory for $HOSTNAME..."

cat > localhost.yml << EOF
---
all:
  children:
    macs:
      hosts:
EOF

if [[ "$OS" == "darwin" ]]; then
  cat >> localhost.yml << EOF
        localhost:
          ansible_connection: local
          ansible_python_interpreter: /opt/homebrew/bin/python3
EOF
fi

cat >> localhost.yml << EOF

    debian:
      hosts:
EOF

if [[ "$OS" == "debian" ]]; then
  cat >> localhost.yml << EOF
        localhost:
          ansible_connection: local
EOF
fi

# Add selected groups
if [[ "$LOGIN" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_login_tools:
      hosts:
        localhost:
EOF
fi

if [[ "$GUI" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_gui_tools:
      hosts:
        localhost:
EOF
fi

if [[ "$BROWSERS" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_browsers:
      hosts:
        localhost:
EOF
fi

if [[ "$AI" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_ai_tools:
      hosts:
        localhost:
EOF
fi

echo
echo "Generated localhost.yml:"
cat localhost.yml
echo

# Run playbook
echo "Running Ansible playbook..."
if [[ "$OS" == "darwin" ]]; then
  /opt/homebrew/bin/ansible-playbook -i localhost.yml setup.yml
else
  ansible-playbook -i localhost.yml setup.yml
fi

echo
echo "=== Bootstrap complete! ==="
