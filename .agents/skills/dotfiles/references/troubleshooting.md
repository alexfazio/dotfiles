# yadm Troubleshooting Guide

Common issues, error messages, and solutions for yadm-managed dotfiles.

## Quick Diagnostics

```bash
# Check overall status
dfs                        # alias for: yadm status

# Check if behind remote
yadm fetch origin && yadm status

# View recent sync activity (primary machine)
cat ~/.local/share/yadm/auto-sync.log

# Check launchd agent (primary machine)
launchctl list com.yadm.autosync
```

## Sync Issues

### Push Rejected

**Symptoms:**
- `yadm push` fails
- Error: "Updates were rejected because the remote contains work"

**Solutions:**

```bash
# Pull and rebase first
yadm pull --rebase

# Then push
yadm push
```

If conflicts arise, resolve them:
```bash
yadm status
# Edit conflicted files
yadm add <file>
yadm rebase --continue
yadm push
```

### Stale Dotfiles Warning

**Symptoms:**
- Shell startup shows: `[dotfiles] X update(s) available. Run: yadm pull`

**Solution:**
```bash
yadm pull
```

Do not run `yadm decrypt` for ordinary dotfile updates. Decrypt only when explicitly restoring legacy local secrets.

### Auto-Sync Not Running (Primary Machine)

**Symptoms:**
- No recent entries in `~/.local/share/yadm/auto-sync.log`
- Changes not being pushed automatically

**Diagnosis:**
```bash
# Check if launchd agent is loaded
launchctl list com.yadm.autosync

# Check plist and sync script
test -f ~/Library/LaunchAgents/com.yadm.autosync.plist && echo plist-ok
test -x ~/.local/bin/yadm-auto-sync.sh && echo script-ok
```

**Solutions:**

1. **Agent not loaded:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist
   ```

2. **Agent crashed:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.yadm.autosync.plist
   launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist
   ```

3. **Script not executable:**
   ```bash
   chmod +x ~/.local/bin/yadm-auto-sync.sh
   ```

4. **Run sync manually:**
   ```bash
   ~/.local/bin/yadm-auto-sync.sh
   ```

## Secret and Encryption Issues

### Decrypt Fails

**Current policy:** local decrypt is optional. 1Password stores recovery material; do not import keys or decrypt unless you are intentionally restoring legacy local SSH/GPG/GH/env files.

**Symptoms:**
- `yadm decrypt` prompts for passphrase but fails
- Error: "decryption failed: No secret key"

**Diagnosis:**
```bash
# Check whether a local GPG secret key is installed
gpg --list-secret-keys --keyid-format LONG

# Check yadm encryption recipient
yadm config yadm.gpg-recipient

# Check legacy archive exists
test -f ~/.local/share/yadm/archive && echo archive-present
```

**Solutions, only if local restore is actually needed:**

1. **Import the GPG private key from 1Password recovery material:**
   ```bash
   gpg --import ~/path/to/private-key.asc
   ```

2. **Read the yadm archive passphrase from 1Password, then decrypt:**
   ```bash
   yadm decrypt
   ```

3. **If GPG agent is stuck:**
   ```bash
   gpgconf --kill gpg-agent
   gpgconf --launch gpg-agent
   export GPG_TTY=$(tty)
   ```

### Pre-commit Hook Blocks Commit (Secret Detected)

**Symptoms:**
- `yadm commit` fails with "SECRET DETECTED - Commit blocked"
- gitleaks shows detected secrets

**Diagnosis:**
```bash
# See what was detected
gitleaks protect --staged --verbose
```

**Solutions:**

1. **Remove the actual secret:**
   - Move the value to 1Password when possible.
   - Replace with a placeholder in the committed file.

2. **Use legacy yadm encryption only for intentional local-file secrets that still must be restored by `yadm decrypt`:**
   ```bash
   # Add pattern to encrypt file
   echo "path/to/file" >> ~/.config/yadm/encrypt

   # Re-encrypt
   yadm encrypt
   yadm add -f ~/.local/share/yadm/archive
   yadm commit -m "Add encrypted secret"
   ```

3. **Add to allowlist (false positive):**
   ```bash
   # Edit ~/.config/yadm/gitleaks.toml
   # Add pattern to regexes or paths array
   ```

4. **Bypass (use sparingly):**
   ```bash
   yadm commit --no-verify -m "Message"
   ```

### Encrypt Command Fails

**Symptoms:**
- `yadm encrypt` fails
- No archive created

**Diagnosis:**
```bash
# Check encryption patterns exist
cat ~/.config/yadm/encrypt

# Check GPG recipient is set
yadm config yadm.gpg-recipient
```

**Solutions:**

1. **No patterns defined:**
   ```bash
   echo ".ssh/id_*" >> ~/.config/yadm/encrypt
   ```

2. **No GPG recipient:**
   ```bash
   gpg --list-keys
   yadm config yadm.gpg-recipient YOUR_KEY_ID
   ```

## Alternates Issues

### Wrong Config Applied

**Symptoms:**
- Machine is using wrong `.zshrc` version
- Host-specific settings not applied

