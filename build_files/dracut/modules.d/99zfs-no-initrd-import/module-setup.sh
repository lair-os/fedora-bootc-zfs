#!/bin/bash
# Dracut module to disable ZFS pool import in initramfs
#
# For systems where root is NOT on ZFS, pool import should happen after
# the real root is mounted. This module removes the zfs-import.target
# from initrd.target.wants, preventing early import that fails due to
# missing /etc/hostname and /etc/hostid.

check() {
    # Only include if zfs module is being included
    require_binaries zpool || return 1
    return 0
}

depends() {
    echo "zfs"
    return 0
}

install() {
    # Remove zfs-import.target from initrd.target.wants
    # The ZFS module adds this, we remove it
    rm -f "${initdir}/etc/systemd/system/initrd.target.wants/zfs-import.target"

    # Also remove individual import service wants if present
    rm -f "${initdir}/etc/systemd/system/zfs-import.target.wants/zfs-import-scan.service"
    rm -f "${initdir}/etc/systemd/system/zfs-import.target.wants/zfs-import-cache.service"

    return 0
}
