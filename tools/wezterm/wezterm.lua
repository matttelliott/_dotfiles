local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'DejaVuSansM Nerd Font Mono'
config.color_scheme = 'tokyonight'
config.enable_tab_bar = false

return config