**Diagnosis:**
```bash
# Check current hostname
hostname -s

# Check which alternate is linked
readlink ~/.zshrc || test -f ~/.zshrc

# List available alternates
yadm ls-files '*##*'
```

**Solutions:**

1. **Reapply alternates:**
   ```bash
   yadm alt
   ```

2. **Check hostname matches file suffix:**
   - File: `.zshrc##hostname.paradigma`
   - Hostname must be exactly: `paradigma`

3. **Use default if no match needed:**
   - Rename to `.zshrc##default`

### Alternates Not Visible

**Symptoms:**
- `yadm list` doesn't show alternate files

**Solution:**
```bash
# Alternates must be tracked by yadm
yadm add -f ~/.zshrc##hostname.$(hostname -s)
yadm commit -m "Add alternate for $(hostname -s)"
```

## Git Issues

### Merge Conflicts

**Symptoms:**
- `yadm pull` fails with conflicts
- `yadm status` shows conflicted files

**Solutions:**

```bash
yadm status

# Option 1: Keep local changes
yadm checkout --ours <file>
yadm add <file>

# Option 2: Accept remote changes
yadm checkout --theirs <file>
yadm add <file>

# Option 3: Manually resolve
vim <file>
yadm add <file>

# Finalize
yadm commit -m "Resolve merge conflict"
```

### Detached HEAD

**Symptoms:**
- `yadm status` shows "HEAD detached"

**Solution:**
```bash
# Save any uncommitted work
yadm stash

# Return to main branch
yadm checkout main

# Restore work if needed
yadm stash pop
```

### Files Showing as Modified

**Symptoms:**
- `yadm status` shows files as modified but you haven't changed them
- Often happens with permission or line ending changes

**Diagnosis:**
```bash
yadm diff <file>
```

**Solutions:**

1. **Reset file permissions:**
   ```bash
   yadm checkout -- <file>
   ```

2. **If line ending issue:**
   ```bash
   yadm config core.autocrlf input
   ```

## Authentication Issues

### Push Authentication Fails

**Symptoms:**
- `yadm push` prompts for password
- Error: "Authentication failed"

**Solutions:**

1. **Use HTTPS with token:**
   ```bash
   # Set remote to HTTPS
   yadm remote set-url origin https://github.com/alexfazio/dotfiles.git

   # Configure credential helper
   yadm config credential.helper osxkeychain

   # Use GitHub CLI for auth
   gh auth login
   ```

2. **Use SSH (if configured):**
   ```bash
   yadm remote set-url origin git@github.com:alexfazio/dotfiles.git

   # Test SSH
   ssh -T git@github.com
   ```

### Secondary Machine Can't Push

**Expected behavior.** Secondary machines have push disabled by bootstrap:

```bash
# Check remote URL
yadm remote -v
# Should show: origin ... (push) no_push

# To temporarily enable (use sparingly)
yadm remote set-url --push origin https://github.com/alexfazio/dotfiles.git
yadm push

# Disable again
yadm remote set-url --push origin no_push
```

## Bootstrap Issues

### Bootstrap Fails

**Symptoms:**
- `yadm clone --bootstrap` fails
- Bootstrap script errors

**Diagnosis:**
```bash
# Run bootstrap manually with debug
bash -x ~/.config/yadm/bootstrap
```

**Solutions:**

1. **Missing Homebrew:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Missing permissions:**
   ```bash
   chmod +x ~/.config/yadm/bootstrap
   ```

3. **Run bootstrap again:**
   ```bash
   ~/.config/yadm/bootstrap
   ```

## Recovery Procedures

### Fresh Start (Nuclear Option)

If everything is broken:

```bash
# 1. Backup any local changes
mkdir ~/dotfiles-backup
cp -r ~/.config ~/dotfiles-backup/
cp ~/.zshrc* ~/dotfiles-backup/

# 2. Remove yadm tracking
rm -rf ~/.local/share/yadm

# 3. Re-clone
yadm clone --bootstrap https://github.com/alexfazio/dotfiles.git

# 4. Optional: restore legacy local secrets only if needed
# yadm decrypt
```

### Disable Auto-Sync Temporarily

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.yadm.autosync.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.yadm.autosync.plist
```

### Reset to Remote State

**Warning:** Loses all local uncommitted changes.

```bash
yadm fetch origin
yadm reset --hard origin/main
yadm alt
# Optional only when intentionally restoring legacy local secrets:
# yadm decrypt
```

## Common Error Messages

| Error | Meaning | Fix |
|-------|---------|-----|
| `Updates were rejected` | Remote has newer commits | `yadm pull --rebase` |
| `No secret key` | GPG key not available | Usually OK; import GPG key from 1Password only if restoring legacy local secrets |
| `SECRET DETECTED` | gitleaks found secret | Remove or encrypt |
| `Agent not running` | GPG agent stopped | `gpgconf --launch gpg-agent` |
| `not a yadm repository` | yadm not initialized | `yadm clone ...` |
| `error: pathspec` | File doesn't exist | Check path spelling |
