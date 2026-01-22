local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("DejaVuSansM Nerd Font Mono")
config.font_size = 18
config.color_scheme = "tokyonight"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.default_prog = { "/bin/zsh", "-l", "-c", "tmux a || tmux; exec $SHELL" }
config.keys = {
	{ key = "Enter", mods = "CMD", action = wezterm.action.ToggleFullScreen },
	{
		key = "v",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, pane)
			local success, stdout, stderr = wezterm.run_child_process({
				os.getenv("HOME") .. "/.local/bin/clip2path",
			})
			if success and stdout then
				local text = stdout:gsub("[\r\n]+$", "")
				pane:send_text(text)
			end
		end),
	},
}

return config
