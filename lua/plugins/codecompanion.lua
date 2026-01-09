return {
  "olimorris/codecompanion.nvim",
  opts = {
    rules = {
      default = {
        description = "Collection of common files for all projects",
        files = {
          { path = ".llm/AGENTS.md",   parser = "codecompanion" },
          { path = "~/.llm/AGENTS.md", parser = "codecompanion" },
        },
        is_preset = true,
      },
      with_history = {
        description = "Continue previous dialog",
        files = {
          { path = ".llm/AGENTS.md",   parser = "codecompanion" },
          { path = "~/.llm/AGENTS.md", parser = "codecompanion" },
          "~/.llm/history.md",
        },
        is_preset = true,
      },
      opts = {
        chat = {
          enabled = true,
          autoload = "default",
          default_rules = "default", -- The rule groups to load
        },
      },
    },
    display = {
      diff = {
        provider = 'split',
        provider_opts = {
          -- Options for inline diff provider
          inline = {
            layout = "buffer", -- float|buffer - Where to display the diff

            diff_signs = {
              signs = {
                text = "▌", -- Sign text for normal changes
                reject = "✗", -- Sign text for rejected changes in super_diff
                highlight_groups = {
                  addition = "DiagnosticOk",
                  deletion = "DiagnosticError",
                  modification = "DiagnosticWarn",
                },
              },
              -- Super Diff options
              icons = {
                accepted = " ",
                rejected = " ",
              },
              colors = {
                accepted = "DiagnosticOk",
                rejected = "DiagnosticError",
              },
            },

            opts = {
              context_lines = 3,         -- Number of context lines in hunks
              dim = 25,                  -- Background dim level for floating diff (0-100, [100 full transparent], only applies when layout = "float")
              full_width_removed = true, -- Make removed lines span full width
              show_keymap_hints = true,  -- Show "gda: accept | gdr: reject" hints above diff
              show_removed = true,       -- Show removed lines as virtual text
            },
          },
        },
      },
      chat = {
        icons = {
          chat_fold = " ",
        },
        fold_reasoning = true,
        show_reasoning = true,
      },
    },
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true
        }
      },
      history = {
        enabled = true,
        opts = {
          -- Keymap to open history from chat buffer (default: gh)
          keymap = "gh",
          -- Keymap to save the current chat manually (when auto_save is disabled)
          save_chat_keymap = "sc",
          -- Save all chats by default (disable to save only manually using 'sc')
          auto_save = true,
          -- Number of days after which chats are automatically deleted (0 to disable)
          expiration_days = 0,
          -- Picker interface (auto resolved to a valid picker)
          picker = "snacks", --- ("telescope", "snacks", "fzf-lua", or "default")
          ---Optional filter function to control which chats are shown when browsing
          chat_filter = nil, -- function(chat_data) return boolean end
          -- Customize picker keymaps (optional)
          picker_keymaps = {
            rename = { n = "r", i = "<M-r>" },
            delete = { n = "d", i = "<M-d>" },
            duplicate = { n = "<C-y>", i = "<C-y>" },
          },
          ---Automatically generate titles for new chats
          auto_generate_title = true,
          title_generation_opts = {
            ---Adapter for generating titles (defaults to current chat adapter)
            adapter = 'openrouter',                 -- "copilot"
            ---Model for generating titles (defaults to current chat model)
            model = 'google/gemini-2.5-flash-lite', -- "gpt-4o"
            ---Number of user prompts after which to refresh the title (0 to disable)
            refresh_every_n_prompts = 3,            -- e.g., 3 to refresh after every 3rd user prompt
            ---Maximum number of times to refresh the title (default: 3)
            max_refreshes = 3,
            format_title = function(original_title)
              -- this can be a custom function that applies some custom
              -- formatting to the title.
              return original_title
            end
          },
          ---On exiting and entering neovim, loads the last chat on opening chat
          continue_last_chat = false,
          ---When chat is cleared with `gx` delete the chat from history
          delete_on_clearing_chat = false,
          ---Directory path to save the chats
          dir_to_save = os.getenv("HOME") .. "/.codecompanion/history",
          ---Enable detailed logging for history extension
          enable_logging = false,

          -- Summary system
          summary = {
            -- Keymap to generate summary for current chat (default: "gcs")
            create_summary_keymap = "gcs",
            -- Keymap to browse summaries (default: "gbs")
            browse_summaries_keymap = "gbs",

            generation_opts = {
              adapter = 'openrouter',            -- defaults to current chat adapter
              model = 'google/gemini-2.5-flash', -- defaults to current chat model
              context_size = 90000,              -- max tokens that the model supports
              include_references = true,         -- include slash command content
              include_tool_outputs = true,       -- include tool execution results
              system_prompt = nil,               -- custom system prompt (string or function)
              format_summary = nil,              -- custom function to format generated summary e.g to remove <think/> tags from summary
            },
          },

          -- Memory system (requires VectorCode CLI)
          -- memory = {
          --   -- Automatically index summaries when they are generated
          --   auto_create_memories_on_summary_generation = true,
          --   -- Path to the VectorCode executable
          --   vectorcode_exe = "vectorcode",
          --   -- Tool configuration
          --   tool_opts = {
          --     -- Default number of memories to retrieve
          --     default_num = 10
          --   },
          --   -- Enable notifications for indexing progress
          --   notify = true,
          --   -- Index all existing memories on startup
          --   -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
          --   index_on_startup = false,
          -- },
        }
      }
    },
    interactions = {
      chat = {
        adapter = "claude_code",
        -- model = "google/gemini-3-pro-preview",
        tools = {
          -- ["mcp"] = {
          --   callback = function() return require("mcphub.extensions.codecompanion") end,
          --   description = "Call tools and resources from the MCP Servers",
          --   opts = {
          --     requires_approval = true,
          --   }
          -- }
        },
        opts = {
          system_prompt = function(ctx)
            return string.format(
              [[The current date is %s.
  The user's Neovim version is %s.
  The user is working on a %s machine.]],
              ctx.date,
              ctx.nvim_version,
              ctx.os
            )
          end,
        }
      },
      inline = {
        adapter = "openrouter",
        model = "anthropic/claude-3.5-sonnet"
      },
    },
    adapters = {
      http = {
        anthropic_with_bearer_token = function()
          local utils = require("codecompanion.utils.adapters")
          local tokens = require("codecompanion.utils.tokens")

          local function filter_out_messages(params)
            local message = params.message
            local allowed = params.allowed_words

            for key, _ in pairs(message) do
              if not vim.tbl_contains(allowed, key) then
                message[key] = nil
              end
            end
            return message
          end

          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              bearer_token = "ANTHROPIC_BEARER_TOKEN",
            },
            headers = {
              ["content-type"] = "application/json",
              ["authorization"] = "Bearer ${bearer_token}",
              ["anthropic-version"] = "2023-06-01",
              ["anthropic-beta"] =
              "claude-code-20250219,oauth-2025-04-20,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14",
            },
            handlers = {
              setup = function(self)
                if self.headers and self.headers["x-api-key"] then
                  self.headers["x-api-key"] = nil
                end

                if self.opts and self.opts.stream then
                  self.parameters.stream = true
                end

                local model = self.schema.model.default
                local model_opts = self.schema.model.choices[model]
                if model_opts and model_opts.opts then
                  self.opts = vim.tbl_deep_extend("force", self.opts, model_opts.opts)
                  if not model_opts.opts.has_vision then
                    self.opts.vision = false
                  end
                end

                return true
              end,

              form_messages = function(self, messages)
                local has_tools = false

                local system = vim
                    .iter(messages)
                    :filter(function(msg)
                      return msg.role == "system"
                    end)
                    :map(function(msg)
                      return {
                        type = "text",
                        text = msg.content,
                        cache_control = nil,
                      }
                    end)
                    :totable()

                table.insert(system, 1, {
                  type = "text",
                  text = "You are Claude Code, Anthropic's official CLI for Claude.",
                  cache_control = {
                    type = "ephemeral",
                  },
                })

                system = next(system) and system or nil

                messages = vim
                    .iter(messages)
                    :filter(function(msg)
                      return msg.role ~= "system"
                    end)
                    :totable()

                messages = vim.tbl_map(function(message)
                  if message.opts and message.opts.tag == "image" and message.opts.mimetype then
                    if self.opts and self.opts.vision then
                      message.content = {
                        {
                          type = "image",
                          source = {
                            type = "base64",
                            media_type = message.opts.mimetype,
                            data = message.content,
                          },
                        },
                      }
                    else
                      return nil
                    end
                  end

                  message = filter_out_messages({
                    message = message,
                    allowed_words = { "content", "role", "reasoning", "tool_calls" },
                  })

                  if message.role == self.roles.user or message.role == self.roles.llm then
                    if message.role == self.roles.user and message.content == "" then
                      message.content = "<prompt></prompt>"
                    end

                    if type(message.content) == "string" then
                      message.content = {
                        { type = "text", text = message.content },
                      }
                    end
                  end

                  if message.tool_calls and vim.tbl_count(message.tool_calls) > 0 then
                    has_tools = true
                  end

                  if message.role == "tool" then
                    message.role = self.roles.user
                  end

                  if has_tools and message.role == self.roles.llm and message.tool_calls then
                    message.content = message.content or {}
                    for _, call in ipairs(message.tool_calls) do
                      table.insert(message.content, {
                        type = "tool_use",
                        id = call.id,
                        name = call["function"].name,
                        input = vim.json.decode(call["function"].arguments),
                      })
                    end
                    message.tool_calls = nil
                  end

                  if message.reasoning and type(message.content) == "table" then
                    table.insert(message.content, 1, {
                      type = "thinking",
                      thinking = message.reasoning.content,
                      signature = message.reasoning._data.signature,
                    })
                  end

                  return message
                end, messages)

                messages = utils.merge_messages(messages)

                if has_tools then
                  for _, m in ipairs(messages) do
                    if m.role == self.roles.user and m.content and m.content ~= "" then
                      if type(m.content) == "table" and m.content.type then
                        m.content = { m.content }
                      end

                      if type(m.content) == "table" and vim.islist(m.content) then
                        local consolidated = {}
                        for _, block in ipairs(m.content) do
                          if block.type == "tool_result" then
                            local prev = consolidated[#consolidated]
                            if prev and prev.type == "tool_result" and prev.tool_use_id == block.tool_use_id then
                              prev.content = prev.content .. block.content
                            else
                              table.insert(consolidated, block)
                            end
                          else
                            table.insert(consolidated, block)
                          end
                        end
                        m.content = consolidated
                      end
                    end
                  end
                end

                local breakpoints_used = 0
                for i = #messages, 1, -1 do
                  local msgs = messages[i]
                  if msgs.role == self.roles.user then
                    for _, msg in ipairs(msgs.content) do
                      if msg.type ~= "text" or msg.text == "" then
                        goto continue
                      end
                      if tokens.calculate(msg.text) >= self.opts.cache_over and breakpoints_used < self.opts.cache_breakpoints then
                        msg.cache_control = { type = "ephemeral" }
                        breakpoints_used = breakpoints_used + 1
                      end
                      ::continue::
                    end
                  end
                end
                if system and breakpoints_used < self.opts.cache_breakpoints then
                  for _, prompt in ipairs(system) do
                    if breakpoints_used < self.opts.cache_breakpoints then
                      prompt.cache_control = { type = "ephemeral" }
                      breakpoints_used = breakpoints_used + 1
                    end
                  end
                end

                return { system = system, messages = messages }
              end,
            },
          })
        end,
        openwebui = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              url = "OPENWEBUI_API_URL",
              models_endpoint = "/api/v1/models",
              chat_url = "/api/v1/chat/completions",
              api_key = "OPENWEBUI_API_KEY",
            },
            handlers = {
              parse_message_meta = function(self, data)
                local extra = data.extra
                if extra and extra.reasoning then
                  data.output.reasoning = { content = extra.reasoning }
                  if data.output.content == "" then
                    data.output.content = nil
                  end
                end
                return data
              end,
            },
            schema = {
              model = {
                default = "gpt-oss:20b",
              },
            },
          })
        end,
        openrouter = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              url = "https://openrouter.ai",
              models_endpoint = "/api/v1/models",
              chat_url = "/api/v1/chat/completions",
              -- api_key = "cmd:cat ~/.codecompanion_openrouter_api_key",
              api_key = "OPENROUTER_API_KEY",
            },
            handlers = {
              parse_message_meta = function(self, data)
                local extra = data.extra
                if extra and extra.reasoning then
                  data.output.reasoning = { content = extra.reasoning }
                  if data.output.content == "" then
                    data.output.content = nil
                  end
                end
                return data
              end,
            },
            schema = {
              model = {
                -- default = "mistralai/codestral-2501",
                -- default = "meta-llama/llama-4-maverick",
                -- default = "qwen/qwen-2.5-coder-32b-instruct",
                -- default = "google/gemini-3-pro-preview",
                -- default = "google/gemini-2.5-pro",
                -- default = "google/gemini-2.0-flash-001",
                default = "anthropic/claude-opus-4.5",
              },
            },
          })
        end,
      },
      acp = {
        claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {
              -- Use OAuth token from Claude Pro subscription (run `claude setup-token` to get it)
              CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN",
              -- Or use API key: ANTHROPIC_API_KEY = "ANTHROPIC_API_KEY",
            },
          })
        end,
      },
    }
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ravitemer/mcphub.nvim",
    "ravitemer/codecompanion-history.nvim",
    {
      "OXY2DEV/markview.nvim",
      lazy = false,
      opts = {
        preview = {
          filetypes = { "markdown", "codecompanion" },
          ignore_buftypes = {},
        },
      },
    },
  },
}
