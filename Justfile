# Fedora Bootc ZFS
# Fedora bootc base image with OpenZFS pre-built

# Load versions from versions.env
set dotenv-load
set dotenv-filename := "versions.env"

fedora_version := env("FEDORA_VERSION")
zfs_version := env("ZFS_VERSION", env("ZFS_STABLE_VERSION"))
zfs_stable_version := env("ZFS_STABLE_VERSION")
zfs_rc_version := env("ZFS_RC_VERSION")
image_name := "fedora-bootc-zfs"

# List available recipes
default:
    @just --list

# Build the image
build:
    podman build \
        --build-arg FEDORA_VERSION={{ fedora_version }} \
        --build-arg ZFS_VERSION={{ zfs_version }} \
        -t {{ image_name }}:fc{{ fedora_version }} \
        -t {{ image_name }}:latest \
        .

# Build with no cache
build-clean:
    podman build --no-cache \
        --build-arg FEDORA_VERSION={{ fedora_version }} \
        --build-arg ZFS_VERSION={{ zfs_version }} \
        -t {{ image_name }}:fc{{ fedora_version }} \
        -t {{ image_name }}:latest \
        .

# Run bootc lint on the image
lint:
    podman run --rm localhost/{{ image_name }}:latest bootc container lint

# Show ZFS version in the image
zfs-version:
    podman run --rm localhost/{{ image_name }}:latest rpm -q zfs

# Show kernel version in the image
kernel-version:
    podman run --rm localhost/{{ image_name }}:latest rpm -q kernel

# Test that ZFS module can be loaded (requires privileged)
test:
    podman run --rm --privileged localhost/{{ image_name }}:latest modprobe zfs && echo "ZFS module loaded successfully"

# Run image in ephemeral VM with SSH
run:
    bcvk ephemeral run-ssh --rm -K localhost/{{ image_name }}:latest

# Run with console output for debugging
run-debug:
    bcvk ephemeral run-ssh --rm -K --console localhost/{{ image_name }}:latest

# Build stable ZFS version
build-stable:
    ZFS_VERSION={{ zfs_stable_version }} just build

# Build RC ZFS version
build-rc:
    ZFS_VERSION={{ zfs_rc_version }} just build

# Remove built images
clean:
    -podman rmi {{ image_name }}:fc{{ fedora_version }} {{ image_name }}:latest
