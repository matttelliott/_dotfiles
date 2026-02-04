# =============================================================================
# TF2 Shell Functions
# =============================================================================

# TF2 custom folder path
export TF2_CUSTOM_DIR="$HOME/.steam/steam/steamapps/common/Team Fortress 2/tf/custom"
# Storage for disabled HUDs (outside custom folder so TF2 doesn't load them)
export TF2_HUD_STORAGE="$HOME/.local/share/tf2-huds"

# -----------------------------------------------------------------------------
# tf2-hud: Select and enable a HUD using fzf
# Usage: tf2-hud [hud-name]
#        tf2-hud           # Interactive fzf picker
#        tf2-hud rayshud   # Directly select rayshud
# -----------------------------------------------------------------------------
tf2-hud() {
  local custom_dir="$TF2_CUSTOM_DIR"
  local storage_dir="$TF2_HUD_STORAGE"

  # Check if custom dir exists
  if [[ ! -d "$custom_dir" ]]; then
    echo "Error: TF2 custom directory not found: $custom_dir"
    return 1
  fi

  # Create storage dir if needed
  mkdir -p "$storage_dir"

  # Migrate any .disabled HUDs to storage (one-time migration)
  for d in "$custom_dir"/*.disabled; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d" .disabled)"
    if [[ ! -d "$storage_dir/$name" ]]; then
      mv "$d" "$storage_dir/$name"
    else
      rm -rf "$d"
    fi
  done

  # Get list of HUDs from both locations
  local huds=()
  local current=""

  # Check active HUD in custom dir
  for d in "$custom_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d")"
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue
    current="$name"
    huds+=("* $name")
  done

  # Check stored HUDs
  for d in "$storage_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d")"
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue
    huds+=("  $name")
  done

  if [[ ${#huds[@]} -eq 0 ]]; then
    echo "No HUDs found"
    echo "Install HUDs with: tf2-hud-install <github-user/repo>"
    return 1
  fi

  local selected
  if [[ -n "$1" ]]; then
    selected="$1"
  else
    selected=$(printf '%s\n' "${huds[@]}" | fzf --prompt="Select HUD: " --header="Current: ${current:-none}" | sed 's/^[* ] //')
  fi

  [[ -z "$selected" ]] && return 0

  # Move current HUD to storage
  if [[ -n "$current" && "$current" != "$selected" ]]; then
    if [[ -d "$custom_dir/$current" ]]; then
      rm -rf "$storage_dir/$current"
      if ! mv "$custom_dir/$current" "$storage_dir/$current"; then
        echo "Error: Failed to disable $current"
        return 1
      fi
    fi
  fi

  # Enable selected HUD (move from storage to custom)
  if [[ -d "$storage_dir/$selected" ]]; then
    if mv "$storage_dir/$selected" "$custom_dir/$selected"; then
      echo "Enabled HUD: $selected"
      echo "Restart TF2 to apply changes"
    else
      echo "Error: Failed to enable $selected"
      return 1
    fi
  elif [[ -d "$custom_dir/$selected" ]]; then
    echo "HUD already enabled: $selected"
  else
    echo "Error: HUD not found: $selected"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# tf2-hud-list: List installed HUDs
# -----------------------------------------------------------------------------
tf2-hud-list() {
  local custom_dir="$TF2_CUSTOM_DIR"
  local storage_dir="$TF2_HUD_STORAGE"

  echo "Installed HUDs:"
  echo ""

  # Active HUDs in custom dir
  for d in "$custom_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d")"
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue
    [[ "$name" == *.disabled ]] && continue
    echo "  [*] $name"
  done

  # Stored HUDs
  if [[ -d "$storage_dir" ]]; then
    for d in "$storage_dir"/*/; do
      [[ -d "$d" ]] || continue
      local name="$(basename "$d")"
      [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue
      echo "  [ ] $name"
    done
  fi
}

# -----------------------------------------------------------------------------
# tf2-hud-install: Install a HUD from GitHub
# Usage: tf2-hud-install <github-user/repo> [name]
#        tf2-hud-install raysfire/rayshud
#        tf2-hud-install CriticalFlaw/flawhud flawhud
# -----------------------------------------------------------------------------
tf2-hud-install() {
  local repo="$1"
  local name="${2:-$(basename "$repo")}"
  local storage_dir="$TF2_HUD_STORAGE"
  local tmp_zip="/tmp/${name}.zip"

  if [[ -z "$repo" ]]; then
    echo "Usage: tf2-hud-install <github-user/repo> [name]"
    echo ""
    echo "Popular HUDs:"
    echo "  tf2-hud-install raysfire/rayshud"
    echo "  tf2-hud-install CriticalFlaw/flawhud"
    echo "  tf2-hud-install rbjaxter/budhud"
    echo "  tf2-hud-install Hypnootize/Flavor-HUD hypnotizehud"
    echo "  tf2-hud-install Zeesastrous/ZeesHUD zeeshud"
    return 1
  fi

  mkdir -p "$storage_dir"

  echo "Downloading $repo..."
  curl -sL "https://github.com/$repo/archive/refs/heads/master.zip" -o "$tmp_zip" || {
    echo "Error: Failed to download from GitHub"
    return 1
  }

  echo "Extracting..."
  unzip -q -o "$tmp_zip" -d "$storage_dir" || {
    echo "Error: Failed to extract"
    return 1
  }

  # Rename extracted folder (GitHub adds -master suffix)
  local extracted_name="$(basename "$repo")-master"
  if [[ -d "$storage_dir/$extracted_name" ]]; then
    rm -rf "$storage_dir/$name" 2>/dev/null
    mv "$storage_dir/$extracted_name" "$storage_dir/$name"
  fi

  rm -f "$tmp_zip"

  echo "Installed: $name"
  echo "Run 'tf2-hud $name' to enable"
}
