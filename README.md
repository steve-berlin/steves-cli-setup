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
| starship     | 1.20     | Installed by `install.sh` if missing     |
| A Nerd Font  | v3       | Installed by `install.sh` if missing     |

Optional, auto-detected and used when present: `fzf`, `eza`, `bat`, `fd`,
`ripgrep`, `zoxide`, `xclip` / `wl-clipboard`.

## Install

```sh
git clone --recurse-submodules https://github.com/steve-berlin/steves-cli-setup.git
cd steves-cli-setup
./install.sh
```

`install.sh` is idempotent, supports `--dry-run` and `--uninstall`, and only
ever creates symlinks — your own files are backed up, never overwritten.

## Roadmap

- [x] Repository skeleton
- [ ] tmux core configuration
- [ ] tmux status bar and theme
- [ ] Session persistence (resurrect + continuum) and pane dimming
- [ ] Starship prompt
- [ ] zsh configuration
- [ ] `install.sh`
- [ ] CI and first release

## Licence

[MIT](LICENSE)
