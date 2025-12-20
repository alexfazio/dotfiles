#!/bin/bash
# =============================================================================
# install.sh - Setup dotfiles on a new machine
# =============================================================================
# Usage:
#   ./install.sh              # Full install
#   ./install.sh --no-brew    # Skip Homebrew packages
#   ./install.sh --no-sync    # Skip auto-sync setup
# =============================================================================

set -e

DOTFILES_DIR="$HOME/.dotfiles"

# Parse args
SKIP_BREW=false
SKIP_SYNC=false
for arg in "$@"; do
    case $arg in
        --no-brew) SKIP_BREW=true ;;
        --no-sync) SKIP_SYNC=true ;;
    esac
done

echo "Setting up dotfiles..."

# =============================================================================
# CONFIG SYMLINKS
# =============================================================================

# Create config directories
mkdir -p ~/.config/{aerospace,ghostty,wezterm,yazi,nvim}

echo "Creating symlinks..."

# AeroSpace
ln -sf "$DOTFILES_DIR/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml

# Ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
ln -sf "$DOTFILES_DIR/ghostty/tmux-attach.sh" ~/.config/ghostty/tmux-attach.sh

# WezTerm
ln -sf "$DOTFILES_DIR/wezterm/wezterm.lua" ~/.config/wezterm/wezterm.lua

# Yazi
ln -sf "$DOTFILES_DIR/yazi/yazi.toml" ~/.config/yazi/yazi.toml
ln -sf "$DOTFILES_DIR/yazi/keymap.toml" ~/.config/yazi/keymap.toml
ln -sf "$DOTFILES_DIR/yazi/package.toml" ~/.config/yazi/package.toml
ln -sf "$DOTFILES_DIR/yazi/plugins" ~/.config/yazi/plugins

# Neovim
ln -sf "$DOTFILES_DIR/nvim/init.lua" ~/.config/nvim/init.lua
ln -sf "$DOTFILES_DIR/nvim/lazy-lock.json" ~/.config/nvim/lazy-lock.json
ln -sf "$DOTFILES_DIR/nvim/lazyvim.json" ~/.config/nvim/lazyvim.json
ln -sf "$DOTFILES_DIR/nvim/stylua.toml" ~/.config/nvim/stylua.toml
ln -sf "$DOTFILES_DIR/nvim/lua" ~/.config/nvim/lua

echo "Symlinks created."

# =============================================================================
# HOMEBREW
# =============================================================================

if [[ "$SKIP_BREW" == "false" ]] && command -v brew &> /dev/null; then
    echo "Installing Homebrew packages..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"

    # Install secret protection tools
    echo "Installing secret protection tools..."
    brew install gitleaks pre-commit 2>/dev/null || true
fi

# =============================================================================
# PRE-COMMIT HOOKS
# =============================================================================

if command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit hooks..."
    cd "$DOTFILES_DIR"
    pre-commit install
fi

# =============================================================================
# SECRETS TEMPLATE
# =============================================================================

if [[ ! -f ~/.secrets.env ]]; then
    echo "Creating secrets template..."
    cp "$DOTFILES_DIR/secrets.env.template" ~/.secrets.env
    echo "Edit ~/.secrets.env to add your API keys (gitignored, safe)"
fi

# =============================================================================
# AUTO-SYNC (LAUNCHD)
# =============================================================================

if [[ "$SKIP_SYNC" == "false" ]] && [[ "$(uname)" == "Darwin" ]]; then
    echo "Setting up auto-sync..."

    PLIST_NAME="com.dotfiles.autosync.plist"
    PLIST_SRC="$DOTFILES_DIR/scripts/$PLIST_NAME"
    PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME"

    # Unload if already loaded
    launchctl unload "$PLIST_DST" 2>/dev/null || true

    # Expand $HOME in plist and install
    mkdir -p ~/Library/LaunchAgents
    sed "s|\$HOME|$HOME|g" "$PLIST_SRC" > "$PLIST_DST"

    # Load the agent
    launchctl load "$PLIST_DST"

    echo "Auto-sync enabled (runs hourly)."
fi

# =============================================================================
# SHELL INTEGRATION
# =============================================================================

echo ""
echo "=== Optional: Add to your ~/.zshrc ==="
echo ""
echo '# Dotfiles status alias'
echo 'alias dfs="~/.dotfiles/scripts/sync-status.sh"'
echo ''
echo '# Load secrets (gitignored)'
echo '[ -f ~/.secrets.env ] && source ~/.secrets.env'
echo ''
echo '# Warn if dotfiles sync is stale'
echo '~/.dotfiles/scripts/sync-status.sh --check 2>/dev/null'
echo ""

# =============================================================================
# DONE
# =============================================================================

echo "Dotfiles installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.secrets.env with your API keys"
echo "  2. Add shell integration above to ~/.zshrc"
echo "  3. Run 'dfs' to check sync status"
