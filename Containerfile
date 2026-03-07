# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/almalinuxorg/atomic-desktop-gnome:latest

RUN dnf install -y dnf-plugins-core 'dnf-command(versionlock)' && \
    dnf -y copr enable ublue-os/packages && \
    dnf -y copr disable ublue-os/packages && \
    dnf -y install epel-release && dnf upgrade -y && \
    dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd


RUN dnf config-manager --add-repo "https://pkgs.tailscale.com/stable/rhel/10/tailscale.repo" && \
    dnf config-manager --set-disabled "tailscale-stable" && \
    dnf -y --enablerepo "tailscale-stable" install tailscale

RUN dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo && \
    dnf config-manager --set-disabled epel-multimedia && \
    dnf -y install --enablerepo=epel-multimedia ffmpeg libavcodec @multimedia gstreamer1-plugins-{bad-free,bad-free-libs,good,base} lame{,-libs} && \
    dnf -y install hplip && \
    dnf -y install ntfs-3g xfsprogs btrfs-progs gvfs-mtp gvfs-smb open-vm-tools-desktop

RUN dnf install -y git cmake make binutils curl wget tmux ddcutil podman distrobox fpaste unzip wireguard-tools wl-clipboard xdg-terminal-exec xhost

RUN dnf -y --setopt=install_weak_deps=False install gcc

RUN systemctl enable firewalld.service fwupd.service tailscaled.service uupd.timer && \
    authselect enable-feature with-silent-lastlog

RUN curl -fsSLo /usr/lib/systemd/zram-generator.conf "https://src.fedoraproject.org/rpms/zram-generator/blob/rawhide/f/zram-generator.conf" && \
    grep -F -e "zram-size =" /usr/lib/systemd/zram-generator.conf

RUN mkdir -p /etc/flatpak/remotes.d && \
     curl --retry 3 -o /etc/flatpak/remotes.d/flathub.flatpakrepo "https://dl.flathub.org/repo/flathub.flatpakrepo" && \
     curl --retry 3 -o /etc/flatpak/remotes.d/gnome-nightly.flatpakrepo "https://nightly.gnome.org/gnome-nightly.flatpakrepo"

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
