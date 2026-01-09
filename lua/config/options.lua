-- ==============================================================================
-- Neovim Options
-- ==============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ==============================================================================
-- Global Settings
-- ==============================================================================

-- Snacks animations
vim.g.snacks_animate = false

-- Show document symbols from Trouble in lualine
vim.g.trouble_lualine = true

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- ==============================================================================
-- Editor Options
-- ==============================================================================

local opt = vim.opt

-- Shell
opt.shell = "/bin/bash"

-- Autowrite
opt.autowrite = true

-- Completion
opt.completeopt = "menu,menuone,noselect"

-- Concealment
opt.conceallevel = 2
vim.cmd([[autocmd FileType json setlocal conceallevel=0]])

-- Confirm save before exit
opt.confirm = true

-- Cursor
opt.cursorline = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.shiftround = true
opt.smartindent = true

-- Fill characters
opt.fillchars = {
  foldopen = "-",
  foldclose = "+",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Folding
opt.foldlevel = 99
opt.foldmethod = vim.fn.has("nvim-0.10") == 1 and "expr" or "indent"
opt.foldtext = ""

-- Format options
opt.formatoptions = "jcroqlnt"

-- Grep
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "nosplit"

-- Jump options
opt.jumpoptions = "view"

-- Status line
opt.laststatus = 3

-- Line wrapping
opt.linebreak = true
opt.wrap = false

-- List characters
opt.list = true

-- Mouse
opt.mouse = "a"

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Popup
opt.pumblend = 10
opt.pumheight = 10

-- Ruler
opt.ruler = false

-- Scroll offset
opt.scrolloff = 4
opt.sidescrolloff = 8

-- Smooth scroll (Neovim 0.10+)
if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true
end

-- Session options
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Short messages
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- Show mode
opt.showmode = false

-- Sign column
opt.signcolumn = "yes"

-- Spell checking
opt.spelllang = { "en", "ru" }

-- Split windows
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Terminal colors
opt.termguicolors = true

-- Timeout
opt.timeoutlen = vim.g.vscode and 1000 or 300

-- Undo
opt.undofile = true
opt.undolevels = 10000

-- Update time
opt.updatetime = 200

-- Virtual edit
opt.virtualedit = "block"

-- Wildmenu
opt.wildmode = "longest:full,full"

-- Window minimum width
opt.winminwidth = 5

-- Disable swap files
opt.swapfile = false

-- ==============================================================================
-- Russian Keyboard Layout Support
-- ==============================================================================

opt.keymap = "russian-jcukenwin"
opt.langmap =
  "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
opt.iminsert = 0
opt.imsearch = 0

-- ==============================================================================
-- Color Scheme
-- ==============================================================================

opt.background = "light"
