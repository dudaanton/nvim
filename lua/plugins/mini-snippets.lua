return {
  {
    "echasnovski/mini.snippets",
    event = "InsertEnter",
    dependencies = "rafamadriz/friendly-snippets",
    opts = function()
      local mini_snippets = require("mini.snippets")

      -- Custom loader for VSCode-style JSON snippets
      local function load_vscode_snippets(ft)
        local result = {}
        local snippets_dir = vim.fn.stdpath("config") .. "/snippets/"

        -- Helper function to process snippet body
        local function process_body(body)
          if type(body) == "table" then
            return table.concat(body, "\n")
          end
          return body
        end

        -- Load global snippets for all filetypes
        local global_path = snippets_dir .. "global.json"
        if vim.fn.filereadable(global_path) == 1 then
          local ok, global_data = pcall(vim.fn.json_decode, vim.fn.readfile(global_path))
          if ok and global_data then
            for name, snippet in pairs(global_data) do
              table.insert(result, {
                prefix = snippet.prefix,
                body = process_body(snippet.body),
                desc = name,
              })
            end
          end
        end

        -- Load filetype-specific snippets
        local snippet_path = snippets_dir .. ft .. ".json"
        if vim.fn.filereadable(snippet_path) == 1 then
          local ok, snippets_data = pcall(vim.fn.json_decode, vim.fn.readfile(snippet_path))
          if ok and snippets_data then
            for name, snippet in pairs(snippets_data) do
              table.insert(result, {
                prefix = snippet.prefix,
                body = process_body(snippet.body),
                desc = name,
              })
            end
          end
        end

        return result
      end

      return {
        snippets = {
          mini_snippets.gen_loader.from_lang(), -- Load friendly-snippets
          load_vscode_snippets, -- Load custom VSCode-style snippets
        },

        -- Following the behavior of vim.snippets,
        -- the intended usage of <esc> is to be able to temporarily exit into normal mode for quick edits.
        --
        -- If you'd rather stop the snippet on <esc>, activate the line below in your own config:
        -- mappings = { stop = "<esc>" }, -- <c-c> by default, see :h MiniSnippets-session

        expand = {
          select = function(snippets, insert)
            -- Close completion window on snippet select - vim.ui.select
            -- Needed to remove virtual text for fzf-lua and telescope, but not for mini.pick...
            local select = expand_select_override or MiniSnippets.default_select
            select(snippets, insert)
          end,
        },
      }
    end,
  },
}
