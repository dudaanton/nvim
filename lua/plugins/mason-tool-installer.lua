return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = "VeryLazy",
  opts = {
    ensure_installed = {
      "prettier",
      "stylua",
    },
    auto_update = true,
    run_on_start = true,
    run_on_write = true,
  },
}
