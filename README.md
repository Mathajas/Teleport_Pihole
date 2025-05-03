# 🔄 Pi-hole Config Sync Script

This script allows automated synchronization of Pi-hole configuration from a remote container (e.g., backup instance) to a local Pi-hole container using Docker.

## ✨ Features

- SSH-based secure sync from a remote host
- Copies `/etc/pihole` and `/etc/dnsmasq.d` from remote container
- Stops local container, cleans old data, restores new configuration
- Automatically runs `pihole -g` after import
- Cleans up temporary files

## 🖥️ Requirements

- Both Pi-hole instances run in Docker containers
- SSH key-based login to remote host
- `docker` and `tar` available locally and remotely

## 📁 Directory layout

On the local Pi-hole host:
```
/opt/pihole/etc-pihole       ← Docker volume for /etc/pihole
/opt/pihole/etc-dnsmasq.d    ← Docker volume for /etc/dnsmasq.d
/opt/teleporter_pihole/      ← Location of this script
```

## ⚙️ Configuration

Edit the script variables to match your setup:

```bash
REMOTE_HOST="host ip"       # Remote host running Docker Pi-hole
REMOTE_USER="USER"               # SSH user
CONTAINER_NAME="pihole"           # Name of remote container
TARGET_PIHOLE="/opt/pihole/etc-pihole"
TARGET_DNSMASQ="/opt/pihole/etc-dnsmasq.d"
```

Make the script executable:
```bash
chmod +x sync_pihole.sh
```

## 🕹️ Usage

Run manually:
```bash
./teleporter_get.sh
```

Or schedule via cron (on the local Pi-hole host):
```bash
0 3 * * * /opt/teleporter_pihole/sync_pihole.sh >> /var/log/pihole-sync.log 2>&1
```

## ✅ Output Example

```text
[1] Cleaning temporary directory...
[1a] Fetching /etc/pihole from container...
[1b] Fetching /etc/dnsmasq.d from container...
[2] Stopping local Pi-hole...
[3] Ensuring target directories exist...
[4] Cleaning target directories...
[5] Restoring configuration...
[6] Starting Pi-hole...
[7] Running gravity update...
[8] Cleanup done.
✅ Pi-hole sync completed.
```

## 🛡️ Notes

- Make sure the `filip` user on the remote host has `sudo docker cp` permission without password (`sudoers.d`).
- This script assumes volumes are mounted outside the container. It does **not** work with Pi-hole installed natively (non-Docker).
