# Adding New Configs with yadm

Simple workflow for adding new application configurations to yadm-managed dotfiles.

## Key Difference from Symlink-based Systems

With yadm, files stay in their original locations. No moving or symlinking required.

| Old way (symlinks) | yadm way |
|--------------------|----------|
| Move file to `~/.dotfiles/` | File stays at `~/.config/app/` |
| Create symlink back | Just run `yadm add` |
| Update install script | Nothing to update |

## Standard Workflow

### Step 1: Verify the Config Exists

Agents should use the Read tool for file/directory checks. In a human terminal:

```bash
test -d ~/.config/<app>/ && echo config-dir-ok
test -f ~/.<app>rc && echo config-file-ok
```

### Step 2: Add to yadm

Broad `$HOME` ignores are intentional. Use `-f` when adding a new config under an ignored top-level directory such as `.config/`.

```bash
# Single file
yadm add -f ~/.config/<app>/config.toml

# Multiple files
yadm add -f ~/.config/<app>/*

# Entire directory
yadm add -f ~/.config/<app>/
```

### Step 3: Commit and Push

```bash
yadm commit -m "Add <app> configuration"
yadm push
```

That's it. On primary machine, auto-sync will handle commit/push within an hour if you forget.

## Examples

### Example 1: Adding Starship Prompt

```bash
# Just add and commit
yadm add -f ~/.config/starship.toml
yadm commit -m "Add starship config"
yadm push
```

### Example 2: Adding Tmux

```bash
# Home directory configs work the same
yadm add -f ~/.tmux.conf
yadm commit -m "Add tmux config"
yadm push
```

### Example 3: Adding Alacritty (Multiple Files)

```bash
# Add entire directory
yadm add -f ~/.config/alacritty/
yadm commit -m "Add alacritty config"
yadm push
```

### Example 4: Adding Host-Specific Config

For configs that should differ per machine, use alternates:

```bash
# Create alternate for current machine
cp ~/.config/app/config ~/.config/app/config##hostname.$(hostname -s)

# Add the alternate
yadm add -f ~/.config/app/config##hostname.$(hostname -s)
yadm commit -m "Add app config for $(hostname -s)"
yadm push

# Apply the alternate
yadm alt
```

## Special Cases

### Application with Dynamic Files

If an app auto-modifies some files (history, cache):

```bash
# Only add static config files
yadm add -f ~/.config/<app>/settings.toml
# Don't add ~/.config/<app>/history.db

# Or add to gitignore if accidentally shown as untracked
echo ".config/<app>/history.db" >> ~/.config/yadm/gitignore
```

### Application in Non-Standard Location

```bash
# Works anywhere in home directory
yadm add -f ~/Library/Application\ Support/<app>/config.json
```

### Files with Secrets

Prefer 1Password for new secrets. Use 1Password Environments/`op run` for env vars and the 1Password SSH agent for SSH keys where practical.

Use legacy yadm encryption only for intentional local-file secrets that must be restored by `yadm decrypt`:

```bash
# Add to encryption patterns
echo ".config/<app>/auth.json" >> ~/.config/yadm/encrypt

# Encrypt
yadm encrypt

# Commit the encrypted archive
yadm add -f ~/.local/share/yadm/archive
yadm commit -m "Add encrypted <app> secrets"
yadm push
```

## Files to Avoid

Don't add these to yadm:

| Pattern | Reason |
|---------|--------|
| `*.db`, `*.sqlite` | Binary database files |
| `history*`, `*_history` | Personal history data |
| `cache/`, `*.cache` | Ephemeral cache |
| `*.log` | Log files |
| `*.lock` | Lock files |
| `credentials*`, `*.key` | Secrets (prefer 1Password; use yadm encrypt only for legacy local-file restore) |
| `node_modules/` | Dependencies |

These patterns are already in `~/.config/yadm/gitignore`.

## Post-Addition Checklist

After adding a new config:

- [ ] Verify no secrets in plain text: `gitleaks protect --staged --redact --exit-code 1`
- [ ] Update `~/README.md` "What's Included" table (optional)
- [ ] Test on another machine: `yadm pull`

## Removing a Config

To stop tracking a file:

```bash
# Remove from yadm but keep local file
yadm rm --cached ~/.config/<app>/config

# Commit the removal
yadm commit -m "Remove <app> config from tracking"
yadm push
```

The file remains on your machine but is no longer tracked.

## Checking What's Tracked

```bash
# List all tracked files
yadm list

# Check tracked paths, then filter in the terminal if needed
yadm ls-files

# Check file status
yadm status
```
