# Alchemist

# Purpose

Minimalist Fedora bootable container with ublue-like utilies


## Workstation

☁️ Based on fedora:43

A slight modification to the base image matching my preference and requirements

### Changes:
- Minimal gnome-shell
- Virtualization support
- Uupd
- Necessary drivers, codecs and utils
- Brew, flathub and gnome-nightly ootb


# How to rebase

```bash
sudo bootc switch --enforce-container-sigpolicy "ghcr.io/jumpyvi/alchemist:latest"
```

# Thanks
- https://github.com/tuna-os/tunaOS
- https://github.com/bootcrew
- https://github.com/ublue-os/bluefin