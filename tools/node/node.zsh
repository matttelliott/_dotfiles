# Fast nvm loading
export NVM_DIR="$HOME/.nvm"

# Load nvm with --no-use (skips slow node activation)
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh" --no-use
elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  \. "/opt/homebrew/opt/nvm/nvm.sh" --no-use
fi

# Manually add default node to PATH (much faster than nvm use)
if [ -d "$NVM_DIR/versions/node" ]; then
  NODE_DEFAULT="$NVM_DIR/alias/default"
  if [ -f "$NODE_DEFAULT" ]; then
    NODE_VERSION=$(cat "$NODE_DEFAULT")
    NODE_PATH="$NVM_DIR/versions/node/v${NODE_VERSION#v}/bin"
    [ -d "$NODE_PATH" ] && export PATH="$NODE_PATH:$PATH"
  fi
fi
