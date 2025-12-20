#!/bin/bash
# Smart tmux session management for Ghostty
# - First window: attach to existing detached session (resume work)
# - Additional windows: create new sessions

TMUX=/opt/homebrew/bin/tmux

# Find first detached session (not attached by any client)
DETACHED=$($TMUX ls 2>/dev/null | grep -v "(attached)" | head -1 | cut -d: -f1)

if [ -n "$DETACHED" ]; then
    # Detached session exists - attach to it (resume work)
    exec $TMUX attach-session -t "$DETACHED"
else
    # No detached sessions - create a new one
    exec $TMUX new-session
fi
