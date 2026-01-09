-- ==============================================================================
-- Custom Keymaps
-- ==============================================================================
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local keymap = vim.keymap
local opts_silent = { noremap = false, silent = true }

-- ==============================================================================
-- Buffer Navigation
-- ==============================================================================

-- Move between buffers
keymap.set("n", "<S-A-l>", ":bnext<CR>", { desc = "Next buffer" })
keymap.set("n", "<S-A-h>", ":bprev<CR>", { desc = "Previous buffer" })

-- Close buffer without closing window
keymap.set("n", "<A-w>", ":bn | bd #<CR>", { desc = "Close buffer" })

-- ==============================================================================
-- Line Navigation
-- ==============================================================================

-- Go to start or end of line easier
keymap.set({ "n", "x" }, "H", "^", { desc = "Go to line start" })
keymap.set({ "n", "x" }, "L", "g_", { desc = "Go to line end" })

-- ==============================================================================
-- Yank/Delete/Change Behavior
-- ==============================================================================

-- Delete/change WITHOUT yanking (default behavior)
keymap.set("n", "d", '"_d', { desc = "Delete without yanking" })
keymap.set("v", "d", '"_d', { desc = "Delete without yanking" })
keymap.set("n", "c", '"_c', { desc = "Change without yanking" })
keymap.set("v", "c", '"_c', { desc = "Change without yanking" })
keymap.set("n", "x", '"_x', { desc = "Delete char without yanking" })

-- Delete/change WITH yanking (requires leader)
keymap.set("n", "<leader>d", "d", { desc = "Delete with yanking" })
keymap.set("v", "<leader>d", "d", { desc = "Delete with yanking" })
keymap.set("n", "<leader>c", "c", { desc = "Change with yanking" })
keymap.set("v", "<leader>c", "c", { desc = "Change with yanking" })

