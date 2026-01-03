-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- ============================================================================
-- Markdown: Disable syntax concealment
-- ============================================================================
-- LazyVim sets conceallevel=2 which hides code fence delimiters (```).
-- This makes it difficult to see where code blocks start/end.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
  desc = "Disable conceal for markdown (show code fence backticks)",
})

-- ============================================================================
-- Claude Code Compatibility: Disable focus reporting (DECSET 1004)
-- ============================================================================
-- When nvim is spawned from claude-cli (Ctrl+G), it can re-enable focus
-- reporting when exiting, causing escape sequences [[O and [[I to appear.
-- See: https://github.com/anthropics/claude-code/issues/10375
--
-- NOTE: Only disable on VimLeave/VimSuspend, NOT on VimEnter.
-- Writing to /dev/tty on VimEnter corrupts Kitty's terminal input state.

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = augroup,
  callback = function()
    local tty = io.open("/dev/tty", "w")
    if tty then
      tty:write("\027[?1004l")
      tty:flush()
      tty:close()
    end
  end,
  desc = "Disable focus reporting on nvim exit/suspend",
})
