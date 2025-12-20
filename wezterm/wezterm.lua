local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- ========================================
-- Session Management: Using WezTerm's Built-in Workspaces
-- ========================================
-- Note: Resurrect plugin has bugs, using native workspace management instead
-- Workspaces persist automatically between sessions

-- 4-way split on startup (only on fresh mux start, not when reconnecting)
-- Check if mux already has windows to determine if this is a reconnection
wezterm.on('gui-startup', function(cmd)
  -- If mux already has windows, we're reconnecting to an existing session
  -- Skip creating new layout to preserve existing panes
  local windows = mux.all_windows()
  if #windows > 0 then
    return
  end

  -- Fresh mux start - create 4-way split layout
  local tab, pane, window = mux.spawn_window(cmd or {})

  -- Split horizontally (top/bottom)
  local bottom_pane = pane:split {
    direction = 'Bottom',
    size = 0.5,
  }

  -- Split top pane vertically (left/right)
  pane:split {
    direction = 'Right',
    size = 0.5,
  }

  -- Split bottom pane vertically (left/right)
  bottom_pane:split {
    direction = 'Right',
    size = 0.5,
  }
end)

-- Terminal configuration
-- Note: Removing term override to use WezTerm's optimized default terminal type
-- config.term = 'xterm-256color'

-- Key handling
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false
-- Enable CSI u encoding for better key handling support
config.enable_csi_u_key_encoding = true

-- Font configuration with fallbacks (JetBrains Mono Nerd Font - same as Ghostty default + icons)
config.font = wezterm.font_with_fallback({
  'JetBrainsMono NF',
  'JetBrains Mono',
  'Menlo',
  'Noto Color Emoji',
})
config.font_size = 18.0

-- Enable scrollback
config.scrollback_lines = 10000  -- Increase scrollback history

-- Scroll bar configuration
config.enable_scroll_bar = true
config.min_scroll_bar_height = "0.5cell"  -- Minimum height of scroll bar thumb (default)

-- Color scheme: Auto-switch between Catppuccin Frappe (dark) and Latte (light)
-- based on system appearance
local function scheme_for_appearance(appearance)
  if appearance:find('Dark') then
    return 'Catppuccin Frappe'
  else
    return 'Catppuccin Latte'
  end
end

-- Safely get appearance (wezterm.gui is not available to mux server)
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark' -- Default to dark when running as mux server
end

-- Set initial color scheme based on current system appearance
config.color_scheme = scheme_for_appearance(get_appearance())

-- Automatically switch theme when system appearance changes
wezterm.on('window-config-reloaded', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

-- Tab bar appearance and customization
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.tab_max_width = 32  -- Prevent excessively long tab titles
config.use_fancy_tab_bar = true  -- Enable the fancy tab bar with better styling
config.window_frame = {
  font_size = 14.0,  -- Larger tab bar font (default is 12pt on macOS)
}

-- Window appearance
config.window_background_opacity = 1.0

-- Enable support for unicode characters
config.warn_about_missing_glyphs = false

-- Scrolling and performance optimization
config.alternate_buffer_wheel_scroll_speed = 5  -- Smooth scrolling in alternate buffers
config.animation_fps = 120  -- Smooth animations
config.max_fps = 120  -- Higher FPS for TUI responsiveness

-- Default shell and startup behavior
config.default_prog = { '/bin/zsh' }  -- Use zsh as default shell
config.initial_cols = 160  -- Initial window width
config.initial_rows = 40   -- Initial window height

-- ========================================
-- Pane Persistence: Keep panes open after process exits
-- ========================================
-- "Hold" keeps panes open for inspection after shell/process exits
-- Alternatives: "Close" (immediate), "CloseOnCleanExit" (only on success)
config.exit_behavior = "Hold"

-- ========================================
-- Session Persistence: Multiplexer Daemon
-- ========================================
-- Enable WezTerm's built-in multiplexer for true session persistence
-- This keeps your panes, tabs, and workspaces alive even when you close WezTerm
config.unix_domains = {
  {
    name = 'unix',
  },
}

-- Automatically connect to the multiplexer daemon on startup
-- If the daemon isn't running, WezTerm will start it automatically
config.default_gui_startup_args = { 'connect', 'unix' }

-- Bell sound settings
config.audible_bell = "Disabled"

-- Copy on select
config.selection_word_boundary = " \t\n{}[]()\"'`,;:"

-- Mouse and interaction settings
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom('Clipboard'),  -- Right-click to paste
  },
}

-- Hyperlink handling for better URL support
config.check_for_updates = false  -- Disable auto-update checks

