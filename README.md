# Alchemist

💙 This uses [zirconium-mkosi](https://github.com/tulilirockz/zirconium-mkosi) as a template, thank you!

# Purpose

Minimalist MkOSI AlmaLinux bootable container with ublue-like utilies


## Workstation

☁️ Based on almalinux:10

Mkosi almalinux image

### Changes:
- Up to date and minimal gnome-shell
- Virtualization support
- Uupd
- Necessary drivers, codecs and utils
- Brew, flathub and gnome-nightly ootb


# How to rebase

```bash
sudo bootc switch --enforce-container-sigpolicy "ghcr.io/jumpyvi/alchemist:latest"
```

# Huge thanks
- https://github.com/tulilirockz/zirconium-mkosi
- https://github.com/tuna-os/tunaOS
- https://github.com/bootcrew
- https://github.com/ublue-os/bluefin-lts