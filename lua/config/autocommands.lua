-- ==============================================================================
-- Autocommands
-- ==============================================================================

-- ==============================================================================
-- Format Command
-- ==============================================================================

vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

-- ==============================================================================
-- GPG Encryption Support
-- ==============================================================================

vim.opt.backupskip:append("*.asc")
vim.opt.viminfo = ""

vim.api.nvim_create_augroup("GPG", { clear = true })

-- Decrypt on read
vim.api.nvim_create_autocmd("BufReadPost", {
  group = "GPG",
  pattern = "*.asc",
  command = "%!gpg -q -d",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = "GPG",
  pattern = "*.asc",
  command = "redraw!",
})

-- Encrypt on write
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "GPG",
  pattern = "*.asc",
  command = "%!gpg -q -e -a",
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = "GPG",
  pattern = "*.asc",
  command = "undo",
})

-- Clear screen on exit
vim.api.nvim_create_autocmd("VimLeave", {
  group = "GPG",
  pattern = "*.asc",
  command = "!clear",
})

-- ==============================================================================
-- Password File Security (redact_pass.vim)
-- ==============================================================================

if vim.g.loaded_redact_pass or vim.opt.compatible:get() then
  return
end

if not vim.fn.has("autocmd") or vim.version().minor < 6 then
  return
end

vim.g.loaded_redact_pass = 1

local function check_args_redact()
  if vim.fn.argc() ~= 1 or vim.fn.fnamemodify(vim.fn.argv(0), ":p") ~= vim.fn.expand("<afile>:p") then
    return
  end

  vim.opt.backup = false
  vim.opt.writebackup = false
  vim.opt.swapfile = false
  vim.opt.viminfo = ""

  if vim.fn.has("persistent_undo") then
    vim.opt.undofile = false
  end

  vim.cmd("redraw")
  vim.cmd('echomsg "Editing password file--disabled leaky options!"')
  vim.g.redact_pass_redacted = 1
end

vim.api.nvim_create_augroup("redact_pass", { clear = true })

local redact_patterns = {
  "/dev/shm/pass.?*/?*.txt",
  os.getenv("TMPDIR") .. "/pass.?*/?*.txt",
  "/tmp/pass.?*/?*.txt",
}

for _, pattern in ipairs(redact_patterns) do
  vim.api.nvim_create_autocmd("VimEnter", {
    group = "redact_pass",
    pattern = pattern,
    callback = check_args_redact,
  })
end

if vim.fn.has("mac") then
  vim.api.nvim_create_autocmd("VimEnter", {
    group = "redact_pass",
    pattern = "/private/var/?*/pass.?*/?*.txt",
    callback = check_args_redact,
  })
end

-- ==============================================================================
-- Clipboard Integration via Socat
-- ==============================================================================

local yank_group = vim.api.nvim_create_augroup("SocatYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  pattern = "*",
  callback = function()
    local text = vim.fn.getreg('"')

    if text and text ~= "" then
      vim.fn.systemlist({ "socat", "-", "TCP:host.docker.internal:42134" }, text)
      vim.notify("Sent to socat", vim.log.levels.INFO, { title = "Yank" })
    end
  end,
})
