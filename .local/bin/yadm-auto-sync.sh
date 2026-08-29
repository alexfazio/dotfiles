#!/bin/bash
# =============================================================================
# yadm-auto-sync.sh - Automatic dotfiles sync for primary machine
# =============================================================================
# Runs via launchd every hour. Commits and pushes any uncommitted changes
# to tracked files. Only operates on the primary machine.
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

PRIMARY_HOSTNAME="paradigma"
LOG_FILE="$HOME/.local/share/yadm/auto-sync.log"
LOCK_FILE="/tmp/yadm-auto-sync.lock"

# -----------------------------------------------------------------------------
# LOGGING
# -----------------------------------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# -----------------------------------------------------------------------------
# GUARDS
# -----------------------------------------------------------------------------

# Only run on primary machine
CURRENT_HOSTNAME=$(hostname -s)
if [[ "$CURRENT_HOSTNAME" != "$PRIMARY_HOSTNAME" ]]; then
    log "SKIP: Not primary machine ($CURRENT_HOSTNAME != $PRIMARY_HOSTNAME)"
    exit 0
fi

# Prevent concurrent runs
if [[ -f "$LOCK_FILE" ]]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [[ -n "$LOCK_PID" ]] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log "SKIP: Another sync is running (PID $LOCK_PID)"
        exit 0
    fi
    # Stale lock, remove it
    rm -f "$LOCK_FILE"
fi

# Create lock
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# -----------------------------------------------------------------------------
# SYNC
# -----------------------------------------------------------------------------

cd "$HOME"

# Check for uncommitted changes to tracked files
if yadm diff --quiet 2>/dev/null; then
    log "OK: No changes to sync"
    exit 0
fi

# Stage tracked file changes
yadm add -u

# Get list of changed files for commit message
CHANGED_FILES=$(yadm diff --cached --name-only | head -5 | tr '\n' ', ' | sed 's/,$//')
if [[ $(yadm diff --cached --name-only | wc -l) -gt 5 ]]; then
    CHANGED_FILES="${CHANGED_FILES}, ..."
fi

# Commit
COMMIT_MSG="Auto-sync: ${CHANGED_FILES:-updates}"
if ! yadm commit -m "$COMMIT_MSG" 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Commit failed"
    exit 1
fi

# Push
if ! yadm push 2>&1 | tee -a "$LOG_FILE"; then
    log "ERROR: Push failed"
    exit 1
fi

log "OK: Synced - $COMMIT_MSG"

# -----------------------------------------------------------------------------
# LOG ROTATION (keep last 1000 lines)
# -----------------------------------------------------------------------------

if [[ -f "$LOG_FILE" ]] && [[ $(wc -l < "$LOG_FILE") -gt 1000 ]]; then
    tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp"
    mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi
