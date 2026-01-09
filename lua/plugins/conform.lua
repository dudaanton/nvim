-- Code formatting with Conform

return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    event = "VeryLazy",
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua", lsp_format = "never" },
        -- Conform will run multiple formatters sequentially
        python = { "isort", "black" },
        -- You can customize some of the format options for the filetype (:help conform.format)
        rust = { "rustfmt", lsp_format = "fallback" },
        -- Conform will run the first available formatter
        javascript = { "eslint", "prettier", stop_after_first = true },
        vue = { "eslint", "prettier", stop_after_first = true },
        typescript = { "eslint", "prettier", stop_after_first = true },
        json = { "prettier", "jq", stop_after_first = true },
        jsonc = { "prettier", stop_after_first = true },
      },
    },
  },
}
