return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "eslint",
        "lua_ls",
        -- "pyright",
        "basedpyright",
        -- "pylsp",
        "rust_analyzer",
        "vtsls",
        "vue_ls",
        "ts_ls",
      },
      automatic_enable = false,
    },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
  },
}
