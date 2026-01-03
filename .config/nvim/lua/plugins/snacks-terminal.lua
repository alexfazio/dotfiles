-- Snacks Terminal Configuration
-- Configure the terminal to open as a floating window
-- Triggered with <C-/> (Ctrl+/)

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          position = "float",
        },
      },
    },
  },
}
