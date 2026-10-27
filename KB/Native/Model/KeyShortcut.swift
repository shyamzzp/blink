//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import SwiftUI

extension UIKeyModifierFlags {
  func toSymbols() -> String {
    var res = ""
    if contains(.control) {
      res += KeyCode.controlLeft.symbol
    }
    if contains(.alternate) {
      res += KeyCode.optionLeft.symbol
    }
    if contains(.shift) {
      res += KeyCode.shiftLeft.symbol
    }
    if contains(.command) {
      res += KeyCode.commandLeft.symbol
    }
    if contains(.alphaShift) {
      res += KeyCode.capsLock.symbol
    }
    return res
  }
}

class KeyShortcut: ObservableObject, Codable, Identifiable {
  @Published var action: KeyBindingAction = .none
  @Published var modifiers: UIKeyModifierFlags = []
  @Published var input: String = ""
  
  var id: String { "\(action.id)-\(modifiers)-\(input)" }
  
  var title: String { action.title }
  
  var isCleared: Bool { input.isEmpty && modifiers.isEmpty }

  var isInDefaultCommandList: Bool {
    guard case .command(let cmd) = action else { return false }
    return KeyShortcut.defaultList.contains {
      if case .command(let defaultCmd) = $0.action { return defaultCmd == cmd }
      return false
    }
  }

  static func defaultFor(_ shortcut: KeyShortcut) -> KeyShortcut? {
    guard case .command(let cmd) = shortcut.action else { return nil }
    return defaultList.first {
      if case .command(let defaultCmd) = $0.action { return defaultCmd == cmd }
      return false
    }
  }

  var description: String {
    if isCleared { return "None" }

    var res = modifiers.toSymbols()
    
    switch input {
    case UIKeyCommand.inputRightArrow:
      res += KeyCode.right.symbol
    case UIKeyCommand.inputLeftArrow:
      res += KeyCode.left.symbol
    case UIKeyCommand.inputUpArrow:
      res += KeyCode.up.symbol
    case UIKeyCommand.inputDownArrow:
      res += KeyCode.down.symbol
    case UIKeyCommand.inputHome:
      res += KeyCode.home.symbol
    case UIKeyCommand.inputEnd:
      res += KeyCode.end.symbol
    case UIKeyCommand.inputPageUp:
      res += KeyCode.pageUp.symbol
    case UIKeyCommand.inputPageDown:
      res += KeyCode.pageDown.symbol
    case UIKeyCommand.inputEscape:
      res += KeyCode.escape.symbol
    case UIKeyCommand.f1:
      res += KeyCode.f1.symbol
    case UIKeyCommand.f2:
      res += KeyCode.f2.symbol
    case UIKeyCommand.f3:
      res += KeyCode.f3.symbol
    case UIKeyCommand.f4:
      res += KeyCode.f4.symbol
    case UIKeyCommand.f5:
      res += KeyCode.f5.symbol
    case UIKeyCommand.f6:
      res += KeyCode.f6.symbol
    case UIKeyCommand.f7:
      res += KeyCode.f7.symbol
    case UIKeyCommand.f8:
      res += KeyCode.f8.symbol
    case UIKeyCommand.f9:
      res += KeyCode.f9.symbol
    case UIKeyCommand.f10:
      res += KeyCode.f10.symbol
    case UIKeyCommand.f11:
      res += KeyCode.f11.symbol
    case UIKeyCommand.f12:
      res += KeyCode.f12.symbol
    case " ":
      res += KeyCode.space.symbol
    case "\r":
      res += KeyCode.return.symbol
    case "\u{8}":
      res += KeyCode.delete.symbol
    case "\t":
      res += KeyCode.tab.symbol
    default:
      res += input.uppercased()
    }
    
    return res
  }
  
  // - MARK: Codable
   
   enum Keys: CodingKey {
     case action
     case modifiers
     case input
   }
   
   func encode(to encoder: Encoder) throws {
     var c = encoder.container(keyedBy: Keys.self)
     try c.encode(action,             forKey: .action)
     try c.encode(modifiers.rawValue, forKey: .modifiers)
     try c.encode(input,              forKey: .input)
   }
   
   required convenience init(from decoder: Decoder) throws {
     let c = try decoder.container(keyedBy: Keys.self)
     
     let action        = try c.decode(KeyBindingAction.self, forKey: .action)
     let modifiers     = try c.decode(Int.self,              forKey: .modifiers)
     let input         = try c.decode(String.self,           forKey: .input)
     
     self.init(
       action: action,
       modifiers: UIKeyModifierFlags(rawValue: modifiers),
       input: input
     )
   }
  
  init(action: KeyBindingAction, modifiers: UIKeyModifierFlags, input: String) {
    self.action = action
    self.modifiers = modifiers
    self.input = input
  }
  
  convenience init(_ command: Command, _ modifiers: UIKeyModifierFlags, _ input: String) {
    let action = KeyBindingAction.command(command)
    self.init(action: action, modifiers: modifiers, input: input)
  }
  
  static var snippetsShowShortcut: KeyShortcut {
    KeyShortcut(.snippetsShow, [.command, .shift], ",")
  }

  static var scratchShowShortcut: KeyShortcut {
    KeyShortcut(.scratchShow, [.command, .shift], ".")
  }

