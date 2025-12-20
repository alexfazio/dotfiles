-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- FIX: Disable focus reporting (DECSET 1004) when leaving nvim
-- Prevents [I[O escape sequences from leaking into claude-code after Ctrl+G editing
-- See: https://github.com/anthropics/claude-code/issues/10375
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    local tty = io.open("/dev/tty", "w")
    if tty then
      tty:write("\027[?1004l")
      tty:flush()
      tty:close()
    end
  end,
  desc = "Disable focus reporting on nvim exit for claude-code compatibility",
})
