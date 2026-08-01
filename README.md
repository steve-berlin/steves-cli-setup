# steves-cli-setup

A self-contained tmux + zsh environment: an Oh My Tmux!-style configuration with
session persistence that actually works, paired with a fast, framework-free zsh
and the [Starship](https://starship.rs) prompt.

Status: **work in progress** — see [Roadmap](#roadmap).

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

## Roadmap

- [x] Repository skeleton
- [x] tmux core configuration
- [x] tmux status bar and theme
- [x] Session persistence (resurrect + continuum) and pane dimming
- [x] Starship prompt
- [x] zsh configuration
- [x] `install.sh`
- [ ] CI and first release

## Licence

[MIT](LICENSE)
