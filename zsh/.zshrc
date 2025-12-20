# IMPORTANT: Core PATH configuration moved to ~/.zshenv
#
# ~/.zshenv is loaded for ALL shells (interactive + non-interactive)
# This fixes pytest-xdist workers not finding docker/python.
# See: ~/.zshenv for /usr/local/bin, Python 3.11, etc.


# Add other paths correctly
export PATH="/Users/alex/Library/Application Support/pypoetry/bin:$PATH"
export PATH="/opt/homebrew/opt/poppler/bin:$PATH"
export PATH="$PATH:$HOME/.local/opt/go/bin"
export PATH="$PATH:$HOME/go/bin"

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Load vi mode key bindings (official zsh vi mode)
bindkey -v

# Reduce ESC delay (vi mode responsiveness)
# Default is 40 (0.4s), setting to 10 (0.1s) for responsive but reliable vi mode
export KEYTIMEOUT=10

# Keep useful emacs-style keybindings in INSERT mode (viins keymap)
bindkey -M viins '^R' history-incremental-search-backward  # Ctrl+R for history search
bindkey -M viins '^A' beginning-of-line                    # Ctrl+A for start of line
bindkey -M viins '^E' end-of-line                          # Ctrl+E for end of line

# Alt/Option + arrow keys in INSERT mode
bindkey -M viins '^[[1;3D' backward-word     # Option + Left
bindkey -M viins '^[[1;3C' forward-word      # Option + Right

# Ensure terminal is set correctly
export TERM=xterm-256color

# Set default editor to Neovim (using wrapper to fix claude-code focus reporting bug)
# See: https://github.com/anthropics/claude-code/issues/10375
export EDITOR="$HOME/.local/bin/nvim-wrapper"
export VISUAL="$HOME/.local/bin/nvim-wrapper"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
# opencode
export PATH=/Users/alex/.opencode/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# CC-Trace: mitmproxy configuration for Claude Code API interception
proxy_claude() {
    # Set proxy environment variables
    export HTTP_PROXY=http://127.0.0.1:8080
    export HTTPS_PROXY=http://127.0.0.1:8080
    export http_proxy=http://127.0.0.1:8080
    export https_proxy=http://127.0.0.1:8080

    # Point Node.js to mitmproxy's CA certificate
    export NODE_EXTRA_CA_CERTS="$HOME/.mitmproxy/mitmproxy-ca-cert.pem"

    # Disable SSL verification warnings (use with caution - local debugging only)
    export NODE_TLS_REJECT_UNAUTHORIZED=0

    echo "🔍 Proxy configured for mitmproxy (http://127.0.0.1:8080)"
    echo "📜 Using CA cert: $NODE_EXTRA_CA_CERTS"
    echo "🚀 Starting Claude Code..."

    # Launch Claude Code (use cc wrapper with any passed flags)
    cc "$@"
}

# Claude CLI wrapper (cc) with custom short flags and project shortcuts
# Expands short flags before passing to claude, disables focus reporting
#
# Custom flags (not native):
#   -dsp  → --dangerously-skip-permissions
#   -mo   → --model opus
#   -ms   → --model sonnet
#   -mh   → --model haiku
#
# Project shortcuts (dynamic):
#   @<project>  → Opens session in ~/Documents/GitHub/<project>
#   Examples: @incide, @incide-portable, @cc-trace-new
#
# Native flags (pass through):
#   -r    → --resume
#   -c    → --continue
#   -p    → --print
#
# Examples:
#   cc -dsp -mo           → claude --dangerously-skip-permissions --model opus
#   cc -ms -r             → claude --model sonnet --resume
#   cc -dsp -mh -c        → claude --dangerously-skip-permissions --model haiku --continue
#   cc @incide            → opens claude in ~/Documents/GitHub/incide
#   cc -dsp -mo @incide   → skip permissions + opus in incide project
#
cc() {
    local dir=""
    local args=()
    local github_base="/Users/alex/Documents/GitHub"

    for arg in "$@"; do
        # @project pattern: opens Claude in ~/Documents/GitHub/<project>
        if [[ "$arg" == @* ]] && [[ ${#arg} -gt 1 ]]; then
            local project="${arg#@}"
            local project_path="$github_base/$project"
            if [[ -d "$project_path" ]]; then
                if [[ -n "$dir" ]]; then
                    echo "cc: multiple projects specified (already using ${dir##*/})" >&2
                    return 1
                fi
                dir="$project_path"
            else
                echo "cc: project '$project' not found in $github_base" >&2
                return 1
            fi
        elif [[ "$arg" == "-dsp" ]]; then
            args+=(--dangerously-skip-permissions)
        elif [[ "$arg" == "-mo" ]]; then
            args+=(--model opus)
        elif [[ "$arg" == "-ms" ]]; then
            args+=(--model sonnet)
        elif [[ "$arg" == "-mh" ]]; then
            args+=(--model haiku)
        else
            args+=("$arg")
        fi
    done

    printf '\e[?1004l'  # Disable focus reporting before starting
    if [[ -n "$dir" ]]; then
        (cd "$dir" && command claude "${args[@]}")
    else
        command claude "${args[@]}"
    fi
    local exit_code=$?
    printf '\e[?1004l'  # Re-disable after exit
    return $exit_code
}

# Tab completion for cc: completes @project names from GitHub directory
_cc_complete() {
    local github_base="/Users/alex/Documents/GitHub"
    local cur="${words[CURRENT]}"

    # Complete @project shortcuts
    if [[ "$cur" == @* ]]; then
        local prefix="${cur#@}"
        local projects=("$github_base"/${prefix}*(/:t))
        compadd -P '@' -- "${projects[@]}"
    # Complete flags
    elif [[ "$cur" == -* ]]; then
        compadd -- -dsp -mo -ms -mh -r -c -p
    fi
}
# Register completion if zsh completion system is available
(( $+functions[compdef] )) && compdef _cc_complete cc

# Added by Antigravity
export PATH="/Users/alex/.antigravity/antigravity/bin:$PATH"
source "$HOME/.cargo/env"

# ============================================================================
# FIX: Disable focus reporting (MUST BE AT END OF FILE)
# ============================================================================
# Map focus reporting escape sequences to nothing (ZLE equivalent of .inputrc)
bindkey -s '\e[I' ''
bindkey -s '\e[O' ''
# Ghostty's shell integration re-enables focus reporting (DECSET 1004).
# This causes ^[[I and ^[[O escape sequences in claude-cli when using Cmd+Tab.
# We disable it here at the END of .zshrc (after shell integration loads)
# and also via precmd hook to ensure it stays disabled.

# Disable immediately after shell integration loads
printf '\e[?1004l'

# Add precmd hook to disable before each prompt (ensures it stays disabled)
_disable_focus_reporting() {
    printf '\e[?1004l'
}

# Initialize precmd_functions if it doesn't exist, then add our function
[[ -z "$precmd_functions" ]] && precmd_functions=()
precmd_functions+=(_disable_focus_reporting)

# fnm
FNM_PATH="/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]; then
  eval "`fnm env`"
fi

# =============================================================================
# DOTFILES
# =============================================================================

# Dotfiles status alias
alias dfs="~/.dotfiles/scripts/sync-status.sh"

# Load secrets (gitignored)
[ -f ~/.secrets.env ] && source ~/.secrets.env

# Warn if dotfiles sync is stale (>24 hours)
~/.dotfiles/scripts/sync-status.sh --check 2>/dev/null
