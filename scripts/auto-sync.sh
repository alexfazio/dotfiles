#!/bin/bash
# =============================================================================
# auto-sync.sh - Automated dotfiles sync with secret protection
# =============================================================================
# Features:
#   - Secret scanning via gitleaks before commit
#   - macOS notifications on failure
#   - Health file tracking for monitoring
#   - Brewfile auto-update
#
# Usage:
#   ./auto-sync.sh           # Run sync
#   ./auto-sync.sh --force   # Skip secret scan (not recommended)
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
HEALTH_FILE="$DOTFILES_DIR/.last-sync"
LOG_FILE="$DOTFILES_DIR/.sync.log"
LOCK_FILE="/tmp/dotfiles-sync.lock"

# =============================================================================
# HELPERS
# =============================================================================

log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

notify_error() {
    local message="$1"
    log "ERROR: $message"

    # macOS notification
    osascript -e "display notification \"$message\" with title \"Dotfiles Sync Failed\" sound name \"Basso\"" 2>/dev/null || true

    # Update health file with error
    echo "error|$(date '+%Y-%m-%d %H:%M:%S')|$message" > "$HEALTH_FILE"
}

notify_success() {
    local message="$1"
    log "SUCCESS: $message"

    # Update health file
    echo "ok|$(date '+%Y-%m-%d %H:%M:%S')|$message" > "$HEALTH_FILE"
}

cleanup() {
    rm -f "$LOCK_FILE"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    # Parse args
    local skip_scan=false
    if [[ "${1:-}" == "--force" ]]; then
        skip_scan=true
        log "WARNING: Skipping secret scan (--force)"
    fi

    # Prevent concurrent runs
    if [[ -f "$LOCK_FILE" ]]; then
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log "Another sync is running (PID: $pid). Exiting."
            exit 0
        fi
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
    trap cleanup EXIT

    cd "$DOTFILES_DIR" || {
        notify_error "Cannot access $DOTFILES_DIR"
        exit 1
    }

    log "Starting dotfiles sync..."

    # Update Brewfile
    if command -v brew &>/dev/null; then
        log "Updating Brewfile..."
        if ! brew bundle dump --file="$DOTFILES_DIR/Brewfile" --force 2>&1 | tee -a "$LOG_FILE"; then
            log "WARNING: Brewfile update failed, continuing..."
        fi
    fi

    # Check for changes
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        log "No changes to sync"
        notify_success "No changes"
        exit 0
    fi

    # Run gitleaks scan before staging
    if [[ "$skip_scan" == "false" ]]; then
        log "Scanning for secrets..."
        if ! gitleaks detect --source . --verbose 2>&1 | tee -a "$LOG_FILE"; then
            notify_error "Secrets detected! Commit blocked."
            exit 1
        fi
    fi

    # Stage all changes
    git add -A

    # Run pre-commit hooks (includes gitleaks)
    if [[ "$skip_scan" == "false" ]] && command -v pre-commit &>/dev/null; then
        log "Running pre-commit hooks..."
        if ! pre-commit run --all-files 2>&1 | tee -a "$LOG_FILE"; then
            notify_error "Pre-commit hooks failed!"
            git reset HEAD
            exit 1
        fi
    fi

    # Commit
    local commit_msg
    commit_msg="Auto-sync: $(date '+%Y-%m-%d %H:%M')"
    if ! git commit -m "$commit_msg" 2>&1 | tee -a "$LOG_FILE"; then
        notify_error "Commit failed!"
        exit 1
    fi

    # Push
    log "Pushing to remote..."
    if ! git push 2>&1 | tee -a "$LOG_FILE"; then
        notify_error "Push failed! Check network."
        exit 1
    fi

    notify_success "Synced $(git rev-parse --short HEAD)"
    log "Sync complete!"
}

main "$@"
