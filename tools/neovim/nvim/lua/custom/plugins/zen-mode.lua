-- zen-mode.nvim - Distraction-free writing/coding
return {
  'folke/zen-mode.nvim',
  cmd = 'ZenMode',
  keys = {
    { '<leader>z', '<cmd>ZenMode<cr>', desc = '[Z]en mode toggle' },
  },
  opts = {
    window = {
      backdrop = 0.95,
      width = 120,
      height = 1,
      options = {
        signcolumn = 'no',
        number = false,
        relativenumber = false,
        cursorline = false,
        cursorcolumn = false,
        foldcolumn = '0',
        list = false,
      },
    },
    plugins = {
      options = {
        enabled = true,
        ruler = false,
        showcmd = false,
        laststatus = 0,
      },
      gitsigns = { enabled = false },
      tmux = { enabled = false },
    },
    on_open = function()
      vim.diagnostic.enable(false)
    end,
    on_close = function()
      vim.diagnostic.enable(true)
    end,
  },
}
