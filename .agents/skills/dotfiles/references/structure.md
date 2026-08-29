# Dotfiles Structure Reference

Complete reference for the yadm-managed dotfiles structure and configuration.

## Architecture Overview

**Manager:** yadm (Yet Another Dotfiles Manager)
**Bare repo:** `~/.local/share/yadm/repo.git`
**Remote:** https://github.com/alexfazio/dotfiles
**Key difference:** Files live directly in `~/` (no symlinks)

## Directory Structure

```
~/
├── .config/
│   ├── aerospace/
│   │   └── aerospace.toml          # Tiling window manager
│   ├── ghostty/
│   │   └── config                  # Terminal emulator
│   ├── kitty/
│   │   ├── kitty.conf              # Terminal config
│   │   └── splits.conf             # Split keybindings
│   ├── wezterm/
│   │   └── wezterm.lua             # Terminal (Lua config)
│   ├── yazi/
│   │   ├── yazi.toml               # File manager config
│   │   ├── keymap.toml             # Keybindings
│   │   ├── package.toml            # Plugin packages
│   │   └── plugins/                # Installed plugins
│   ├── nvim/
│   │   ├── init.lua                # Neovim entry point
│   │   ├── lazy-lock.json          # Plugin lockfile
│   │   ├── lazyvim.json            # LazyVim config
│   │   ├── stylua.toml             # Lua formatter
│   │   └── lua/                    # Config modules
│   │       ├── config/
│   │       └── plugins/
│   ├── gh/
│   │   └── hosts.yml               # GitHub CLI auth (encrypted)
│   └── yadm/
│       ├── bootstrap               # New machine setup script
│       ├── encrypt                 # Patterns for encrypted files
│       ├── gitignore               # Never-track patterns (30+)
│       ├── gitleaks.toml           # False positive allowlist
│       └── hooks/
│           └── pre_commit          # Secret scanning hook
│
├── .gnupg/
│   ├── gpg-agent.conf              # Passphrase caching
│   └── private-keys-v1.d/          # Private keys (encrypted)
│
├── .ssh/
│   ├── id_*                        # SSH keys (encrypted)
│   └── config                      # SSH config (if tracked)
│
├── .local/
│   ├── bin/
│   │   ├── nvim-wrapper            # Editor wrapper script
│   │   └── yadm-auto-sync.sh       # Hourly sync (primary only)
│   └── share/yadm/
│       ├── repo.git/               # Bare git repository
│       ├── archive                 # Encrypted secrets
│       ├── auto-sync.log           # Sync history
│       └── .last-fetch             # Stale-check marker
│
├── Library/LaunchAgents/
│   └── com.yadm.autosync.plist     # Hourly sync agent (primary)
│
├── .zshenv                         # Early shell setup
├── .zshrc##default                 # Portable base config
├── .zshrc##hostname.paradigma      # Primary machine config
├── .secrets.env                    # Legacy local env secrets (only after explicit decrypt)
└── README.md                       # Repository documentation
```

## yadm Configuration Files

### `~/.config/yadm/bootstrap`

New machine setup script. Runs automatically after `yadm clone --bootstrap`.

**Responsibilities:**
- Detect machine role (`local.class`: `primary` or `secondary`)
- Install Homebrew packages
- Configure yadm repository defaults (`core.excludesfile`, `status.showUntrackedFiles`)
- Apply alternates
- Set up auto-sync on the primary machine
- Configure pull-only mode on secondary machines

### `~/.config/yadm/encrypt`

Legacy patterns for files to encrypt with GPG. Keep these for recovery unless a separate 1Password migration removes them:
```
.ssh/id_*
.gnupg/private-keys-v1.d/*
.config/gh/hosts.yml
.secrets.env
```

### `~/.config/yadm/gitignore`

Patterns for files yadm should never track. This file is also configured as the yadm repository `core.excludesfile`, so broad `$HOME` scans stay usable.

Important groups:
- environment files and local secret files
- API keys, tokens, credentials, SSH key material
- editor/app caches and logs
- top-level user-data directories (`Library/`, `Desktop/`, `Documents/`, `Downloads/`, media folders)
- agent/tool runtime directories (`.claude/`, `.codex/`, `.cache/`, `.agent-browser/`, etc.)

### `~/.config/yadm/gitleaks.toml`

Allowlist for gitleaks false positives:

**Ignored paths:**
- `lazy-lock.json`, `package.toml`, `Brewfile.lock.json`

