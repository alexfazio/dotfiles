-- Oil.nvim - Edit your filesystem like a buffer
-- Replaces Snacks Explorer with a more vim-native approach

return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      -- Oil takes over directory buffers (replaces netrw)
      default_file_explorer = true,

      -- Columns to display
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },

      -- Buffer options for oil buffers
      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },

      -- Window options
      win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },

      -- Delete to trash instead of permanent deletion (safer)
      delete_to_trash = true,

      -- Skip confirmation for simple operations (rename single file, etc.)
      skip_confirm_for_simple_edits = true,

      -- Prompt to save before selecting new file
      prompt_save_on_select_new_entry = true,

      -- Cleanup hidden oil buffers after 2 seconds
      cleanup_delay_ms = 2000,

      -- LSP integration for file renames
      lsp_file_methods = {
        enabled = true,
        timeout_ms = 1000,
        autosave_changes = "unmodified",
      },

      -- Keep cursor on file names
      constrain_cursor = "editable",

      -- Watch filesystem for external changes
      watch_for_changes = true,

      -- Keymaps - aligned with Yazi preferences
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["l"] = "actions.select", -- Yazi-style: l to enter
        ["<C-s>"] = { "actions.select", opts = { vertical = true } },
        ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["q"] = { "actions.close", mode = "n" },
        ["<C-r>"] = "actions.refresh", -- Changed from <C-l> to preserve window navigation
        ["-"] = { "actions.parent", mode = "n" },
        ["h"] = { "actions.parent", mode = "n" }, -- Yazi-style: h to go up
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["H"] = { "actions.toggle_hidden", mode = "n" }, -- Yazi-style toggle hidden
        ["g\\"] = { "actions.toggle_trash", mode = "n" },

        -- Copy path to clipboard (like Snacks 'Y' binding)
        ["Y"] = {
          desc = "Copy file path to clipboard",
          callback = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if entry and dir then
              local path = dir .. entry.name
              vim.fn.setreg("+", path)
              vim.fn.setreg('"', path)
              vim.notify("Copied: " .. path, vim.log.levels.INFO)
            end
          end,
        },

        -- Yank relative path
        ["y"] = {
          desc = "Copy relative path to clipboard",
          callback = function()
            local oil = require("oil")
            local entry = oil.get_cursor_entry()
            if entry then
              local path = entry.name
              vim.fn.setreg("+", path)
              vim.fn.setreg('"', path)
              vim.notify("Copied: " .. path, vim.log.levels.INFO)
            end
          end,
        },
      },

      use_default_keymaps = true,

      view_options = {
        -- Show hidden files by default (toggle with H or g.)
        show_hidden = false,
        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, ".")
        end,
        is_always_hidden = function(name, bufnr)
          -- Hide .DS_Store and similar
          return name == ".DS_Store" or name == ".git"
        end,
        natural_order = "fast",
        case_insensitive = false,
        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },

      -- Floating window configuration
      float = {
        padding = 2,
        max_width = 0.8,
        max_height = 0.8,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },

      -- Preview window configuration
      preview_win = {
        update_on_cursor_moved = true,
      },

      -- SSH configuration
      extra_scp_args = {},

      -- Git integration (experimental)
      git = {
        add = function(path)
          return false
        end,
        mv = function(src_path, dest_path)
          return false
        end,
        rm = function(path)
          return false
        end,
      },

      -- Confirmation dialog settings
      confirmation = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },

      -- Progress window
      progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        border = "rounded",
        minimized_border = "none",
        win_options = {
          winblend = 0,
        },
      },
    },

    dependencies = {
      { "nvim-mini/mini.icons", opts = {} },
    },

    -- Don't lazy load - Oil needs to handle directory buffers immediately
    lazy = false,

    -- Global keymaps
    keys = {
      -- Primary: Open parent directory of current file (vim-vinegar style)
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },

      -- LazyVim-style explorer bindings (replacing Snacks Explorer)
      { "<leader>e", "<CMD>Oil<CR>", desc = "Explorer Oil (current file)" },
      { "<leader>E", "<CMD>Oil .<CR>", desc = "Explorer Oil (cwd)" },
      { "<leader>fe", "<CMD>Oil<CR>", desc = "Explorer Oil (current file)" },
      { "<leader>fE", "<CMD>Oil .<CR>", desc = "Explorer Oil (cwd)" },

      -- Floating window variant
      {
        "<leader>fo",
        function()
          require("oil").open_float()
        end,
        desc = "Oil (float)",
      },
    },
  },

  -- Disable neo-tree if it's enabled
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },
}
