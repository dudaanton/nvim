return {
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    opts = {
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = "˙",
        right = "¬",
        down = "∆",
        up = "˚",

        -- Move current line in Normal mode
        line_left = "˙",
        line_right = "¬",
        line_down = "∆",
        line_up = "˚",
      },

      -- Options which control moving behavior
      options = {
        -- Automatically reindent selection during linewise vertical move
        reindent_linewise = true,
      },
    },
  },
}
