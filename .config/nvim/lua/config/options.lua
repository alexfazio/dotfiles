-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Python provider - dedicated venv for Neovim plugins (pynvim)
vim.g.python3_host_prog = vim.fn.expand("~/.config/nvim/venv/bin/python")

-- Font configuration for GUI clients (Neovide, VimR, etc.)
vim.opt.guifont = "IosevkaTerm Nerd Font:h14"
