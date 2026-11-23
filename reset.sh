#!/usr/bin/env bash
# Deletes the Windows install completely so the next start.sh installs fresh (any VERSION).
STORAGE="${STORAGE:-/workspaces/.win10-storage}"
read -rp "Delete EVERYTHING in $STORAGE (Windows disk + files)? Type yes: " a
[ "$a" = yes ] || exit 1
docker rm -f win10 >/dev/null 2>&1
rm -rf "$STORAGE"
echo "Done. Run: bash start.sh"
