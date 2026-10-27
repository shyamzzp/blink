<!--
  Generated from ipad-blink-iterm2-parity.html with pandoc, then tidied.
  Source of truth for the parity work in this fork. Every branch in the
  series names the section it implements.
-->

# Blink on iPad: iTerm2 Feature Parity Reference

What you can copy from iTerm2 into Blink Shell on an iPad with a hardware keyboard, how to copy it, and what simply does not exist.

**Session:** ipad-blink  ·  **Date:** 2026-10-27  ·  **Target:** iPad + Magic Keyboard / Smart Keyboard Folio\
**Verified against:** Blink source tree at `~/blink-build`, MARKETING_VERSION `15.0.8`, commit `3352a10a`.\
**Method:** every default shortcut, preference key and command in this document was read out of that source tree, not from memory or marketing docs. Where a workaround depends on the remote machine rather than on Blink, that is stated.

## 0. Table of contents

1.  How Blink is built, and why that decides parity
2.  Blink default keyboard shortcuts (verified)
3.  Every bindable Blink command
4.  The keyboard configuration model
5.  iTerm2 to Blink parity matrix
6.  Appearance: the hterm preference surface
7.  tmux: the layer that buys you panes
8.  Mapping iTerm2 muscle memory onto tmux via hex shortcuts
9.  Remote shell setup for the iTerm2 conveniences
10. Clipboard, notifications and file transfer
11. Connections: hosts, ssh_config, forwarding, mosh
12. Recommended final shortcut map
13. Gaps with no workaround
14. Ordered setup checklist
15. Appendix A: built-in local commands
16. Appendix B: hex codes cheat sheet
17. Appendix C: file locations

## 1. How Blink is built, and why that decides parity

Blink is not a port of a desktop terminal. Knowing its three layers tells you in advance which iTerm2 features are a settings change, which need tmux, and which are impossible.

| Layer | What it is | Consequence for iTerm2 parity |
|----|----|----|
| **Terminal rendering** | hterm (the Chromium/ChromeOS terminal engine) running inside a `WKWebView`. Confirmed: `Resources/hterm_all.min.js`, `Resources/term.js`. | Anything that is an hterm preference is reachable. A Blink "theme" is literally JavaScript calling `t.prefs_.set(key, value)`, so you get roughly 89 preference keys, not just colours. |
| **Local commands** | `ios_system` provides a BSD-ish userland inside the app sandbox, plus Blink's own commands (`ssh`, `mosh`, `config`, `code`, `geo`, `build`). | There is no local shell scripting environment worth the name and no local tmux. All heavy work happens on the remote host. Local side is a launcher. |
| **App chrome** | UIKit scenes. A Blink "window" is an iPadOS scene; a Blink "tab" is a terminal inside that scene. | Tabs and windows exist natively. **Split panes do not exist at all.** That single gap is why tmux is mandatory, not optional. |

Two further facts that matter:

- `TERM` is set to `xterm-256color` (`Blink/AppDelegate.m:76`). hterm renders 24-bit colour, so you can force truecolor in tmux.
- OSC 52 clipboard write is enabled roughly two seconds after each session starts (`TermController.swift:557`). Remote-to-local clipboard works, which is the single most useful thing to turn on.

## 2. Blink default keyboard shortcuts (verified)

Read from `KeyShortcut.defaultList` in `KB/Native/Model/KeyShortcut.swift`. These are the shipped defaults; every one of them is reassignable in **Settings \> Keyboard \> Shortcuts**.

