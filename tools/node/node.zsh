# nvm - fast loading with deferred full init
export NVM_DIR="$HOME/.nvm"

# Resolve nvm alias chain to actual version
_nvm_resolve_alias() {
  local alias="$1" target
  while true; do
    if [[ "$alias" =~ ^v?[0-9] ]]; then
      echo "${alias#v}"
      return
    elif [[ "$alias" == lts/* ]]; then
      local lts_name="${alias#lts/}"
      target="$NVM_DIR/alias/lts/$lts_name"
    else
      target="$NVM_DIR/alias/$alias"
    fi
    [ -f "$target" ] || return 1
    alias=$(cat "$target")
  done
}

# Find .nvmrc in current or parent directories
_nvm_find_nvmrc() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    [ -f "$dir/.nvmrc" ] && cat "$dir/.nvmrc" && return
    dir=$(dirname "$dir")
  done
  return 1
}

# Get version to use: .nvmrc if present, else default
_nvm_get_version() {
  local version
  if version=$(_nvm_find_nvmrc 2>/dev/null); then
    _nvm_resolve_alias "$version"
  else
    _nvm_resolve_alias default
  fi
}

# Add node to PATH immediately (fast)
if _nvm_version=$(_nvm_get_version 2>/dev/null); then
  _nvm_node_path="$NVM_DIR/versions/node/v$_nvm_version/bin"
  [ -d "$_nvm_node_path" ] && export PATH="$_nvm_node_path:$PATH"
  unset _nvm_version _nvm_node_path
fi

# Load full nvm on first use
nvm() {
  unset -f nvm
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
  elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    \. "/opt/homebrew/opt/nvm/nvm.sh"
  fi
  nvm "$@"
}
