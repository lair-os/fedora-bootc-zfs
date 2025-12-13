# =============================================================================
# Fedora Bootc ZFS
# =============================================================================
# Fedora bootc base image with OpenZFS kernel modules pre-built and ready.
#
# This image provides:
#   - ZFS kernel modules built for the exact kernel in fedora-bootc
#   - ZFS userspace tools (zpool, zfs, etc.)
#   - ZFS systemd services enabled (import, mount, share)
#   - initramfs rebuilt with ZFS support
#
# Use as a base for ZFS-enabled bootc projects:
#   FROM ghcr.io/lair-os/fedora-bootc-zfs:fc43
#
# Build:
#   podman build -t fedora-bootc-zfs .
# =============================================================================

ARG FEDORA_VERSION="${FEDORA_VERSION:-43}"
ARG ZFS_VERSION="${ZFS_VERSION:-2.3.5}"

# -----------------------------------------------------------------------------
# Build context
# -----------------------------------------------------------------------------
FROM scratch AS build-ctx
COPY build_files /build_files

# -----------------------------------------------------------------------------
# Stage: Build ZFS kernel modules
# -----------------------------------------------------------------------------
# Using the same fedora-bootc base guarantees the kernel version matches.
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS zfs-builder

ARG ZFS_VERSION="${ZFS_VERSION:-2.3.5}"

# Install build dependencies + kernel-devel (matches kernel already in image)
RUN --mount=type=cache,dst=/var/cache/dnf,sharing=locked \
    dnf5 -y install \
        kernel-devel \
        rpm-build \
        gcc \
        make \
        automake \
        autoconf \
        libtool \
        elfutils-libelf-devel \
        libblkid-devel \
        libuuid-devel \
        libudev-devel \
        openssl-devel \
        zlib-devel \
        libaio-devel \
        libattr-devel \
        libtirpc-devel \
        python3 \
        python3-devel \
        python3-cffi \
        python3-setuptools \
        libffi-devel \
        ncompress \
        curl

# Get kernel version (guaranteed to match the kernel in this bootc image)
RUN KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -1) && \
    echo "KERNEL_VERSION=${KVER}" > /tmp/kernel-version && \
    echo "Building ZFS ${ZFS_VERSION} for kernel ${KVER}"

# Download and extract ZFS source
WORKDIR /build
RUN curl -fsSL -o zfs-${ZFS_VERSION}.tar.gz \
        https://github.com/openzfs/zfs/releases/download/zfs-${ZFS_VERSION}/zfs-${ZFS_VERSION}.tar.gz && \
    tar xzf zfs-${ZFS_VERSION}.tar.gz

# Configure ZFS with the kernel source
WORKDIR /build/zfs-${ZFS_VERSION}
RUN source /tmp/kernel-version && \
    ./configure \
        --with-linux=/usr/src/kernels/${KERNEL_VERSION} \
        --with-linux-obj=/usr/src/kernels/${KERNEL_VERSION}

# Build kmod RPMs
RUN make -j$(nproc) rpm-kmod \
        RPMBUILD_FLAGS="--define '_source_date_epoch_from_changelog 0'"

# Build userspace RPMs
RUN make -j$(nproc) rpm-utils \
        RPMBUILD_FLAGS="--define '_source_date_epoch_from_changelog 0'"

# Collect RPMs into /rpms (excluding debug/devel/test/src packages)
RUN mkdir -p /rpms && \
    find /build/zfs-${ZFS_VERSION} -name "*.rpm" \
        ! -name "*debuginfo*" \
        ! -name "*debugsource*" \
        ! -name "*.src.rpm" \
        ! -name "*test*" \
        ! -name "*devel*" \
        -exec cp {} /rpms/ \; && \
    ls -la /rpms/

# -----------------------------------------------------------------------------
# Stage: Final image with ZFS installed and configured
# -----------------------------------------------------------------------------
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION}

ARG FEDORA_VERSION="${FEDORA_VERSION:-43}"
ARG ZFS_VERSION="${ZFS_VERSION:-2.3.5}"

# Install ZFS RPMs from builder stage
RUN --mount=type=bind,from=zfs-builder,src=/rpms,dst=/rpms/zfs \
    dnf5 -y install /rpms/zfs/*.rpm && \
    dnf5 clean all

# Enable ZFS systemd services
RUN --mount=type=bind,from=build-ctx,source=/,target=/ctx \
    /ctx/build_files/scripts/enable-zfs-services.sh

# Install tmpfiles.d config for pcp directories (needed by sysstat, which ZFS requires)
COPY build_files/zfs-tmpfiles.conf /usr/lib/tmpfiles.d/zfs.conf

# Build initramfs with ZFS support
RUN depmod -a "$(ls /usr/lib/modules)" && \
    kver=$(ls /usr/lib/modules) && \
    DRACUT_NO_XATTR=1 dracut -vf /usr/lib/modules/$kver/initramfs.img "$kver"

# Cleanup /var for bootc compliance (state created at runtime via tmpfiles.d)
RUN rm -rf /var/log/* /var/cache/* /var/lib/pcp && \
    rm -rf /var/lib/dnf /var/lib/rpm-state

# Labels
LABEL org.opencontainers.image.title="fedora-bootc-zfs"
LABEL org.opencontainers.image.description="Fedora bootc with OpenZFS"
LABEL org.opencontainers.image.version="${FEDORA_VERSION}-zfs${ZFS_VERSION}"
LABEL zfs.version="${ZFS_VERSION}"
LABEL containers.bootc="1"
LABEL ostree.bootable="1"

# Validate image
RUN bootc container lint
