// my-iterm-port.js : an iTerm2 setup ported to Blink.
//
// A Blink theme is not a colour list. It is JavaScript executed against the
// live hterm preference manager, so anything hterm can be told, you can set
// here. That is roughly 89 preference keys, not just colours.
//
// Blink forces a handful of preferences at startup (copy-on-select false,
// audible-bell-sound empty, receive-encoding raw, allow-images-inline true,
// scroll-wheel-may-send-arrow-keys true). Your theme runs after those, so
// anything below overrides them.
//
// Install: host this at any URL, then Settings > Terminal > Style > Themes.
// To port your own palette instead, run:
//     contrib/ipad/itermcolors2blink.py YourScheme.itermcolors

// --- The 16 ANSI colours, in iTerm2's own order -----------------------
var black       = '#1d1f21';  var red          = '#cc6666';
var green       = '#b5bd68';  var yellow       = '#f0c674';
var blue        = '#81a2be';  var magenta      = '#b294bb';
var cyan        = '#8abeb7';  var white        = '#c5c8c6';
var lightBlack  = '#666666';  var lightRed     = '#d54e53';
var lightGreen  = '#b9ca4a';  var lightYellow  = '#e7c547';
var lightBlue   = '#7aa6da';  var lightMagenta = '#c397d8';
var lightCyan   = '#70c0b1';  var lightWhite   = '#eaeaea';

t.prefs_.set('color-palette-overrides', [
  black,      red,      green,      yellow,
  blue,       magenta,  cyan,       white,
  lightBlack, lightRed, lightGreen, lightYellow,
  lightBlue,  lightMagenta, lightCyan, lightWhite
]);

t.prefs_.set('foreground-color', white);
t.prefs_.set('background-color', black);
t.prefs_.set('cursor-color', 'rgba(197, 200, 198, 0.65)');

// --- Behaviour parity with a typical iTerm2 setup ---------------------
// "Copy to pasteboard on selection". Blink turns this off at startup.
t.prefs_.set('copy-on-select', true);
t.prefs_.set('clear-selection-after-copy', true);
// The "copied" overlay. Turn off if it gets in the way.
t.prefs_.set('enable-clipboard-notice', false);
t.prefs_.set('scroll-on-keystroke', true);
t.prefs_.set('scroll-on-output', false);
t.prefs_.set('scrollbar-visible', false);
// Worth raising on the Magic Keyboard trackpad.
t.prefs_.set('scroll-wheel-move-multiplier', 3);
t.prefs_.set('cursor-blink', false);
t.prefs_.set('enable-bold-as-bright', true);
t.prefs_.set('hide-mouse-while-typing', true);

// --- Smart selection --------------------------------------------------
// iTerm2's Smart Selection in a cruder form: these regexes decide what
// counts as a word on a double tap. Keeping punctuation common in paths,
// URLs and flags inside the word is most of the practical value.
t.prefs_.set('word-break-match-left',
  '[^\\s\\[\\]()<>{}:"\'\\u00a0]+$');
t.prefs_.set('word-break-match-right',
  '^[^\\s\\[\\]()<>{}:"\'\\u00a0]+');

// --- Anything else: raw CSS into the terminal document ----------------
// The escape hatch for letter spacing, line height, selection colour and
// padding, none of which have preference keys.
t.prefs_.set('user-css-text', `
  x-screen { padding: 6px 8px !important; }
  x-screen::selection { background: rgba(129,162,190,0.35); }
`);

// --- Optional extras --------------------------------------------------
// iTerm2's background image. Also the only way to fake transparency,
// which iPadOS does not expose.
// t.prefs_.set('background-image', 'url(https://example.com/bg.jpg)');
// t.prefs_.set('background-size', 'cover');
// t.prefs_.set('background-position', 'center');

// Blinking text, off by default in Blink.
// t.prefs_.set('enable-blink', true);
