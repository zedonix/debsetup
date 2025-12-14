#!/usr/bin/env bash
set -e

kvantummanager --set Gruvbox
gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-Material-Dark'
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
declare -A gsettings_keys=(
  ["org.virt-manager.virt-manager.new-vm firmware"]="uefi"
  ["org.virt-manager.virt-manager.new-vm cpu-default"]="host-passthrough"
  ["org.virt-manager.virt-manager.new-vm graphics-type"]="spice"
)

for key in "${!gsettings_keys[@]}"; do
  schema="${key% *}"
  subkey="${key#* }"
  value="${gsettings_keys[$key]}"

  if gsettings describe "$schema" "$subkey" >/dev/null; then
    gsettings set "$schema" "$subkey" "$value"
  fi
done

# Firefox user.js linking
echo -n "/home/$USER/Documents/personal/default/dotfiles/ublock.txt" | wl-copy
gh auth login
dir=$(echo ~/.mozilla/firefox/*.default-esr)
ln -sf ~/Documents/personal/default/dotfiles/user.js "$dir/user.js"
cp -f ~/Documents/personal/default/dotfiles/book* "$dir/bookmarkbackups/"

# Configure static IP, gateway, and custom DNS
# sudo tee /etc/systemd/resolved.conf <<EOF
# [Resolve]
# DNS=8.8.8.8 8.8.4.4
# EOF
# sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
# sudo tee /etc/NetworkManager/conf.d/dns.conf <<EOF
# [main]
# dns=none
# systemd-resolved=false
# EOF
# sudo tee /etc/resolv.conf <<EOF
# nameserver 1.1.1.1
# nameserver 1.0.0.1
# EOF
# sudo systemctl restart NetworkManager

bemoji --download all &
# Nvim tools install
foot -e nvim +MasonToolsInstall &
foot -e sudo nvim +MasonToolsInstall &
foot -e tmux &

# Libvirt setup
NEW="/home/piyush/Documents/libvirt"
TMP="/tmp/default-pool.xml"
VIRSH="virsh --connect qemu:///system"

if dpkg -s libvirt-daemon &>/dev/null; then
  sudo virsh net-autostart default
  sudo virsh net-start default

  sudo mkdir -p "$NEW"
  sudo chown -R root:libvirt "$NEW"
  sudo chmod -R 2775 "$NEW"

  for p in $(sudo "$VIRSH" pool-list --all --name); do
    [ -z "$p" ] && continue
    if sudo "$VIRSH" pool-dumpxml "$p" | grep -q "<path>${NEW}</path>"; then
      if [ "$p" != "default" ]; then
        sudo "$VIRSH" pool-destroy "$p" || true
        sudo "$VIRSH" pool-undefine "$p" || true
      fi
    fi
  done

  if sudo "$VIRSH" pool-list --all | awk 'NR>2{print $1}' | grep -qx default; then
    sudo "$VIRSH" pool-destroy default || true
    sudo "$VIRSH" pool-undefine default || true
  fi

  cat <<'EOF' | sudo tee "$TMP" >/dev/null
<pool type='dir'>
  <name>default</name>
  <target><path>${NEW}</path></target>
</pool>
EOF

  sudo "$VIRSH" pool-define "$TMP"
  sudo "$VIRSH" pool-start default
  sudo "$VIRSH" pool-autostart default

  if [ -d /var/lib/libvirt/images ] && [ "$(ls -A /var/lib/libvirt/images || true)" != "" ]; then
    sudo rsync -aHAX --progress /var/lib/libvirt/images/ "$NEW/"
    sudo chown -R root:libvirt -- "$NEW"
    sudo find "$NEW" -type d -exec sudo chmod 2775 {} + || true
    sudo find "$NEW" -type f -exec sudo chmod 0644 {} + || true
  fi

  sudo "$VIRSH" pool-refresh default
fi
