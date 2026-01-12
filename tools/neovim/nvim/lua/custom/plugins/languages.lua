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
        volar = {},
        tailwindcss = {},
        -- Python
        pyright = {},
        -- Go
        gopls = {},
        -- Rust
        rust_analyzer = {},
        -- Lua
        lua_ls = {},
        -- C/C++
        clangd = {},
        -- Shell
        bashls = {},
        -- Docker
        dockerls = {},
        docker_compose_language_service = {},
        -- YAML
        yamlls = {},
        -- Terraform
        terraformls = {},
        -- SQL
        sqlls = {},
        -- Ruby
        solargraph = {},
        -- PHP
        intelephense = {},
        -- Java
        jdtls = {},
        -- Kotlin
        kotlin_language_server = {},
        -- Swift
        sourcekit = {},
        -- Zig
        zls = {},
        -- Haskell
        hls = {},
        -- Elixir
        elixirls = {},
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
        'vue-language-server',
        'tailwindcss-language-server',
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
        -- C/C++
        'clangd',
        'clang-format',
        -- Shell
        'bash-language-server',
        'shfmt',
        'shellcheck',
        -- Docker
        'dockerfile-language-server',
        'docker-compose-language-service',
        -- YAML
        'yaml-language-server',
        -- Terraform
        'terraform-ls',
        -- SQL
        'sqlls',
        'sql-formatter',
        -- Ruby
        'solargraph',
        -- PHP
        'intelephense',
        -- Java
        'jdtls',
        -- Kotlin
        'kotlin-language-server',
        -- Zig
        'zls',
        -- Haskell
        'haskell-language-server',
        -- Elixir
        'elixir-ls',
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
        vue = { 'prettierd' },
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
        -- C/C++
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        -- Shell
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
        -- SQL
        sql = { 'sql_formatter' },
        -- Terraform
        terraform = { 'terraform_fmt' },
        hcl = { 'terraform_fmt' },
      },
    },
  },

  -- Treesitter: ensure languages are installed
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      local parsers = {
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
        'vue',
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
        -- C/C++
        'c',
        'cpp',
        -- Shell
        'bash',
        -- Docker
        'dockerfile',
        -- SQL
        'sql',
        -- Terraform
        'terraform',
        'hcl',
        -- Ruby
        'ruby',
        -- PHP
        'php',
        -- Java
        'java',
        -- Kotlin
        'kotlin',
        -- Swift
        'swift',
        -- Zig
        'zig',
        -- Haskell
        'haskell',
        -- Elixir
        'elixir',
        -- Misc
        'xml',
        'regex',
        'gitcommit',
        'gitignore',
        'git_rebase',
        'make',
        'cmake',
        'ninja',
        'proto',
      }
      require('nvim-treesitter').install(parsers)
    end,
  },
}
