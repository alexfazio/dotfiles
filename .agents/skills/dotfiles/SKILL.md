---
name: dotfiles
description: "Complete dotfiles management using yadm (Yet Another Dotfiles Manager). This skill should be used when the user asks to check dotfiles status, edit any configuration (aerospace, ghostty, kitty, wezterm, yazi, nvim, zsh), add new configs, troubleshoot sync issues, manage encrypted secrets, or perform dotfiles maintenance. Triggers on requests like 'check my dotfiles', 'edit my ghostty config', 'add tmux to dotfiles', 'why is sync not working', 'encrypt my secrets', 'dfs', or any yadm-related task."
---

# Dotfiles Management

This skill provides comprehensive management for dotfiles using yadm, enabling status monitoring, config editing, secret encryption, sync management, and troubleshooting.

## Overview

**Manager:** [yadm](https://yadm.io) (Yet Another Dotfiles Manager)
**Remote:** https://github.com/alexfazio/dotfiles
**Architecture:** Real files in `~/`, tracked by yadm's bare git repo (no symlinks)

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Bare repo** | yadm stores git data at `~/.local/share/yadm/repo.git`, files live directly in `~/` |
| **Alternates** | Files with `##` suffixes for host-specific configs (current primary: `.zshrc##hostname.paradigma`) |
| **Encryption** | Legacy GPG-encrypted archive for local secret restore via `yadm encrypt/decrypt`; 1Password is recovery source of truth |
| **Primary/Secondary** | Primary machine (`paradigma`) can push + auto-syncs; secondary machines are pull-only |

### Managed Applications

| Application | Config Path | Notes |
|-------------|-------------|-------|
| AeroSpace | `~/.config/aerospace/aerospace.toml` | Tiling window manager |
| Ghostty | `~/.config/ghostty/config` | Terminal emulator |
| Kitty | `~/.config/kitty/*.conf` | Alternative terminal |
| WezTerm | `~/.config/wezterm/wezterm.lua` | Cross-platform terminal |
| Yazi | `~/.config/yazi/*.toml` | File manager |
| Neovim | `~/.config/nvim/` | LazyVim-based config |
| Zsh | `~/.zshrc` (via alternates) | Shell config |

## Quick Commands

```bash
# Check status
dfs                              # Alias for: yadm status

# View changes
yadm diff

# Commit and push changes
yadm add -u
yadm commit -m "Update configs"
yadm push

# Pull updates
yadm pull

# Legacy encrypted archive commands
yadm encrypt                     # Updates ~/.local/share/yadm/archive
yadm decrypt                     # Restores legacy local secret files only when explicitly needed

# Check auto-sync log (primary machine)
cat ~/.local/share/yadm/auto-sync.log
```

## Workflows

### 1. Checking Dotfiles Status

To check current dotfiles status:

```bash
dfs                    # or: yadm status
yadm diff              # View uncommitted changes
```

On shell startup, if dotfiles are behind remote:
```
[dotfiles] 3 update(s) available. Run: yadm pull
```

### 2. Editing Configurations

To edit any configuration:

1. Read the config file directly (files are real, not symlinks)
2. Make changes using the Edit tool
3. Commit and push:
   ```bash
   yadm add -u
   yadm commit -m "Update config"
   yadm push
   ```

**Config file paths:**
- AeroSpace: `~/.config/aerospace/aerospace.toml`
- Ghostty: `~/.config/ghostty/config`
- Kitty: `~/.config/kitty/kitty.conf`
- WezTerm: `~/.config/wezterm/wezterm.lua`
- Yazi: `~/.config/yazi/yazi.toml`, `keymap.toml`
- Neovim: `~/.config/nvim/init.lua`, `~/.config/nvim/lua/`
- Zsh (portable): `~/.zshrc##default`
- Zsh (machine-specific): `~/.zshrc##hostname.paradigma`

### 3. Adding New Configurations

To add a new application's config, use `-f` when the path is under a broadly ignored directory such as `.config/`:

```bash
yadm add -f ~/.config/newapp/config.toml
yadm commit -m "Add newapp config"
yadm push
```

For host-specific configs, use alternates:
```bash
# Create host-specific version
cp ~/.config/app/config ~/.config/app/config##hostname.$(hostname -s)
yadm add -f ~/.config/app/config##hostname.$(hostname -s)
```

### 4. Managing Secrets

Keep two concepts separate:

**Current yadm setup:** public dotfiles plus a legacy encrypted archive.

**1Password integration:** recovery material and future env/SSH workflows live in 1Password.

**Legacy encrypted files** (defined in `~/.config/yadm/encrypt`):
- SSH private keys (`~/.ssh/id_*`)
- GPG private keys (`~/.gnupg/private-keys-v1.d/*`)
- GitHub CLI auth (`~/.config/gh/hosts.yml`)
- Environment secrets (`~/.secrets.env`)

Do **not** run `yadm decrypt` during normal setup. It writes local secret files back into `$HOME`.

Use `yadm decrypt` only when explicitly restoring legacy local SSH/GPG/GH/env files:
```bash
yadm decrypt    # Requires imported GPG private key and passphrase
```

For new env-secret workflows, prefer 1Password Environments/`op run` instead of adding new `.secrets.env` dependencies.

### 5. Troubleshooting

For common issues, consult `references/troubleshooting.md`:

| Issue | Quick Fix |
|-------|-----------|
| Push rejected | `yadm pull --rebase` then push |
| Decrypt fails | Check whether local restore is actually needed; then check `gpg --list-secret-keys` |
| Auto-sync not running | `launchctl list com.yadm.autosync` |
| Secret detected in commit | Pre-commit hook blocked it - remove secret or add to encrypt |
| Alternates not applied | Run `yadm alt` |

### 6. Secret Protection

Four layers protect against accidental secret exposure:

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| 1Password | Recovery material and future env/SSH workflows | Avoids writing secrets to disk by default |
| Legacy GPG archive | `yadm encrypt` / `yadm decrypt` | Restores old local secret files only when explicitly needed |
| Pre-commit hook | gitleaks scanning | Blocks commits with accidental secrets |
| Gitignore | broad `$HOME` ignore rules | Prevents tracking sensitive/runtime/user-data paths |

If pre-commit blocks a commit:
1. Remove the secret from the file, OR
2. Add file to `~/.config/yadm/encrypt` (for intentional secrets), OR
3. Add pattern to `~/.config/yadm/gitleaks.toml` (if false positive)

### 7. Setting Up a New Machine

To set up dotfiles on a new machine:

```bash
# 1. Install yadm
brew install yadm

# 2. Clone and bootstrap
yadm clone --bootstrap https://github.com/alexfazio/dotfiles.git
```

The bootstrap script automatically:
- Detects machine role (`local.class`: `primary` or `secondary`)
- Installs Homebrew packages, including `zoxide`, `fzf`, `fd`, `ripgrep`, `neovim`, and `gitleaks`
- Configures yadm repository defaults:
  - `core.excludesfile=~/.config/yadm/gitignore`
  - `status.showUntrackedFiles=no`
- Applies alternates
- Sets up auto-sync on the primary machine (`paradigma`)
- Configures pull-only mode on secondary machines

Do not decrypt secrets by default. Run `yadm decrypt` only when restoring legacy local secret files and after importing the matching GPG private key from 1Password.

To pull updates on secondary machines:
```bash
yadm pull
```

### 8. Running Health Check

To verify dotfiles setup is healthy:

```bash
~/.agents/skills/dotfiles/scripts/health-check.sh
```

The health check verifies:
- yadm installation and repository
- GPG archive/recovery state
- Secret protection (hooks, gitleaks, gitignore)
- launchd auto-sync (primary machine only)
- Alternates are correctly applied
- Sync status (pending changes, behind/ahead of remote)

## Machine Roles

| Role | Hostname | Push | Auto-Sync | Stale-Check |
|------|----------|------|-----------|-------------|
| Primary | `paradigma` | Yes | Hourly (launchd) | Yes |
| Secondary | Any other | No (disabled) | No | Yes (warns if behind) |

**Primary machine auto-sync:**
- launchd agent: `~/Library/LaunchAgents/com.yadm.autosync.plist`
- Script: `~/.local/bin/yadm-auto-sync.sh`
- Log: `~/.local/share/yadm/auto-sync.log`

**To manage auto-sync:**
```bash
# Check status
launchctl list com.yadm.autosync

# Stop
launchctl unload ~/Library/LaunchAgents/com.yadm.autosync.plist

# Start
launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist

# Manual sync
~/.local/bin/yadm-auto-sync.sh
```

## Reference Documentation

For detailed information:

- **`references/structure.md`** - File structure, yadm config files, alternates
- **`references/troubleshooting.md`** - Common issues and solutions
- **`references/adding-configs.md`** - Detailed guide for adding new configs
- **`references/cc-wrapper-bare-yolo-cleanup.md`** - `--yolo` removal, `-bare` exclusivity guards, flag tracking booleans
- **`scripts/health-check.sh`** - Diagnostic script to verify dotfiles health

## Key Files

| File | Purpose |
|------|---------|
| `~/.config/yadm/bootstrap` | New machine setup script |
| `~/.config/yadm/encrypt` | Patterns for encrypted files |
| `~/.config/yadm/gitignore` | Never-track patterns and yadm `core.excludesfile` |
| `~/.config/yadm/gitleaks.toml` | False positive allowlist |
| `~/.config/yadm/hooks/pre_commit` | Secret scanning hook |
| `~/.local/bin/yadm-auto-sync.sh` | Hourly sync script (primary) |
| `~/.local/share/yadm/archive` | Legacy encrypted secrets archive |
| `~/.local/share/yadm/auto-sync.log` | Sync history |
| `~/.zshrc##default` | Portable shell config |
| `~/.zshrc##hostname.paradigma` | Primary machine shell config |

## Zsh Integration

### `dfs` Alias
Quick status check: `alias dfs="yadm status"`

### `cc` Wrapper Function (in `.zshrc##hostname.paradigma`)
Custom flags for Claude Code:
- `-dsp` → `--dangerously-skip-permissions`
- `-mo` → `--model opus`
- `-ms` → `--model sonnet`
- `-mh` → `--model haiku`
- `@project` → Opens in `~/Documents/GitHub/<project>`

### Stale-Check (in `.zshrc##default`)
On shell startup, background fetch checks for updates and warns if behind remote.

## Requirements

- **macOS** (tested on Sonoma/Sequoia)
- **Homebrew** - package manager
- **GPG** - for secrets encryption/decryption
- **gitleaks** - secret scanning (`brew install gitleaks`; bootstrap installs/checks it)

Essential tools installed by bootstrap: `zoxide`, `fzf`, `fd`, `ripgrep`, `neovim`, `gitleaks`

## Important Notes

1. **Edit files directly** - No symlinks; configs live at their real paths
2. **Primary machine (`paradigma`) auto-syncs hourly** - Manual commits optional
3. **Secondary machines are pull-only** - Push disabled by bootstrap
4. **Pre-commit blocks secrets** - Intentional safety feature
5. **GPG passphrase/private key only needed for explicit legacy decrypt/restore**
6. **nvim-wrapper** at `~/.local/bin/` - Fixes Ghostty focus reporting issue with Neovim
