#!/bin/bash
# install.sh - Setup dotfiles on a new machine

set -e

DOTFILES_DIR="$HOME/.dotfiles"

echo "Setting up dotfiles..."

# Create config directories
mkdir -p ~/.config/{aerospace,ghostty,wezterm,yazi,nvim}

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

# Install brew packages
if command -v brew &> /dev/null; then
    echo "Installing Homebrew packages..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
fi

echo "Dotfiles installed successfully!"
