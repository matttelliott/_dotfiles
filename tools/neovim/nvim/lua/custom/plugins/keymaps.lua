-- Custom keymaps

return {
  -- Telescope keymaps
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      { '<leader>o', '<cmd>Telescope find_files<cr>', desc = '[O]pen file' },
      { '<leader>/', '<cmd>Telescope live_grep<cr>', desc = 'Grep project' },
    },
  },

  -- Exit insert mode with jk/kj variants
  {
    dir = vim.fn.stdpath 'config',
    name = 'custom-keymaps',
    lazy = false,
    config = function()
      vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
      vim.keymap.set('i', 'kj', '<Esc>', { desc = 'Exit insert mode' })
      vim.keymap.set('i', 'JK', '<Esc>', { desc = 'Exit insert mode' })
      vim.keymap.set('i', 'KJ', '<Esc>', { desc = 'Exit insert mode' })
      vim.keymap.set('i', 'jK', '<Esc>', { desc = 'Exit insert mode' })
      vim.keymap.set('i', 'Kj', '<Esc>', { desc = 'Exit insert mode' })
    end,
  },
}
