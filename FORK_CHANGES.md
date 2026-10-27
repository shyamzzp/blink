# What this fork changes

Upstream Blink, plus two things: it builds and installs on a free Apple
Developer account, and it ships configured for iTerm2 muscle memory instead
of neutral defaults.

Nothing here is intended to go upstream. Several changes are deliberately
opinionated, and the sideload changes would be wrong on a paid account.

## Free-account sideloading

See [SIDELOAD.md](SIDELOAD.md) for the full account of what a free Personal
Team cannot sign and how each one is worked around.

Short version: entitlements a Personal Team is refused are stripped, the app
falls back to its own container when there is no app group, and two
migration steps that assume iCloud and a provisioned File Provider are
skipped. `./scripts/sideload.sh` builds, signs, installs and launches in one
command; re-run it when the 7-day profile lapses.

## Voice input

A push-to-talk microphone button in the bottom-right of every interactive
terminal. Hold to dictate, release to insert.

The transcript goes in **without a trailing newline**, so a misheard command
sits on the prompt waiting to be read rather than running itself. In a shell
that distinction matters more than the convenience does.

Recognition is on-device where the hardware supports it and falls back to
Apple's servers otherwise, which means older devices need a network
connection for dictation. Implemented in `Blink/VoiceInput.swift`.

## iTerm2 parity

Implements the reference in [docs/ITERM2_PARITY.md](docs/ITERM2_PARITY.md).
Start with [docs/SETUP_CHECKLIST.md](docs/SETUP_CHECKLIST.md); the steps this
fork already ships as defaults are marked, so a new device skips them.

### Shipped as defaults

| Area | Change | Reference |
|---|---|---|
| Modifiers | Caps Lock is Control held, Escape tapped | §4.1 |
| Modifiers | Functional keys moved to `^⌘`+digit | §4.2 |
| Shortcuts | `⌘1`–`⌘9` jump to a tab, `⌘N` new window, cycling tab keys | §2, §11 |
| Shortcuts | tmux hex map: `⌘D` split, `⌘F` search, `⌘⇧↩` zoom, and 16 more | §8, §11 |
| Shortcuts | Previously unbound commands given keys | §3 |

### Remote side, in `contrib/ipad/`

The reference is clear that most of the remaining parity lives on the
machines you connect to, not on the iPad.

| File | Purpose | Reference |
|---|---|---|
| `tmux.conf` | panes, scrollback search, broadcast input, persistence, status bar | §7 |
| `remote-setup.sh` | fzf, atuin, zoxide, zsh-autosuggestions, eza, bat, tmux, mosh | §9 |
| `ssh_config.example` | land every connection inside tmux; jump hosts, forwarding | §5.4 |
| `blink-notify.sh` | OSC notifications, the substitute for iTerm2 triggers | §10.2 |
| `itermcolors2blink.py` | convert an `.itermcolors` palette into a Blink theme | §6.3 |
| `my-iterm-port.js` | the non-colour hterm preferences, including copy-on-select | §6.2 |

### Not possible

[docs/KNOWN_GAPS.md](docs/KNOWN_GAPS.md) records the features that cannot be
built, with the blocker and the closest honest substitute for each. Split
panes are the notable one: absent from Blink at any level, which is why tmux
is the design here rather than a stopgap.
