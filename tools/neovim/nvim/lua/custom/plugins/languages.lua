-- Language support (LSP, formatters, treesitter)
-- Trimmed to: Web, Lua, Python, Bash, Rust, Markdown, Git

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
        tailwindcss = {},
        -- Python
        pyright = {},
        -- Rust
        rust_analyzer = {},
        -- Lua
        lua_ls = {},
        -- Shell
        bashls = {},
        -- YAML/Markdown
        yamlls = {},
      },
    },
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
