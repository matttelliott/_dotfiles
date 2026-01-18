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

# Group selection
echo "Select groups to enable (y/n):"
echo

read -p "with_login_tools (git signing, ssh keys, cloud CLIs)? [y/n]: " LOGIN
read -p "with_gui_tools (WezTerm, LibreWolf, DBeaver)? [y/n]: " GUI
read -p "with_browsers (Chrome, Firefox, etc)? [y/n]: " BROWSERS
read -p "with_ai_tools (Claude Code)? [y/n]: " AI

echo

# Age key setup for SOPS decryption
AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"

if [[ ! -f "$AGE_KEY_FILE" ]]; then
  echo "=== Age Key Setup (for SOPS encrypted secrets) ==="
  echo
  echo "An Age private key is required to decrypt personal info (git name, email, SSH keys)."
  echo
  echo "Options:"
  echo "  1) Paste Age private key"
  echo "  2) Provide path to existing keys.txt"
  echo "  3) Generate new key (you'll need to re-encrypt personal-info.sops.yml)"
  echo
  read -p "Choose [1/2/3]: " AGE_CHOICE

  mkdir -p "$AGE_KEY_DIR"

  case $AGE_CHOICE in
    1)
      echo
      echo "Paste your Age private key (starts with AGE-SECRET-KEY-), then press Enter:"
      read -r AGE_SECRET
      echo "$AGE_SECRET" > "$AGE_KEY_FILE"
      ;;
    2)
      echo
      read -p "Path to keys.txt: " AGE_PATH
      cp "$AGE_PATH" "$AGE_KEY_FILE"
      ;;
    3)
      echo
      if command -v age-keygen &> /dev/null; then
        age-keygen -o "$AGE_KEY_FILE"
        echo
        echo "New key generated. You'll need to re-encrypt personal-info.sops.yml with this public key."
        echo "See: sops updatekeys group_vars/all/personal-info.sops.yml"
      else
        echo "age-keygen not found. It will be installed later, then run:"
        echo "  age-keygen -o $AGE_KEY_FILE"
        echo "  sops updatekeys group_vars/all/personal-info.sops.yml"
      fi
      ;;
  esac

  chmod 600 "$AGE_KEY_FILE" 2>/dev/null || true
  echo
fi

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

if [[ "$OS" == "arch" ]]; then
  echo "Installing dependencies..."
  sudo pacman -Sy --noconfirm git ansible
fi

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

cat > localhost.yml << EOF
---
all:
  children:
    macs:
      hosts:
EOF

if [[ "$OS" == "darwin" ]]; then
  cat >> localhost.yml << EOF
        $HOSTNAME:
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
        $HOSTNAME:
          ansible_connection: local
EOF
fi

cat >> localhost.yml << EOF

    arch:
      hosts:
EOF

if [[ "$OS" == "arch" ]]; then
  cat >> localhost.yml << EOF
        $HOSTNAME:
          ansible_connection: local
EOF
fi

# Add selected groups
if [[ "$LOGIN" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_login_tools:
      hosts:
        $HOSTNAME:
EOF
fi

if [[ "$GUI" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_gui_tools:
      hosts:
        $HOSTNAME:
EOF
fi

if [[ "$BROWSERS" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_browsers:
      hosts:
        $HOSTNAME:
EOF
fi

if [[ "$AI" =~ ^[Yy]$ ]]; then
  cat >> localhost.yml << EOF

    with_ai_tools:
      hosts:
        $HOSTNAME:
EOF
fi

echo
echo "Generated localhost.yml:"
cat localhost.yml
echo

# Run playbook
echo "Running Ansible playbook..."
if [[ "$OS" == "darwin" ]]; then
  /opt/homebrew/bin/ansible-playbook -i localhost.yml setup.yml --ask-become-pass
else
  ansible-playbook -i localhost.yml setup.yml --ask-become-pass
fi

echo
echo "=== Bootstrap complete! ==="
