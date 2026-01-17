# Lazy-load nvm (only loads when you use nvm/node/npm/npx)
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
}

nvm() { _load_nvm && nvm "$@"; }
node() { _load_nvm && node "$@"; }
npm() { _load_nvm && npm "$@"; }
npx() { _load_nvm && npx "$@"; }
claude() { _load_nvm && claude "$@"; }
