-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
--
-- ============================================================================
-- "OPTION 4" WORKFLOW: Oil + Picker + Yazi (No Sidebar)
-- ============================================================================
-- Philosophy: "If you know what you're looking for, fuzzy find it.
--              If you need to explore, Oil or Yazi is enough."
--
-- FINDING FILES (Picker - Snacks/Telescope/fzf):
--   <leader><space>  Find files (root)
--   <leader>ff       Find files (root)
--   <leader>fF       Find files (cwd)
--   <leader>fr       Recent files
--   <leader>fb       Buffers
--   <leader>/        Live grep (root)
--   <leader>sg       Live grep (root)
--   <leader>sG       Live grep (cwd)
--   <leader>sw       Grep word under cursor
--
-- FILE OPERATIONS (Oil):
--   -                Open parent directory (vim-vinegar style)
--   <leader>e        Open Oil at current file
--   <leader>E        Open Oil at cwd
--   <leader>fo       Open Oil in floating window
--
-- EXPLORATION (Yazi):
--   <leader>y        Open Yazi at current file
--   <leader>Y        Open Yazi at cwd
--   <C-Up>           Resume last Yazi session
--
-- ============================================================================

local map = vim.keymap.set

-- ============================================================================
-- QUICK ACCESS SHORTCUTS
-- ============================================================================

-- Alt+e for quick Oil access (faster than <leader>e)
map("n", "<A-e>", "<CMD>Oil<CR>", { desc = "Oil (quick)" })

-- Alt+y for quick Yazi access
map("n", "<A-y>", "<CMD>Yazi<CR>", { desc = "Yazi (quick)" })

-- ============================================================================
-- BUFFER NAVIGATION (complements the picker workflow)
-- ============================================================================
-- LazyVim defaults (no override needed):
--   <S-h>  Previous buffer
--   <S-l>  Next buffer
--   [b     Previous buffer
--   ]b     Next buffer

-- Close buffer without closing window
map("n", "<leader>bd", function()
  require("snacks").bufdelete()
end, { desc = "Delete buffer" })

-- ============================================================================
-- WINDOW NAVIGATION (standard but worth documenting)
-- ============================================================================

-- Quick splits
map("n", "<leader>-", "<C-W>s", { desc = "Split below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split right", remap = true })

-- ============================================================================
-- SEARCH ENHANCEMENTS
-- ============================================================================

-- Search in current buffer
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, { desc = "Buffer lines" })

-- Search in Oil directory (when in Oil buffer)
map("n", "<leader>so", function()
  local oil = require("oil")
  local dir = oil.get_current_dir()
  if dir then
    Snacks.picker.files({ cwd = dir })
  else
    Snacks.picker.files()
  end
end, { desc = "Find in Oil directory" })
