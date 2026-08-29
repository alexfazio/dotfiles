# Rust / Cargo Across Machines

## Background

`~/.zshenv` sources `~/.cargo/env` to add `~/.cargo/bin` to PATH for Rust
toolchains installed via `rustup`. This file is only created by `rustup` — it
does **not** exist when Rust is installed via `brew install rust`.

Since `.zshenv` is loaded for every shell (interactive, non-interactive,
scripts, background jobs), a missing `.cargo/env` causes a startup error on
any machine without rustup:

```
/Users/<user>/.zshenv:20: no such file or directory: /Users/<user>/.cargo/env
```

## The Fix

Guard the source with a file existence check:

```zsh
# ~/.zshenv
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
```

This is safe for all scenarios:

| Machine state | `~/.cargo/env` exists? | Behaviour |
|---------------|------------------------|-----------|
| rustup installed | Yes | Sourced normally — cargo/rustc in PATH |
| brew rust only | No | Skipped silently — no error |
| No rust at all | No | Skipped silently — no error |
| Recovery (rustup reinstalled) | Yes (after install) | Sourced automatically |

## Installing Rust

**Recommended: rustup** (official toolchain manager)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Creates `~/.cargo/env` and manages `stable`/`nightly`/`beta` toolchains.
Update with `rustup update`.

**Alternative: Homebrew**

```bash
brew install rust
```

Installs to `/opt/homebrew/bin/`. Does **not** create `~/.cargo/env`.
Avoid mixing with rustup — they conflict on PATH.

## Secondary Machine Checklist

If you see the `.cargo/env` error on a new machine:

1. Confirm the guard is in `.zshenv` (pull latest dotfiles: `yadm pull`)
2. If you need Rust: install via rustup (above)
3. Open a new terminal — error should be gone
