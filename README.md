# Dotfiles

Personal dotfiles managed with [yadm](https://yadm.io). Files live at their real paths in `$HOME`; yadm tracks them with a bare Git repo at `~/.local/share/yadm/repo.git`.

## What's Included

| Application | Config Location | Description |
|-------------|-----------------|-------------|
| **Zsh** | `.zshrc##default`, `.zshrc##hostname.paradigma` | Portable shell config plus primary-machine overrides |
| **Neovim** | `.config/nvim/` | LazyVim-based config with custom plugins |
| **AeroSpace** | `.config/aerospace/aerospace.toml` | macOS tiling window manager |
| **Ghostty** | `.config/ghostty/config` | GPU-accelerated terminal emulator |
| **Kitty** | `.config/kitty/*.conf` | Alternative terminal config |
| **WezTerm** | `.config/wezterm/wezterm.lua` | Cross-platform terminal config |
| **Yazi** | `.config/yazi/*.toml` | Terminal file manager config |
| **Mole** | `.config/mole/whitelist` | macOS cleanup whitelist |
| **GPG Agent** | `.gnupg/gpg-agent.conf` | Passphrase caching config |
| **yadm** | `.config/yadm/`, `.local/bin/yadm-auto-sync.sh` | Bootstrap, ignores, secret scanning, autosync |

Not currently tracked: `.tmux.conf` and Nushell config.

---

## Current Machine Model

| Role | Hostname | Push | Pull | Auto-Sync |
|------|----------|------|------|-----------|
| Primary | `paradigma` | Yes | Yes | Hourly via launchd |
| Secondary | Any other | Disabled by bootstrap | Yes | Shell stale-check only |

Bootstrap records the role in yadm config:

```bash
yadm config local.class
```

The primary machine runs:

```bash
~/Library/LaunchAgents/com.yadm.autosync.plist
~/.local/bin/yadm-auto-sync.sh
```

---

## Daily Workflow

```bash
# Check status
dfs                        # alias for: yadm status

# View changes
yadm diff

# Commit tracked-file changes
yadm add -u
yadm commit -m "Update configs"
yadm push

# Pull updates
yadm pull
```

New files often live under broadly ignored `$HOME` paths such as `.config/` and `.local/`, so use `-f` when intentionally adding them:

```bash
yadm add -f ~/.config/newapp/config.toml
yadm commit -m "Add newapp config"
yadm push
```

---

## Bootstrap

New machine setup:

```bash
brew install yadm
yadm clone --bootstrap https://github.com/alexfazio/dotfiles.git
```

Bootstrap does the safe, non-secret setup:

- detects machine role and sets `local.class`
- disables push on secondary machines
- installs/checks essential Homebrew tools
- configures yadm repository defaults:
  - `core.excludesfile=~/.config/yadm/gitignore`
  - `status.showUntrackedFiles=no`
- applies alternates with `yadm alt`
- configures primary-machine autosync when hostname is `paradigma`
- does **not** decrypt secrets automatically

Essential tools installed by bootstrap:

- `zoxide` - smarter `cd`
- `fzf` - fuzzy finder
- `fd` - file finder
- `ripgrep` - fast search
- `neovim` - editor
- `gitleaks` - pre-commit secret scanning

---

## Secrets Policy

Keep two concepts separate.

### Current yadm setup

The dotfiles repo tracks public config and keeps a legacy encrypted archive at:

```text
~/.local/share/yadm/archive
```

Legacy encrypted paths are defined in `~/.config/yadm/encrypt`:

```text
.secrets.env
.ssh/id_*
!.ssh/*.pub
.gnupg/private-keys-v1.d/*
.config/gh/hosts.yml
```

`yadm decrypt` writes those legacy local secret files back into `$HOME`. Do not run it during normal setup or normal pulls.

Use it only when intentionally restoring legacy local SSH/GPG/GH/env files, after importing the matching GPG private key and reading the archive passphrase from 1Password:

```bash
yadm decrypt
```

### 1Password integration

1Password is the recovery/source-of-truth direction for secrets:

- recovery material for the yadm archive lives in 1Password
- future env-secret workflows should prefer 1Password Environments / `op run`
- future SSH workflows should prefer the 1Password SSH agent where practical
- yadm encryption remains for legacy local-file restore, not as the default path for new secrets

### Updating the legacy archive

Only for secrets that still must exist as local files after `yadm decrypt`:

```bash
yadm encrypt
yadm add -f ~/.local/share/yadm/archive
yadm commit -m "Update encrypted secrets"
yadm push
```

---

## Secret Protection

Four layers protect against accidental secret exposure:

| Layer | Mechanism | Purpose |
|-------|-----------|---------|
| **1Password** | Recovery material and future env/SSH workflows | Avoids writing secrets to disk by default |
| **Legacy GPG archive** | `yadm encrypt` / `yadm decrypt` | Restores old local secret files only when explicitly needed |
| **Pre-commit hook** | `gitleaks` scans staged files | Blocks commits containing accidental secrets |
| **Gitignore** | Broad `$HOME` ignore rules | Prevents tracking sensitive/runtime/user-data paths |

If pre-commit blocks a commit:

1. Remove the secret from the file, or move it to 1Password.
2. Use yadm encryption only when the file must be restored locally by `yadm decrypt`.
3. Add a pattern to `~/.config/yadm/gitleaks.toml` only for confirmed false positives.
4. Use `yadm commit --no-verify` only as a last resort.

---

## Host-Specific Configs

yadm alternates use `##` suffixes:

```text
.zshrc##default                 # Portable fallback
.zshrc##hostname.paradigma      # Primary-machine shell config
```

`yadm alt` links the correct alternate to `.zshrc`.

The primary zsh config sources `.zshrc##default` and adds local overrides such as the `cc` wrapper and project shortcuts.

---

## Public Users

Want to use this repo as a starting point? Fork it first.

### Fork and customize

```bash
yadm clone --bootstrap https://github.com/YOUR_USERNAME/dotfiles.git
```

Then:

1. Remove my encrypted archive; you cannot decrypt it:
   ```bash
   yadm rm .local/share/yadm/archive
   yadm commit -m "Remove original encrypted archive"
   ```

2. Create your own host-specific alternate if needed:
   ```bash
   cp ~/.zshrc##default ~/.zshrc##hostname.$(hostname -s)
   yadm add -f ~/.zshrc##hostname.$(hostname -s)
   ```

3. Update `~/.config/yadm/bootstrap`:
   ```bash
   PRIMARY_HOSTNAME="$(hostname -s)"
   ```

4. Choose a secrets model:
   - recommended: 1Password / platform-native secret storage
   - legacy yadm path: generate your own GPG key, set `yadm.gpg-recipient`, then run `yadm encrypt`

### What needs customization

| Item | Why | Action |
|------|-----|--------|
| `.zshrc##hostname.paradigma` | Host-specific to my primary machine | Create your own `##hostname.$(hostname -s)` alternate or use `##default` |
| Encrypted archive | Encrypted to my GPG key | Remove it and create your own if needed |
| `cc` function | Contains my project shortcuts/workflow | Edit or remove host-specific shell overrides |
| `nvim-wrapper` | Ghostty/Claude focus-reporting workaround | Keep if useful, otherwise remove the EDITOR override |

### What works immediately

- `.zshrc##default` - portable shell config
- `.config/nvim/` - Neovim setup; run `nvim --headless "+Lazy! sync" +qa` or `:Lazy sync` if plugins need installation
- `.config/aerospace/` - AeroSpace config
- `.config/ghostty/` - Ghostty config
- `.config/kitty/` - Kitty config
- `.config/wezterm/` - WezTerm config
- `.config/yazi/` - Yazi config

---

## File Structure

```text
~/
├── README.md
├── .config/
│   ├── aerospace/aerospace.toml
│   ├── ghostty/config
│   ├── kitty/*.conf
│   ├── mole/whitelist
│   ├── nvim/
│   │   ├── init.lua
│   │   ├── lazy-lock.json
│   │   ├── lazyvim.json
│   │   └── lua/{config,plugins}/
│   ├── wezterm/wezterm.lua
│   ├── yadm/
│   │   ├── bootstrap
│   │   ├── config
│   │   ├── encrypt
│   │   ├── gitignore
│   │   ├── gitleaks.toml
│   │   └── hooks/pre_commit
│   └── yazi/{*.toml,plugins/}
├── .gnupg/gpg-agent.conf
├── .local/
│   ├── bin/
│   │   ├── nvim-wrapper
│   │   └── yadm-auto-sync.sh
│   └── share/yadm/
│       ├── archive                 # Legacy encrypted secrets archive
│       └── auto-sync.log
├── .zshenv
├── .zshrc##default
└── .zshrc##hostname.paradigma
```

---

## Health Check

Manual checks:

```bash
yadm status --short --untracked-files=all
yadm config local.class
yadm gitconfig --get core.excludesfile
yadm gitconfig --get status.showUntrackedFiles
launchctl list com.yadm.autosync
```

Expected healthy state on `paradigma`:

- yadm installed and on `main`
- `local.class=primary`
- repository ignores configured
- autosync launchd agent loaded
- gitleaks/pre-commit available
- `.zshrc` alternate applied
- no pending yadm changes
- GPG secret key may be absent locally; that is a warning only unless restoring legacy secrets

---

## License

MIT - Feel free to use, modify, and share.
