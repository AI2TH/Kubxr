#!/bin/bash
set -e

# Internal script to bootstrap the aarch64 Alpine rootfs.
# Runs inside the Docker container started by build_qcow2.sh.

echo "--- Creating empty 2GB raw disk ---"
dd if=/dev/zero of=/tmp/rootfs.raw bs=1M count=2048
mkfs.ext4 -F /tmp/rootfs.raw

echo "--- Mounting raw disk ---"
mkdir -p /mnt/rootfs
mount -o loop /tmp/rootfs.raw /mnt/rootfs

echo "--- Bootstrapping Alpine aarch64 ---"
apk add --no-cache apk-tools-static
mkdir -p /mnt/rootfs/etc/apk
cp /etc/apk/repositories /mnt/rootfs/etc/apk/repositories
# Use aarch64 statically linked apk to install to the mount
apk.static --arch aarch64 -X https://dl-cdn.alpinelinux.org/alpine/v3.19/main -U --root /mnt/rootfs --initdb add alpine-base openrc curl bash e2fsprogs util-linux libc6-compat

echo "--- Configuring Alpine ---"
# Password 'alpine'
echo "root:alpine" | chroot /mnt/rootfs /usr/sbin/chpasswd

# Network setup
cat <<EOF > /mnt/rootfs/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Copy bootstrap script
mkdir -p /mnt/rootfs/opt/k8s
cp /src/guest/init_bootstrap.sh /mnt/rootfs/opt/k8s/init_bootstrap.sh
chmod +x /mnt/rootfs/opt/k8s/init_bootstrap.sh

# Run bootstrap on first boot via OpenRC
cat <<EOF > /mnt/rootfs/etc/init.d/k8s_bootstrap
#!/sbin/openrc-run
description="k8s node bootstrap"
start() {
    ebegin "Running k8s node bootstrap"
    /opt/k8s/init_bootstrap.sh
    rc-update del k8s_bootstrap default
    eend \$?
}
EOF
chmod +x /mnt/rootfs/etc/init.d/k8s_bootstrap
chroot /mnt/rootfs /sbin/rc-update add k8s_bootstrap default

echo "--- Unmounting and converting to QCOW2 ---"
umount /mnt/rootfs
qemu-img convert -f raw -O qcow2 /tmp/rootfs.raw /out/base.qcow2
rm /tmp/rootfs.raw

echo "--- Extraction complete ---"
