local settings = require("config.settings")
local util = require("lspconfig.util")

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      diagnostics = {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = settings.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = settings.icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = settings.icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = settings.icons.diagnostics.Info,
          },
        },
      },
    },
    config = function(_, opts)
      for severity, icon in pairs(opts.diagnostics.signs.text) do
        local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end

      local basedpyright_config = {
        settings = {
          basedpyright = {
            plugins = {
              rope_autoimport = {
                enabled = true,
              },
            },
          },
        },
      }

      -- Configure all LSP servers BEFORE enabling them
      vim.lsp.config("basedpyright", basedpyright_config)

      -- Swift LSP Configuration (Neovim 0.11+ API)
      -- Based on: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/sourcekit.lua
      vim.lsp.config.sourcekit = {
        -- Remote LSP: Connect to sourcekit-lsp running on macOS host via TCP
        -- Host runs: ~/config/nvim/scripts/sourcekit-lsp-server.sh
        -- Server binds to 0.0.0.0:9000 (required for host.docker.internal connectivity)
        -- Container connects via: host.docker.internal:9000
        cmd = { "socat", "-", "TCP:host.docker.internal:9000" },
        filetypes = { "swift", "objc", "objcpp", "c", "cpp" },
        root_dir = function(bufnr, on_dir)
          local filename = vim.api.nvim_buf_get_name(bufnr)
          -- Use lspconfig.util for root_pattern (supports wildcards like *.xcodeproj)
          local lsputil = require("lspconfig.util")
          on_dir(
            lsputil.root_pattern("buildServer.json", ".bsp")(filename)
              or lsputil.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
              or lsputil.root_pattern("compile_commands.json", "Package.swift")(filename)
              or vim.fs.dirname(vim.fs.find(".git", { path = filename, upward = true })[1])
          )
        end,
        get_language_id = function(_, ftype)
          -- Map short filetype names to LSP language IDs
          local t = { objc = "objective-c", objcpp = "objective-cpp" }
          return t[ftype] or ftype
        end,
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
          textDocument = {
            diagnostic = {
              dynamicRegistration = true,
              relatedDocumentSupport = true,
            },
          },
        },
      }

      vim.lsp.config("*", {
        capabilities = {
          textDocument = {
            semanticTokens = {
              multilineTokenSupport = true,
            },
          },
        },
        root_markers = { ".git" },
        on_attach = function(args, bufnr)
          local map = vim.keymap.set
          map("n", "gd", vim.lsp.buf.definition, { desc = "[G]oto [D]efinition", buffer = bufnr })
        end,
      })

      -- Enable LSP servers AFTER configuration
      vim.lsp.enable({
        "eslint",
        "lua_ls",
        -- "pyright",
        -- "pylsp",
        "basedpyright",
        "rust_analyzer",
        "sourcekit",
      })

      -- https://github.com/vuejs/language-tools/wiki/Neovim
      -- If you are using mason.nvim, you can get the ts_plugin_path like this
      -- For Mason v1,
      -- local mason_registry = require('mason-registry')
      -- local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'
      -- For Mason v2,
      -- local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'
      -- or even
      local vue_language_server_path = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }
      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
        configNamespace = "typescript",
      }
      local vtsls_config = {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
            },
          },
        },
        filetypes = tsserver_filetypes,
      }

      local ts_ls_config = {
        init_options = {
          plugins = {
            vue_plugin,
          },
        },
        filetypes = tsserver_filetypes,
      }

      -- Vue LSP integration with TypeScript
      local vue_ls_config = {
        on_init = function(client)
          client.handlers["tsserver/request"] = function(_, result, context)
            local ts_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })
            local vtsls_clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
            local clients = {}

            vim.list_extend(clients, ts_clients)
            vim.list_extend(clients, vtsls_clients)

            if #clients == 0 then
              vim.notify(
                "Could not find `vtsls` or `ts_ls` lsp client, `vue_ls` would not work without it.",
                vim.log.levels.ERROR
              )
              return
            end
            local ts_client = clients[1]

            local param = unpack(result)
            local id, command, payload = unpack(param)
            ts_client:exec_cmd({
              title = "vue_request_forward", -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
              command = "typescript.tsserverRequest",
              arguments = {
                command,
                payload,
              },
            }, { bufnr = context.bufnr }, function(_, r)
              local response = r and r.body
              -- TODO: handle error or response nil here, e.g. logging
              -- NOTE: Do NOT return if there's an error or no response, just return nil back to the vue_ls to prevent memory leak
              local response_data = { { id, response } }

              ---@diagnostic disable-next-line: param-type-mismatch
              client:notify("tsserver/response", response_data)
            end)
          end
        end,
      }
      -- nvim 0.11 or above
      vim.lsp.config("vtsls", vtsls_config)
      vim.lsp.config("vue_ls", vue_ls_config)
      vim.lsp.config("ts_ls", ts_ls_config)
      vim.lsp.enable({ "ts_ls", "vue_ls" })
    end,
  },
}
