-- vim-slime: send nvim buffer text to a tmux pane (zsh, claude-code, etc.)
return {
  'jpalardy/vim-slime',
  init = function()
    vim.g.slime_target = 'tmux'
    vim.g.slime_default_config = {
      socket_name = 'default',
      target_pane = '{last}',
    }
    vim.g.slime_dont_ask_default = 1
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_no_mappings = 0
  end,
  keys = {
    { '<leader>rr', ':%SlimeSend<CR>', mode = 'n', desc = '[R]EPL send buffer' },
    { '<leader>rb', ':%SlimeSend<CR>', mode = 'n', desc = '[R]EPL send [b]uffer' },
    {
      '<leader>rl',
      function()
        local loc = string.format('%s:%d:%d', vim.fn.expand '%:p', vim.fn.line '.', vim.fn.col '.')
        vim.fn['slime#send'](loc)
      end,
      mode = 'n',
      desc = '[R]EPL send [l]ocation (file:line:col)',
    },
    {
      '<leader>rL',
      function()
        local loc = string.format('%s:%d:%d', vim.fn.expand '%:p', vim.fn.line '.', vim.fn.col '.')
        vim.fn['slime#send'](loc .. '\r')
      end,
      mode = 'n',
      desc = '[R]EPL send [L]ocation and submit',
    },
    { '<leader>rp', '<Plug>SlimeParagraphSend', mode = 'n', desc = '[R]EPL send [p]aragraph' },
    { '<leader>rc', '<Plug>SlimeConfig', mode = 'n', desc = '[R]EPL [c]onfigure target' },
    { '<leader>r', '<Plug>SlimeRegionSend', mode = 'x', desc = '[R]EPL send selection' },
  },
}
