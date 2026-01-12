-- Language support (LSP, formatters, treesitter)

return {
  -- LSP servers
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        -- Web
        ts_ls = {},
        eslint = {},
        cssls = {},
        html = {},
        jsonls = {},
        svelte = {},
        angularls = {},
        -- Python
        pyright = {},
        -- Go
        gopls = {},
        -- Rust
        rust_analyzer = {},
        -- Lua
        lua_ls = {},
        -- Django
        djlsp = {},
      },
    },
  },

  -- Mason: ensure tools are installed
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    opts = {
      ensure_installed = {
        -- Web
        'typescript-language-server',
        'eslint-lsp',
        'prettierd',
        'eslint_d',
        'css-lsp',
        'html-lsp',
        'json-lsp',
        'svelte-language-server',
        'angular-language-server',
        'djlint',
        -- Python
        'pyright',
        'black',
        'isort',
        'ruff',
        -- Go
        'gopls',
        'gofumpt',
        'goimports',
        -- Rust
        'rust-analyzer',
        'rustfmt',
        -- Lua
        'lua-language-server',
        'stylua',
      },
    },
  },

  -- Conform: formatters (respects project config)
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
        svelte = { 'prettierd' },
        markdown = { 'prettierd' },
        yaml = { 'prettierd' },
        graphql = { 'prettierd' },
        angular = { 'prettierd' },
        htmldjango = { 'djlint' },
        gotmpl = { 'prettierd' },
        -- Python
        python = { 'ruff_format', 'isort' },
        -- Go
        go = { 'goimports', 'gofumpt' },
        -- Rust
        rust = { 'rustfmt' },
        -- Lua
        lua = { 'stylua' },
      },
    },
  },

  -- Treesitter: ensure languages are installed
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        -- Web
        'javascript',
        'typescript',
        'tsx',
        'json',
        'jsonc',
        'css',
        'scss',
        'html',
        'svelte',
        'yaml',
        'graphql',
        'angular',
        'htmldjango',
        -- Go
        'go',
        'gomod',
        'gosum',
        'gotmpl',
        -- Python
        'python',
        -- Rust
        'rust',
        'toml',
        -- Lua
        'lua',
        'luadoc',
      },
    },
  },
}
