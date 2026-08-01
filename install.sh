#!/usr/bin/env bash
#
# steves-cli-setup installer.
#
# Deploys the configuration by symlink, so editing a file in this repository is
# the same as editing the live config. Idempotent: running it twice changes
# nothing the second time.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Pinned rather than "latest" so two machines installed months apart get the
# same glyphs.
NERD_FONT_VERSION="v3.4.0"
NERD_FONT_NAME="JetBrainsMono"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

VENDOR_LINK="$XDG_DATA_HOME/steves-cli-setup"
FONT_DIR="$XDG_DATA_HOME/fonts"

dry_run=0
uninstall=0
with_starship=0
with_font=1

# target:source, relative to the repository root.
LINKS=(
  "$HOME/.tmux.conf:tmux/tmux.conf"
  "$HOME/.zshrc:zsh/zshrc"
  "$XDG_CONFIG_HOME/starship.toml:starship/starship.toml"
)

# ── Output ────────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then
  C_INFO=$'\033[34m'; C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_OFF=$'\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''
fi

info() { printf '%s==>%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%swarn%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%serror%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

# Echo the command instead of running it under --dry-run, so the output doubles
# as an exact record of what would change.
run() {
  if (( dry_run )); then
    printf '     %s\n' "$*"
  else
    "$@"
  fi
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run         Print what would change without touching anything.
  --uninstall       Remove the symlinks this installer created.
  --with-starship   Also install starship via its official installer.
  --no-font         Skip downloading the Nerd Font.
  -h, --help        Show this message.

Existing regular files are moved aside to <path>.bak.<timestamp>, never
overwritten. Symlinks already pointing into this repository are left alone.
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────

while (( $# )); do
  case "$1" in
    --dry-run)       dry_run=1 ;;
    --uninstall)     uninstall=1 ;;
    --with-starship) with_starship=1 ;;
    --no-font)       with_font=0 ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

# ── Steps ─────────────────────────────────────────────────────────────────────

require_versions() {
  command -v git >/dev/null 2>&1 || die "git is required"
  command -v tmux >/dev/null 2>&1 || die "tmux is required"
  command -v zsh  >/dev/null 2>&1 || die "zsh is required"

  # The config uses `terminal-features` and `display-popup`, both 3.2+, and is
  # only tested from 3.3 onward.
  local tmux_version
  tmux_version="$(tmux -V | sed 's/[^0-9.]*//g')"
  if [[ "$(printf '%s\n3.3\n' "$tmux_version" | sort -V | head -1)" != "3.3" ]]; then
    die "tmux 3.3 or newer is required, found $tmux_version"
  fi
}

# Links a single path, reporting which of the three cases it hit.
link_one() {
  local target="$1" source="$2"

  if [[ -L "$target" && "$(readlink -f -- "$target")" == "$(readlink -f -- "$source")" ]]; then
    ok "$target (already linked)"
    return
  fi

  # Anything already here is the user's own config, whether it is a regular file
  # or a symlink into some other dotfile setup. Both get moved aside; neither is
  # destroyed. A dangling symlink is the one exception, since there is nothing
  # behind it to preserve.
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -L "$target" && ! -e "$target" ]]; then
      warn "$target is a dangling symlink; removing it"
      run rm -- "$target"
    else
      local backup
      backup="$target.bak.$(date +%Y%m%d%H%M%S)"
      warn "$target exists; moving it to $backup"
      run mv -- "$target" "$backup"
    fi
  fi

  run mkdir -p -- "$(dirname -- "$target")"
  run ln -s -- "$source" "$target"
  ok "$target -> $source"
}

