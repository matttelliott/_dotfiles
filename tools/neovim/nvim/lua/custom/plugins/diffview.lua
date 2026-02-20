-- diffview.nvim - Git diff/history viewer
return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  keys = {
    {
      '<leader>gd',
      function()
        local lib = require 'diffview.lib'
        if lib.get_current_view() then
          vim.cmd 'DiffviewClose'
        else
          vim.cmd 'DiffviewOpen'
        end
      end,
      desc = '[G]it [D]iff toggle',
    },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it file [H]istory' },
    { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it repo [H]istory' },
    { '<leader>gp', '<cmd>DiffviewOpen origin/main...HEAD<cr>', desc = '[G]it [P]R review vs origin/main' },
    {
      '<leader>gb',
      function()
        require('telescope.builtin').git_branches {
          prompt_title = 'Diff against branch',
          attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry(prompt_bufnr)
              require('telescope.actions').close(prompt_bufnr)
              vim.cmd('DiffviewOpen ' .. entry.value .. '...HEAD')
            end)
            return true
          end,
        }
      end,
      desc = '[G]it diff against [B]ranch',
    },
    {
      '<leader>gc',
      function()
        require('telescope.builtin').git_commits {
          prompt_title = 'Diff against commit',
          attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
              local entry = require('telescope.actions.state').get_selected_entry(prompt_bufnr)
              require('telescope.actions').close(prompt_bufnr)
              vim.cmd('DiffviewOpen ' .. entry.value)
            end)
            return true
          end,
        }
      end,
      desc = '[G]it diff against [C]ommit',
    },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = {
        layout = 'diff2_horizontal',
      },
    },
  },
}
