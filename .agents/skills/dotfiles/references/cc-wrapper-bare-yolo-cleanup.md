# CC Wrapper: --yolo Removal and -bare Exclusivity Guards

**Created:** 2026-02-28
**Context:** Cleanup of dead `--yolo` flag and addition of `-bare` exclusivity guards in the `cc()` wrapper function in `~/.zshrc`.

## Problem Statement

The `cc()` wrapper in `~/.zshrc` had two issues:

1. **Dead `--yolo` flag**: Referenced `~/.claude/yolo-settings.json` which was never created. Using `--yolo` caused a hard error (`Error: Settings file not found`) — Claude Code refused to start.

2. **Unrestricted `-bare` flag combining**: The `-bare` flag (which strips all settings via `--setting-sources ''`) could be freely combined with other settings-altering flags (`-dh`, `-glm`, `-mm`), producing commands with multiple `--settings` arguments whose merge behavior is undefined.

## Root Cause

- `--yolo` was added (commit `bccdaf4`, Feb 26) without its corresponding `yolo-settings.json` file ever being created.
- `-bare` (commit `9c80d8d`, Feb 22) uses `--setting-sources ''` to clear all user settings for clean-slate testing, but had no guards preventing combination with flags that re-add `--settings` layers.
- The `-dh` flag is redundant with `-bare` because `bare-settings.json` already contains `"disableAllHooks": true`.

## Changes Made

### 1. Full --yolo Removal

All references removed (12 occurrences → 0):

| Component | Before | After |
|-----------|--------|-------|
| Comment header | Listed `--yolo` as a flag | Removed |
| Example comments | `cc --yolo @incide` | `cc -bare @incide -mo` |
| `has_yolo` boolean | `local has_yolo=false has_dh=false has_bare=false` | Removed `has_yolo` |
| `elif` branch | `elif [[ "$arg" == "--yolo" ]]; then ...` | Removed entirely |
| Clash guards | `if $has_yolo && $has_dh` / `if $has_yolo && $has_bare` | Replaced with bare guards |
| Tab completion | Included `--yolo` | Removed |

### 2. -bare Exclusivity Guard

Added a single clash guard: `-bare` + `-dh` is rejected (redundant — bare already disables hooks).

```zsh
# Clash guard: -bare already disables hooks, -dh is redundant
if $has_bare && $has_dh; then
    echo "cc: -bare and -dh clash (-bare already disables hooks)" >&2
    return 1
fi
```

**Allowed combinations** (user requirement):
- `cc -bare -glm` — strips user settings, layers Z.AI provider config
- `cc -bare -mm` — strips user settings, layers MiniMax provider config
- `cc -bare -mo` / `-ms` / `-mh` — model flags don't touch settings
- `cc -bare @project` — directory changes don't affect settings

### 3. Flag Tracking Booleans

Replaced `has_yolo` with `has_glm` and `has_mm` for tracking settings-altering flags:

```zsh
# Before:
local has_yolo=false has_dh=false has_bare=false

# After:
local has_dh=false has_glm=false has_mm=false has_bare=false
```

Added `has_glm=true` and `has_mm=true` in their respective `elif` branches (previously these flags didn't track their state).

### 4. Tab Completion Updated

```zsh
# Before:
compadd -- -dsp -mo -ms -mh -glm -mm -dh --yolo -r -c -p

# After:
compadd -- -dsp -mo -ms -mh -glm -mm -dh -bare -r -c -p
```

Note: `-bare` was missing from tab completion before this change.

### 5. Comment Updates

```bash
# Before:
#   --yolo -> --settings ~/.claude/yolo-settings.json (autonomous yolo mode)

# After:
#   -bare -> zero-config mode: no settings layers, no MCPs, no hooks, no skills
#            (exclusive with -dh; combinable with -glm, -mm)
```

Example section updated from `cc --yolo @incide` to `cc -bare @incide -mo`.

## Design Decision: -bare + -glm/-mm Allowed

Initially, `-bare` was made exclusive with all settings-altering flags (including `-glm` and `-mm`). The user requested that `-bare` be combinable with provider flags:

- **Use case**: Testing third-party providers (GLM, MiniMax) without user settings layers
- **Behavior**: `--setting-sources ''` strips user/project settings, then `--settings zai-settings.json` layers the provider config on top of `bare-settings.json`
- **Only `-dh` is blocked**: Because it's genuinely redundant (bare already disables hooks)

## Files Modified

| File | Change |
|------|--------|
| `~/.zshrc` | Removed all `--yolo` references (flag, branch, boolean, guards, comments, completion) |
| `~/.zshrc` | Added `has_glm` and `has_mm` tracking booleans |
| `~/.zshrc` | Added `-bare` + `-dh` clash guard |
| `~/.zshrc` | Added `-bare` to tab completion |
| `~/.zshrc` | Updated comments documenting flag behavior |

No other files were modified. `bare-settings.json` was left unchanged.

## Verification

```bash
# Verify no yolo references remain
zsh -c 'source ~/.zshrc; functions cc | grep -i yolo'
# Expected: no output

# Verify -bare flag handler exists
zsh -c 'source ~/.zshrc; functions cc | grep -A2 "\-bare"'

# Verify clash guard
zsh -c 'source ~/.zshrc; functions cc | grep -A2 "has_bare"'

# Verify tab completion includes -bare
zsh -c 'source ~/.zshrc; functions _cc_complete | grep compadd'

# Verify syntax is valid
zsh -n ~/.zshrc && echo "Syntax OK"

# Test clash guard
cc -bare -dh  # Should print error and exit
# Expected: "cc: -bare and -dh clash (-bare already disables hooks)"

# Test allowed combinations
cc -bare -glm  # Should launch successfully
cc -bare @incide -mo  # Should launch in incide with opus
```

## Related

- CC Wrapper Disable Hooks: see cc-config skill `references/cc-wrapper-disable-hooks.md`
- AskUserQuestion 2.1.63 Regression: see cc-config skill `references/askuserquestion-2163-regression.md`
- Third-Party Providers: see cc-config skill `references/third-party-providers.md`
