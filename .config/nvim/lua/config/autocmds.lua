-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup("UserAutocmds", { clear = true })

-- LazyVim sets conceallevel=2, which hides Markdown code fence delimiters.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
  desc = "Disable conceal for markdown",
})

-- Disable terminal focus reporting on exit/suspend so Claude Code shells do not
-- receive stray focus escape sequences after Neovim closes.
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
