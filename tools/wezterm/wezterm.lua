local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'DejaVuSansMono Nerd Font'
config.color_scheme = 'tokyonight'
config.enable_tab_bar = false

return config
