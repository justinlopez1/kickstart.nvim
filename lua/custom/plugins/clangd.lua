-- ~/.config/nvim/lua/custom/plugins/clangd.lua
return {
  -- make sure we patch the existing lspconfig plugin
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    -- extend its opts instead of calling setup()
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      -- ensure mason installs clangd (and lua_ls if you want)
      if require 'mason-lspconfig' then
        local mlc = require 'mason-lspconfig'
        local ensure = (mlc.settings and mlc.settings.current.ensure_installed) or {}
        table.insert(ensure, 'clangd')
      end

      -- your clangd flags
      opts.servers.clangd = vim.tbl_deep_extend('force', opts.servers.clangd or {}, {
        cmd = {
          'clangd',
          '--background-index',
          '-j=12',
          '--query-driver=**',
          '--clang-tidy',
          '--all-scopes-completion',
          '--cross-file-rename',
          '--completion-style=detailed',
          '--header-insertion-decorators',
          '--header-insertion=iwyu',
          '--pch-storage=memory',
          '--suggest-missing-includes',
        },
      })
    end,
  },
}
