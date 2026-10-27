#!/usr/bin/env bash
#
# Fire an iPad notification from a remote shell.
#
# Blink has no trigger engine: there is no regex-to-action matching anywhere
# in the stack. The remote has to announce events itself, which it does with
# OSC escape sequences that Blink turns into real iOS notifications.
#
# Install on the remote host, not on the iPad.
#
# Usage:
#   blink-notify.sh "Build finished"
#   blink-notify.sh "Deploy" "prod rollout complete"
#   long_running_command; blink-notify.sh "Done" "exit $?"
#
# Wrap a command and be told how it ended:
#   blink-notify.sh --wrap make -j8
#
set -uo pipefail

# OSC 9 is the simple form: one line of text.
# OSC 777;notify is the growl form iTerm2 popularised: title plus body.
notify() {
  local title="$1"
  local body="${2:-}"
  if [ -n "$body" ]; then
    printf '\033]777;notify;%s;%s\a' "$title" "$body"
  else
    printf '\033]9;%s\a' "$title"
  fi
}

if [ "${1:-}" = "--wrap" ]; then
  shift
  [ $# -eq 0 ] && { echo "usage: $0 --wrap <command...>" >&2; exit 2; }
  start=$(date +%s)
  "$@"
  status=$?
  elapsed=$(( $(date +%s) - start ))
  if [ $status -eq 0 ]; then
    notify "Finished in ${elapsed}s" "$*"
  else
    notify "Failed (exit $status) after ${elapsed}s" "$*"
  fi
  exit $status
fi

[ $# -eq 0 ] && { echo "usage: $0 <title> [body]   |   $0 --wrap <command...>" >&2; exit 2; }
notify "$@"
