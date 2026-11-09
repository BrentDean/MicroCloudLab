#!/usr/bin/env bash
# MicroCloud PoC: create the NoCloud seed for micro2, then define and boot the VM.
# Run on the Debian KVM host as the interactive operator. Do not run as root.
set -euo pipefail
umask 077

# Pass local paths at runtime; do not commit host-specific storage or key locations.
# Required: MICROCLOUD_LAB_ROOT, MICROCLOUD_SSH_PUBKEY_1, MICROCLOUD_SSH_PUBKEY_2
: "${MICROCLOUD_LAB_ROOT:?Set MICROCLOUD_LAB_ROOT to the directory holding nodes/, cloud-init/, and images/}"
: "${MICROCLOUD_SSH_PUBKEY_1:?Set MICROCLOUD_SSH_PUBKEY_1 to the first SSH public key path}"
: "${MICROCLOUD_SSH_PUBKEY_2:?Set MICROCLOUD_SSH_PUBKEY_2 to the second SSH public key path}"
LAB_ROOT="${MICROCLOUD_LAB_ROOT%/}"
NODE="$LAB_ROOT/nodes/micro2"
DIR="$LAB_ROOT/cloud-init/micro2"
BASE="$LAB_ROOT/images/ubuntu-26.04-server-cloudimg-amd64.img"
SEED="$DIR/seed.iso"
KEY_1="$MICROCLOUD_SSH_PUBKEY_1"
KEY_2="$MICROCLOUD_SSH_PUBKEY_2"

echo "===== PRE-FLIGHT ====="
if sudo virsh -c qemu:///system dominfo micro2 >/dev/null 2>&1; then
  echo "STOP: micro2 is already defined"
  exit 1
fi

ACTIVE_NETS="$(sudo virsh -c qemu:///system net-list --name)"
for network in mc-mgmt mc-uplink; do
  if ! grep -Fx "$network" <<< "$ACTIVE_NETS" >/dev/null; then
    echo "STOP: libvirt network $network is not active"
    exit 1
  fi
  echo "$network: PASS"
done

for disk in os.qcow2 local.qcow2 ceph.qcow2; do
  path="$NODE/$disk"
  if [ ! -f "$path" ] || [ -L "$path" ]; then
    echo "STOP: expected regular disk missing or symlink: $path"
    exit 1
  fi
  if ! sudo -u libvirt-qemu test -w "$path"; then
    echo "STOP: libvirt-qemu cannot write $path"
    exit 1
  fi
  echo "$disk: PASS"
done

for key in "$KEY_1" "$KEY_2"; do
  ssh-keygen -lf "$key" >/dev/null
done

sudo -u libvirt-qemu test -r "$BASE" || {
  echo "STOP: QEMU cannot read the base cloud image"
  exit 1
}

# Guard against replacing any previously generated cloud-init material.
for name in user-data meta-data network-config seed.iso; do
  if [ -e "$DIR/$name" ] || [ -L "$DIR/$name" ]; then
    echo "STOP: cloud-init artifact already exists: $DIR/$name"
    exit 1
  fi
done

install -d -m 0755 "$DIR"

echo "===== CREATE MICR02 NOCLOUD SEED ====="
cat > "$DIR/user-data" <<'EOF'
#cloud-config
hostname: micro2
manage_etc_hosts: true
disable_root: true
ssh_pwauth: false
users:
  - name: ubuntu
    groups: [adm, sudo]
    shell: /bin/bash
    lock_passwd: true
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_authorized_keys:
EOF

for key in "$KEY_1" "$KEY_2"; do
  awk 'NR==1 { print "      - " $1 " " $2 }' "$key" >> "$DIR/user-data"
done

cat > "$DIR/meta-data" <<'EOF'
instance-id: iid-micro2-20261107-01
local-hostname: micro2
EOF

cat > "$DIR/network-config" <<'EOF'
version: 2
ethernets:
  mgmt0:
    match:
      macaddress: "52:54:00:20:30:12"
    set-name: mgmt0
    dhcp4: false
    dhcp6: false
    addresses:
      - 10.203.10.12/24
    routes:
      - to: default
        via: 10.203.10.1
    nameservers:
      addresses:
        - 10.203.10.1
  uplink0:
    match:
      macaddress: "52:54:00:20:31:12"
    set-name: uplink0
    dhcp4: false
    dhcp6: false
    accept-ra: false
    link-local: []
    optional: true
EOF

cloud-localds -N "$DIR/network-config" \
  "$SEED" "$DIR/user-data" "$DIR/meta-data"
chmod 0644 "$SEED"

echo "===== SEED VERIFICATION ====="
file "$SEED"
sudo -u libvirt-qemu test -r "$SEED" || {
  echo "STOP: QEMU cannot read seed ISO"
  exit 1
}
KEY_COUNT="$(grep -c '^      - ' "$DIR/user-data")"
if [ "$KEY_COUNT" -ne 2 ]; then
  echo "STOP: expected two authorized public keys; found $KEY_COUNT"
  exit 1
fi
echo "Authorized SSH public keys: $KEY_COUNT"
echo "Seed access: PASS"

echo "===== DEFINE AND BOOT MICRO2 ====="
sudo virt-install \
  --connect qemu:///system \
  --name micro2 \
  --virt-type kvm \
  --memory 8192 \
  --vcpus 4 \
  --cpu host-passthrough \
  --osinfo ubuntu22.04 \
  --import \
  --boot hd \
  --disk "path=$NODE/os.qcow2,format=qcow2,bus=virtio" \
  --disk "path=$NODE/local.qcow2,format=qcow2,bus=virtio" \
  --disk "path=$NODE/ceph.qcow2,format=qcow2,bus=virtio" \
  --disk "path=$SEED,device=cdrom,readonly=on" \
  --network network=mc-mgmt,model=virtio,mac=52:54:00:20:30:12 \
  --network network=mc-uplink,model=virtio,mac=52:54:00:20:31:12 \
  --graphics none \
  --console pty,target_type=serial \
  --noautoconsole

echo "===== VM STATUS ====="
sudo virsh -c qemu:///system list --all
echo "===== ATTACHED DISKS ====="
sudo virsh -c qemu:///system domblklist micro2
echo "===== ATTACHED NETWORKS ====="
sudo virsh -c qemu:///system domiflist micro2