| Action | Default binding | iTerm2 equivalent |
|----|----|----|
| Copy | <span class="kbd">⌘ C</span> | Same |
| Copy Raw | <span class="kbd">⌘ ⇧ C</span> | Closest to Copy with Styles off, strips formatting |
| Paste | <span class="kbd">⌘ V</span> | Same |
| New tab | <span class="kbd">⌘ T</span> | Same |
| Close tab | <span class="kbd">⌘ W</span> | Same |
| Next tab | <span class="kbd">⌘ ⇧ \]</span> and <span class="kbd">⌘ ⇧ →</span> | Same |
| Previous tab | <span class="kbd">⌘ ⇧ \[</span> and <span class="kbd">⌘ ⇧ ←</span> | Same |
| New Window | <span class="kbd">⌘ ⇧ T</span> | iTerm2 uses <span class="kbd">⌘ N</span>; Blink reserves plain <span class="kbd">⌘ N</span> for nothing, you can rebind |
| Close Window | <span class="kbd">⌘ ⇧ W</span> | iTerm2 <span class="kbd">⌘ ⇧ W</span>, identical |
| Focus on other Window | <span class="kbd">⌘ O</span> | No clean equivalent, iPadOS scene switching |
| Move tab to other Window | <span class="kbd">⌘ ⇧ O</span> | iTerm2 drag-out of tab |
| Zoom In | <span class="kbd">⌘ ⇧ =</span> | iTerm2 <span class="kbd">⌘ +</span> |
| Zoom Out | <span class="kbd">⌘ -</span> | Same |
| Zoom Reset | <span class="kbd">⌘ =</span> | iTerm2 <span class="kbd">⌘ 0</span> |
| Show Config | <span class="kbd">⌘ ,</span> | Same |
| Show Snippets (Snips) | <span class="kbd">⌘ ⇧ ,</span> | iTerm2 Snippets, no default binding there |
| Show Scratch | <span class="kbd">⌘ ⇧ .</span> | No iTerm2 equivalent, Blink-only scratchpad |

**Discovery trick:** hold <span class="kbd">⌘</span> on a hardware keyboard and iPadOS prints the live shortcut sheet for the current Blink state. That sheet is always truer than any document, including this one, because it reflects your edits.

### Gestures that have no keyboard equivalent

- Two-finger tap: new terminal.
- One-finger tap: mouse click (sends a click to the remote, so tmux mouse mode and vim mouse mode work).
- One-finger swipe left/right: switch terminals.
- Pinch: change font size.

## 3. Every bindable Blink command

From `enum Command` in `KB/Native/Model/KeyBindingAction.swift`. The ones not listed in section 2 ship **unbound**. Several are exactly the iTerm2 behaviours you are missing, so bind them.

| Command | Default | Why you care |
|----|----|----|
| `tab1` … `tab12` | unbound | Direct tab jumps. This is iTerm2 <span class="kbd">⌘ 1</span>…<span class="kbd">⌘ 9</span>. See the conflict warning in section 4. |
| `tabLast` | unbound | Jump to final tab, iTerm2 <span class="kbd">⌘ 9</span> semantics. |
| `tabNextCycling` / `tabPrevCycling` | unbound | Wrap-around tab cycling. The default next/prev stop at the ends. |
| `toggleQuickActions` | unbound | Shows or hides the on-screen Smart Keys bar. Worth binding so you can reclaim screen rows when the hardware keyboard is attached. |
| `toggleKeyCast` | unbound | On-screen keystroke visualiser. Useful for screen recording and for debugging your own key remaps. |
| `hideKeyboard` | unbound | Dismisses the software keyboard without detaching hardware. |
| `selectionGoogle` | unbound | Search the current selection on Google. No iTerm2 default, but iTerm2 has it in the context menu. |
| `selectionStackOverflow` | unbound | Same, against Stack Overflow. |
| `selectionShare` | unbound | iOS share sheet for the selection. Fast way to get an error message into Slack or Notes. |
| `toggleGeoTrack` | unbound | Starts or stops background location tracking, which is how Blink keeps a session alive in the background. See section 10. |
| `clipboardCopyRaw` | <span class="kbd">⌘ ⇧ C</span> | Copy without line-wrap reflow. |
| `scratchShow`, `snippetsShow`, `configShow` | bound | See section 2. |
| `windowFocusOther`, `tabMoveToOtherWindow` | bound | Multi-scene workflow on iPad, useful under Stage Manager. |

## 4. The keyboard configuration model

Blink's keyboard config has four independent layers. iTerm2 users usually only think about the fourth. On iPad the first three matter more, because the Magic Keyboard has no Escape key and no function row.

### 4.1 Modifier remapping

Settings \> Keyboard. Each of Caps Lock, Shift, Control, Option, Command can be reconfigured, left and right independently. The available modifier roles come from `enum KeyModifier`:

| Role | Meaning |
|----|----|
| `None` | No modifier produced. |
| `8-bit` | Adds 128 to the unshifted character, as xterm does. |
| `Escape` | Sends an ESC prefix. This is what modern editors call ALT. **Set Option to this** if you want <span class="kbd">⌥ f</span> / <span class="kbd">⌥ b</span> word motion in readline, and it is the default. |
| `Shift` | Shift modifier. |
| `Control` | Control sequence. |
| `Meta` | Adds modifiers to the control sequence. |

Defaults as shipped: Shift is Shift, Control is Control, Option sends Escape, Command produces no terminal modifier (it is reserved for app shortcuts), Caps Lock is a plain Caps Lock.

**The single highest value change on an iPad:** remap Caps Lock. Vim users set Caps Lock to `Escape` on key up. Emacs and readline users set it to `Control`. Blink supports a press/release split (`up` and `down` actions on a key config), so you can have Caps Lock act as Control when held and send Escape when tapped alone, which is the classic desktop setup.

### 4.2 Functional keys binding

Settings \> Keyboard \> Functional Keys. Default is <span class="kbd">⌘</span> + `[0-9]`, meaning <span class="kbd">⌘ 1</span> sends F1, <span class="kbd">⌘ 2</span> sends F2 and so on. This exists because an iPad keyboard has no function row.

**Direct conflict to resolve first.** If you want iTerm2's <span class="kbd">⌘ 1</span>…<span class="kbd">⌘ 9</span> tab switching, you must first move the Functional Keys binding off <span class="kbd">⌘</span>. Recommended: set Functional Keys to <span class="kbd">⌃ ⌘</span> + `[0-9]`, then bind `tab1`…`tab9` to <span class="kbd">⌘ 1</span>…<span class="kbd">⌘ 9</span>. Decide this before you build the rest of your map, because every other decision depends on whether <span class="kbd">⌘</span>+digit is free.

### 4.3 Cursor keys binding

Settings \> Keyboard \> Cursor Keys. Default is <span class="kbd">⌘</span> + arrow, giving you Home, End, Page Up and Page Down, which the iPad keyboard also lacks. Keep this. It is how you get `Home`/`End` in readline and `PgUp`/`PgDn` in less and tmux copy mode.

### 4.4 Shortcuts: the four action types

Settings \> Keyboard \> Shortcuts. Each shortcut maps a key combination to one of four action kinds (`enum KeyBindingAction`):

| Action kind | What it does | Use it for |
|----|----|----|
| `command` | Runs one of the Blink app commands from section 3. | Tabs, windows, zoom, config, snippets. |
| `press` | Synthesises a key press with modifiers, for example "press <span class="kbd">⌃ Space</span>" or "press F5". | Reaching keys the iPad keyboard does not have. |
| `hex` | Sends an arbitrary byte sequence written as hex. Verified in `blink-uio.min.js`: the string is parsed two hex digits at a time into a byte array and decoded as UTF-8, so **multi-byte sequences work**. | This is the lever. It is how you map iTerm2 muscle memory onto tmux. See section 8. |
| `hex` with string input | Same path, but you type the literal text and Blink converts it to hex for you. | Canned text, for example a long kubectl context name. |

### 4.5 iPadOS shortcuts you cannot take

Do not bind these; the system eats them before Blink sees them.

- <span class="kbd">⌘ Space</span> Spotlight, <span class="kbd">⌘ Tab</span> app switcher, <span class="kbd">⌘ H</span> Home.
- <span class="kbd">⌘ ⌥ D</span> show or hide Dock, <span class="kbd">⌘ ⇧ 3</span> and <span class="kbd">⌘ ⇧ 4</span> screenshots.
- Any combination starting with the Globe key on a Magic Keyboard.
- <span class="kbd">⌘ ⌥ ←</span> / <span class="kbd">⌘ ⌥ →</span> can be captured by Stage Manager window switching depending on iPadOS version. Test before relying on it for tmux pane navigation.

## 5. iTerm2 to Blink parity matrix

Status key: <span class="ok">Native</span> means Blink does it with no extra software. <span class="part">Workaround</span> means you get it, but through tmux, the remote shell, or a theme file. <span class="no">None</span> means it does not exist and no sensible substitute does either.

### 5.1 Windows, tabs and panes

| iTerm2 feature | Status | How to get it on iPad |
|----|----|----|
| Tabs, new / close / cycle | Native | <span class="kbd">⌘ T</span>, <span class="kbd">⌘ W</span>, <span class="kbd">⌘ ⇧ \[</span> / <span class="kbd">⌘ ⇧ \]</span>. |
| Jump to tab N (<span class="kbd">⌘ 1</span>…) | Native | Bind `tab1`…`tab12`. Resolve the Functional Keys conflict first, section 4.2. |
| Windows (<span class="kbd">⌘ N</span>) | Native | <span class="kbd">⌘ ⇧ T</span> creates a new iPadOS scene. Use with Stage Manager or Split View for genuine side-by-side terminals without tmux. |
| Split panes (<span class="kbd">⌘ D</span>, <span class="kbd">⌘ ⇧ D</span>) | Workaround | **Not present in Blink at any level.** tmux `split-window -h` / `-v`. Map to <span class="kbd">⌘ D</span> / <span class="kbd">⌘ ⇧ D</span> with hex actions, section 8. |
| Pane navigation (<span class="kbd">⌘ ⌥</span> arrows) | Workaround | tmux `select-pane`. Hex actions, section 8. |
| Maximise pane (<span class="kbd">⌘ ⇧ Enter</span>) | Workaround | tmux `resize-pane -Z`. |
| Broadcast input to all panes (<span class="kbd">⌘ ⌥ I</span>) | Workaround | tmux `setw synchronize-panes`. Bind it in tmux, then map a Blink hex shortcut to it. |
| Dim inactive panes | Workaround | tmux `window-style` and `window-active-style`. |
| Window arrangements, save and restore | Workaround | tmux sessions plus `tmux-resurrect` and `tmux-continuum`, or declarative layouts with `tmuxp`. |
| Session restoration after app quit | Native | Blink restores scenes and terminals via `UIStateRestorable`. Combine with mosh so the remote side survives too. |
| Hotkey window (<span class="kbd">⌥ Space</span> global) | None | iPadOS has no global hotkey API. Closest is keeping Blink pinned in Stage Manager and using <span class="kbd">⌘ Tab</span>. |
| Full screen (<span class="kbd">⌘ Enter</span>) | Native | iPadOS apps are full screen by default. Nothing to do. |
| tmux control mode integration (`tmux -CC`) | None | Blink has no `-CC` client. Use plain tmux. You lose native tabs mirroring tmux windows; you keep everything else. |

### 5.2 Text, selection and clipboard

| iTerm2 feature | Status | How to get it on iPad |
|----|----|----|
| Copy / paste | Native | <span class="kbd">⌘ C</span> / <span class="kbd">⌘ V</span>, plus <span class="kbd">⌘ ⇧ C</span> for raw copy. |
| Copy mode, keyboard selection | Native | Blink has built-in Selection Control. Vim keys: `h j k l` move, `w b` by word, `o` swaps the selection anchor, `y` yank, `p` paste. Emacs keys: `C-f C-b C-n C-p`, `C-M-f` / `C-M-b` by word, `C-x` swaps anchor. |
| Copy on select | Workaround | Blink sets `copy-on-select` to `false` at startup. Turn it on from a custom theme: `t.prefs_.set('copy-on-select', true)`. |
| Remote to local clipboard (OSC 52) | Native | Enabled automatically about two seconds into each session. On the remote: `tmux set -s set-clipboard on`, and in vim use an OSC 52 yank plugin. This is the feature to turn on first. |
| Find in scrollback (<span class="kbd">⌘ F</span>, <span class="kbd">⌘ G</span>) | Workaround | **No native find.** Use tmux copy mode search: prefix then `[` then `/` in vi mode. Map it to <span class="kbd">⌘ F</span> with a hex shortcut. Without tmux you have no scrollback search at all. |
| Paste history (<span class="kbd">⌘ ⇧ H</span>) | Workaround | tmux paste buffers: prefix `#` lists them, prefix `=` chooses one. Blink's own Snips panel (<span class="kbd">⌘ ⇧ ,</span>) covers the "canned text" half of the feature. |
| Snippets | Native | Blink "Snips", <span class="kbd">⌘ ⇧ ,</span>. Stored locally or in iCloud Drive, syncs across devices, and can pull the public index from `github.com/blinksh/snippets`. |
| Scratchpad | Native | <span class="kbd">⌘ ⇧ .</span>. Blink-only, iTerm2 has nothing like it. Good for composing a long command before sending it. |
| Paste slowly / paste special | Workaround | Use tmux `load-buffer` and `paste-buffer`, or bracketed paste on the remote shell, which Blink supports. |
| Smart selection (regex-aware double click) | Workaround | hterm exposes `word-break-match-left`, `word-break-match-middle` and `word-break-match-right`. Set these in a theme to control what counts as a word, which recovers most of the practical value. |
| Semantic history (cmd-click a path to open it) | None | No file-path click handling. Nearest is the `open` command for URLs and files. |
| Instant replay (<span class="kbd">⌘ ⌥ B</span>) | None | Record instead: `asciinema rec`, the `tmux-logging` plugin, or `script` on the remote. |
| Captured output / command marks (<span class="kbd">⌘ ⇧ ↑</span>) | None | Blink has no shell integration protocol. Partial substitute: make your prompt start with a rare character and search for it in tmux copy mode. |
| Timestamps on each line | Workaround | Remote side: pipe through `ts` from moreutils. |

### 5.3 Appearance

| iTerm2 feature | Status | How to get it on iPad |
|----|----|----|
| Colour presets and themes | Native | Settings \> Terminal \> Style \> Themes, or the `theme` command. Ships Default, Solarized, Flat, Monokai Light, WWDC 16. Import your own by URL. |
| Convert an iTerm2 `.itermcolors` file | Workaround | Not importable directly. Extract the sixteen ANSI colours plus foreground, background and cursor from the plist and write them into the JS theme template in section 6.3. |
| Powerline and Nerd Font glyphs | Native | Bundled: Fira Code, Fira Code Nerd Font, JetBrains Mono, JetBrains Mono Nerd Font, Iosevka, Iosevka Nerd Font, Menlo and DejaVu Sans Mono Powerline variants. Add more by pointing Blink at a CSS `@font-face` URL. |
| Ligatures | Native | Use Fira Code or JetBrains Mono. hterm renders through the DOM so ligatures work. |
| Font size shortcuts | Native | <span class="kbd">⌘ ⇧ =</span>, <span class="kbd">⌘ -</span>, <span class="kbd">⌘ =</span>, plus pinch. |
| Background image | Workaround | Theme JS: `background-image`, `background-size`, `background-position`. |
| Transparency and blur | None | No window compositing control on iPadOS. You can fake depth with a dark background image. |
| Minimum contrast, cursor boost | Workaround | No direct preference. Use `user-css-text` in a theme to inject CSS, or simply pick a higher-contrast palette. |
| Cursor colour and blink | Native | Style settings has a Cursor Blink toggle; theme JS adds `cursor-color` and `cursor-blink-cycle`. |
| Cursor shape (bar, underline, block) | Workaround | Drive it from the shell with DECSCUSR, for example `printf '\e[6 q'` for a steady bar. Put it in your zsh `zle-keymap-select` hook for vi-mode cursor shapes. |
| Bold as bright, enable bold | Native | Settings \> Terminal \> Style has both, as Auto / On / Off and a Bold as Bright toggle. |
| Blinking text | Workaround | Theme JS: `enable-blink`. |
| Inline images (`imgcat`) | Workaround | Blink sets `allow-images-inline` to `true` at startup and hterm implements the iTerm2 OSC 1337 `File=` protocol. The source comment next to it reads "need to make it work", so treat this as likely but verify on your build before depending on it. |
| Badges and status bar | Workaround | No native badge. tmux status line is the replacement, and it is more capable: host, session, battery, k8s context, git branch. |
| Per-host colour switching | Workaround | Two options. Emit OSC colour sequences from the remote `.zshrc`, or give each tmux session a different `status-style` and pane border colour. |
| Scrollbar visibility | Workaround | Theme JS: `scrollbar-visible`. |
| External display handling | Native | Settings \> Terminal \> Display gives Cover, Safe Fit and Fill layout modes, separate external font size, and overscan control. iTerm2 has no equivalent because it never needed one. |

### 5.4 Connections, profiles and automation

| iTerm2 feature | Status | How to get it on iPad |
|----|----|----|
| Profiles | Native | Settings \> Connect \> Hosts, plus a real `ssh_config`. Blink writes `~/.blink/ssh_config` which begins with `Include ssh_config` and `Include ../.ssh/config`, so your desktop `~/.ssh/config` drops in almost unchanged. |
| Dynamic profiles | Native | Same mechanism. `Host` and `Match` blocks in the included config files. |
| Jump hosts / ProxyJump | Native | `ssh -J`, and `-W` for stdio forwarding. |
| Port forwarding | Native | `ssh -L`, `-R`, `-D` for SOCKS, `-N` for no remote command. |
| Connection multiplexing | Native | `ControlMaster auto` is set globally by default. Manage with `ssh -O forward`, `-O cancel`, `-O exit`, `-O stop`. |
| Agent forwarding | Native | `ssh -A`, plus Settings \> Connect \> Default Agent and `ssh-add`. |
| Password manager (<span class="kbd">⌘ ⌥ F</span>) | Native | Settings \> Connect \> Keys & Certificates. Supports Secure Enclave keys and WebAuthn keys. Settings \> Configuration \> Auto Lock adds Face ID or Touch ID gating. This is stronger than iTerm2's. |
| Survive network changes and sleep | Native | **mosh.** This is where Blink beats iTerm2 outright. On a tablet that keeps changing networks and suspending, mosh plus tmux is the entire reason the setup is usable. |
| Triggers (regex matches an action) | None | No trigger engine. Partial substitute: have the remote emit an OSC notification when something matters, see section 10. |
| Alerts and notifications | Workaround | Settings \> Terminal \> Notifications. BEL plays a sound, notifies when the shell is backgrounded, and can use haptics. Blink also honours standard OSC notification sequences and iTerm2-style growl notifications. |
| Python API / scripting | None | No scripting API. Blink exposes an x-callback-url interface (`xcall`, `open`) usable from the Shortcuts app for coarse automation. |
| Autocomplete (<span class="kbd">⌘ ;</span>) | Workaround | Blink has its own local completion with command hints on <span class="kbd">Tab</span>. For the remote shell, install `zsh-autosuggestions` and `fzf`. |
| Command history search (<span class="kbd">⌘ ⇧ ;</span>) | Workaround | Local: the `history` command. Remote: `atuin` or fzf's <span class="kbd">⌃ R</span>, which is strictly better than iTerm2's. |
| File upload / download via drag | Native | Built-in `scp` and `sftp`. Blink also ships a Files.app provider, so remote hosts appear in the Files app, plus `link-files` to mount Files.app folders into the shell, and a Bookmarks system in Settings. |
| Editing remote files | Native | Built-in `vim`, or the `code` command which runs a VS Code-like editor in-app. Install the `blink-fs` extension so it can see remote files. |
| Toolbelt | None | No panel. tmux status line plus a second Blink window under Stage Manager covers most of the use. |

## 6. Appearance: the hterm preference surface

This is the part most Blink users never discover. A theme is not a colour list; it is a JavaScript file executed against the live hterm preference manager (`Resources/term.js` exposes `t.prefs_`). Anything hterm can be told, you can set.

### 6.1 Preferences Blink forces at startup

From `term_setupDefaults()`. Your theme runs after these, so you can override any of them.

- `copy-on-select` set to `false`
- `audible-bell-sound` set to empty, the native notification system handles bells instead
- `receive-encoding` set to `raw`, because Blink is UTF-8 end to end
- `allow-images-inline` set to `true`
- `scroll-wheel-may-send-arrow-keys` set to `true`

### 6.2 The preferences worth setting

| Preference key | Effect, and the iTerm2 setting it replaces |
|----|----|
| `color-palette-overrides` | The sixteen ANSI colours. This is where an `.itermcolors` file lands. |
| `foreground-color`, `background-color`, `cursor-color` | The three colours outside the palette. |
| `cursor-blink`, `cursor-blink-cycle` | Cursor blink and its on/off timing in milliseconds. |
| `copy-on-select` | iTerm2 "Copy to pasteboard on selection". |
| `clear-selection-after-copy` | Whether the highlight disappears after copying. |
| `enable-clipboard-write` | OSC 52 clipboard write. Blink manages this per session already; leave it alone unless you are debugging. |
| `enable-clipboard-notice` | The "copied" overlay. Turn off if it gets in the way. |
| `scroll-on-keystroke`, `scroll-on-output` | iTerm2 scrollback jump behaviour. |
| `scrollbar-visible` | Show or hide the scrollbar. |
| `scroll-wheel-move-multiplier` | Trackpad scroll speed. Worth raising on the Magic Keyboard trackpad. |
| `word-break-match-left`, `-middle`, `-right` | Regexes defining a word for double-click selection. This is iTerm2 Smart Selection, in a cruder form. |
| `enable-bold`, `enable-bold-as-bright`, `enable-blink` | Text rendering attributes. The first two also have UI toggles. |
| `font-smoothing`, `font-family`, `font-size` | Typography. Font family and size also have UI. |
| `background-image`, `background-size`, `background-position` | iTerm2 background image. |
| `user-css`, `user-css-text` | Arbitrary CSS injected into the terminal document. The escape hatch for anything else: letter spacing, line height, selection colour, padding. |
| `alt-sends-what`, `alt-is-meta`, `alt-backspace-is-meta-backspace` | Option key behaviour. Normally handled by Blink's own modifier config instead; change these only if the native remap is not doing what you want. |
| `pass-alt-number`, `pass-ctrl-number`, `pass-meta-number` | Whether modifier plus digit reaches the terminal or is swallowed. Relevant to the <span class="kbd">⌘</span>+digit conflict in section 4.2. |
| `shift-insert-paste`, `ctrl-c-copy`, `ctrl-v-paste` | Alternative clipboard keys. |
| `desktop-notification-bell`, `audible-bell-sound` | Bell handling, though Blink's native Notifications settings is the better control. |
| `allow-images-inline` | Inline image protocol. On by default. |
| `hide-mouse-while-typing` | Hides the trackpad pointer while typing. |
| `close-on-exit` | Whether the terminal closes when the session ends. |

### 6.3 A theme template to start from

Save as a `.js` file, host it anywhere reachable by URL, then Settings \> Terminal \> Style \> Themes \> Add a new theme. Substitute your iTerm2 palette into the sixteen colour variables.

    // my-iterm-port.js : iTerm2 palette and behaviour, ported to Blink.
    // The 16 ANSI colours, in iTerm2's own order.
    black        = '#1d1f21';  red          = '#cc6666';
    green        = '#b5bd68';  yellow       = '#f0c674';
    blue         = '#81a2be';  magenta      = '#b294bb';
    cyan         = '#8abeb7';  white        = '#c5c8c6';
    lightBlack   = '#666666';  lightRed     = '#d54e53';
    lightGreen   = '#b9ca4a';  lightYellow  = '#e7c547';
    lightBlue    = '#7aa6da';  lightMagenta = '#c397d8';
    lightCyan    = '#70c0b1';  lightWhite   = '#eaeaea';

    t.prefs_.set('color-palette-overrides', [
      black,      red,      green,      yellow,
      blue,       magenta,  cyan,       white,
      lightBlack, lightRed, lightGreen, lightYellow,
      lightBlue,  lightMagenta, lightCyan, lightWhite
    ]);

    t.prefs_.set('foreground-color', white);
    t.prefs_.set('background-color', black);
    t.prefs_.set('cursor-color', 'rgba(197, 200, 198, 0.65)');

    // Behaviour parity with a typical iTerm2 setup.
    t.prefs_.set('copy-on-select', true);
    t.prefs_.set('clear-selection-after-copy', true);
    t.prefs_.set('enable-clipboard-notice', false);
    t.prefs_.set('scroll-on-keystroke', true);
    t.prefs_.set('scroll-on-output', false);
    t.prefs_.set('scrollbar-visible', false);
    t.prefs_.set('scroll-wheel-move-multiplier', 3);
    t.prefs_.set('cursor-blink', false);
    t.prefs_.set('enable-bold-as-bright', true);
    t.prefs_.set('hide-mouse-while-typing', true);

    // Smart-selection-ish: treat these as part of a word on double tap.
    t.prefs_.set('word-break-match-left',
      '[^\\s\\[\\](){}:"\'\\u00a0]+$');
    t.prefs_.set('word-break-match-right',
      '^[^\\s\\[\\](){}:"\'\\u00a0]+');

    // Anything else: raw CSS into the terminal document.
    t.prefs_.set('user-css-text', `
      x-screen { padding: 6px 8px !important; }
      x-screen::selection { background: rgba(129,162,190,0.35); }
    `);

**Converting an `.itermcolors` file:** it is a plist of `Ansi 0 Colour` through `Ansi 15 Colour` plus `Foreground`, `Background` and `Cursor`, each stored as float RGB components in 0..1. Multiply each by 255, round, and convert to hex. Do it once per theme on the Mac and keep the resulting `.js` in a gist so Blink can fetch it by URL on any device.

## 7. tmux: the layer that buys you panes

Blink has no panes, no scrollback search, no broadcast input, no session persistence across a terminal close, and no status bar. tmux on the remote host supplies all five. On an iPad this is not a nicety; it is the architecture.

Paste this into `~/.tmux.conf` on the machines you ssh into. It is tuned for Blink specifically: prefix stays <span class="kbd">⌃ b</span> because the hex shortcuts in section 8 encode `0x02`, truecolor is forced because `TERM` is `xterm-256color`, and OSC 52 clipboard is switched on because Blink supports it.

    # ~/.tmux.conf : tuned for Blink Shell on iPad

    # --- Core -------------------------------------------------------------
    set -g default-terminal "xterm-256color"
    set -as terminal-features ",xterm-256color:RGB"   # hterm renders truecolor
    set -s escape-time 0                               # no lag on Esc, vital for vim
    set -g history-limit 100000                        # your only scrollback that is searchable
    set -g base-index 1
    setw -g pane-base-index 1
    set -g renumber-windows on
    set -g focus-events on
    set -g mouse on                                    # iPad taps and trackpad now work in tmux

    # --- Clipboard: this is the OSC 52 bridge to the iPad clipboard -------
    set -s set-clipboard on

    # --- Copy mode: iTerm2-like selection ---------------------------------
    setw -g mode-keys vi
    bind -T copy-mode-vi v send -X begin-selection
    bind -T copy-mode-vi y send -X copy-pipe-and-cancel
    bind -T copy-mode-vi Escape send -X cancel
    bind -T copy-mode-vi C-v send -X rectangle-toggle

    # --- Splits: iTerm2 geometry, and keep the current directory ----------
    bind % split-window -h -c "#{pane_current_path}"   # side by side, iTerm2 Cmd+D
    bind '"' split-window -v -c "#{pane_current_path}" # stacked,    iTerm2 Cmd+Shift+D
    bind c new-window -c "#{pane_current_path}"

    # --- iTerm2 features that tmux has and Blink does not -----------------
    bind I setw synchronize-panes                      # broadcast input, iTerm2 Cmd+Opt+I
    bind C-k send-keys -R \; clear-history             # true clear, iTerm2 Cmd+K
    bind z resize-pane -Z                              # maximise pane, iTerm2 Cmd+Shift+Enter
    bind r source-file ~/.tmux.conf \; display "reloaded"

    # --- Dim inactive panes, iTerm2 "dim inactive split panes" ------------
    set -g window-style        'fg=colour247,bg=colour236'
    set -g window-active-style 'fg=colour250,bg=colour234'
    set -g pane-border-style        'fg=colour238'
    set -g pane-active-border-style 'fg=colour81'

    # --- Status line: the badge and toolbelt replacement ------------------
    set -g status-interval 5
    set -g status-position bottom
    set -g status-style 'bg=colour234 fg=colour137'
    set -g status-left  ' #[bold]#S #[nobold]'
    set -g status-left-length 24
    set -g status-right '#[fg=colour245]#(hostname -s) #[fg=colour81]%H:%M '
    setw -g window-status-current-style 'fg=colour81 bold'

    # --- Pane navigation without the prefix, for arrow shortcuts ----------
    bind -n M-Left  select-pane -L
    bind -n M-Right select-pane -R
    bind -n M-Up    select-pane -U
    bind -n M-Down  select-pane -D

**Make every connection land in tmux.** Put `ssh myhost -t 'tmux new -A -s main'` behind a Blink Host entry or an ssh_config `RemoteCommand`. Combined with mosh, closing the iPad lid, losing wifi, or quitting Blink all become harmless.

### 7.1 Session persistence stack

1.  **mosh** survives IP changes and sleep. Use it instead of ssh wherever the server allows UDP.
2.  **tmux** survives the client dying completely.
3.  **`tmux-resurrect` and `tmux-continuum`** survive a server reboot, which is the closest thing to iTerm2's saved window arrangements.
4.  **Blink state restoration** brings the tabs back when you reopen the app.

## 8. Mapping iTerm2 muscle memory onto tmux via hex shortcuts

This is the technique that makes the whole thing feel like iTerm2 instead of like tmux. Blink's `hex` shortcut action sends an arbitrary byte sequence to the terminal. A tmux command is just a prefix byte followed by a key. So you can bind <span class="kbd">⌘ D</span> in Blink to the bytes that mean "tmux, split this pane".

Prefix <span class="kbd">⌃ b</span> is `0x02`. If you change your tmux prefix to <span class="kbd">⌃ a</span>, replace every leading `02` below with `01`.

In Settings \> Keyboard \> Shortcuts, add a shortcut, press the key combination, choose the **Send Hex Code** action, and type the hex string with no spaces or `0x`.

| Bind in Blink | Hex to send | tmux keys it sends | Result, and the iTerm2 shortcut it reproduces |
|----|----|----|----|
| <span class="kbd">⌘ D</span> | `0225` | prefix then `%` | Split vertically, panes side by side. iTerm2 <span class="kbd">⌘ D</span>. |
| <span class="kbd">⌘ ⇧ D</span> | `0222` | prefix then `"` | Split horizontally, panes stacked. iTerm2 <span class="kbd">⌘ ⇧ D</span>. |
| <span class="kbd">⌘ ⌥ ←</span> | `021B5B44` | prefix then Left arrow | Focus pane left. iTerm2 <span class="kbd">⌘ ⌥ ←</span>. |
| <span class="kbd">⌘ ⌥ →</span> | `021B5B43` | prefix then Right arrow | Focus pane right. |
| <span class="kbd">⌘ ⌥ ↑</span> | `021B5B41` | prefix then Up arrow | Focus pane up. |
| <span class="kbd">⌘ ⌥ ↓</span> | `021B5B42` | prefix then Down arrow | Focus pane down. |
| <span class="kbd">⌘ ⇧ Enter</span> | `027A` | prefix then `z` | Zoom or unzoom the pane. iTerm2 <span class="kbd">⌘ ⇧ Enter</span>. |
| <span class="kbd">⌘ ⌥ W</span> | `0278` | prefix then `x` | Kill pane. tmux asks to confirm, press `y`. iTerm2 <span class="kbd">⌘ W</span> on a pane. |
| <span class="kbd">⌘ F</span> | `025B2F` | prefix, `[`, then `/` | Enter copy mode and start a search. This is your <span class="kbd">⌘ F</span>. Type the pattern, Enter, then `n` for next, which is your <span class="kbd">⌘ G</span>. |
| <span class="kbd">⌘ ⌥ T</span> | `0263` | prefix then `c` | New tmux window. Distinct from <span class="kbd">⌘ T</span>, which makes a new Blink tab. |
| <span class="kbd">⌘ ⌥ \]</span> | `026E` | prefix then `n` | Next tmux window. |
| <span class="kbd">⌘ ⌥ \[</span> | `0270` | prefix then `p` | Previous tmux window. |
| <span class="kbd">⌘ ⌥ I</span> | `0249` | prefix then `I` | Toggle broadcast input to all panes, using the `bind I` line in the tmux config. iTerm2 <span class="kbd">⌘ ⌥ I</span>. |
| <span class="kbd">⌘ K</span> | `020B` | prefix then <span class="kbd">⌃ k</span> | Clear screen and wipe scrollback, using the `bind C-k` line. iTerm2 <span class="kbd">⌘ K</span>. |
| <span class="kbd">⌘ ⌥ S</span> | `0273` | prefix then `s` | Session chooser. No iTerm2 equivalent, better than one. |
| <span class="kbd">⌘ ⌥ V</span> | `025D` | prefix then `]` | Paste the tmux buffer. |
| <span class="kbd">⌘ ⇧ H</span> | `0223` | prefix then `#` | List paste buffers. This is iTerm2's paste history. |
| <span class="kbd">⌘ ⌥ D</span> | `0264` | prefix then `d` | Detach from the session, leaving it running. |

**Two cautions.** First, these shortcuts fire whether or not you are inside tmux; outside tmux `0225` just types `%` at your prompt. Keep that in mind when a connection drops. Second, <span class="kbd">⌘ ⌥ ←</span> and <span class="kbd">⌘ ⌥ →</span> may be intercepted by Stage Manager on some iPadOS versions. If pane navigation silently does nothing, that is why; use the `bind -n M-Left` alternative from the tmux config and bind <span class="kbd">⌥ ←</span> in Blink to a plain `press` action instead.

### 8.1 Non-tmux hex worth binding

| Suggested key | Hex | Sends |
|----|----|----|
| <span class="kbd">⌘ .</span> | `03` | <span class="kbd">⌃ C</span>. Blink already offers this as a preset action. |
| any | `04` | <span class="kbd">⌃ D</span>, end of file. |
| any | `1A` | <span class="kbd">⌃ Z</span>, suspend. |
| any | `0C` | <span class="kbd">⌃ L</span>, redraw. |
| any | `1B` | Escape. Only needed if you did not remap Caps Lock. |
| any | `7C` `5C` `7E` `60` | `|`, `\`, `~`, backtick. Useful on non-US iPad keyboard layouts where these are awkward. Blink ships presets for several of these. |

## 9. Remote shell setup for the iTerm2 conveniences

Several iTerm2 features are really shell features that iTerm2 happens to bundle. On iPad you install them on the remote host instead, and the result is usually better than the original.

| iTerm2 feature | Remote replacement | Notes |
|----|----|----|
| Autocomplete <span class="kbd">⌘ ;</span> | `zsh-autosuggestions` | Inline grey suggestion from history, accept with <span class="kbd">→</span>. Fewer keystrokes matters more on a tablet. |
| Command history <span class="kbd">⌘ ⇧ ;</span> | `atuin` or fzf <span class="kbd">⌃ R</span> | atuin gives you a synced, searchable, per-directory history across every machine. Strictly beyond what iTerm2 offers. |
| Shell integration marks | Distinctive prompt plus tmux search | Start the prompt with a rare glyph, then <span class="kbd">⌘ F</span> and search for it to hop between commands. |
| Directory jumping | `zoxide` | Replaces "recent directories" in iTerm2's toolbelt. |
| Fuzzy file and process pickers | `fzf` | The single highest leverage install. Pairs with the small screen. |
| Readable `ls` and `cat` | `eza`, `bat` | Colour and icons, which matter more at iPad font sizes. Needs a Nerd Font, which Blink already bundles. |
| Session manager | A tmux sessionizer script bound to a key | fzf over your project directories, attach or create a tmux session for the pick. This is the real replacement for iTerm2 window arrangements. |
| Vim cursor shape per mode | DECSCUSR from `zle-keymap-select` | `printf '\e[6 q'` for bar, `'\e[2 q'` for block. |

## 10. Clipboard, notifications and file transfer

### 10.1 Clipboard

Three separate clipboards exist and confusing them is the usual source of frustration.

1.  **iPad system clipboard.** Written by <span class="kbd">⌘ C</span> in Blink, by OSC 52 from the remote, and by `pbcopy` locally. Read by <span class="kbd">⌘ V</span> and `pbpaste`.
2.  **tmux buffers.** Written by copy mode yank. Bridged to the system clipboard by `set -s set-clipboard on`, which is already in the config in section 7.
3.  **Remote program clipboard,** for example vim registers. Bridge with an OSC 52 yank plugin.

With `set-clipboard on` plus Blink's automatic OSC 52 enablement, yanking in tmux copy mode on a server lands the text in your iPad clipboard, ready to paste into Safari or Slack. Set this up before anything else; it is the difference between a usable and an unusable tablet terminal.

### 10.2 Notifications, the nearest thing to iTerm2 triggers

Settings \> Terminal \> Notifications has: play sound on active shell, notify on background shell, haptic feedback, and OSC notification support. Blink accepts both the standard and the iTerm2 growl sequences. Fire them from the remote at the end of long jobs:

    # Simple system notification
    echo -e "\033]9;Build finished\a"

    # Title plus body
    echo -e "\033]777;notify;Deploy;prod rollout complete\a"

    # Practical use: notify when any long command ends
    long_running_command; echo -e "\033]777;notify;Done;$?\a"

Caveat recorded in Blink's own settings text: some OSC sequences may not pass through mosh. Test on your connection type.

### 10.3 Background sessions and the geo trick

iPadOS suspends backgrounded apps, which kills a terminal that is not protected. Blink's documented workaround is the `geo` command, which takes a location-tracking background assertion and keeps the connection alive. Usage: `geo track` to start, `geo lock <metres>` to only wake on real movement, `geo stop`, `geo current`, `geo last N`. Bind `toggleGeoTrack` to a key if you use it often. It costs battery, so turn it off when you are done.

### 10.4 File transfer

- `scp` and `sftp` are built in.
- Blink's Files.app provider exposes remote hosts inside the iPad Files app, so other apps can open remote files directly.
- `link-files` links a Files.app folder into the Blink shell, which is how you get iCloud Drive or Working Copy content into a terminal command.
- Settings \> Configuration \> Bookmarks stores frequently used locations.
- `code` launches the in-app editor; install the `blink-fs` extension so it can read remote paths.

## 11. Recommended final shortcut map

A complete map that keeps iTerm2 muscle memory, avoids iPadOS reserved keys, and resolves the <span class="kbd">⌘</span>+digit conflict. Configure in Settings \> Keyboard.

#### Step 1, prerequisites

- Functional Keys binding: change from <span class="kbd">⌘</span>+`[0-9]` to <span class="kbd">⌃ ⌘</span>+`[0-9]`.
- Cursor Keys binding: leave at <span class="kbd">⌘</span>+arrow.
- Caps Lock: Control on hold, Escape on tap.
- Option: leave as `Escape` so ALT works in readline and vim.

#### Step 2, the map

| Key | Action type | Value | What it does |
|----|----|----|----|
| <span class="kbd">⌘ T</span> | command | tabNew | New Blink tab. Default, keep. |
| <span class="kbd">⌘ W</span> | command | tabClose | Close Blink tab. Default, keep. |
| <span class="kbd">⌘ 1</span> … <span class="kbd">⌘ 9</span> | command | tab1 … tab9 | Jump to tab. Needs step 1. |
| <span class="kbd">⌘ ⇧ \[</span> / <span class="kbd">⌘ ⇧ \]</span> | command | tabPrevCycling / tabNextCycling | Replace the defaults with the cycling variants so you wrap around. |
| <span class="kbd">⌘ N</span> | command | windowNew | Add this so <span class="kbd">⌘ N</span> matches iTerm2. Keep <span class="kbd">⌘ ⇧ T</span> too. |
| <span class="kbd">⌘ D</span> | hex | `0225` | tmux split, side by side. |
| <span class="kbd">⌘ ⇧ D</span> | hex | `0222` | tmux split, stacked. |
| <span class="kbd">⌘ ⌥ ←→↑↓</span> | hex | `021B5B44` / `43` / `41` / `42` | tmux pane focus. See the Stage Manager caution in section 8. |
| <span class="kbd">⌘ ⇧ Enter</span> | hex | `027A` | Zoom pane. |
| <span class="kbd">⌘ F</span> | hex | `025B2F` | Search scrollback. The most missed iTerm2 feature. |
| <span class="kbd">⌘ K</span> | hex | `020B` | Clear screen and scrollback. |
| <span class="kbd">⌘ ⌥ I</span> | hex | `0249` | Broadcast input to all panes. |
| <span class="kbd">⌘ ⌥ T</span> | hex | `0263` | New tmux window. |
| <span class="kbd">⌘ ⌥ S</span> | hex | `0273` | tmux session chooser. |
| <span class="kbd">⌘ ⇧ H</span> | hex | `0223` | Paste history, tmux buffers. |
| <span class="kbd">⌘ .</span> | hex | `03` | Send <span class="kbd">⌃ C</span> without reaching for Control. |
| <span class="kbd">⌘ ⇧ ,</span> | command | snippetsShow | Snips. Default, keep. |
| <span class="kbd">⌘ ⇧ .</span> | command | scratchShow | Scratchpad. Default, keep. |
| <span class="kbd">⌘ ⌥ K</span> | command | toggleQuickActions | Hide the on-screen Smart Keys bar to reclaim rows. |
| <span class="kbd">⌘ ⌥ G</span> | command | selectionGoogle | Search the selected error message. |
| <span class="kbd">⌘ ⌥ ⇧ S</span> | command | selectionShare | Share selection via the iOS share sheet. |

## 12. Gaps with no workaround

Accept these rather than fighting them.

- **Global hotkey window.** iPadOS has no API. Nothing comes close.
- **Triggers.** No regex-to-action engine anywhere in the stack. The remote must announce events itself via OSC sequences.
- **Instant replay.** Record with asciinema or `tmux-logging` instead, and accept that it is a deliberate act, not a safety net.
- **Shell integration marks and captured output.** No protocol support, so no <span class="kbd">⌘ ⇧ ↑</span> prompt jumping and no "select last command's output".
- **Semantic history.** Tapping a file path in a stack trace does nothing.
- **tmux `-CC` control mode.** tmux windows will never become Blink tabs.
- **Window transparency and blur.** Not exposed on iPadOS.
- **Python scripting API.** Only coarse x-callback-url automation from the Shortcuts app.
- **A real local shell.** `ios_system` is a convenience layer, not a development environment. Do the work on a remote host, a Blink Build machine, or a VM.

## 13. Ordered setup checklist

1.  **Keys first.** Settings \> Connect \> Keys & Certificates. Generate or import, prefer a Secure Enclave key. Turn on Auto Lock with Face ID.
2.  **Hosts and config.** Copy your desktop `~/.ssh/config` into Blink. The global config already does `Include ../.ssh/config`, so it is picked up. Add a `RemoteCommand` that attaches tmux.
3.  **Modifier remaps.** Caps Lock to Control-on-hold plus Escape-on-tap. Move Functional Keys off <span class="kbd">⌘</span> to <span class="kbd">⌃ ⌘</span>.
4.  **tmux config on every remote.** Paste section 7. Confirm `set-clipboard on` works by yanking something and pasting it into Notes.
5.  **Hex shortcuts.** Enter the map from section 11. Test each one inside a tmux session.
6.  **Theme and font.** Port your iTerm2 palette with section 6.3. Pick a Nerd Font variant so your prompt glyphs render.
7.  **Notifications.** Enable OSC notifications, then add a notify call to the end of your long build command.
8.  **Remote shell tooling.** fzf, zsh-autosuggestions, atuin, zoxide, eza, bat.
9.  **mosh.** Install the server side, switch your main host entry to mosh, and confirm it survives flight mode toggling.
10. **Snips.** Move your iTerm2 snippets in, store them in iCloud so they follow you.
11. **Persistence.** Add `tmux-resurrect` and `tmux-continuum` so a server reboot does not cost you the layout.

## 14. Appendix A: built-in local commands

Available in the local Blink shell, from `Blink/Complete.swift`. These run on the iPad, not on a remote host.

**Blink specific:** `config`, `theme`, `ssh`, `ssh-copy-id`, `mosh`, `code`, `build`, `geo`, `facecam`, `open`, `link-files`, `history`, `showkey`, `whatsnew`, `help`, `exit`, `clear`, `pbcopy`, `pbpaste`, `device_info`, `bench`, `say`, `browse`, `xcall`.\
**File and text:** `awk`, `cat`, `cd`, `cp`, `diff`, `du`, `echo`, `egrep`, `fgrep`, `find`, `grep`, `head`, `less`, `link`, `ls`, `md5`, `mkdir`, `mv`, `pwd`, `readlink`, `rm`, `rmdir`, `sed`, `sort`, `stat`, `sum`, `tail`, `tee`, `touch`, `uniq`, `unlink`, `vim`, `wc`.\
**Archive:** `tar`, `gzip`, `gunzip`, `compress`, `uncompress`.\
**Network:** `curl`, `dig`, `host`, `nslookup`, `ping`, `scp`, `sftp`, `telnet`, `whois`.\
**Environment:** `env`, `printenv`, `date`, `uname`, `uptime`, `whoami`, `bc`.

Press <span class="kbd">Tab</span> at an empty prompt to list everything available on your build, and run `help` for the short version.

## 15. Appendix B: hex codes cheat sheet

For writing your own Send Hex Code shortcuts. Prefix bytes assume tmux prefix <span class="kbd">⌃ b</span> equals `02`.

| Character                    | Hex      | Character  | Hex         |
|------------------------------|----------|------------|-------------|
| <span class="kbd">⌃ a</span> | `01`     | `"`        | `22`        |
| <span class="kbd">⌃ b</span> | `02`     | `#`        | `23`        |
| <span class="kbd">⌃ c</span> | `03`     | `%`        | `25`        |
| <span class="kbd">⌃ d</span> | `04`     | `,`        | `2C`        |
| <span class="kbd">⌃ k</span> | `0B`     | `/`        | `2F`        |
| <span class="kbd">⌃ l</span> | `0C`     | `0` … `9`  | `30` … `39` |
| <span class="kbd">⌃ r</span> | `12`     | `[`        | `5B`        |
| <span class="kbd">⌃ v</span> | `16`     | `\`        | `5C`        |
| <span class="kbd">⌃ z</span> | `1A`     | `]`        | `5D`        |
| Escape                       | `1B`     | backtick   | `60`        |
| Space                        | `20`     | `|`        | `7C`        |
| Return                       | `0D`     | `~`        | `7E`        |
| Up arrow                     | `1B5B41` | Down arrow | `1B5B42`    |
| Right arrow                  | `1B5B43` | Left arrow | `1B5B44`    |

Lower case letters are `61` for `a` through `7A` for `z`. Upper case are `41` through `5A`. To build any tmux command, concatenate `02` with the hex of the bound key.

## 16. Appendix C: file locations and where settings live

| What | Where |
|----|----|
| Global ssh config written by Blink | `~/.blink/ssh_config` equivalent, which begins `Include ssh_config` and `Include ../.ssh/config` and sets `ControlMaster auto`, `Compression yes`, `SendEnv LANG` for `Host *`. |
| Your own ssh config | `~/.ssh/config` inside the Blink sandbox. Included automatically. |
| Snips | Local storage or iCloud Drive, visible in the Files app. Optional public index from `github.com/blinksh/snippets`. |
| Themes and fonts | Downloaded by URL from Settings \> Terminal \> Style. Themes are `.js`, fonts are `.css` with `@font-face`. |
| Keyboard config | Encoded `KBConfig`, edited only through Settings \> Keyboard. Defaults live in `KB/Native/Model/KeyShortcut.swift`. |
| Terminal engine and defaults | `Resources/term.js` and `Resources/hterm_all.min.js` in the app bundle. `Resources/FontsAndThemes.md` is the authoring guide. |
| Source tree used for this document | `~/blink-build` on this Mac, version 15.0.8. |

Blink on iPad: iTerm2 Feature Parity Reference  ·  session ipad-blink  ·  2026-10-27  ·  verified against Blink 15.0.8 source at ~/blink-build. Behaviour may differ on App Store builds of other versions. Hold the Command key in Blink for the authoritative live shortcut sheet.
