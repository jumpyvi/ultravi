FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/almalinuxorg/almalinux-bootc:10-kitten

COPY --from=ctx / /ctx/

RUN cp /ctx/hyperscale.repo /etc/yum.repos.d/

RUN dnf -y --allowerasing --setopt=protected_packages= upgrade \
    systemd systemd-libs systemd-resolved systemd-container systemd-oomd

RUN dnf -y install selinux-policy selinux-policy-targeted systemd-selinux

RUN dnf install -y python3-dnf-plugin-versionlock dnf-plugins-core 'dnf-command(versionlock)' && \
    dnf upgrade -y && \
    dnf -y copr enable ublue-os/packages && \
    dnf -y copr disable ublue-os/packages && \
    dnf -y copr enable jreilly1821/c10s-gnome-49 && \
    dnf -y upgrade glib2 && \
    dnf versionlock add glib2 && \
    dnf config-manager --set-enabled --setopt "copr:copr.fedorainfracloud.org:jreilly1821:c10s-gnome-49.priority=10" && \
    dnf -y install gnome49-el10-compat && \
    dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd

RUN dnf group install -y --nobest \
    -x PackageKit \
    -x PackageKit-command-not-found \
    "Common NetworkManager submodules" \
    "Core" \
    "Fonts" \
    "Guest Desktop Agents" \
    "Hardware Support" \
    "Printing Client" \
    "Standard" \
    "Workstation product core"

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
    "libcamera-v4l2" \
    "libcamera-gstreamer" \
    "libcamera-tools" \
    "system-reinstall-bootc" \
    "gnome-disk-utility" \
    "tuned-ppd"

RUN dnf -y install epel-release

RUN dnf -y remove console-login-helper-messages setroubleshoot

RUN dnf -y install almalinux-backgrounds almalinux-logos

# RUN dnf -y --setopt=install_weak_deps=False install gcc
# COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
# RUN --mount=type=cache,dst=/var/cache \
#     --mount=type=cache,dst=/var/log \
#     --mount=type=tmpfs,dst=/tmp \
#     /usr/bin/systemctl preset brew-setup.service && \
#     /usr/bin/systemctl preset brew-update.timer && \
#     /usr/bin/systemctl preset brew-upgrade.timer

# RUN dnf config-manager --add-repo "https://pkgs.tailscale.com/stable/rhel/10/tailscale.repo" && \
#     dnf config-manager --set-disabled "tailscale-stable" && \
#     dnf -y --enablerepo "tailscale-stable" install tailscale

# RUN dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo && \
#     dnf config-manager --set-disabled epel-multimedia && \
#     dnf -y install --enablerepo=epel-multimedia ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} && \
#     dnf -y install cups sane-backends-drivers-scanners hplip && \
#     dnf -y install firewalld firewall-config && \
#     dnf -y install ntfs-3g xfsprogs btrfs-progs gvfs-mtp gvfs-smb open-vm-tools-desktop zram-generator

# RUN dnf install -y git cmake make binutils curl wget tmux ddcutil podman distrobox fpaste unzip wireguard-tools fpaste wl-clipboard xdg-terminal-exec xhost

# RUN dnf install -y qemu-kvm libvirt virt-install

RUN dnf -y --setopt=install_weak_deps=False install gcc

# RUN systemctl enable firewalld.service fwupd.service brew-setup.service systemd-resolved.service gdm.service tailscaled.service uupd.timer && \
#     systemctl disable rpm-ostree.service mcelog.service

RUN authselect enable-feature with-silent-lastlog

# RUN curl -fsSLo /usr/lib/systemd/zram-generator.conf "https://src.fedoraproject.org/rpms/zram-generator/raw/rawhide/f/zram-generator.conf" && \
#     grep -F -e "zram-size =" /usr/lib/systemd/zram-generator.conf

# RUN mkdir -p /etc/flatpak/remotes.d && \
#      curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo" && \
#      curl --retry 3 -o /etc/flatpak/remotes.d/gnome-nightly.flatpakrepo "https://nightly.gnome.org/gnome-nightly.flatpakrepo"

RUN rm -rf /var/cache/

RUN rm /usr/lib/systemd/system/gdm.service

RUN echo "changeme" | passwd --stdin root
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
