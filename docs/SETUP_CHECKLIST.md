# Ordered setup checklist

From **§13** of the parity reference. The order matters: later steps assume
earlier ones.

1. **Keys first.** Settings > Connect > Keys & Certificates. Generate or
   import, preferring a Secure Enclave key. Turn on Auto Lock with Face ID
   or Touch ID under Settings > Configuration.

2. **Hosts and config.** Copy your desktop `~/.ssh/config` into Blink. The
   global config already does `Include ../.ssh/config`, so it is picked up
   as-is. Add a `RemoteCommand` that attaches tmux.
   Start from [`contrib/ipad/ssh_config.example`](../contrib/ipad/ssh_config.example).

3. **Modifier remaps.** Caps Lock to Control-on-hold plus Escape-on-tap, and
   functional keys off `⌘` onto `^⌘`.
   *Both are defaults in this fork.*

4. **tmux config on every remote.** Copy
   [`contrib/ipad/tmux.conf`](../contrib/ipad/tmux.conf) to `~/.tmux.conf`.
   Confirm `set-clipboard on` works by yanking something and pasting it into
   Notes on the iPad.

5. **Hex shortcuts.** The tmux muscle-memory map.
   *Shipped as defaults in this fork.* Test each one inside a tmux session.

6. **Theme and font.** Port your iTerm2 palette with
   [`contrib/ipad/itermcolors2blink.py`](../contrib/ipad/itermcolors2blink.py).
   Pick a Nerd Font variant so prompt glyphs render.

7. **Notifications.** Enable OSC notifications under Settings > Terminal >
   Notifications, then add a notify call to the end of long commands with
   [`contrib/ipad/blink-notify.sh`](../contrib/ipad/blink-notify.sh).

8. **Remote shell tooling.** fzf, zsh-autosuggestions, atuin, zoxide, eza,
   bat. [`contrib/ipad/remote-setup.sh`](../contrib/ipad/remote-setup.sh)
   installs the lot.

9. **mosh.** Install the server side, switch your main host entry to mosh,
   and confirm it survives toggling flight mode.

10. **Snips.** Move your iTerm2 snippets in, stored in iCloud so they follow
    you across devices.

11. **Persistence.** Add `tmux-resurrect` and `tmux-continuum` so a server
    reboot does not cost you the layout.
