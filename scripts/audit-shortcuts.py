#!/usr/bin/env python3
"""Audit KeyShortcut defaults for the traps Blink's loadConfig sets.

Run against one or more git refs, or with no argument to check the working
tree:

    ./scripts/audit-shortcuts.py              # working tree
    ./scripts/audit-shortcuts.py main HEAD    # named refs

Exits non-zero when it finds a problem, so it works as a pre-merge gate.


1. Duplicate action ids. loadConfig keeps only the first shortcut per action,
   so a second binding for the same action is silently discarded.
2. Duplicate key combinations. Two actions on one chord is ambiguous.
3. iPadOS reserved chords that never reach the app.
"""
import re, subprocess, sys

RESERVED = {
    ("command", "space"): "Spotlight",
    ("command", "tab"): "app switcher",
    ("command", "h"): "Home",
    ("command|alternate", "d"): "show/hide Dock",
}

PATH = "KB/Native/Model/KeyShortcut.swift"


def entries(branch):
    if branch == "WORKTREE":
        src = open(PATH).read()
    else:
        src = subprocess.run(["git", "show", f"{branch}:{PATH}"],
                             capture_output=True, text=True).stdout
    # Only the default lists, not the helper functions above them.
    start = src.find("static var defaultList")
    body = src[start:] if start > 0 else src
    out = []
    # KeyShortcut(.cmd, mods, "x")
    for m in re.finditer(r'KeyShortcut\(\.(\w+),\s*(\[[^\]]*\]|\.\w+),\s*(.+?)\)\s*,', body):
        out.append(("cmd-" + m.group(1), norm(m.group(2)), norm_in(m.group(3))))
    # hex("0225", "comment", [mods], "x")
    for m in re.finditer(r'hex\("([0-9A-Fa-f]+)",\s*"[^"]*",\s*(\[[^\]]*\]),\s*(.+?)\)\s*,', body):
        out.append(("hex-" + m.group(1), norm(m.group(2)), norm_in(m.group(3))))
    return out

def norm(mods):
    return "|".join(sorted(re.findall(r'\.(\w+)', mods)))

def norm_in(raw):
    raw = raw.strip()
    m = re.match(r'UIKeyCommand\.input(\w+)', raw)
    if m:
        return m.group(1).lower()
    return raw.strip('"').replace('\\\\r', 'return')

def audit(branch):
    rows = entries(branch)
    problems = []

    seen_action = {}
    for action, mods, inp in rows:
        if action in seen_action:
            problems.append(f"DISCARDED  {action} bound to {mods}+{inp}, "
                            f"already bound to {seen_action[action]} and dropped by loadConfig")
        else:
            seen_action[action] = f"{mods}+{inp}"

    seen_key = {}
    for action, mods, inp in rows:
        key = (mods, inp)
        if key in seen_key and seen_key[key] != action:
            problems.append(f"COLLISION  {mods}+{inp} bound to both {seen_key[key]} and {action}")
        else:
            seen_key[key] = action

    for (mods, inp), why in RESERVED.items():
        if (mods, inp) in seen_key:
            problems.append(f"RESERVED   {mods}+{inp} is taken by iPadOS ({why})")

    print(f"\n=== {branch}: {len(rows)} shortcuts ===")
    if problems:
        for p in problems:
            print("  " + p)
    else:
        print("  clean: no discarded bindings, no collisions, no reserved chords")
    return len(problems)

refs = sys.argv[1:] or ["WORKTREE"]
total = sum(audit(b) for b in refs)
print(f"\n{total} problem(s) total")
sys.exit(1 if total else 0)
