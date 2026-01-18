-- Language support (LSP, formatters, treesitter)
-- Trimmed to: Web, Lua, Python, Bash, Rust, Markdown, Git

-- Set up additional LSP servers after lspconfig loads
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    local lspconfig = require 'lspconfig'
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Web
    lspconfig.ts_ls.setup { capabilities = capabilities }
    lspconfig.eslint.setup { capabilities = capabilities }
    lspconfig.cssls.setup { capabilities = capabilities }
    lspconfig.html.setup { capabilities = capabilities }
    lspconfig.jsonls.setup { capabilities = capabilities }
    lspconfig.tailwindcss.setup { capabilities = capabilities }
    -- Python
    lspconfig.pyright.setup { capabilities = capabilities }
    -- Rust
    lspconfig.rust_analyzer.setup { capabilities = capabilities }
    -- Shell
    lspconfig.bashls.setup { capabilities = capabilities }
    -- YAML
    lspconfig.yamlls.setup { capabilities = capabilities }
  end,
})

return {

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
