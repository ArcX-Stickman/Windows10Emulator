#!/usr/bin/env bash
# Stops Windows cleanly, then the Codespace, after N minutes with no browser viewing port 8006.
# During the first install it never fires (nobody needs to watch an install).
MIN="${1:-15}"
STORAGE="${STORAGE:-/workspaces/.win10-storage}"
idle=0
while docker ps --format '{{.Names}}' | grep -qx win10; do
  sleep 60
  [ -f "$STORAGE/windows.boot" ] || { idle=0; continue; }   # still installing
  # established TCP connections on local port 8006 (hex 1F46, state 01) -- no ss/netstat needed
  viewers=$(cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | awk '$2 ~ /:1F46$/ && $4 == "01"' | wc -l)
  if [ "$viewers" -gt 0 ]; then idle=0; else idle=$((idle + 1)); fi
  if [ "$idle" -ge "$MIN" ]; then
    echo "$(date): no viewer for $MIN min -> stopping"
    exec bash "$(dirname "$0")/stop.sh" --codespace
  fi
done
