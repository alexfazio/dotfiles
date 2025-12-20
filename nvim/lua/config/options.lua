-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- ============================================================================
-- FIX: Disable syntax concealment for markdown files
-- ============================================================================
-- LazyVim sets conceallevel=2 which hides code fence delimiters (```).
-- This makes it difficult to see where code blocks start/end.
-- Setting conceallevel=0 shows all characters as-is.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
  desc = "Disable conceal for markdown (show code fence backticks)",
})

-- Font configuration for GUI clients (Neovide, VimR, etc.)
vim.opt.guifont = "Berkeley Mono:h14"

-- ============================================================================
-- FIX: Disable terminal focus reporting (DECSET 1004)
-- ============================================================================
-- When nvim is spawned from claude-cli (Ctrl+G), it can re-enable focus
-- reporting when exiting, causing escape sequences [[O and [[I to appear.
-- This is a known bug in claude-code (issues #9137, #9218, #10375).
-- These autocmds ensure focus reporting stays disabled.

vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, {
  callback = function()
    -- Write directly to the controlling terminal
    local tty = io.open("/dev/tty", "w")
    if tty then
      tty:write("\027[?1004l")
      tty:flush()
      tty:close()
    end
  end,
  desc = "Disable focus reporting on nvim start/resume",
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  callback = function()
    -- Write directly to the controlling terminal
    local tty = io.open("/dev/tty", "w")
    if tty then
      tty:write("\027[?1004l")
      tty:flush()
      tty:close()
    end
  end,
  desc = "Disable focus reporting on nvim exit/suspend",
})
