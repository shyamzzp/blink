# iTerm2 features with no Blink equivalent

From **§12 Gaps with no workaround** of the parity reference. These are
recorded so nobody in this fork spends a weekend trying to implement one
before discovering why it cannot work. Accept them rather than fighting them.

Each entry states the blocker and the closest honest substitute.

| Feature | Why it cannot work | Closest substitute |
|---|---|---|
| **Global hotkey window** (`⌥Space`) | iPadOS exposes no global hotkey API. An app cannot be summoned while another is foreground. | Keep Blink pinned in Stage Manager and use `⌘Tab`. |
| **Triggers** (regex match to action) | No regex-to-action engine anywhere in the stack, and no hook where one could observe the stream. | The remote announces events itself with OSC sequences. See `contrib/ipad/blink-notify.sh`. |
| **Instant replay** (`⌘⌥B`) | Nothing records the terminal stream. | Record deliberately on the remote: `asciinema rec`, the `tmux-logging` plugin, or `script`. A deliberate act, not a safety net. |
| **Shell integration marks and captured output** (`⌘⇧↑`, select last command's output) | No shell integration protocol, so there are no command boundaries to jump between. | Start the prompt with a rare glyph and search for it in tmux copy mode. `contrib/ipad/remote-setup.sh` sets `PROMPT_MARK` for this. |
| **Semantic history** (tap a path in a stack trace) | No file-path click handling in the terminal view. | The `open` command handles URLs and files by hand. |
| **tmux `-CC` control mode** | Blink has no `-CC` client, so tmux windows can never become Blink tabs. | Plain tmux. You lose native tabs mirroring tmux windows; you keep everything else. |
| **Window transparency and blur** | Not exposed on iPadOS. No window compositing control. | Fake depth with a dark background image via the `background-image` theme key. |
| **Python scripting API** | No scripting API. | Coarse automation through the x-callback-url interface (`xcall`, `open`) from the Shortcuts app. |
| **A real local shell** | `ios_system` is a convenience userland inside the app sandbox, not a development environment. There is no `fork`/`exec`. | Do the work on a remote host or a VM. The local side is a launcher. |

## Split panes, the one that looks like a gap but is not

Split panes do not exist in Blink at any level, which is why tmux is
mandatory rather than optional in this fork. That one is covered: see the
tmux hex shortcut defaults and `contrib/ipad/tmux.conf`, which together put
`⌘D` and `⌘⇧D` back under your fingers.

It is listed here only to be explicit that the native implementation is not
coming, and that the tmux route is the design, not a stopgap.
