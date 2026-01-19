-- trouble.nvim - Better diagnostics list
return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = 'Trouble',
  keys = {
    { '<leader>dd', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer [D]iagnostics' },
    { '<leader>dD', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Project [D]iagnostics' },
  },
  opts = {
    warn_no_results = false,
    open_no_results = false,
    focus = true,
  },
}
