# .zshenv - Loaded for ALL shells (interactive + non-interactive)
#
# This file is sourced by zsh for:
# - Interactive shells (terminal sessions)
# - Non-interactive shells (scripts, subprocesses)
# - pytest-xdist workers
# - Background jobs
#
# Use this for PATH and environment variables needed everywhere.

# Ensure /usr/local/bin is in PATH (required for OrbStack Docker and other tools)
# This MUST be in .zshenv (not .zshrc) for pytest-xdist workers to find docker
export PATH="/usr/local/bin:$PATH"

# Ensure Python 3.11 is FIRST in the PATH
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"

# Remove conflicting Python versions from PATH
export PATH=$(echo $PATH | awk -v RS=: -v ORS=: '/Library\/Frameworks\/Python.framework\/Versions\/3.12\/bin/ {next} {print}' | sed 's/:$//')
. "$HOME/.cargo/env"
