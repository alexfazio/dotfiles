#!/bin/bash
# =============================================================================
# sync-status.sh - Check dotfiles sync health
# =============================================================================
# Usage:
#   ./sync-status.sh          # Full status
#   ./sync-status.sh --brief  # One-line summary (for shell prompt)
#   ./sync-status.sh --check  # Exit 1 if stale (for shell startup warning)
# =============================================================================

DOTFILES_DIR="$HOME/.dotfiles"
HEALTH_FILE="$DOTFILES_DIR/.last-sync"
STALE_HOURS=24  # Consider stale after 24 hours

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

get_status() {
    if [[ ! -f "$HEALTH_FILE" ]]; then
        echo "unknown|never|No sync recorded"
        return
    fi
    cat "$HEALTH_FILE"
}

is_stale() {
    if [[ ! -f "$HEALTH_FILE" ]]; then
        return 0  # No file = stale
    fi

    local last_sync
    last_sync=$(stat -f %m "$HEALTH_FILE" 2>/dev/null || echo 0)
    local now
    now=$(date +%s)
    local age_hours=$(( (now - last_sync) / 3600 ))

    [[ $age_hours -ge $STALE_HOURS ]]
}

show_full_status() {
    echo "=== Dotfiles Sync Status ==="
    echo ""

    local status_line
    status_line=$(get_status)
    local status
    status=$(echo "$status_line" | cut -d'|' -f1)
    local timestamp
    timestamp=$(echo "$status_line" | cut -d'|' -f2)
    local message
    message=$(echo "$status_line" | cut -d'|' -f3-)

    case "$status" in
        ok)
            echo -e "Status: ${GREEN}OK${NC}"
            ;;
        error)
            echo -e "Status: ${RED}ERROR${NC}"
            ;;
        *)
            echo -e "Status: ${YELLOW}UNKNOWN${NC}"
            ;;
    esac

    echo "Last sync: $timestamp"
    echo "Message: $message"
    echo ""

    # Check if stale
    if is_stale; then
        echo -e "${YELLOW}Warning: Sync is stale (>$STALE_HOURS hours)${NC}"
    fi

    # Show pending changes
    cd "$DOTFILES_DIR" 2>/dev/null || return
    local changes
    changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [[ $changes -gt 0 ]]; then
        echo ""
        echo "Pending changes: $changes file(s)"
        git status --short
    fi
}

show_brief() {
    local status_line
    status_line=$(get_status)
    local status
    status=$(echo "$status_line" | cut -d'|' -f1)
    local timestamp
    timestamp=$(echo "$status_line" | cut -d'|' -f2)

    case "$status" in
        ok)
            if is_stale; then
                echo -e "${YELLOW}dotfiles: stale${NC}"
            else
                echo -e "${GREEN}dotfiles: ok${NC}"
            fi
            ;;
        error)
            echo -e "${RED}dotfiles: error${NC}"
            ;;
        *)
            echo -e "${YELLOW}dotfiles: unknown${NC}"
            ;;
    esac
}

check_health() {
    local status_line
    status_line=$(get_status)
    local status
    status=$(echo "$status_line" | cut -d'|' -f1)

    if [[ "$status" == "error" ]]; then
        echo -e "${RED}Dotfiles sync failed! Run: dfs${NC}"
        return 1
    fi

    if is_stale; then
        echo -e "${YELLOW}Dotfiles sync stale (>$STALE_HOURS hours). Run: ~/.dotfiles/scripts/auto-sync.sh${NC}"
        return 1
    fi

    return 0
}

case "${1:-}" in
    --brief)
        show_brief
        ;;
    --check)
        check_health
        ;;
    *)
        show_full_status
        ;;
esac
