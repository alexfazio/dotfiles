#!/bin/bash
# =============================================================================
# health-check.sh - yadm dotfiles health verification
# =============================================================================
# Checks:
#   1. yadm is installed and configured
#   2. GPG archive/recovery state is understood
#   3. Pre-commit hook is installed
#   4. gitleaks is available for secret scanning
#   5. launchd agent is running (primary machine only)
#   6. Alternates are correctly applied
#   7. Not behind remote
#   8. No pending changes (optional warning)
# =============================================================================

set -uo pipefail

CURRENT_HOSTNAME=$(hostname -s)
PRIMARY_HOSTNAME="${PRIMARY_HOSTNAME:-paradigma}"
MACHINE_CLASS="${YADM_MACHINE_CLASS:-}"
if [[ -z "$MACHINE_CLASS" ]] && command -v yadm &>/dev/null; then
    MACHINE_CLASS=$(yadm config local.class 2>/dev/null || true)
fi
if [[ -z "$MACHINE_CLASS" ]]; then
    if [[ "$CURRENT_HOSTNAME" == "$PRIMARY_HOSTNAME" ]]; then
        MACHINE_CLASS="primary"
    else
        MACHINE_CLASS="secondary"
    fi
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# =============================================================================
# HELPERS
# =============================================================================

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    PASS=$((PASS + 1))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    FAIL=$((FAIL + 1))
}

check_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
    WARN=$((WARN + 1))
}

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# =============================================================================
# YADM CHECKS
# =============================================================================

check_yadm() {
    section "yadm Installation"

    # Check yadm is installed
    if command -v yadm &>/dev/null; then
        check_pass "yadm command available"
    else
        check_fail "yadm not installed (brew install yadm)"
        return 1
    fi

    # Check repo exists
    if [[ -d "$HOME/.local/share/yadm/repo.git" ]]; then
        check_pass "yadm repository exists"
    else
        check_fail "yadm repository missing"
        return 1
    fi

    # Check remote is configured
    local remote
    remote=$(yadm remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$remote" ]]; then
        check_pass "Remote: $remote"
    else
        check_fail "No remote configured"
    fi

    # Check on main branch
    local branch
    branch=$(yadm rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ "$branch" == "main" ]]; then
        check_pass "On main branch"
    elif [[ -n "$branch" ]]; then
        check_warn "On branch: $branch (expected: main)"
    else
        check_fail "Could not determine branch"
    fi

    # Check machine class used by bootstrap/autosync decisions
    if [[ "$MACHINE_CLASS" == "primary" || "$MACHINE_CLASS" == "secondary" ]]; then
        check_pass "Machine class: $MACHINE_CLASS"
    else
        check_warn "Machine class not configured (expected primary or secondary)"
    fi

    # Check repository defaults that keep yadm status usable in $HOME
    local excludesfile
    excludesfile=$(yadm gitconfig --get core.excludesfile 2>/dev/null || echo "")
    if [[ "$excludesfile" == "$HOME/.config/yadm/gitignore" ]]; then
        check_pass "Repository excludesfile configured"
    else
        check_warn "Repository excludesfile not set to ~/.config/yadm/gitignore"
    fi

    local untracked
    untracked=$(yadm gitconfig --get status.showUntrackedFiles 2>/dev/null || echo "")
    if [[ "$untracked" == "no" ]]; then
        check_pass "Untracked home noise hidden by default"
    else
        check_warn "status.showUntrackedFiles is not set to no"
    fi
}

# =============================================================================
# GPG CHECKS
# =============================================================================

check_gpg() {
    section "GPG Encryption"

    # Check GPG is installed
    if command -v gpg &>/dev/null; then
        check_pass "gpg command available"
    else
        check_fail "gpg not installed"
        return
    fi

    # Check GPG agent is running
    if gpg-connect-agent /bye &>/dev/null; then
        check_pass "GPG agent running"
    else
        check_warn "GPG agent not running (gpgconf --launch gpg-agent)"
    fi

    # Check yadm GPG recipient is set
    local recipient
    recipient=$(yadm config yadm.gpg-recipient 2>/dev/null || echo "")
    if [[ -n "$recipient" ]]; then
        check_pass "Encryption recipient: $recipient"

        # Current policy keeps the private key in 1Password unless legacy
        # local decrypt/restore is explicitly needed.
        if gpg --list-secret-keys "$recipient" &>/dev/null; then
            check_pass "GPG secret key available for local decrypt"
        elif [[ -f "$HOME/.local/share/yadm/archive" ]]; then
            check_warn "GPG secret key not installed locally (OK unless running yadm decrypt; recovery is in 1Password)"
        else
            check_warn "GPG secret key not installed locally"
        fi
    else
        check_warn "No GPG recipient configured (yadm config yadm.gpg-recipient KEY_ID)"
    fi

    # Check encrypt file exists
    if [[ -f "$HOME/.config/yadm/encrypt" ]]; then
        local pattern_count
        pattern_count=$(grep -v '^#' "$HOME/.config/yadm/encrypt" | grep -v '^$' | wc -l | tr -d ' ')
        check_pass "Encryption patterns: $pattern_count"
    else
        check_warn "No encryption patterns file"
    fi

    # Check archive exists
    if [[ -f "$HOME/.local/share/yadm/archive" ]]; then
        check_pass "Encrypted archive exists"
    else
        check_warn "No encrypted archive (run: yadm encrypt)"
    fi
}

# =============================================================================
# SECRET PROTECTION CHECKS
# =============================================================================

