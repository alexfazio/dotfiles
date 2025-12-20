# Dotfiles

Personal dotfiles for macOS, managed with traditional symlinks and automated sync.

## What's Included

| Application | Config Location | Description |
|-------------|-----------------|-------------|
| **AeroSpace** | `aerospace/` | Tiling window manager for macOS |
| **Ghostty** | `ghostty/` | GPU-accelerated terminal emulator |
| **WezTerm** | `wezterm/` | Cross-platform terminal emulator |
| **Yazi** | `yazi/` | Terminal file manager |
| **Neovim** | `nvim/` | LazyVim-based Neovim configuration |
| **Zsh** | `zsh/` | Shell configuration with aliases and functions |
| **Homebrew** | `Brewfile` | All installed packages and casks |

## Quick Start

### On a New Machine

```bash
# Clone the repo
git clone https://github.com/alexfazio/dotfiles.git ~/.dotfiles

# Run install script
cd ~/.dotfiles && ./install.sh
```

### What `install.sh` Does

1. Creates symlinks from `~/.config/*` to `~/.dotfiles/*`
2. Installs Homebrew packages from Brewfile
3. Installs gitleaks and pre-commit for secret protection
4. Sets up hourly auto-sync via launchd
5. Creates `~/.secrets.env` from template

## Architecture

### Symlink Structure

Files live in `~/.dotfiles/` and are symlinked to their expected locations:

```
~/.dotfiles/aerospace/aerospace.toml  →  ~/.config/aerospace/aerospace.toml
~/.dotfiles/ghostty/config            →  ~/.config/ghostty/config
~/.dotfiles/wezterm/wezterm.lua       →  ~/.config/wezterm/wezterm.lua
~/.dotfiles/yazi/*.toml               →  ~/.config/yazi/*.toml
~/.dotfiles/nvim/*                    →  ~/.config/nvim/*
~/.dotfiles/zsh/.zshrc                →  ~/.zshrc
```

### Why Symlinks?

- **Industry standard**: Used by most dotfiles repos
- **Git tracks actual content**: Not just symlink paths
- **Simple to understand**: No magic, just file links
- **Works everywhere**: No special tools required

Alternative approaches considered and rejected:
- **Reverse symlinks** (repo contains symlinks pointing to ~/.config): Git stores symlink paths, not file contents
- **Git submodules**: Unnecessary complexity for personal configs (5-6 repos to manage)

## Secret Protection

Three layers prevent accidental secret commits:

### 1. Pre-commit Hook (gitleaks)

Scans staged files for API keys, tokens, and credentials before every commit.

```bash
# Manual scan
cd ~/.dotfiles && gitleaks detect --source .

# Run all pre-commit hooks
pre-commit run --all-files
```

### 2. Comprehensive .gitignore

Blocks 30+ sensitive file patterns:
- `*.env`, `.env.*` (except templates)
- `credentials.json`, `*.credentials`
- `id_rsa`, `id_ed25519`, `*.key`
- `.aws/credentials`, `*.tfvars`
- And many more...

### 3. Secrets Template System

API keys go in `~/.secrets.env` (gitignored), not in dotfiles:

```bash
# Copy template (done by install.sh)
cp ~/.dotfiles/secrets.env.template ~/.secrets.env

# Edit with your actual keys
vim ~/.secrets.env

# Source in your shell (add to ~/.zshrc)
[ -f ~/.secrets.env ] && source ~/.secrets.env
```

## Auto-Sync System

Dotfiles sync automatically every hour without manual commits.

### How It Works

1. **launchd agent** triggers `auto-sync.sh` hourly
2. **Brewfile** is regenerated to capture new packages
3. **gitleaks** scans for secrets before staging
4. **pre-commit hooks** run before commit
5. **Changes are committed and pushed** to GitHub
6. **macOS notification** alerts you if anything fails

### Monitoring

```bash
# Check sync status (add alias: dfs)
~/.dotfiles/scripts/sync-status.sh

# Output example:
# === Dotfiles Sync Status ===
# Status: OK
# Last sync: 2025-12-20 13:45:35
# Message: Synced ff7d92c
```

### Shell Integration

