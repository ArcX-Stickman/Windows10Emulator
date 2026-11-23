#!/usr/bin/env bash
# Shows what is using disk, and (with --clean) removes leftovers that are safe to delete.
STORAGE="${STORAGE:-/workspaces/.win10-storage}"
echo "== Codespace disk"; df -h /workspaces | tail -1
echo "== Windows storage ($STORAGE) -- real size on disk, not virtual size"
du -sh --apparent-size "$STORAGE" 2>/dev/null | sed 's/^/virtual: /'
du -sh "$STORAGE" 2>/dev/null | sed 's/^/real:    /'
ls -lhs "$STORAGE" 2>/dev/null | tail -n +2
echo "== Docker"; docker system df 2>/dev/null

[ "${1:-}" = "--clean" ] || { echo; echo "Run 'bash space.sh --clean' to delete safe leftovers."; exit 0; }

if docker ps --format '{{.Names}}' | grep -qx win10; then
  echo "Stop Windows first: bash stop.sh --windows-only"; exit 1
fi
if [ ! -f "$STORAGE/windows.boot" ] || ! ls "$STORAGE"/data.* >/dev/null 2>&1; then
  echo "Install hasn't finished (no windows.boot marker) -- refusing to delete anything,"
  echo "removing the media now would make it reinstall from scratch."
  exit 1
fi
# Safe once Windows has booted from its own disk: install media, setup image, old backups.
rm -fv "$STORAGE"/*.iso "$STORAGE/setup.img"
rm -rf "$STORAGE/tmp"
if [ -d "$STORAGE/backups" ]; then
  du -sh "$STORAGE/backups"
  read -rp "Delete old install backups too? [y/N] " a
  [ "${a,,}" = y ] && rm -rf "$STORAGE/backups" && echo "backups deleted"
fi
docker image prune -f >/dev/null 2>&1
echo "Clean."
