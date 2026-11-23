#!/usr/bin/env bash
# Graceful shutdown of Windows (ACPI shutdown, waits up to 2 min), then stops the Codespace
# so it stops using core-hours. Use 'bash stop.sh --windows-only' to keep the Codespace on.
pkill -f idle-watch.sh 2>/dev/null || true
if docker stop -t 120 win10 >/dev/null 2>&1; then echo "Windows stopped."; else echo "Windows not running."; fi
sync

[ "${1:-}" = "--windows-only" ] && exit 0
if [ -n "${CODESPACE_NAME:-}" ]; then
  echo "Stopping this Codespace ($CODESPACE_NAME)..."
  if gh codespace stop -c "$CODESPACE_NAME" 2>/dev/null; then
    echo "Done."
  else
    echo "Couldn't stop it from inside (the Codespace token usually isn't allowed to)."
    echo "Stop it yourself: github.com/codespaces -> ... -> Stop codespace"
  fi
fi
