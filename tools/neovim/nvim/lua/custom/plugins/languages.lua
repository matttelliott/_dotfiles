-- Language support (LSP, formatters, treesitter)
-- Trimmed to: Web, Lua, Python, Bash, Rust, Markdown, Git

return {
  -- LSP setup helper (runs after lspconfig is loaded)
  {
    dir = vim.fn.stdpath 'config' .. '/lua/custom',
    name = 'custom-lsp-setup',
    dependencies = { 'neovim/nvim-lspconfig', 'saghen/blink.cmp' },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local servers = {
        'ts_ls',
        'eslint',
        'cssls',
        'html',
        'jsonls',
        'tailwindcss',
        'pyright',
        'rust_analyzer',
        'bashls',
        'yamlls',
      }

      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
        vim.lsp.enable(server)
      end
    end,
  },

  -- Mason: ensure tools are installed
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      run_on_start = true,
      start_delay = 3000, -- 3 second delay so it doesn't block startup
      ensure_installed = {
        -- Web
        'typescript-language-server',
        'eslint-lsp',
        'prettierd',
        'css-lsp',
        'html-lsp',
        'json-lsp',
        'tailwindcss-language-server',
        -- Python
        'pyright',
        'black',
        'isort',
        'ruff',
        -- Rust
        'rust-analyzer',
        -- Lua
        'lua-language-server',
        'stylua',
        -- Shell
        'bash-language-server',
        'shfmt',
        'shellcheck',
        -- YAML
        'yaml-language-server',
      },
    },
  },

  -- Conform: formatters
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        -- Web
        javascript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescript = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        css = { 'prettierd' },
        scss = { 'prettierd' },
        html = { 'prettierd' },
        markdown = { 'prettierd' },
        yaml = { 'prettierd' },
        -- Python
        python = { 'ruff_format', 'isort' },
        -- Rust
        rust = { 'rustfmt' },
        -- Lua
        lua = { 'stylua' },
        -- Shell
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
      },
    },
  },
}
