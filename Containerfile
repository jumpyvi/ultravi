FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/fedora/fedora-bootc:43

RUN dnf install -y dnf5-plugins && \
    dnf -y copr enable ublue-os/packages && \
    dnf -y copr disable ublue-os/packages && \
    dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd

RUN dnf -y install \
    -x gnome-software \
    -x gnome-extensions-app \
    -x PackageKit \
    -x PackageKit-command-not-found \
    -x gnome-software-fedora-langpacks \
    "NetworkManager-adsl" \
    "glib2" \
    "gdm" \
    "gnome-bluetooth" \
    "gnome-color-manager" \
    "gnome-control-center" \
    "gnome-initial-setup" \
    "gnome-remote-desktop" \
    "gnome-session-wayland-session" \
    "gnome-settings-daemon" \
    "gnome-shell" \
    "gnome-user-docs" \
    "gvfs-fuse" \
    "gvfs-goa" \
    "gvfs-gphoto2" \
    "gvfs-mtp" \
    "gvfs-smb" \
    "libsane-hpaio" \
    "nautilus" \
    "orca" \
    "ptyxis" \
    "xdg-desktop-portal-gnome" \
    "xdg-user-dirs-gtk" \
    "yelp-tools" \
    "plymouth" \
    "plymouth-system-theme" \
    "fwupd" \
    "systemd-resolved" \
    "systemd-container" \
    @workstation-product \
    "libcamera-v4l2" \
    "libcamera-gstreamer" \
    "libcamera-tools" \
    "system-reinstall-bootc" \
    "gnome-disk-utility" \
    "tuned-ppd"

RUN dnf -y remove console-login-helper-messages setroubleshoot

RUN dnf -y --setopt=install_weak_deps=False install gcc
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer

RUN dnf config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-multimedia.repo && \
    dnf config-manager setopt fedora-multimedia.enabled=0 && \
    dnf -y install --enablerepo=fedora-multimedia ffmpeg libavcodec @multimedia \
        gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} && \
    dnf -y install cups sane-backends-drivers-scanners hplip && \
    dnf -y install firewalld firewall-config tailscale && \
    dnf -y install ntfs-3g xfsprogs btrfs-progs gvfs-mtp gvfs-smb open-vm-tools-desktop zram-generator

# Ubuntu-like
RUN dnf -y install uutils-coreutils sudo-rs yaru-theme

RUN dnf install -y git cmake make binutils just curl wget tmux ddcutil podman distrobox fpaste unzip wireguard-tools fpaste wl-clipboard xdg-terminal-exec xhost

RUN dnf install -y evolution evolution-ews

RUN systemctl enable firewalld.service fwupd.service brew-setup.service systemd-resolved.service gdm.service tailscaled.service uupd.timer && \
    systemctl disable mcelog.service

RUN authselect enable-feature with-silent-lastlog

RUN sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service

RUN mkdir -p /etc/flatpak/remotes.d && \
     curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo" && \
     curl --retry 3 -o /etc/flatpak/remotes.d/gnome-nightly.flatpakrepo "https://nightly.gnome.org/gnome-nightly.flatpakrepo"


RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build.sh

RUN dnf remove -y libreoffice-core libreoffice

RUN rm -rf /var/cache/
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