-- Vi-style copy mode configuration
config.key_tables = {
  copy_mode = {
    {key = 'Tab', mods = 'NONE', action = act.CopyMode('MoveForwardWord')},
    {key = 'Tab', mods = 'SHIFT', action = act.CopyMode('MoveBackwardWord')},
    {key = 'Enter', mods = 'NONE', action = act.CopyMode('MoveToStartOfNextLine')},
    {key = 'Escape', mods = 'NONE', action = act.CopyMode('Close')},
    {key = 'Space', mods = 'NONE', action = act.CopyMode({SetSelectionMode = 'Cell'})},
    {key = '$', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent')},
    {key = '$', mods = 'SHIFT', action = act.CopyMode('MoveToEndOfLineContent')},
    {key = ',', mods = 'NONE', action = act.CopyMode('JumpReverse')},
    {key = '0', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine')},
    {key = ';', mods = 'NONE', action = act.CopyMode('JumpAgain')},
    {key = 'F', mods = 'NONE', action = act.CopyMode({JumpBackward = {prev_char = false}})},
    {key = 'F', mods = 'SHIFT', action = act.CopyMode({JumpBackward = {prev_char = false}})},
    {key = 'G', mods = 'NONE', action = act.CopyMode('MoveToScrollbackBottom')},
    {key = 'G', mods = 'SHIFT', action = act.CopyMode('MoveToScrollbackBottom')},
    {key = 'H', mods = 'NONE', action = act.CopyMode('MoveToViewportTop')},
    {key = 'H', mods = 'SHIFT', action = act.CopyMode('MoveToViewportTop')},
    {key = 'L', mods = 'NONE', action = act.CopyMode('MoveToViewportBottom')},
    {key = 'L', mods = 'SHIFT', action = act.CopyMode('MoveToViewportBottom')},
    {key = 'M', mods = 'NONE', action = act.CopyMode('MoveToViewportMiddle')},
    {key = 'M', mods = 'SHIFT', action = act.CopyMode('MoveToViewportMiddle')},
    {key = 'O', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEndHoriz')},
    {key = 'O', mods = 'SHIFT', action = act.CopyMode('MoveToSelectionOtherEndHoriz')},
    {key = 'T', mods = 'NONE', action = act.CopyMode({JumpBackward = {prev_char = true}})},
    {key = 'T', mods = 'SHIFT', action = act.CopyMode({JumpBackward = {prev_char = true}})},
    {key = 'V', mods = 'NONE', action = act.CopyMode({SetSelectionMode = 'Line'})},
    {key = 'V', mods = 'SHIFT', action = act.CopyMode({SetSelectionMode = 'Line'})},
    {key = '^', mods = 'NONE', action = act.CopyMode('MoveToStartOfLineContent')},
    {key = '^', mods = 'SHIFT', action = act.CopyMode('MoveToStartOfLineContent')},
    {key = 'b', mods = 'NONE', action = act.CopyMode('MoveBackwardWord')},
    {key = 'b', mods = 'ALT', action = act.CopyMode('MoveBackwardWord')},
    {key = 'b', mods = 'CTRL', action = act.CopyMode('PageUp')},
    {key = 'c', mods = 'CTRL', action = act.CopyMode('Close')},
    {key = 'd', mods = 'CTRL', action = act.CopyMode({MoveByPage = (0.5)})},
    {key = 'e', mods = 'NONE', action = act.CopyMode('MoveForwardWordEnd')},
    {key = 'f', mods = 'NONE', action = act.CopyMode({JumpForward = {prev_char = false}})},
    {key = 'f', mods = 'ALT', action = act.CopyMode('MoveForwardWord')},
    {key = 'f', mods = 'CTRL', action = act.CopyMode('PageDown')},
    {key = 'g', mods = 'NONE', action = act.CopyMode('MoveToScrollbackTop')},
    {key = 'g', mods = 'CTRL', action = act.CopyMode('Close')},
    {key = 'h', mods = 'NONE', action = act.CopyMode('MoveLeft')},
    {key = 'j', mods = 'NONE', action = act.CopyMode('MoveDown')},
    {key = 'k', mods = 'NONE', action = act.CopyMode('MoveUp')},
    {key = 'l', mods = 'NONE', action = act.CopyMode('MoveRight')},
    {key = 'm', mods = 'ALT', action = act.CopyMode('MoveToStartOfLineContent')},
    {key = 'o', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEnd')},
    {key = 'q', mods = 'NONE', action = act.CopyMode('Close')},
    {key = 't', mods = 'NONE', action = act.CopyMode({JumpForward = {prev_char = true}})},
    {key = 'u', mods = 'CTRL', action = act.CopyMode({MoveByPage = (-0.5)})},
    {key = 'v', mods = 'NONE', action = act.CopyMode({SetSelectionMode = 'Cell'})},
    {key = 'v', mods = 'CTRL', action = act.CopyMode({SetSelectionMode = 'Block'})},
    {key = 'w', mods = 'NONE', action = act.CopyMode('MoveForwardWord')},
    {key = 'y', mods = 'NONE', action = act.Multiple({{CopyTo = 'ClipboardAndPrimarySelection'}, {CopyMode = 'Close'}})},
    {key = 'PageUp', mods = 'NONE', action = act.CopyMode('PageUp')},
    {key = 'PageDown', mods = 'NONE', action = act.CopyMode('PageDown')},
    {key = 'End', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent')},
    {key = 'Home', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine')},
    {key = 'LeftArrow', mods = 'NONE', action = act.CopyMode('MoveLeft')},
    {key = 'LeftArrow', mods = 'ALT', action = act.CopyMode('MoveBackwardWord')},
    {key = 'RightArrow', mods = 'NONE', action = act.CopyMode('MoveRight')},
    {key = 'RightArrow', mods = 'ALT', action = act.CopyMode('MoveForwardWord')},
    {key = 'UpArrow', mods = 'NONE', action = act.CopyMode('MoveUp')},
    {key = 'DownArrow', mods = 'NONE', action = act.CopyMode('MoveDown')},
  }
}

-- Leader key and keybindings configuration
-- Leader: CMD+Space (macOS-native, avoids Neovim conflicts, timeout after 1000ms)
config.leader = {key = 'Space', mods = 'CMD', timeout_milliseconds = 1000}

config.keys = {
  -- ========================================
  -- Copy Mode
  -- ========================================
  {mods = 'LEADER', key = '[', action = act.ActivateCopyMode},

  -- ========================================
  -- Pane Navigation (vim-style hjkl)
  -- ========================================
  -- Direct navigation with CMD+hjkl (sends ESC first to exit insert mode)
  {key = 'h', mods = 'CMD', action = act.Multiple { act.SendKey { key = 'Escape' }, act.ActivatePaneDirection('Left') }},
  {key = 'j', mods = 'CMD', action = act.Multiple { act.SendKey { key = 'Escape' }, act.ActivatePaneDirection('Down') }},
  {key = 'k', mods = 'CMD', action = act.Multiple { act.SendKey { key = 'Escape' }, act.ActivatePaneDirection('Up') }},
  {key = 'l', mods = 'CMD', action = act.Multiple { act.SendKey { key = 'Escape' }, act.ActivatePaneDirection('Right') }},

  -- ========================================
  -- Pane Resizing (Shift + hjkl)
  -- ========================================
  {mods = 'LEADER|SHIFT', key = 'H', action = act.AdjustPaneSize({'Left', 5})},
  {mods = 'LEADER|SHIFT', key = 'J', action = act.AdjustPaneSize({'Down', 5})},
  {mods = 'LEADER|SHIFT', key = 'K', action = act.AdjustPaneSize({'Up', 5})},
  {mods = 'LEADER|SHIFT', key = 'L', action = act.AdjustPaneSize({'Right', 5})},

  -- ========================================
  -- Pane Splitting
  -- ========================================
  -- Tmux-style splits
  {mods = 'LEADER', key = '-', action = act.SplitPane {direction = 'Down', size = {Percent = 50}}},
  {mods = 'LEADER', key = '|', action = act.SplitPane {direction = 'Right', size = {Percent = 50}}},

  -- Vim-style splits
  {mods = 'LEADER', key = 'v', action = act.SplitPane {direction = 'Right', size = {Percent = 50}}},  -- Like :vsplit
  {mods = 'LEADER', key = 's', action = act.SplitPane {direction = 'Down', size = {Percent = 50}}},   -- Like :split

  -- ========================================
  -- Pane Management
  -- ========================================
  {mods = 'LEADER', key = 'x', action = act.CloseCurrentPane({confirm = true})},
  {mods = 'LEADER', key = 'q', action = act.CloseCurrentPane({confirm = true})},  -- Like :q in vim
  {key = 'w', mods = 'CMD', action = act.CloseCurrentPane({confirm = true})},  -- Close pane (override default tab close)
  {key = 'w', mods = 'CMD|SHIFT', action = act.CloseCurrentTab({confirm = true})},  -- Close entire tab
  {mods = 'LEADER', key = 'z', action = act.TogglePaneZoomState},

  -- ========================================
  -- Workspace Management (Built-in WezTerm Features)
  -- ========================================
  -- Show workspace switcher (fuzzy find all workspaces)
  {mods = 'ALT', key = 'w', action = act.ShowLauncherArgs({flags = 'FUZZY|WORKSPACES'})},

  -- Create/switch to named workspace
  {mods = 'ALT|SHIFT', key = 'N', action = act.PromptInputLine({
    description = 'Enter new workspace name:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:perform_action(act.SwitchToWorkspace({name = line}), pane)
      end
    end),
  })},

  -- Rename current workspace
  {mods = 'ALT|SHIFT', key = 'R', action = act.PromptInputLine({
    description = 'Rename workspace to:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        mux.rename_workspace(mux.get_active_workspace(), line)
      end
    end),
  })},
}

return config
