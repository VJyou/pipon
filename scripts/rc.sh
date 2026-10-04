#!/usr/bin/env bash
# Start (or reattach to) the Remote Control server inside tmux.
#   scripts/rc.sh          -> start/attach
#   scripts/rc.sh resume   -> bring back sessions after the server stopped (~4h window)
#   scripts/rc.sh stop     -> kill the tmux session
set -euo pipefail
SESSION="zk"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
NAME="zkCredentials"

case "${1:-start}" in
  stop)
    tmux kill-session -t "$SESSION" 2>/dev/null && echo "stopped" || echo "not running"
    exit 0 ;;
  resume) CMD="claude remote-control --continue" ;;
  start)  CMD="claude remote-control --name \"$NAME\" --spawn worktree --permission-mode acceptEdits" ;;
  *) echo "usage: $0 [start|resume|stop]"; exit 1 ;;
esac

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "tmux session '$SESSION' already running — attaching (detach: Ctrl-b d)"
else
  tmux new-session -d -s "$SESSION" -c "$DIR" "$CMD; echo; echo '[server exited] press Enter'; read"
  echo "started in tmux '$SESSION'. Press SPACE inside to show the QR code. Detach: Ctrl-b d"
fi
exec tmux attach -t "$SESSION"
