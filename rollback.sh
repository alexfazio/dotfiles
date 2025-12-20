#!/bin/bash
# rollback.sh - Restore configs from backup

set -e

if [ ! -f ~/.dotfiles-backup-location ]; then
    echo "Error: No backup location found. Cannot rollback."
    exit 1
fi

BACKUP_DIR=$(cat ~/.dotfiles-backup-location)

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory $BACKUP_DIR does not exist."
    exit 1
fi

echo "Restoring from: $BACKUP_DIR"

# Remove symlinks and dotfiles
rm -rf ~/.dotfiles
rm -f ~/.config/aerospace/aerospace.toml
rm -f ~/.config/ghostty/config ~/.config/ghostty/tmux-attach.sh
rm -f ~/.config/wezterm/wezterm.lua
rm -f ~/.config/yazi/yazi.toml ~/.config/yazi/keymap.toml ~/.config/yazi/package.toml
rm -rf ~/.config/yazi/plugins
rm -f ~/.config/nvim/init.lua ~/.config/nvim/lazy-lock.json ~/.config/nvim/lazyvim.json ~/.config/nvim/stylua.toml
rm -rf ~/.config/nvim/lua

# Restore from backup
cp -R "$BACKUP_DIR/aerospace/"* ~/.config/aerospace/
cp -R "$BACKUP_DIR/ghostty/"* ~/.config/ghostty/
cp -R "$BACKUP_DIR/wezterm/"* ~/.config/wezterm/
cp -R "$BACKUP_DIR/yazi/"* ~/.config/yazi/
cp -R "$BACKUP_DIR/nvim/"* ~/.config/nvim/

echo "Rollback complete! Configs restored from $BACKUP_DIR"
echo "You can delete the backup with: rm -rf $BACKUP_DIR ~/.dotfiles-backup-location"
