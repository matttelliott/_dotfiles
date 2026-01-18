local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("DejaVuSansM Nerd Font Mono")
config.font_size = 18
config.color_scheme = "tokyonight"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.default_prog = { "/bin/zsh", "-c", "tmux a || tmux" }
config.keys = {
	{ key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen },
}

return config
