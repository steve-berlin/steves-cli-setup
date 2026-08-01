# steves-cli-setup

Oh My Tmux!-style tmux config + framework-free zsh + Starship. Deployed by
symlink; the repo is the source of truth for every config file.

## Design rules

- **Minimalism first.** Fewest files, fewest lines, fewest dependencies that
  still gets the job done. Justify every new file and every new dependency.
- **No runtime plugin managers.** No TPM, no oh-my-zsh, no zinit. Third-party
  code is vendored as git submodules under `vendor/` so the commit is pinned in
  the repo and nothing hits the network at shell or tmux start.
- **Optional deps are optional.** Anything not in the Requirements table must be
  feature-detected (`command -v`) with a working fallback.
- **The repo never edits user files.** `install.sh` only symlinks. Pre-existing
  regular files are moved to `<path>.bak.<timestamp>` first.
- **User overrides live in `*.local` files** which are gitignored and never
  written by the installer.

## Layout

| Path                    | Purpose                                    |
| ----------------------- | ------------------------------------------ |
| `tmux/tmux.conf`        | tmux configuration (symlinked to `~/.tmux.conf`) |
| `zsh/zshrc`             | zsh configuration (symlinked to `~/.zshrc`) |
| `starship/starship.toml`| prompt (symlinked to `~/.config/starship.toml`) |
| `vendor/`               | git submodules — third-party code only     |
| `install.sh`            | symlink deployment; idempotent             |

## Conventions

- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, must pass
  `shellcheck`. Two-space indent.
- `install.sh` must support `--dry-run` and `--uninstall`, and must stay
  idempotent — running it twice changes nothing the second time.
- tmux config is a single file, ordered: options, keybindings, theme, plugins.
- Never source anything from `~/.zshrc` history or other personal dotfiles into
  this repo; it is meant to be publishable and machine-independent.

## Target profile

Primary target is Debian 13 (trixie), tmux 3.5a, zsh 5.9, X11, no mouse
support wanted, JetBrainsMono Nerd Font. Keep everything else portable: macOS
and Wayland paths must not be broken, but the above is what gets tested.

## Non-obvious decisions

- **Pane dimming needs no plugin.** tmux 3.3+ `window-style` /
  `window-active-style` do it natively. The dim-pane plugins are unmaintained;
  do not reintroduce one.
- **`escape-time` is 10ms, not 0.** Zero breaks some terminals over slow SSH
  links; 10 is enough to keep vim's ESC responsive.
- **`tmux-continuum` must be the last plugin sourced.** It rewrites
  `status-right` to store its save timestamp, so anything sourced after it that
  also touches `status-right` will silently disable auto-save.