-- Paste without yanking deleted text
keymap.set("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Paste with indent
keymap.set({ "n", "v", "i" }, "C-A-v", " <BS><Esc>]p", { desc = "Paste with indent" })
keymap.set({ "n", "v", "i" }, "C-S-A-v", " <BS><Esc>[p", { desc = "Paste before with indent" })

-- ==============================================================================
-- Buffer Operations
-- ==============================================================================

-- Select entire buffer
keymap.set("n", "<leader>v", "ggVG", { desc = "Select entire buffer" })

-- Yank entire buffer
keymap.set("n", "<leader>y", "<cmd>%yank<cr>", { desc = "Yank entire buffer" })

-- Reload buffer
keymap.set("n", "<leader>bb", "<cmd>e!<cr>", { desc = "Reload buffer" })

-- ==============================================================================
-- Insert Mode Navigation
-- ==============================================================================

-- Go to line start/end in insert mode
keymap.set("i", "<C-h>", "<C-o>^", { desc = "Go to line start" })
keymap.set("i", "<C-l>", "<C-o>$", { desc = "Go to line end" })

-- Delete operations in insert mode
keymap.set("i", "<C-D>", "<DEL>", { desc = "Delete char right" })
keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete word left" })
keymap.set("i", "<A-DEL>", "<esc><leader>dei", { desc = "Delete word right" })

-- ==============================================================================
-- Command-line Mode
-- ==============================================================================

-- Go to beginning of command
keymap.set("c", "<C-A>", "<HOME>", { desc = "Go to command start" })

-- ==============================================================================
-- Window Navigation & Management
-- ==============================================================================

-- Move between windows (Ctrl+Alt+hjkl)
keymap.set("n", "<C-A-h>", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<C-A-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap.set("n", "<C-A-k>", "<C-w>k", { desc = "Move to top window" })
keymap.set("n", "<C-A-l>", "<C-w>l", { desc = "Move to right window" })
keymap.set({ "i", "v" }, "<C-A-h>", "<esc><C-w>h", { desc = "Move to left window" })
keymap.set({ "i", "v" }, "<C-A-j>", "<esc><C-w>j", { desc = "Move to bottom window" })
keymap.set({ "i", "v" }, "<C-A-k>", "<esc><C-w>k", { desc = "Move to top window" })
keymap.set({ "i", "v" }, "<C-A-l>", "<esc><C-w>l", { desc = "Move to right window" })

-- Window resizing (Alt + Arrow keys)
keymap.set("n", "<M-Up>", ":resize +2<CR>", { desc = "Increase window height" })
keymap.set("n", "<M-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
keymap.set("n", "<M-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
keymap.set("n", "<M-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Close all other windows
keymap.set("n", "<leader>o", ":only<CR>", { desc = "Close other windows" })

-- ==============================================================================
-- Fast Cursor Movement
-- ==============================================================================

-- Move 10 lines at a time (Ctrl+hjkl)
keymap.set("n", "<C-h>", "10h", { desc = "Move left 10 chars" })
keymap.set("n", "<C-j>", "10j", { desc = "Move down 10 lines" })
keymap.set("n", "<C-k>", "10k", { desc = "Move up 10 lines" })
keymap.set("n", "<C-l>", "10l", { desc = "Move right 10 chars" })

keymap.set("v", "<C-h>", "10h", { desc = "Move left 10 chars" })
keymap.set("v", "<C-j>", "10j", { desc = "Move down 10 lines" })
keymap.set("v", "<C-k>", "10k", { desc = "Move up 10 lines" })
keymap.set("v", "<C-l>", "10l", { desc = "Move right 10 chars" })

-- ==============================================================================
-- Formatting & Search
-- ==============================================================================

-- Format code
keymap.set("n", "<M-S-f>", "<cmd>:Format<cr>", { desc = "Format code" })

-- Clear search highlight
keymap.set("n", "<F3>", "<cmd>:noh<cr>", { desc = "Clear search highlight" })

-- ==============================================================================
-- File Navigation
-- ==============================================================================

-- Neotree focus
keymap.set("n", ",", "<cmd>Neotree focus<cr>", { desc = "Focus file tree" })

-- Oil.nvim - parent directory
keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- ==============================================================================
-- Text Objects - vim-sandwich
-- ==============================================================================

vim.g.sandwich_no_default_key_mappings = 1

-- Add surrounding
keymap.set("n", "<leader>ra", "<Plug>(sandwich-add)", opts_silent)
keymap.set("x", "<leader>ra", "<Plug>(sandwich-add)", opts_silent)
keymap.set("o", "<leader>ra", "<Plug>(sandwich-add)", opts_silent)

-- Delete surrounding
keymap.set("n", "<leader>rd", "<Plug>(sandwich-delete)", opts_silent)
keymap.set("x", "<leader>rd", "<Plug>(sandwich-delete)", opts_silent)
keymap.set("n", "<leader>rdb", "<Plug>(sandwich-delete-auto)", opts_silent)

-- Replace surrounding
keymap.set("n", "<leader>rr", "<Plug>(sandwich-replace)", opts_silent)
keymap.set("x", "<leader>rr", "<Plug>(sandwich-replace)", opts_silent)
keymap.set("n", "<leader>rrb", "<Plug>(sandwich-replace-auto)", opts_silent)

-- ==============================================================================
-- AI Assistants - CodeCompanion
-- ==============================================================================

keymap.set("n", "<leader>a", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions" })
keymap.set("v", "<leader>a", "<cmd>CodeCompanionActions<cr>", { desc = "AI Actions" })
keymap.set("n", "<leader>b", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
keymap.set("v", "<leader>b", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add to AI Chat" })

-- Expand 'cc' to 'CodeCompanion' in command line
vim.cmd([[cab cc CodeCompanion]])

-- ==============================================================================
-- LSP & Diagnostics
-- ==============================================================================

-- Navigate diagnostics with auto-open float
keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev()
  vim.diagnostic.open_float()
end, { desc = "Previous diagnostic" })

keymap.set("n", "]d", function()
  vim.diagnostic.goto_next()
  vim.diagnostic.open_float()
end, { desc = "Next diagnostic" })

-- Code actions
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- ==============================================================================
-- Terminal Mode
-- ==============================================================================

-- Exit terminal mode with double escape
keymap.set("t", "<esc><esc>", "<C-\\><C-n>", { silent = true, desc = "Exit terminal mode" })
