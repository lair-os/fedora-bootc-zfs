# Fedora Bootc ZFS

Fedora bootc base image with OpenZFS kernel modules pre-built and ready to use.

## Features

- ZFS kernel modules built for the exact kernel in `fedora-bootc`
- ZFS userspace tools (`zpool`, `zfs`, `zdb`, etc.)
- ZFS systemd services enabled (auto-import, mount, share)
- initramfs rebuilt with ZFS support (for ZFS root if desired)

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

| Tag | Description |
|-----|-------------|
| `fc43` | Latest build for Fedora 43 |
| `fc43-zfs2.3.5` | Fedora 43 with ZFS 2.3.5 |
| `fc43-YYYYMMDD` | Date-stamped build |
| `latest` | Most recent build |

## Building Locally

```bash
# Build the image
just build

# Build with specific versions
FEDORA_VERSION=43 ZFS_VERSION=2.3.5 just build

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