  static var defaultList: [KeyShortcut] {
    [
      KeyShortcut(.clipboardCopy, .command, "c"),
      KeyShortcut(.clipboardCopyRaw, [.command, .shift], "c"),
      KeyShortcut(.clipboardPaste, .command, "v"),

      // iTerm2 opens a window with Command-N. Only one shortcut per action
      // survives: KeyBindingAction.id is "cmd-<command>" with no key in it,
      // and loadConfig drops every later duplicate. So this replaces the old
      // Command-Shift-T rather than joining it.
      KeyShortcut(.windowNew, .command, "n"),
      KeyShortcut(.windowClose, [.command, .shift], "w"),
      KeyShortcut(.windowFocusOther, [.command], "o"),

      KeyShortcut(.tabNew, .command, "t"),
      KeyShortcut(.tabClose, .command, "w"),
      // Cycling variants, so the ends of the tab strip wrap around the way
      // iTerm2 does rather than stopping.
      KeyShortcut(.tabNextCycling, [.command, .shift], "]"),
      KeyShortcut(.tabPrevCycling, [.command, .shift], "["),
      // The arrow variants are deliberately left on the non-cycling actions.
      // Binding them to the cycling ones as well would be silently discarded,
      // because only the first shortcut per action survives loadConfig.
      KeyShortcut(.tabNext, [.command, .shift], UIKeyCommand.inputRightArrow),
      KeyShortcut(.tabPrev, [.command, .shift], UIKeyCommand.inputLeftArrow),

      // Jump straight to a tab, as iTerm2 does. This needs the functional
      // keys moved off Command, which is the default since the modifier
      // layout change.
      KeyShortcut(.tab1, .command, "1"),
      KeyShortcut(.tab2, .command, "2"),
      KeyShortcut(.tab3, .command, "3"),
      KeyShortcut(.tab4, .command, "4"),
      KeyShortcut(.tab5, .command, "5"),
      KeyShortcut(.tab6, .command, "6"),
      KeyShortcut(.tab7, .command, "7"),
      KeyShortcut(.tab8, .command, "8"),
      KeyShortcut(.tab9, .command, "9"),

      KeyShortcut(.tabMoveToOtherWindow, [.command, .shift], "o"),

      KeyShortcut(.zoomIn, [.command, .shift], "="),
      KeyShortcut(.zoomOut, .command, "-"),
      KeyShortcut(.zoomReset, .command, "="),

      KeyShortcut(.configShow, .command, ","),

      // Reclaim screen rows when a hardware keyboard is attached.
      KeyShortcut(.toggleQuickActions, [.command, .shift], "k"),
      // iTerm2 keeps these in its context menu rather than on a key.
      KeyShortcut(.selectionGoogle, [.command, .shift], "g"),
      KeyShortcut(.selectionShare, [.command, .alternate, .shift], "s"),

      Self.snippetsShowShortcut,
      Self.scratchShowShortcut
    ] + tmuxDefaultList
  }

  /// iTerm2 muscle memory mapped onto tmux.
  ///
  /// Blink has no split panes at any level, no scrollback search, no
  /// broadcast input and no session persistence. tmux on the remote host
  /// supplies all of them, and a tmux command is just the prefix byte
  /// followed by a key. Sending those bytes directly is what makes the
  /// result feel like iTerm2 rather than like tmux.
  ///
  /// Prefix bytes assume the default tmux prefix of Control-b, which is
  /// `0x02`. On a Control-a prefix, replace every leading `02` with `01`.
  ///
  /// These fire whether or not a tmux session is attached. Outside tmux,
  /// `0225` simply types `%` at the prompt.
  static var tmuxDefaultList: [KeyShortcut] {
    func hex(_ bytes: String, _ comment: String,
             _ modifiers: UIKeyModifierFlags, _ input: String) -> KeyShortcut {
      KeyShortcut(action: .hex(bytes, stringInput: nil, comment: "tmux: " + comment),
                  modifiers: modifiers,
                  input: input)
    }

    return [
      // Splits. The single biggest gap: Blink has no panes of its own.
      hex("0225", "split side by side",     [.command], "d"),
      hex("0222", "split stacked",          [.command, .shift], "d"),

      // Pane focus. May be intercepted by Stage Manager on some iPadOS
      // versions; the tmux config also binds Alt-arrow without a prefix as
      // a fallback.
      hex("021B5B44", "focus pane left",    [.command, .alternate], UIKeyCommand.inputLeftArrow),
      hex("021B5B43", "focus pane right",   [.command, .alternate], UIKeyCommand.inputRightArrow),
      hex("021B5B41", "focus pane up",      [.command, .alternate], UIKeyCommand.inputUpArrow),
      hex("021B5B42", "focus pane down",    [.command, .alternate], UIKeyCommand.inputDownArrow),

      hex("027A", "zoom or unzoom pane",    [.command, .shift], "\r"),
      hex("0278", "kill pane",              [.command, .alternate], "w"),

      // Scrollback search, the most missed iTerm2 feature. Enters copy mode
      // and starts a search: prefix, [, then /.
      hex("025B2F", "search scrollback",    [.command], "f"),

      // Clear screen and wipe scrollback, via the bind C-k line in the
      // shipped tmux config.
      hex("020B", "clear screen and scrollback", [.command], "k"),

      // Broadcast input to all panes, via the bind I line.
      hex("0249", "broadcast input to all panes", [.command, .alternate], "i"),

      // tmux windows, distinct from Blink tabs.
      hex("0263", "new tmux window",        [.command, .alternate], "t"),
      hex("026E", "next tmux window",       [.command, .alternate], "]"),
      hex("0270", "previous tmux window",   [.command, .alternate], "["),

      hex("0273", "session chooser",        [.command, .alternate], "s"),
      hex("0264", "detach from session",    [.command, .alternate], "d"),

      // Paste buffers, which is tmux's answer to iTerm2's paste history.
      hex("0223", "list paste buffers",     [.command, .shift], "h"),
      hex("025D", "paste the tmux buffer",  [.command, .alternate], "v"),
    ]
  }
}
