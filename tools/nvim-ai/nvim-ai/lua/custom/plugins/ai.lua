-- AI plugins for nvim-ai
-- Uses Claude Code subscription (not API token) via CLI integration

return {
	-- Register <leader>a group in which-key
	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				{ "<leader>a", group = "[A]I" },
			},
		},
	},

	-- claudecode.nvim - Full IDE integration via WebSocket MCP protocol (TESTING)
	-- Same protocol as official VS Code/JetBrains extensions
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		config = true,
		keys = {
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "[A]I [C]laude toggle" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "[A]I [F]ocus Claude" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "[A]I [S]end selection" },
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "[A]I [A]ccept diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "[A]I [D]eny diff" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "[A]I [R]esume session" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "[A]I [C]ontinue conversation" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "[A]I Select [M]odel" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "[A]I Add [B]uffer to context" },
		},
		opts = {
			terminal = {
				split_side = "right",
				split_width_percentage = 0.40,
			},
		},
	},
}
