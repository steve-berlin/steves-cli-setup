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
| `zsh/zshenv`            | sourced before all else (symlinked to `~/.zshenv`) |
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

Primary target is Debian 13 (trixie), tmux 3.5a, zsh 5.9, KDE Plasma on
Wayland, Alacritty, no mouse support wanted, JetBrainsMono Nerd Font. Keep
everything else portable: macOS, X11 and Konsole paths must not be broken, but
the above is what gets tested.

## Non-obvious decisions

- **Pane dimming needs no plugin.** tmux 3.3+ `window-style` /
  `window-active-style` do it natively. The dim-pane plugins are unmaintained;
  do not reintroduce one.
- **`escape-time` is 10ms, not 0.** Zero breaks some terminals over slow SSH
  links; 10 is enough to keep vim's ESC responsive.
- **`tmux-continuum` must be the last plugin sourced.** It prepends a
  `#(continuum_save.sh)` interpolation to `status-right` and drives its timer
  off the status bar redraw, so anything that replaces `status-right` after it
  loads silently disables auto-save. This is why `~/.tmux.conf.local` is sourced
  *before* the plugins rather than at the end of the file.
- **Continuum disables its own auto-save when a second tmux server is running.**
  `another_tmux_server_running` in `continuum.tmux` skips the status-right hook
  entirely so that two servers cannot overwrite each other's saved state. A
  config test run from inside an existing tmux session will therefore always
  show a missing hook — that is the guard working, not a broken config. Verify
  auto-save on a machine with exactly one tmux server.
- **`status-interval` bounds continuum's save granularity.** The save check only
  runs when the status bar redraws, so `status-interval 0` would disable
  auto-save no matter what `@continuum-save-interval` says.
- **`compinit` must be called with `-i`.** A single group-writable directory in
  `fpath` otherwise makes it block on a yes/no prompt before the first prompt is
  drawn. Homebrew on macOS and most CI runners both produce exactly that. `-i`
  drops the offending directories; do not "fix" this with `-u`, which loads
  their completion functions regardless and is the unsafe option.
- **`zsh/zshenv` exists solely to set `skip_global_compinit=1`.** Debian and
  Ubuntu's `/etc/zsh/zshrc` runs its own unguarded `compinit` before `~/.zshrc`
  is read, which both reintroduces that blocking prompt and pays for the
  slowest part of zsh startup twice. The opt-out is only read if it is already
  set by then, so it cannot live in `zshrc`. Do not merge this file into
  `zshrc`.
- **Test the empty-dump case, not just the stale one.** `${dump}(#qN.mh+24)`
  matches nothing when the file is absent, so a staleness-only test sends a
  brand-new machine down the `compinit -C` path — no audit and no dump to
  load, which yields a shell with no completions at all.
- **The fzf popups are not a tmux mode.** `display-popup -E` runs a shell, so
  none of `choose-tree`'s keys reach the server — no `:` command prompt, no `x`
  to kill, no `f` filter. Anything the popup should do has to be bound on the
  fzf side one key at a time (`--bind ctrl-x:...`), and a destructive bind needs
  a `reload(...)` after it or the list keeps showing what was just killed. This
  is why stock `choose-tree` stays reachable on `prefix + S` / `prefix + W`
  rather than being replaced outright.
- **`detach-on-destroy off` is what makes the popup's `ctrl-x` safe.** With the
  default `on`, killing the session you are attached to drops the client back to
  the shell instead of moving it to another session. tmux still detaches when no
  other session is left, so the option changes the common case only.
- **The clipboard `if-shell` checks run once, at server start.** `WAYLAND_DISPLAY`
  is read from the environment the tmux *server* was forked with, so a server
  started under X11 or from a TTY keeps the `xclip` binding for its whole life
  no matter what later attaches to it. Changing clipboard tooling needs
  `tmux kill-server`, not `source-file`.
- **OSC 52 is not universal.** `set-clipboard on` is a silent no-op on
  terminals that lack it (Konsole is the usual example), so the remote-copy
  path cannot be assumed. Local copying does not depend on it.
- **Document terminal capabilities, not terminals.** README gives the reader
  three checks to run — RGB, Nerd Font glyphs, OSC 52 — instead of per-emulator
  recipes, because the recipe list is unbounded and goes stale while the
  capabilities do not. Resist adding a section per terminal.
