-- Snacks Explorer Configuration with Yazi-inspired keybindings
-- This configures the file explorer to match Yazi's navigation patterns
-- while avoiding conflicts with LazyVim's global keybindings

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            -- Explorer window configuration
            win = {
              list = {
                keys = {
                  -- ============================================================
                  -- SELECTION (Yazi-aligned)
                  -- ============================================================
                  -- Use Space for toggling selection (Yazi-style)
                  -- Note: Tab is the default, we're changing it to Space
                  ["<Space>"] = "<Tab>", -- Maps Space to the default toggle action

                  -- ============================================================
                  -- FILE OPERATIONS (Yazi-aligned)
                  -- ============================================================
                  -- Add 'y' as alias for copy (Yazi uses 'y' for yank/copy)
                  ["y"] = "c", -- Map 'y' to copy action (default is 'c')

                  -- Add 'x' for cut (Yazi-style)
                  -- Note: Snacks uses 'm' for move, which is similar to cut
                  ["x"] = "m", -- Map 'x' to move action

                  -- Y - Copy file path to clipboard (custom action)
                  ["Y"] = "copy_path",

                  -- Keep all other default bindings as they align with Yazi:
                  -- c - copy (keep as alternative to 'y')
                  -- p - paste (already aligned)
                  -- d - delete (already aligned)
                  -- r - rename (already aligned)
                  -- a - add/create (already aligned)
                  -- o - open with system (already aligned)
                  -- l/<CR> - open file or enter directory (already aligned)
                  -- h - close directory (already aligned)
                  -- <BS> - go to parent directory (already aligned)

                  -- ============================================================
                  -- TOGGLE FEATURES (Keep Snacks defaults)
                  -- ============================================================
                  -- H - toggle hidden (already aligned with Yazi concept)
                  -- I - toggle ignored files
                  -- P - toggle preview
                  -- Z - close all directories

                  -- ============================================================
                  -- OTHER ALIGNMENTS
                  -- ============================================================
                  -- u - refresh (Snacks default, close to Yazi's concept)
                  -- / - search (already aligned)
                  -- . - set as cwd (Snacks default, different from Yazi but useful)

                  -- ============================================================
                  -- Note: Advanced navigation (gg, G, <C-u>, <C-d>, etc.)
                  -- These work by default in Vim/Neovim for list navigation
                  -- ============================================================
                },
              },
            },
            -- Custom actions
            actions = {
              copy_path = {
                action = function(picker, item)
                  -- Get the file path
                  local path = item.file
                  if path then
                    -- Copy to system clipboard
                    vim.fn.setreg("+", path)
                    -- Also copy to unnamed register
                    vim.fn.setreg('"', path)
                    -- Show notification
                    Snacks.notify.info("Copied path: " .. path)
                  end
                end,
              },
            },
          },
        },
      },
    },
  },
}
