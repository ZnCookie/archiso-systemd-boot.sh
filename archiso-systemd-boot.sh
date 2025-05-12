#!/bin/bash
set -eo pipefail

EFI_DIR="/efi"
ISO_URL="https://mirrors.cernet.edu.cn/archlinux/iso/latest/archlinux-x86_64.iso"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "正在下载最新Arch ISO..."
curl -fL -o "$TMP_DIR/arch.iso" "$ISO_URL"

echo "解压核心文件..."
(
  cd "$TMP_DIR"
  bsdtar -xf arch.iso \
    "arch/boot/x86_64/vmlinuz-linux" \
    "arch/boot/x86_64/initramfs-linux.img" \
    "arch/x86_64/airootfs.sfs"
)

echo "部署启动文件..."
sudo mkdir -p "$EFI_DIR/archiso/x86_64"
sudo cp -f "$TMP_DIR"/arch/boot/x86_64/vmlinuz-linux "$EFI_DIR/archiso/"
sudo cp -f "$TMP_DIR"/arch/boot/x86_64/initramfs-linux.img "$EFI_DIR/archiso/"
sudo cp -f "$TMP_DIR"/arch/x86_64/airootfs.sfs "$EFI_DIR/archiso/x86_64/"

echo -e "创建启动项..."
sudo tee "$EFI_DIR/loader/entries/arch-rescue.conf" >/dev/null <<EOF
title    Arch Linux (rescue system)
sort-key arch-rescue
linux    /archiso/vmlinuz-linux
initrd   /archiso/initramfs-linux.img
options  archisobasedir=archiso archisosearchfilename=/archiso/vmlinuz-linux
EOF

sudo sbctl sign -s "$EFI_DIR/archiso/vmlinuz-linux"

echo -e "完成!"