check_secret_protection() {
    section "Secret Protection"

    # Check gitleaks is installed
    if command -v gitleaks &>/dev/null; then
        check_pass "gitleaks command available"
    else
        check_warn "gitleaks not installed (brew install gitleaks)"
    fi

    # Check pre-commit hook exists
    if [[ -x "$HOME/.config/yadm/hooks/pre_commit" ]]; then
        check_pass "Pre-commit hook installed"
    else
        check_warn "Pre-commit hook missing or not executable"
    fi

    # Check gitleaks config exists
    if [[ -f "$HOME/.config/yadm/gitleaks.toml" ]]; then
        check_pass "Gitleaks allowlist config exists"
    else
        check_warn "Gitleaks allowlist config missing"
    fi

    # Check gitignore exists and has patterns
    if [[ -f "$HOME/.config/yadm/gitignore" ]]; then
        local pattern_count
        pattern_count=$(grep -v '^#' "$HOME/.config/yadm/gitignore" | grep -v '^$' | wc -l | tr -d ' ')
        if [[ $pattern_count -ge 20 ]]; then
            check_pass "Gitignore has $pattern_count patterns"
        else
            check_warn "Gitignore only has $pattern_count patterns (expected 20+)"
        fi
    else
        check_warn "Gitignore file missing"
    fi
}

# =============================================================================
# LAUNCHD CHECKS (PRIMARY ONLY)
# =============================================================================

check_launchd() {
    section "Auto-Sync (Primary Machine)"

    if [[ "$MACHINE_CLASS" != "primary" ]]; then
        echo -e "  ${BLUE}→${NC} Skipped (machine class: $MACHINE_CLASS)"
        return
    fi

    local plist="$HOME/Library/LaunchAgents/com.yadm.autosync.plist"

    # Check plist exists
    if [[ -f "$plist" ]]; then
        check_pass "launchd plist exists"
    else
        check_fail "launchd plist missing"
        return
    fi

    # Check plist syntax
    if plutil -lint "$plist" &>/dev/null; then
        check_pass "Plist syntax valid"
    else
        check_fail "Plist syntax invalid"
    fi

    # Check if loaded
    if launchctl list com.yadm.autosync &>/dev/null; then
        check_pass "launchd agent loaded"
    else
        check_warn "Agent not loaded (launchctl load $plist)"
    fi

    # Check sync script exists
    if [[ -x "$HOME/.local/bin/yadm-auto-sync.sh" ]]; then
        check_pass "Sync script exists and executable"
    else
        check_fail "Sync script missing or not executable"
    fi

    # Check recent sync activity
    local log="$HOME/.local/share/yadm/auto-sync.log"
    if [[ -f "$log" ]]; then
        local last_sync
        last_sync=$(stat -f %m "$log" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        local age_hours=$(( (now - last_sync) / 3600 ))

        if [[ $age_hours -lt 2 ]]; then
            check_pass "Last sync: ${age_hours}h ago"
        elif [[ $age_hours -lt 24 ]]; then
            check_warn "Last sync: ${age_hours}h ago"
        else
            check_warn "Sync stale: ${age_hours}h ago"
        fi
    else
        check_warn "No sync log found"
    fi
}

# =============================================================================
# ALTERNATES CHECK
# =============================================================================

check_alternates() {
    section "Alternates"

    # Check if .zshrc is correctly linked
    if [[ -f "$HOME/.zshrc" ]]; then
        check_pass ".zshrc exists"

        # Check if it's the right alternate
        local expected_alt
        if [[ "$MACHINE_CLASS" == "primary" ]]; then
            expected_alt="$HOME/.zshrc##hostname.$CURRENT_HOSTNAME"
        else
            expected_alt="$HOME/.zshrc##default"
        fi

        if [[ -L "$HOME/.zshrc" ]]; then
            local target
            target=$(readlink "$HOME/.zshrc")
            if [[ "$target" == *"$CURRENT_HOSTNAME"* ]] || [[ "$target" == *"default"* ]]; then
                check_pass ".zshrc alternate correctly applied"
            else
                check_warn ".zshrc points to unexpected target"
            fi
        else
            # Real file, not symlink - this is fine for yadm alternates
            check_pass ".zshrc is a real file (yadm alternate)"
        fi
    else
        check_fail ".zshrc missing"
    fi
}

# =============================================================================
# SYNC STATUS CHECK
# =============================================================================

check_sync_status() {
    section "Sync Status"

    # Check for pending changes
    local changes
    changes=$(yadm status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ $changes -eq 0 ]]; then
        check_pass "No pending changes"
    else
        check_warn "$changes pending change(s)"
    fi

    # Check if behind remote (use cached fetch)
    local behind
    behind=$(yadm rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
    if [[ "$behind" -eq 0 ]]; then
        check_pass "Up to date with remote"
    else
        check_warn "$behind commit(s) behind remote (yadm pull)"
    fi

    # Check if ahead of remote
    local ahead
    ahead=$(yadm rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
    if [[ "$ahead" -eq 0 ]]; then
        check_pass "Nothing to push"
    else
        check_warn "$ahead commit(s) ahead (yadm push)"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      yadm Dotfiles Health Check        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "Machine: $CURRENT_HOSTNAME ($MACHINE_CLASS)"

    check_yadm
    check_gpg
    check_secret_protection
    check_launchd
    check_alternates
    check_sync_status

    # Summary
    section "Summary"
    echo -e "  ${GREEN}Passed:${NC} $PASS"
    echo -e "  ${YELLOW}Warnings:${NC} $WARN"
    echo -e "  ${RED}Failed:${NC} $FAIL"

    if [[ $FAIL -gt 0 ]]; then
        echo -e "\n${RED}Health check failed. See issues above.${NC}"
        exit 1
    elif [[ $WARN -gt 0 ]]; then
        echo -e "\n${YELLOW}Health check passed with warnings.${NC}"
        exit 0
    else
        echo -e "\n${GREEN}All checks passed!${NC}"
        exit 0
    fi
}

main "$@"
