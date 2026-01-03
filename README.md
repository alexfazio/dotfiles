# Dotfiles

Personal dotfiles managed with [yadm](https://yadm.io) (Yet Another Dotfiles Manager).

## What's Included

| Application | Config Location | Description |
|-------------|-----------------|-------------|
| **Zsh** | `.zshrc##*` | Shell config with vi mode, aliases, PATH setup |
| **Neovim** | `.config/nvim/` | LazyVim-based config with custom plugins |
| **Aerospace** | `.config/aerospace/` | Tiling window manager for macOS |
| **Ghostty** | `.config/ghostty/` | GPU-accelerated terminal emulator |
| **Kitty** | `.config/kitty/` | Alternative terminal with splits |
| **WezTerm** | `.config/wezterm/` | Cross-platform terminal in Lua |
| **Yazi** | `.config/yazi/` | Terminal file manager with plugins |
| **GPG Agent** | `.gnupg/gpg-agent.conf` | Passphrase caching config |

---

## For Me (Alex)

### On Primary Machine (Alex-MBP)

#### Daily Workflow

```bash
# Check status
dfs                        # alias for: yadm status

# After editing configs
yadm add -u                # stage tracked file changes
yadm commit -m "message"
yadm push
```

#### Adding New Files

```bash
yadm add ~/.config/newapp/config.toml
yadm commit -m "Add newapp config"
yadm push
```

#### After Adding/Changing Secrets

```bash
# Re-encrypt and push
yadm encrypt
yadm add ~/.local/share/yadm/archive
yadm commit -m "Update encrypted secrets"
yadm push
```

#### Current Encrypted Files

- SSH private keys (`~/.ssh/id_*`)
- GPG private keys (`~/.gnupg/private-keys-v1.d/*`)
- GitHub CLI auth (`~/.config/gh/hosts.yml`)
- Environment secrets (`~/.secrets.env` - if created)

### On Secondary Machines

#### Initial Setup

```bash
# Install yadm
brew install yadm

# Clone and bootstrap (sets up pull-only mode automatically)
yadm clone --bootstrap https://github.com/alexfazio/dotfiles.git

# Decrypt secrets (requires GPG passphrase)
yadm decrypt
```

#### Pulling Updates

```bash
yadm pull
yadm decrypt   # if secrets were updated
```

#### If You Need to Push from Secondary

```bash
# Enable push (use sparingly)
yadm remote set-url --push origin https://github.com/alexfazio/dotfiles.git

# After pushing, consider disabling again
yadm remote set-url --push origin no_push
```

---

## For Public Users

Want to use these dotfiles as a starting point? Here's how.

### Option 1: Fork and Customize (Recommended)

1. **Fork this repo** on GitHub

2. **Remove my secrets and identity:**
   ```bash
   # Clone your fork
   yadm clone --bootstrap https://github.com/YOUR_USERNAME/dotfiles.git

   # Remove my encrypted archive (you can't decrypt it)
   yadm rm .local/share/yadm/archive
   yadm commit -m "Remove original encrypted secrets"
   ```

3. **Create your own alternates:**
   ```bash
   # Rename or create host-specific config for your machine
   mv ~/.zshrc##hostname.Alex-MBP ~/.zshrc##hostname.$(hostname -s)

   # Or just use the default (works on any machine)
   # The .zshrc##default file is portable
   ```

4. **Update the bootstrap script:**

   Edit `~/.config/yadm/bootstrap` and change:
   ```bash
   PRIMARY_HOSTNAME="Alex-MBP"  # Change to your hostname
   ```

5. **Set up your own GPG key for secrets:**
   ```bash
   # Generate a key
   gpg --full-generate-key

   # Configure yadm to use it
   yadm config yadm.gpg-recipient YOUR_KEY_ID

   # Add your secrets to ~/.config/yadm/encrypt patterns
   # Then encrypt
   yadm encrypt
   yadm add ~/.local/share/yadm/archive
   yadm commit -m "Add my encrypted secrets"
   ```

### Option 2: Cherry-Pick Configs

Just copy specific configs you want:

```bash
# Example: just grab the Neovim config
curl -fsSL https://raw.githubusercontent.com/alexfazio/dotfiles/main/.config/nvim/init.lua \
  -o ~/.config/nvim/init.lua
```

### What Won't Work Without Changes

| Item | Issue | Solution |
|------|-------|----------|
| `~/.zshrc##hostname.Alex-MBP` | Wrong hostname | Rename to your hostname or use `##default` |
| `yadm decrypt` | My GPG key | Set up your own encryption |
| `cc` function | My project paths | Edit paths in `.zshrc##hostname.*` |
| `nvim-wrapper` | Ghostty-specific fix | Remove EDITOR override or keep the wrapper |

### What Works Immediately

- `.zshrc##default` - Portable shell config
- `.config/nvim/` - Full Neovim setup (may need `:Lazy sync`)
- `.config/aerospace/` - Tiling WM config
- `.config/ghostty/` - Terminal config
- `.config/kitty/` - Terminal config
- `.config/wezterm/` - Terminal config
- `.config/yazi/` - File manager config

---

## How It Works

### Host-Specific Configs (Alternates)

yadm uses `##` suffixes to provide different files per machine:

```
.zshrc##default              # Used if no hostname match
.zshrc##hostname.Alex-MBP    # Used only on Alex-MBP
```

When you run `yadm alt` (or clone/bootstrap), yadm symlinks the appropriate file to `.zshrc`.

### Primary vs Secondary Machines

| Machine | Hostname | Push | Pull | Auto-Sync |
|---------|----------|------|------|-----------|
| Primary | `Alex-MBP` | Yes | Yes | Hourly (launchd) |
| Secondary | Any other | No (disabled) | Yes | Stale-check only |

The bootstrap script detects hostname and configures accordingly. This prevents accidental config overwrites from test machines.

### Automatic Sync

**Primary machine:** A launchd agent runs hourly to commit and push any uncommitted changes to tracked files.

```bash
# Check sync log
cat ~/.local/share/yadm/auto-sync.log

# Manual sync (don't wait for hourly)
~/.local/bin/yadm-auto-sync.sh

# Stop/start auto-sync
launchctl unload ~/Library/LaunchAgents/com.yadm.autosync.plist
launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist
```

**All machines:** On shell startup, a background fetch checks for updates. If behind remote, you'll see:

```
[dotfiles] 3 update(s) available. Run: yadm pull
```

### Secrets Encryption

Sensitive files are GPG-encrypted into a single archive:

```
~/.ssh/id_*                    ─┐
~/.gnupg/private-keys-v1.d/*    ├─► yadm encrypt ─► ~/.local/share/yadm/archive
~/.config/gh/hosts.yml         ─┘
```

The archive is safe to commit (encrypted), and `yadm decrypt` restores the files.

---

## File Structure

```
~/
├── .config/
│   ├── aerospace/aerospace.toml
│   ├── ghostty/config
│   ├── kitty/*.conf
│   ├── nvim/
│   │   ├── init.lua
│   │   └── lua/{config,plugins}/
│   ├── wezterm/wezterm.lua
│   ├── yazi/{*.toml,plugins/}
│   └── yadm/
│       ├── bootstrap          # New machine setup
│       ├── encrypt            # Patterns for secrets
│       └── gitignore          # Never-track patterns
├── .gnupg/gpg-agent.conf
├── .local/
│   ├── bin/
│   │   ├── nvim-wrapper       # Editor wrapper script
│   │   └── yadm-auto-sync.sh  # Hourly sync script (primary only)
│   └── share/yadm/
│       ├── archive            # Encrypted secrets
│       └── auto-sync.log      # Sync history
├── .zshenv
├── .zshrc##default            # Portable base config
└── .zshrc##hostname.Alex-MBP  # Machine-specific config
```

---

## Requirements

- **macOS** (tested on Sonoma/Sequoia)
- **Homebrew** - package manager
- **GPG** - for secrets encryption/decryption

Essential tools installed by bootstrap:
- `zoxide` - smarter cd
- `fzf` - fuzzy finder
- `fd` - better find
- `ripgrep` - better grep
- `neovim` - editor

---

## License

MIT - Feel free to use, modify, and share.
