# Fedora Bootc ZFS

Fedora bootc base image with OpenZFS kernel modules pre-built and ready to use.

## Features

- ZFS kernel modules built for the exact kernel in `fedora-bootc`
- ZFS userspace tools (`zpool`, `zfs`, `zdb`, etc.)
- ZFS systemd services enabled (auto-import, mount, share)

> **Note:** This image does not support ZFS root. Pool import is deferred to
> after the root filesystem is mounted to ensure `/etc/hostid` and
> `/etc/hostname` are available. If you need ZFS root, remove
> `/usr/lib/dracut/modules.d/99zfs-no-initrd-import` and rebuild initramfs.

## Usage

Use as a base image for your ZFS-enabled bootc project:

```dockerfile
FROM ghcr.io/lair-os/fedora-bootc-zfs:fc43

# ZFS is already installed and configured!
# Add your packages and configuration...
RUN dnf5 -y install your-packages

COPY your-files /
```

## Available Tags

### Stable Builds

| Tag | Description |
|-----|-------------|
| `latest` | Most recent stable build |
| `fc43` | Latest stable build for Fedora 43 |
| `fc43-zfs2.3.5` | Fedora 43 with ZFS 2.3.5 (stable) |
| `fc43-YYYYMMDD` | Date-stamped stable build |

### Release Candidate Builds

| Tag | Description |
|-----|-------------|
| `rc` | Latest RC build |
| `fc43-rc` | Latest RC build for Fedora 43 |
| `fc43-zfs2.4.0-rc5` | Fedora 43 with ZFS 2.4.0-rc5 (RC) |

## Version Management

All versions are centrally defined in `versions.env`:

```bash
# versions.env
FEDORA_VERSION=43
ZFS_STABLE_VERSION=2.3.5
ZFS_RC_VERSION=2.4.0-rc5
```

To update versions, edit this single file. Both CI and local builds read from it.

## Building Locally

```bash
# Build the image (uses default stable version)
just build

# Build stable version explicitly
just build-stable

# Build RC version
just build-rc

# Build with a custom version override
ZFS_VERSION=2.3.4 just build

# Build without cache
just build-clean
```

## Included ZFS Services

The following systemd services are enabled by default:

| Service | Description |
|---------|-------------|
| `zfs-import-cache.service` | Import pools from `/etc/zfs/zpool.cache` |
| `zfs-import-scan.service` | Scan and import discoverable pools |
| `zfs-mount.service` | Mount ZFS filesystems |
| `zfs-share.service` | Share ZFS filesystems (NFS/SMB) |
| `zfs.target` | ZFS systemd target |

## Why Pre-built?

Building ZFS kernel modules takes 5-10 minutes. By providing a pre-built base image:

- Your downstream builds are fast (no ZFS compilation)
- Kernel version matching is guaranteed (same base image)
- ZFS configuration is consistent and tested

## License

ZFS is licensed under CDDL. This image simply packages the upstream OpenZFS releases.
