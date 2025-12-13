#!/usr/bin/env bash
set -ouex pipefail

# Enable ZFS systemd services for automatic pool import and mount

# Pool import services
systemctl enable zfs-import-cache.service   # Import pools from /etc/zfs/zpool.cache
systemctl enable zfs-import-scan.service    # Scan and import discoverable pools

# Mount and share services
systemctl enable zfs-mount.service          # Mount ZFS filesystems
systemctl enable zfs-share.service          # Share ZFS filesystems (NFS/SMB)

# ZFS target (ordering for other services)
systemctl enable zfs.target

# Configure ZFS module to load at boot
echo "zfs" > /usr/lib/modules-load.d/zfs.conf
