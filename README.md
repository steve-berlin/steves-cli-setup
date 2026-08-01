# steves-cli-setup

[![ci](https://github.com/steve-berlin/steves-cli-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/steve-berlin/steves-cli-setup/actions/workflows/ci.yml)

A self-contained tmux + zsh environment: an Oh My Tmux!-style configuration with
session persistence that actually works, paired with a fast, framework-free zsh
and the [Starship](https://starship.rs) prompt.

## Why not Oh My Tmux!

Oh My Tmux! is excellent, but its plugin story is bolted on: `tmux-resurrect`,
`tmux-continuum` and pane dimming are left to TPM and frequently break after
upgrades. This repo ships those three as first-class, version-pinned parts of
the configuration:

- **tmux-resurrect** and **tmux-continuum** are vendored as git submodules, so
  the exact commit is recorded in the repo. No network access at tmux start, no
  TPM, no drift.
- **Pane dimming** uses tmux's native `window-style` / `window-active-style`
  instead of an unmaintained plugin. Nothing to install and nothing to break.

## Requirements

| Requirement  | Minimum  | Notes                                    |
| ------------ | -------- | ---------------------------------------- |
| tmux         | 3.3      | Developed against 3.5a                   |
| zsh          | 5.8      | Developed against 5.9                    |
| git          | 2.30     | Submodules are fetched during install    |
| starship     | 1.20     | Install it yourself, or pass `--with-starship` |
| A Nerd Font  | v3       | Downloaded by `install.sh` unless `--no-font` |

Optional, auto-detected and used when present: `fzf`, `eza`, `bat`, `fd`,
`ripgrep`, `zoxide`, `xclip` / `wl-clipboard`.

## Install

```sh
git clone https://github.com/steve-berlin/steves-cli-setup.git
cd steves-cli-setup
./install.sh --dry-run   # see exactly what would change
./install.sh
```

Then set your terminal's font to **JetBrainsMono Nerd Font** and start a new
shell.

| Flag              | Effect                                            |
| ----------------- | ------------------------------------------------- |
| `--dry-run`       | Print every change as a shell command, apply none  |
| `--uninstall`     | Remove only the symlinks this installer created    |
| `--with-starship` | Also run starship's official installer             |
| `--no-font`       | Skip the Nerd Font download                        |

The installer only ever creates symlinks, and it is idempotent — a second run
reports `already linked` and changes nothing.

## Deploy

The full sequence for a machine that already has dotfiles. Every step is
reversible; the point of no return does not exist, because nothing is deleted.

### 1. Check the prerequisites

```sh
tmux -V          # 3.3 or newer
zsh --version    # 5.8 or newer
echo "$SHELL"    # should end in /zsh
```

If `$SHELL` is not zsh, `chsh -s "$(command -v zsh)"` and log out and back in.
The installer does not change your login shell: that is a system-level change
with a bad failure mode, so it stays your decision.

### 2. Preview

```sh
./install.sh --dry-run
```

Read the output before continuing. Lines beginning `warn` are the ones that
matter — each names a file that will be moved aside, and the exact backup path
it will move to. Note those paths down; they are your rollback.

### 3. Install

```sh
./install.sh
```

Four symlinks are created (`~/.tmux.conf`, `~/.zshenv`, `~/.zshrc`,
`~/.config/starship.toml`), plus `~/.local/share/steves-cli-setup` pointing at
the clone. The vendored plugins are fetched at their pinned commits. Do not
move or rename the clone afterwards: the symlinks and the plugin paths both
resolve through it.

### 4. Set the terminal font

Set your terminal emulator's font to **JetBrainsMono Nerd Font**. Skipping this
leaves the status bar and prompt full of replacement boxes; nothing is broken,
the glyphs are simply not in the font. See
[KDE Plasma and Alacritty](#kde-plasma-and-alacritty) below for the exact
settings on the tested desktop.

### 5. Restart both

```sh
exec zsh                            # new shell, new config
tmux kill-server                    # only if a server is already running
tmux
```

`tmux source-file ~/.tmux.conf` reloads options and bindings, but it cannot
undo settings the old config applied, and continuum only arms its timer at
server start. On the first deploy, kill the server.

### 6. Verify

```sh
tmux show -g prefix                 # prefix C-a
tmux show -g renumber-windows       # renumber-windows on
tmux show -g @continuum-restore     # @continuum-restore on
ls ~/.local/share/tmux/resurrect/   # a new save appears within 15 minutes
```

Press `prefix + C-s` to force a save immediately rather than waiting. Continuum
disables its own auto-save whenever a second tmux server is running, so run
this check with exactly one server up.

### 7. Reclaim your old settings

Your previous `~/.zshrc` is intact at the backup path from step 2. Move
anything worth keeping into `~/.zshrc.local`, which this repo sources and never
overwrites — do not paste it back into the tracked `zsh/zshrc`.

### Rolling back

```sh
./install.sh --uninstall
mv ~/.zshrc.bak.<timestamp> ~/.zshrc
mv ~/.tmux.conf.bak.<timestamp> ~/.tmux.conf
```

Uninstall removes a symlink only if it points into this repository, so a
config you installed some other way in the meantime survives. Backups and the
font are never touched — delete them yourself once you are sure.

### What it will not do to your files

Anything already at a target path is **moved to `<path>.bak.<timestamp>`**,
whether it is a regular file or a symlink belonging to another dotfile setup.
Nothing is overwritten and nothing is deleted, with one exception: a dangling
symlink is removed, because there is nothing behind it to preserve.

`--uninstall` removes a link only if it points into this repository. Foreign
links, backups and the font are left alone.

Starship is deliberately *not* installed automatically. Piping a remote script
into a shell should be an explicit decision, so `--with-starship` exists and the
default merely warns.

### Local overrides

`~/.tmux.conf.local` and `~/.zshrc.local` are sourced when present and are never
written by the installer. Put machine-specific settings there rather than
editing the tracked files.

## KDE Plasma and Alacritty

The tested desktop is KDE Plasma on Wayland with Alacritty as the terminal.
Nothing here is required — the configuration works on any terminal that
reports RGB — but these are the settings that make it look and behave as
intended, and the two Wayland-specific traps worth knowing about.

### Alacritty

Alacritty has no font picker; the configuration is a TOML file it reads on
every save, so changes apply live to open windows. Create
`~/.config/alacritty/alacritty.toml`:

```toml
[font]
size = 11.0

[font.normal]
family = "JetBrainsMono Nerd Font"
style  = "Regular"

[env]
TERM = "alacritty"
```

The key names changed in Alacritty 0.13 (`[font.normal] family` used to be
`font.normal.family` in YAML), and the file moved from `alacritty.yml` to
`alacritty.toml`. Guides written before 2024 will not work as-is; check
`alacritty --version` against anything you copy.

Leave `TERM` as `alacritty` outside tmux. It is a real terminfo entry, shipped
in Debian's `ncurses-term`, and downgrading it to `xterm-256color` costs you
undercurl and styled underlines. Inside tmux the value is irrelevant — this
config sets `default-terminal tmux-256color` and advertises the outer
terminal's capabilities with `terminal-features`.

### Konsole

Konsole stores the font per profile, not globally: Settings → Edit Current
Profile → Appearance → Font → Select. Setting it anywhere else changes nothing,
and a fresh profile silently reverts to the default font.

One real limitation: **Konsole does not support OSC 52**, and has not for many
years. `set-clipboard on` in this configuration is therefore a no-op there, so
copying out of a tmux session running over SSH will not reach your local
clipboard. Local copies still work through the `xclip` / `wl-copy` bindings.
Alacritty does support OSC 52 for copy by default, which is the main reason it
is the tested terminal.

### Wayland clipboard

Install `wl-clipboard`, or copying will take a detour you did not ask for:

```sh
sudo apt install wl-clipboard
```

The copy binding prefers `wl-copy` when `WAYLAND_DISPLAY` is set, and falls
back to `xclip` otherwise. Without `wl-clipboard` on a Wayland session, `xclip`
is what runs, which means the copy goes into XWayland's X11 clipboard and only
reaches native Wayland applications because KWin bridges the two. That bridge
works, until XWayland is not running — then copying fails silently, with no
error anywhere.

`WAYLAND_DISPLAY` is read once, when the tmux **server** starts. A server
started from a TTY or an X11 session keeps the X11 binding for its entire life,
however many Wayland clients later attach to it. After installing
`wl-clipboard`, run `tmux kill-server` so the check runs again.

## What is included

| File | What it does |
| ---- | ------------ |
| `tmux/tmux.conf` | `C-a` prefix (`C-b` still works), 1-indexed auto-renumbering windows, vi copy mode with system clipboard and OSC 52, fzf session/window popups on `prefix+s` / `prefix+w`, Nord status bar, native pane dimming, resurrect + continuum |
| `zsh/zshrc` | history, completion, aliases and deferred plugins — 22 ms to prompt |
| `zsh/zshenv` | opts out of Debian's redundant global `compinit` |
| `starship/starship.toml` | two-line Nord prompt, ~9 ms |
| `install.sh` | symlink deployment, idempotent, reversible |

Ten files and 800 lines in total, with three runtime dependencies: tmux, zsh
and git.

## Licence

[MIT](LICENSE)
