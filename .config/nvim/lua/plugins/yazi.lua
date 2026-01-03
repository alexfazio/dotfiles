-- Yazi.nvim - Terminal file manager for exploration
-- Part of the "Option 4" workflow: Oil + Picker + Yazi (no sidebar)

return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      -- Primary Yazi keybinding - floating exploration
      {
        "<leader>y",
        "<cmd>Yazi<cr>",
        desc = "Yazi (current file)",
      },
      {
        "<leader>Y",
        "<cmd>Yazi cwd<cr>",
        desc = "Yazi (cwd)",
      },
      {
        "<leader>fy",
        "<cmd>Yazi<cr>",
        desc = "Yazi (current file)",
      },
      -- Resume last Yazi session
      {
        "<c-up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume last Yazi session",
      },
    },
    ---@type YaziConfig
    opts = {
      -- Open yazi instead of netrw when opening directories
      -- Set to false since Oil handles this
      open_for_directories = false,

      -- Floating window settings
      floating_window_scaling_factor = 0.9,
      yazi_floating_window_winblend = 0,
      yazi_floating_window_border = "rounded",

      -- Keymaps inside Yazi
      keymaps = {
        show_help = "<f1>",
        open_file_in_vertical_split = "<c-v>",
        open_file_in_horizontal_split = "<c-x>",
        open_file_in_tab = "<c-t>",
        grep_in_directory = "<c-s>",
        replace_in_directory = "<c-g>",
        cycle_open_buffers = "<tab>",
        copy_relative_path_to_selected_files = "<c-y>",
        send_to_quickfix_list = "<c-q>",
        change_working_directory = "<c-\\>",
      },

      -- Hooks
      hooks = {
        yazi_opened = function(preselected_path, yazi_buffer_id, config)
          -- Optional: do something when yazi opens
        end,
        yazi_closed_successfully = function(chosen_file, config, state)
          -- Optional: do something when yazi closes
        end,
      },
    },
  },
}
