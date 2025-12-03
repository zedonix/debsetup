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

bemoji --download all

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

# Nvim tools install
foot -e nvim +MasonToolsInstall &
foot -e sudo nvim +MasonToolsInstall &
foot -e tmux &
