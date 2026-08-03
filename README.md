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
- **tmux-assistant-resurrect** rides on the same mechanism, restoring AI
  assistant sessions with their conversation intact rather than as a bare
  restarted binary. It is the one component that writes outside this repo — see
  [Assistant session restore](#assistant-session-restore).
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
the glyphs are simply not in the font. [Your terminal](#your-terminal) below
has a one-line check for this and for the two other things the configuration
wants from a terminal.

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

## Assistant session restore

`tmux-assistant-resurrect` extends resurrect to AI assistant panes. Resurrect
alone would relaunch the bare binary and lose the conversation; this plugin
records each assistant's session ID on save and resumes that exact session on
restore. Claude Code, OpenCode, Codex CLI, Pi, Oh My Pi and Grok are supported.

It hangs off `@resurrect-hook-post-save-all` and `@resurrect-hook-post-restore-all`,
so `tmux/tmux.conf` sources it after resurrect and before continuum.

Unlike everything else here, it writes outside the repo. Both effects run on
every server start and are idempotent:

| Path | What it does |
| ---- | ------------ |
| `~/.claude/settings.json` | Adds `SessionStart` / `SessionEnd` hooks. Needs `jq`; silently skipped without it. Existing keys are preserved. |
| `~/.config/opencode/plugins/session-tracker.js` | Symlink to the tracker in `vendor/`. |

Back that settings file up before the first run if it matters to you. To opt
out entirely, comment out the `run-shell` line for the plugin in
`tmux/tmux.conf` — resurrect and continuum keep working without it.

Verify it loaded:

```sh
tmux show -g @resurrect-hook-post-save-all   # points into vendor/tmux-assistant-resurrect
jq '.hooks.SessionStart' ~/.claude/settings.json
```

### 7. Reclaim your old settings

Your previous `~/.zshrc` is intact at the backup path from step 2. Move
anything worth keeping into `~/.zshrc.local`, which this repo sources and never
overwrites — do not paste it back into the tracked `zsh/zshrc`.

### Installers write through the symlink

`~/.zshrc` is a symlink into this repository, so anything that appends to it is
appending to the tracked `zsh/zshrc`. Tool installers do this routinely —
`atuin`, `deno`, `rustup`, `nvm`, `bun` and Homebrew all offer to "add this to
your shell config" — and the edit lands in your git working tree, not in a
personal file. It is also how a config from another machine can end up
overwriting this one wholesale.

Nothing breaks immediately, which is what makes it easy to miss: the lines
work, they are just in the wrong file, unversioned intent mixed into a
publishable repo, and they are lost on the next `git checkout`. They also tend
to duplicate what `zshrc` already does more carefully — an installer's bare
`eval "$(atuin init zsh)"` overrides the flags you chose, and a second
`compinit` throws away the cached dump.

After installing anything that touches your shell:

```sh
git -C /path/to/steves-cli-setup status --short   # expect no changes to zsh/
```

If `zsh/zshrc` shows up modified, move the added lines into `~/.zshrc.local`
and `git checkout -- zsh/zshrc`. Prefer the installer's opt-out where there is
one (`rustup --no-modify-path`, `nvm` with `PROFILE=/dev/null`).

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

## Your terminal

This configuration asks three things of a terminal emulator. Rather than look
yours up in a table of a hundred, run the three checks — each answers in a
second, on any terminal, including one nobody has written a guide for.

### 1. 24-bit colour

```sh
printf '\033[38;2;255;100;0mIf this is orange, RGB works\033[0m\n'
```

Muddy red or plain white means the terminal is falling back to a 256-colour
approximation. The palette will still be legible, just not the intended
colours. Inside tmux, confirm the capability survived with `tmux info | grep
RGB`.

### 2. A Nerd Font

```sh
printf '    <- three glyphs, no boxes\n'
```

Boxes or question marks mean the font is not a Nerd Font, or the name is
spelled differently than you think. The name is the part people get wrong, so
take it from fontconfig rather than from a guide:

```sh
fc-list : family | tr , '\n' | grep -i 'nerd font' | sort -u
```

Use that string verbatim wherever your terminal wants a font family. Where
that setting lives is the only genuinely per-terminal detail, and it is always
one of two shapes: terminals with a GUI keep it under Preferences or Profile →
Appearance, usually **per profile**, so a new profile silently reverts to the
default; terminals configured by file want a family key in that file. As an
example, `~/.config/alacritty/alacritty.toml`:

```toml
[font.normal]
family = "JetBrainsMono Nerd Font"
```

### 3. OSC 52, only if you copy from remote sessions

```sh
printf '\033]52;c;%s\a' "$(printf 'osc52 works' | base64)"
```

Then paste somewhere. If `osc52 works` appears, your terminal honours OSC 52,
and a copy inside a tmux session on a remote machine will reach the clipboard
of the machine in front of you. If nothing arrives, the terminal does not
support it — Konsole is the common example, and has not for many years. Local
copies are unaffected either way; they go through `xclip` or `wl-copy`.

Some terminals ship OSC 52 disabled, or enabled for copy but not paste, since
a program that can read your clipboard is a different risk from one that can
write to it. Copy-only is all this configuration needs.

### `TERM`

Leave `TERM` at whatever your terminal sets. If that value has a real terminfo
entry — check with `infocmp "$TERM" >/dev/null && echo ok`, and install
`ncurses-term` if not — you get undercurl and styled underlines that
`xterm-256color` would cost you. Inside tmux the outer value stops mattering:
this config sets `default-terminal tmux-256color` and advertises the outer
terminal's abilities through `terminal-features`.

### Clipboard on Wayland

Independent of the terminal — this one is a property of the session:

```sh
[ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null || echo 'install wl-clipboard'
```

The copy binding prefers `wl-copy` when `WAYLAND_DISPLAY` is set and falls back
to `xclip`. On a Wayland session without `wl-clipboard`, the fallback is what
runs, so copies land in XWayland's X11 clipboard and reach native Wayland
applications only because the compositor bridges the two. That bridge works —
until XWayland is not running, at which point copying fails silently with no
error anywhere.

`WAYLAND_DISPLAY` is read once, when the tmux **server** starts. A server
started from a TTY or an X11 session keeps the `xclip` binding for its entire
life, however many Wayland clients later attach to it. After installing
`wl-clipboard`, run `tmux kill-server` so the check runs again.

## What is included

| File | What it does |
| ---- | ------------ |
| `tmux/tmux.conf` | `C-a` prefix (`C-b` still works), 1-indexed auto-renumbering windows, vi copy mode with system clipboard and OSC 52, fzf session/window popups with preview on `prefix+s` / `prefix+w` and stock `choose-tree` on `prefix+S` / `prefix+W`, killing a session switches the client instead of detaching it, Nord status bar, native pane dimming, resurrect + continuum + assistant-resurrect |
| `zsh/zshrc` | history, completion, aliases and deferred plugins — 22 ms to prompt |
| `zsh/zshenv` | opts out of Debian's redundant global `compinit` |
| `starship/starship.toml` | two-line Nord prompt, ~9 ms |
| `install.sh` | symlink deployment, idempotent, reversible |

Ten files and 800 lines in total, with three runtime dependencies: tmux, zsh
and git.

## Licence

[MIT](LICENSE)
