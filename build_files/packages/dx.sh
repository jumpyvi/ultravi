#!/bin/bash

set -ouex pipefail

dnf -y copr enable ublue-os/packages
dnf5 install -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages --skip-unavailable \
    libvirt \
    ublue-os-libvirt-workarounds \
    edk2-ovmf \
    genisoimage \
    libvirt-nss \
    virt-manager \
    virt-v2v \
    qemu-char-spice \
    qemu-device-display-virtio-gpu \
    qemu-device-display-virtio-vga \
    qemu-device-usb-redirect \
    qemu-img \
    qemu-system-x86-core \
    qemu-user-binfmt \
    qemu-user-static \
    qemu
    
dnf -y install vim
