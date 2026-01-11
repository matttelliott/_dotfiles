#!/bin/bash
set -e

# Install Xcode CLT
if [ ! -f /Library/Developer/CommandLineTools/usr/bin/git ]; then
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  softwareupdate -l | grep -o 'Command Line Tools.*' | head -1 | xargs -I {} softwareupdate -i "{}"
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

# Install Homebrew
if [ ! -f /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Ansible
if [ ! -f /opt/homebrew/bin/ansible ]; then
  /opt/homebrew/bin/brew install ansible
fi

# Run playbook
cd "$(dirname "$0")"
/opt/homebrew/bin/ansible-playbook -i localhost.yml setup.yml