**Ignored patterns:**
- Placeholder values: `YOUR_API_KEY_HERE`, `<API_KEY>`, `REPLACE_ME`
- Hex color codes: `#[0-9a-fA-F]{6}`
- Example domains: `example.com`, `localhost`

### `~/.config/yadm/hooks/pre_commit`

Secret scanning hook using gitleaks:

```bash
#!/bin/bash
gitleaks protect --staged --verbose --redact --exit-code 1 \
    --config="$HOME/.config/yadm/gitleaks.toml"
```

## Alternates System

yadm uses `##` suffixes for host-specific files:

| Suffix | Applied When |
|--------|--------------|
| `##default` | No hostname match |
| `##hostname.paradigma` | Hostname is `paradigma` |
| `##os.Darwin` | macOS systems |
| `##class.primary` | yadm class is `primary` |

**Current alternates:**
```
.zshrc##default                 # Portable fallback
.zshrc##hostname.paradigma      # Primary machine config
```

Run `yadm alt` to reapply alternates after changes.

## launchd Agent (Primary Machine)

**Plist:** `~/Library/LaunchAgents/com.yadm.autosync.plist`
**Script:** `~/.local/bin/yadm-auto-sync.sh`
**Log:** `~/.local/share/yadm/auto-sync.log`

| Property | Value |
|----------|-------|
| Label | `com.yadm.autosync` |
| StartInterval | `3600` (hourly) |
| RunAtLoad | `true` |

### Management Commands

```bash
# Check if running
launchctl list com.yadm.autosync

# Reload
launchctl unload ~/Library/LaunchAgents/com.yadm.autosync.plist
launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist

# Manual sync
~/.local/bin/yadm-auto-sync.sh

# View log
cat ~/.local/share/yadm/auto-sync.log
```

## Secret Protection Layers

### Layer 1: 1Password recovery/source-of-truth

Current policy keeps yadm recovery material in 1Password and does not install local secret files by default.

### Layer 2: Legacy GPG archive

```bash
yadm encrypt    # Updates ~/.local/share/yadm/archive
yadm decrypt    # Restores legacy local secret files only when explicitly needed
```

Configured by: `~/.config/yadm/encrypt`

### Layer 3: Pre-commit Hook

Blocks commits containing secrets using gitleaks.

**Location:** `~/.config/yadm/hooks/pre_commit`
**Config:** `~/.config/yadm/gitleaks.toml`

### Layer 4: Gitignore Patterns

Broad patterns prevent tracking sensitive files, runtime state, caches, and top-level user data.

**Location:** `~/.config/yadm/gitignore`

## Zsh Configuration

### .zshrc##default (Portable)

- PATH setup (Homebrew, user bins, Go)
- Vi mode with emacs keybindings in insert mode
- Editor fallback chain: nvim > vim > vi
- Optional tool loading (cargo, zoxide, fnm)
- Stale-check function (warns if behind remote)
- `dfs` alias for quick status

### .zshrc##hostname.paradigma (Primary)

Sources `##default` and adds:
- `cc` wrapper function for Claude Code
- Tab completion for `cc` command
- Project shortcuts (`@project` → `~/Documents/GitHub/project`)

### cc Wrapper Function

| Flag | Expands to |
|------|------------|
| `-dsp` | `--dangerously-skip-permissions` |
| `-mo` | `--model opus` |
| `-ms` | `--model sonnet` |
| `-mh` | `--model haiku` |
| `@project` | `cd ~/Documents/GitHub/<project> && claude` |

## Machine Roles

| Role | Hostname | Push | Auto-Sync | Stale-Check |
|------|----------|------|-----------|-------------|
| Primary | `paradigma` | Yes | Hourly | Yes |
| Secondary | Any other | No (disabled) | No | Yes |

Bootstrap detects hostname and configures accordingly.

## Key Locations Summary

| Purpose | Location |
|---------|----------|
| Bare git repo | `~/.local/share/yadm/repo.git` |
| Encrypted archive | `~/.local/share/yadm/archive` |
| Encryption patterns | `~/.config/yadm/encrypt` |
| Bootstrap script | `~/.config/yadm/bootstrap` |
| Pre-commit hook | `~/.config/yadm/hooks/pre_commit` |
| Gitleaks config | `~/.config/yadm/gitleaks.toml` |
| Gitignore | `~/.config/yadm/gitignore` |
| Auto-sync script | `~/.local/bin/yadm-auto-sync.sh` |
| Auto-sync log | `~/.local/share/yadm/auto-sync.log` |
| launchd agent | `~/Library/LaunchAgents/com.yadm.autosync.plist` |