The `.zshrc` is managed by this repo and includes:
- `dfs` alias for checking sync status
- Auto-loading of `~/.secrets.env` (gitignored)
- Startup warning if sync is stale (>24 hours)

### Manual Sync

```bash
# Run sync manually
~/.dotfiles/scripts/auto-sync.sh

# Force sync (skip secret scan - not recommended)
~/.dotfiles/scripts/auto-sync.sh --force
```

### Launchd Management

```bash
# Check if agent is running
launchctl list | grep dotfiles

# Reload agent
launchctl unload ~/Library/LaunchAgents/com.dotfiles.autosync.plist
launchctl load ~/Library/LaunchAgents/com.dotfiles.autosync.plist

# View sync logs
cat /tmp/dotfiles-sync.stdout.log
cat /tmp/dotfiles-sync.stderr.log
```

## Backup & Rollback

### Automatic Backup

Before first install, a timestamped backup is created:

```bash
~/.dotfiles-backup-YYYYMMDD_HHMMSS/
├── aerospace/
├── ghostty/
├── wezterm/
├── yazi/
└── nvim/
```

### Rollback

If something goes wrong:

```bash
# Restore all configs from backup
~/.dotfiles/rollback.sh

# This removes symlinks and restores original files
```

### Cleanup After Successful Setup

Once everything works:

```bash
BACKUP_DIR=$(cat ~/.dotfiles-backup-location)
rm -rf "$BACKUP_DIR" ~/.dotfiles-backup-location
```

## File Reference

```
~/.dotfiles/
├── aerospace/
│   └── aerospace.toml          # Window manager config
├── ghostty/
│   ├── config                  # Terminal config
│   └── tmux-attach.sh          # Tmux integration script
├── wezterm/
│   └── wezterm.lua             # Terminal config (Lua)
├── yazi/
│   ├── yazi.toml               # File manager config
│   ├── keymap.toml             # Keybindings
│   ├── package.toml            # Plugin packages
│   └── plugins/                # Installed plugins
├── nvim/
│   ├── init.lua                # Neovim entry point
│   ├── lazy-lock.json          # Plugin lockfile
│   ├── lazyvim.json            # LazyVim config
│   ├── stylua.toml             # Lua formatter config
│   └── lua/                    # Lua config modules
├── zsh/
│   └── .zshrc                  # Shell config (aliases, functions, PATH)
├── scripts/
│   ├── auto-sync.sh            # Automated sync with secret scanning
│   ├── sync-status.sh          # Health monitoring
│   └── com.dotfiles.autosync.plist  # launchd agent
├── Brewfile                    # Homebrew packages (auto-updated)
├── install.sh                  # New machine setup
├── rollback.sh                 # Restore from backup
├── secrets.env.template        # API key template
├── .pre-commit-config.yaml     # Pre-commit hook config
├── .gitleaks.toml              # Secret scanner allowlist
└── .gitignore                  # Sensitive file patterns
```

## Adding New Configs

To add a new application's config:

1. **Move config to dotfiles**:
   ```bash
   mv ~/.config/newapp ~/.dotfiles/newapp
   ```

2. **Create symlink**:
   ```bash
   ln -sf ~/.dotfiles/newapp ~/.config/newapp
   ```

3. **Update install.sh** to create the symlink on new machines

4. **Commit**:
   ```bash
   cd ~/.dotfiles && git add -A && git commit -m "Add newapp config"
   ```

   Or just wait for auto-sync.

## Troubleshooting

### Sync Not Running

```bash
# Check if launchd agent is loaded
launchctl list | grep dotfiles

# If not loaded, reload it
launchctl load ~/Library/LaunchAgents/com.dotfiles.autosync.plist
```

### Secret Detected (Commit Blocked)

```bash
# See what was detected
cd ~/.dotfiles && gitleaks detect --source . --verbose

# If false positive, add to .gitleaks.toml allowlist
# If real secret, remove it and add pattern to .gitignore
```

### Symlink Broken

```bash
# Re-run install script
cd ~/.dotfiles && ./install.sh
```

### Need to Restore Original Configs

```bash
~/.dotfiles/rollback.sh
```

## License

MIT
