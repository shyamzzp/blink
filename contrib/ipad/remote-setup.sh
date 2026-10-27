#!/usr/bin/env bash
#
# Install the remote-side tooling that replaces iTerm2 features Blink cannot
# provide locally. Run this on the machines you ssh into from the iPad, not
# on the iPad.
#
# Several iTerm2 "features" are really shell features that iTerm2 happens to
# bundle. Installed on the remote host instead, the result is usually better
# than the original.
#
#   autocomplete        -> zsh-autosuggestions
#   command history     -> atuin (synced, per-directory) or fzf's Ctrl-R
#   directory jumping   -> zoxide
#   fuzzy pickers       -> fzf
#   readable ls / cat   -> eza, bat
#
# Usage:
#   ./remote-setup.sh            # install everything available
#   ./remote-setup.sh --dry-run  # print what it would do
#
set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[skip]\033[0m %s\n' "$*"; }
run()  {
  if [ "$DRY_RUN" = "1" ]; then
    printf '    would run: %s\n' "$*"
  else
    "$@"
  fi
}

# --- Work out how to install ------------------------------------------
if command -v brew >/dev/null 2>&1; then
  PM=brew
elif command -v apt-get >/dev/null 2>&1; then
  PM=apt
elif command -v dnf >/dev/null 2>&1; then
  PM=dnf
elif command -v pacman >/dev/null 2>&1; then
  PM=pacman
else
  echo "No supported package manager found (brew, apt, dnf, pacman)." >&2
  exit 1
fi
say "Using $PM"

pm_install() {
  case "$PM" in
    brew)   run brew install "$@" ;;
    apt)    run sudo apt-get install -y "$@" ;;
    dnf)    run sudo dnf install -y "$@" ;;
    pacman) run sudo pacman -S --noconfirm "$@" ;;
  esac
}

# --- Packages ---------------------------------------------------------
# tmux first: it is the layer that supplies panes, scrollback search,
# broadcast input and session persistence, none of which Blink has.
for pkg in tmux fzf zoxide bat; do
  if command -v "$pkg" >/dev/null 2>&1; then
    warn "$pkg already installed"
  else
    say "Installing $pkg"
    pm_install "$pkg"
  fi
done

# eza is named differently across distros and is absent from older ones.
if command -v eza >/dev/null 2>&1 || command -v exa >/dev/null 2>&1; then
  warn "eza already installed"
else
  say "Installing eza"
  pm_install eza || warn "eza unavailable in this package manager, skipping"
fi

# mosh: survives IP changes and sleep, which is the whole point on a tablet.
if command -v mosh-server >/dev/null 2>&1; then
  warn "mosh already installed"
else
  say "Installing mosh"
  pm_install mosh || warn "mosh unavailable, skipping"
fi

# atuin and zsh-autosuggestions have their own installers.
if command -v atuin >/dev/null 2>&1; then
  warn "atuin already installed"
else
  say "Installing atuin"
  if [ "$DRY_RUN" = "1" ]; then
    printf '    would run: curl --proto =https --tlsv1.2 -sSf https://setup.atuin.sh | sh\n'
  else
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh || warn "atuin install failed"
  fi
fi

ZSH_AUTO_DIR="${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions"
if [ -d "$ZSH_AUTO_DIR" ]; then
  warn "zsh-autosuggestions already present"
else
  say "Installing zsh-autosuggestions"
  run git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTO_DIR"
fi

# --- Shell wiring -----------------------------------------------------
SNIPPET_MARK="# --- blink ipad parity ---"
RC="${ZDOTDIR:-$HOME}/.zshrc"

if [ -f "$RC" ] && grep -qF "$SNIPPET_MARK" "$RC"; then
  warn "shell snippet already in $RC"
else
  say "Appending shell snippet to $RC"
  if [ "$DRY_RUN" = "1" ]; then
    printf '    would append the blink parity snippet to %s\n' "$RC"
  else
    cat >> "$RC" <<'RC_SNIPPET'

# --- blink ipad parity ---
# Inline grey suggestion from history, accepted with the right arrow. Fewer
# keystrokes matters more on a tablet.
[ -f "${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v atuin  >/dev/null 2>&1 && eval "$(atuin init zsh)"
command -v eza    >/dev/null 2>&1 && alias ls='eza --icons --group-directories-first'
command -v bat    >/dev/null 2>&1 && alias cat='bat --paging=never'

# Blink has no shell integration protocol, so there are no prompt marks to
# jump between. A rare glyph in the prompt gives tmux copy mode search
# something unambiguous to find, which recovers most of the value.
export PROMPT_MARK='◆'

# Cursor shape per vi mode, the DECSCUSR sequences iTerm2 sets for you.
function zle-keymap-select {
  case $KEYMAP in
    vicmd)      printf '\e[2 q' ;;  # block
    viins|main) printf '\e[6 q' ;;  # bar
  esac
}
zle -N zle-keymap-select
RC_SNIPPET
  fi
fi

say "Done."
echo
echo "Next:"
echo "  1. Copy contrib/ipad/tmux.conf to ~/.tmux.conf on this machine."
echo "  2. Confirm OSC 52 works: yank in tmux copy mode, paste on the iPad."
echo "  3. Point your Blink host entry at mosh, and attach tmux on connect."
