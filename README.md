# Win10Browser

Real Windows 10 (not Wine, not a fake web desktop) running in a QEMU virtual machine inside a
GitHub Codespace, shown in your browser. Built on the open-source
[dockur/windows](https://github.com/dockur/windows) container, which downloads the ISO from
Microsoft, installs Windows unattended, and serves a web viewer on port 8006.

## Run it

1. Upload this folder to a GitHub repo -> **Code -> Codespaces -> ... -> New with options**.
   - **2-core (32 GB)**: 60 free hours/month, tight on disk, slower.
   - **4-core (64 GB)**: 30 free hours/month, disk is comfortable, faster.
2. In the Codespace terminal:

```bash
bash start.sh
```

3. **PORTS** tab -> port **8006** -> globe icon.
4. When you're done (shuts Windows down cleanly, then tries to stop the Codespace):

```bash
bash stop.sh
```

| Script | What it does |
|---|---|
| `start.sh` | Starts Windows. Options: `VERSION=10l/10/10e`, `RAM=5G`, `CORES=2`, `DISK=32G`, `IDLE_MIN=15` |
| `stop.sh` | Clean Windows shutdown + stop Codespace. `--windows-only` keeps the Codespace on |
| `space.sh` | Shows real disk use. `--clean` deletes leftovers (ISO, setup image, backups) once installed |
| `logs.sh` | Follow install/boot log |
| `reset.sh` | Wipe the Windows install completely |

## Keeping usage down

- **Sparse disk**: the 32 GB virtual disk only takes up what Windows actually writes
  (`ALLOCATE=N`). TRIM is passed through, so deleting files in Windows and running
  "Optimize Drives" in Windows gives the space back to the Codespace.
- **Install media is deleted automatically** after Windows first boots from its own disk.
  `bash space.sh --clean` removes anything left over, and refuses to run before the install
  has finished (deleting the media too early would make it reinstall).
- **The version is locked** after install. Switching `VERSION` would make dockur reinstall
  and keep a backup of the old disk, doubling storage use. `reset.sh` first if you want to switch.
- **Idle watchdog**: after 15 minutes with no browser viewing port 8006, it shuts Windows down
  cleanly and stops the Codespace. It doesn't run during the first install. Turn it off with
  `IDLE_MIN=0`.
- **Do this on github.com too**: Settings -> Codespaces -> idle timeout **10 min**, retention
  period short. Check usage: Settings -> Billing. Free plan with a $0 spending limit = no bill,
  just blocked until next month.
- **Storage is the hard limit**: free plan = 15 GB-months. A ~15 GB Windows install kept a
  whole month uses all of it. Delete the Codespace when you're done with the experiment.

## Limits

- **Codespaces has no `/dev/kvm`**, so Windows runs in pure software CPU emulation. Expect a
  very slow install (likely hours, not measured) and a laggy desktop. No games.
  If `/dev/kvm` ever exists, `start.sh` uses it automatically.
- `stop.sh` may not be able to stop the Codespace from inside (depends on token permissions);
  it then tells you to stop it at github.com/codespaces. The idle timeout setting is the backup.
- Watching the screen may not count as "activity" for the Codespace idle timeout (unverified).
  If the Codespace stops on its own mid-session, Windows gets cut off without a clean shutdown.
  Raise the idle timeout while you're actively using it, or type in the terminal now and then.
- **Licensing**: Windows runs **unactivated** (watermark, locked personalization) or as an
  evaluation, depending on the edition. Microsoft's license terms still require a license for
  ongoing use; this repo contains no activation bypass. Windows 10 is past end of support
  (Oct 2025): don't sign into anything important inside it.
