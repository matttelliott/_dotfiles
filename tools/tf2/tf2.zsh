# =============================================================================
# TF2 Shell Functions
# =============================================================================

# TF2 custom folder path
export TF2_CUSTOM_DIR="$HOME/.steam/steam/steamapps/common/Team Fortress 2/tf/custom"

# -----------------------------------------------------------------------------
# tf2-hud: Select and enable a HUD using fzf
# Usage: tf2-hud [hud-name]
#        tf2-hud           # Interactive fzf picker
#        tf2-hud rayshud   # Directly select rayshud
# -----------------------------------------------------------------------------
tf2-hud() {
  local custom_dir="$TF2_CUSTOM_DIR"

  # Check if custom dir exists
  if [[ ! -d "$custom_dir" ]]; then
    echo "Error: TF2 custom directory not found: $custom_dir"
    return 1
  fi

  cd "$custom_dir" || return 1

  # Get list of HUDs (directories, strip .disabled suffix for display)
  local huds=()
  local current=""

  for d in */; do
    [[ -d "$d" ]] || continue
    local name="${d%/}"
    local display_name="${name%.disabled}"

    # Skip non-HUD folders (configs, etc)
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue

    # Track current active HUD
    if [[ "$name" == "$display_name" ]]; then
      current="$display_name"
      huds+=("* $display_name")
    else
      huds+=("  $display_name")
    fi
  done

  if [[ ${#huds[@]} -eq 0 ]]; then
    echo "No HUDs found in $custom_dir"
    echo "Install HUDs to: $custom_dir/<hud-name>/"
    return 1
  fi

  local selected
  if [[ -n "$1" ]]; then
    # Direct selection
    selected="$1"
  else
    # Interactive fzf picker
    selected=$(printf '%s\n' "${huds[@]}" | fzf --prompt="Select HUD: " --header="Current: ${current:-none}" | sed 's/^[* ] //')
  fi

  [[ -z "$selected" ]] && return 0

  # Disable all HUDs
  for d in */; do
    [[ -d "$d" ]] || continue
    local name="${d%/}"
    local base_name="${name%.disabled}"
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue

    if [[ "$name" == "$base_name" ]]; then
      mv "$name" "${name}.disabled" 2>/dev/null
    fi
  done

  # Enable selected HUD
  if [[ -d "${selected}.disabled" ]]; then
    mv "${selected}.disabled" "$selected"
    echo "Enabled HUD: $selected"
  elif [[ -d "$selected" ]]; then
    echo "HUD already enabled: $selected"
  else
    echo "Error: HUD not found: $selected"
    return 1
  fi

  cd - > /dev/null
}

# -----------------------------------------------------------------------------
# tf2-hud-list: List installed HUDs
# -----------------------------------------------------------------------------
tf2-hud-list() {
  local custom_dir="$TF2_CUSTOM_DIR"

  if [[ ! -d "$custom_dir" ]]; then
    echo "Error: TF2 custom directory not found"
    return 1
  fi

  echo "Installed HUDs ($custom_dir):"
  echo ""

  for d in "$custom_dir"/*/; do
    [[ -d "$d" ]] || continue
    local name="$(basename "$d")"
    [[ -d "$d/resource" ]] || [[ -d "$d/scripts" ]] || continue

    if [[ "$name" == *.disabled ]]; then
      echo "  [ ] ${name%.disabled}"
    else
      echo "  [*] $name"
    fi
  done
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
  local custom_dir="$TF2_CUSTOM_DIR"
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

  echo "Downloading $repo..."
  curl -sL "https://github.com/$repo/archive/refs/heads/master.zip" -o "$tmp_zip" || {
    echo "Error: Failed to download from GitHub"
    return 1
  }

  echo "Extracting to $custom_dir..."
  unzip -q -o "$tmp_zip" -d "$custom_dir" || {
    echo "Error: Failed to extract"
    return 1
  }

  # Rename extracted folder (GitHub adds -master suffix)
  local extracted_name="$(basename "$repo")-master"
  if [[ -d "$custom_dir/$extracted_name" ]]; then
    rm -rf "$custom_dir/${name}.disabled" "$custom_dir/$name" 2>/dev/null
    mv "$custom_dir/$extracted_name" "$custom_dir/${name}.disabled"
  fi

  rm -f "$tmp_zip"

  echo "Installed: $name (disabled by default)"
  echo "Run 'tf2-hud $name' to enable"
}