install_links() {
  info "Linking configuration"

  run mkdir -p -- "$XDG_DATA_HOME"
  if [[ -L "$VENDOR_LINK" && "$(readlink -f -- "$VENDOR_LINK")" == "$REPO_DIR" ]]; then
    ok "$VENDOR_LINK (already linked)"
  else
    [[ -e "$VENDOR_LINK" || -L "$VENDOR_LINK" ]] && run rm -rf -- "$VENDOR_LINK"
    run ln -s -- "$REPO_DIR" "$VENDOR_LINK"
    ok "$VENDOR_LINK -> $REPO_DIR"
  fi

  local entry target source
  for entry in "${LINKS[@]}"; do
    target="${entry%%:*}"
    source="$REPO_DIR/${entry#*:}"
    link_one "$target" "$source"
  done
}

install_submodules() {
  info "Fetching vendored plugins"
  # Not --recursive: tmux-resurrect's own submodule is its test harness, which
  # is of no use to an installed copy.
  run git -C "$REPO_DIR" submodule update --init --depth 1
  ok "submodules at pinned commits"
}

install_font() {
  (( with_font )) || { info "Skipping font (--no-font)"; return; }

  if fc-list 2>/dev/null | grep -qi "$NERD_FONT_NAME Nerd Font"; then
    ok "$NERD_FONT_NAME Nerd Font already installed"
    return
  fi

  command -v curl >/dev/null 2>&1 || { warn "curl not found; skipping font"; return; }
  command -v unzip >/dev/null 2>&1 || { warn "unzip not found; skipping font"; return; }

  info "Installing $NERD_FONT_NAME Nerd Font $NERD_FONT_VERSION"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONT_VERSION/$NERD_FONT_NAME.zip"

  if (( dry_run )); then
    printf '     download %s into %s\n' "$url" "$FONT_DIR"
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf -- "$tmp"' RETURN

  curl -fsSL -o "$tmp/font.zip" "$url" || { warn "font download failed; skipping"; return; }
  mkdir -p -- "$FONT_DIR"
  # Variable fonts render badly in several terminals, so take the static set.
  unzip -qo "$tmp/font.zip" -x '*Variable*' 'README*' 'LICENSE*' -d "$FONT_DIR/$NERD_FONT_NAME"
  fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
  ok "font installed to $FONT_DIR/$NERD_FONT_NAME"
  warn "set your terminal's font to '$NERD_FONT_NAME Nerd Font' to see the icons"
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    ok "starship $(starship --version | head -1 | awk '{print $2}')"
    return
  fi

  # Not automatic. Piping a remote script into a shell is the user's call to
  # make explicitly, not something an installer should do quietly on their
  # behalf.
  if (( with_starship )); then
    info "Installing starship"
    run sh -c 'curl -fsSL https://starship.rs/install.sh | sh'
  else
    warn "starship is not installed; the prompt will fall back to zsh's default"
    warn "  install it with your package manager, or re-run with --with-starship"
  fi
}

report_optional() {
  local missing=()
  local tool
  for tool in fzf eza bat fd rg zoxide; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  (( ${#missing[@]} )) && info "Optional tools not installed: ${missing[*]}"
  return 0
}

do_uninstall() {
  info "Removing symlinks"

  local entry target
  for entry in "${LINKS[@]}"; do
    target="${entry%%:*}"
    if [[ -L "$target" && "$(readlink -f -- "$target")" == "$REPO_DIR"/* ]]; then
      run rm -- "$target"
      ok "removed $target"
    else
      ok "$target not ours; left alone"
    fi
  done

  if [[ -L "$VENDOR_LINK" && "$(readlink -f -- "$VENDOR_LINK")" == "$REPO_DIR" ]]; then
    run rm -- "$VENDOR_LINK"
    ok "removed $VENDOR_LINK"
  fi

  info "Backups (*.bak.*) and the font were left in place."
}

main() {
  (( dry_run )) && info "Dry run: nothing will be modified"

  if (( uninstall )); then
    do_uninstall
    return
  fi

  require_versions
  install_submodules
  install_links
  install_starship
  install_font
  report_optional

  info "Done. Start a new shell, then reload tmux with: tmux source-file ~/.tmux.conf"
}

main
