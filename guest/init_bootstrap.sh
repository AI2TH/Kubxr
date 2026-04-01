#!/bin/bash
set -e

# 1. System Setup
apk add --no-cache curl coreutils findutils util-linux mount blkid nfs-utils iptables ip6tables cni-plugins libc6-compat openssh

# 2. Setup SSH for config extraction
ssh-keygen -A
echo "root:alpine" | chpasswd
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
rc-update add sshd default
/etc/init.d/sshd start

# 3. Enable Cgroups
mount -t cgroup2 none /sys/fs/cgroup || true

# 3. Disable Swap
swapoff -a || true

# 4. Install k0s (Preferred for musl/Alpine)
echo "Installing k0s..."
curl -sSLf https://get.k0s.sh | sh

# 5. Configure k0s for single-node SQLite
mkdir -p /etc/k0s
k0s default-config > /etc/k0s/k0s.yaml

# Enable metrics-server in k0s config if not already there
# (k0s typically includes metrics-server by default, but we ensure it's active)

# 6. Create OpenRC service
cat <<EOF > /etc/init.d/k0s
#!/sbin/openrc-run
description="k0s kubernetes"
command="/usr/local/bin/k0s"
command_args="controller --single"
pidfile="/run/k0s.pid"
command_background=true
EOF
chmod +x /etc/init.d/k0s

# 7. Start k0s
rc-update add k0s default
/etc/init.d/k0s start

echo "k0s initialization complete"
