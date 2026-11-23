#!/usr/bin/env bash
# Start Windows 10 in a VM (QEMU inside the dockurr/windows container).
# Desktop shows up in the browser on port 8006 (PORTS tab -> globe icon).
#
# Options (env vars):
#   VERSION=10l   Windows 10 LTSC (default, smallest) | 10 = Pro | 10e = Enterprise
#                 Locked after the first install (changing it would reinstall + back up = 2x disk).
#   RAM=5G        RAM for the VM   (default: host RAM minus 3 GB, max 8G)
#   CORES=2       vCPUs            (default: all host cores)
#   DISK=32G      virtual disk max size (sparse: only uses what Windows actually writes)
#   IDLE_MIN=15   auto-stop Windows + Codespace after this many minutes with no viewer (0 = off)
#   STORAGE=dir   where the disk lives (default /workspaces/.win10-storage)
#   LANGUAGE=English
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-10l}"
DISK="${DISK:-32G}"
LANGUAGE="${LANGUAGE:-English}"
STORAGE="${STORAGE:-/workspaces/.win10-storage}"
IDLE_MIN="${IDLE_MIN:-15}"
NAME=win10

host_cores=$(nproc)
host_ram_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
CORES="${CORES:-$host_cores}"
if [ -z "${RAM:-}" ]; then
  r=$(( host_ram_gb - 3 )); [ $r -gt 8 ] && r=8; [ $r -lt 2 ] && r=2
  RAM="${r}G"
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: Docker daemon not running. Did the devcontainer build with docker-in-docker?"
  echo "       Command palette -> 'Codespaces: Rebuild Container', then run this again."
  exit 1
fi

if docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "Already running. Open port 8006 in the PORTS tab. Logs: bash logs.sh"
  exit 0
fi

mkdir -p "$STORAGE"

# Version lock: a different VERSION makes dockur reinstall and keep a backup of the old disk.
if [ -f "$STORAGE/.win10browser-version" ]; then
  locked=$(cat "$STORAGE/.win10browser-version")
  if [ "$locked" != "$VERSION" ]; then
    echo "ERROR: this disk was installed as VERSION=$locked, you asked for VERSION=$VERSION."
    echo "       Changing it would reinstall and keep a backup (double disk use)."
    echo "       Use VERSION=$locked, or run 'bash reset.sh' first to wipe and switch."
    exit 1
  fi
fi
echo "$VERSION" > "$STORAGE/.win10browser-version"

free_gb=$(df -BG --output=avail "$STORAGE" | tail -1 | tr -dc 0-9)
installed=0; [ -f "$STORAGE/windows.boot" ] && installed=1
echo "Free space: ${free_gb} GB  |  machine: ${host_cores} cores, ${host_ram_gb} GB RAM"
if [ $installed = 0 ]; then
  # Install peak: ISO download + extracted copy + rebuilt ISO + growing Windows disk.
  need=22
  if [ "$free_gb" -lt "$need" ]; then
    echo "WARNING: only ${free_gb} GB free; first install peaks around ${need} GB."
    echo "         On a 2-core (32 GB) Codespace this may not fit. Free space first:"
    echo "         docker system prune -af    (and delete anything big in /workspaces)"
    read -rp "Try anyway? [y/N] " a; [ "${a,,}" = y ] || exit 1
  fi
fi

KVM_FLAGS=()
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  echo "KVM: available -> hardware acceleration (fast)."
  KVM_FLAGS=(--device=/dev/kvm -e KVM=Y)
else
  echo "KVM: NOT available -> pure software CPU emulation (slow)."
  KVM_FLAGS=(-e KVM=N)
fi

NET_FLAGS=(--cap-add NET_ADMIN)
[ -e /dev/net/tun ] && NET_FLAGS+=(--device=/dev/net/tun)

docker rm -f "$NAME" >/dev/null 2>&1 || true
echo "Starting Windows ($VERSION): $CORES cores, $RAM RAM, disk up to $DISK (sparse)..."
# ALLOCATE=N  -> sparse disk, grows only as Windows writes
# REMOVE=Y    -> dockur deletes install media once Windows boots from its own disk
docker run -d --name "$NAME" \
  "${KVM_FLAGS[@]}" "${NET_FLAGS[@]}" \
  -e VERSION="$VERSION" -e RAM_SIZE="$RAM" -e CPU_CORES="$CORES" \
  -e DISK_SIZE="$DISK" -e ALLOCATE=N -e REMOVE=Y -e LANGUAGE="$LANGUAGE" \
  -p 8006:8006 \
  -v "$STORAGE:/storage" \
  --stop-timeout 120 \
  docker.io/dockurr/windows >/dev/null

if [ "$IDLE_MIN" != 0 ]; then
  pkill -f idle-watch.sh 2>/dev/null || true
  nohup bash ./idle-watch.sh "$IDLE_MIN" > /tmp/idle-watch.log 2>&1 &
  echo "Idle watchdog: stops Windows + Codespace after $IDLE_MIN min with nobody viewing."
  [ $installed = 0 ] && echo "  (it waits until the install has finished before it starts counting)"
fi

echo
echo "Started. Open the PORTS tab -> port 8006 -> globe icon."
echo "Login (if asked): user 'Docker', password 'admin'."
echo "Progress: bash logs.sh   |   Disk use: bash space.sh   |   Done for today: bash stop.sh"
