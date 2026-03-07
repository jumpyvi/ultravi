# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM quay.io/almalinuxorg/almalinux-bootc:10-kitten

RUN dnf install -y dnf-plugins-core 'dnf-command(versionlock)' && \
    dnf -y copr enable ublue-os/packages && \
    dnf -y copr disable ublue-os/packages && \
    dnf -y install epel-release && dnf upgrade -y && \
    dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install uupd && \
    dnf -y install glib2 && dnf versionlock add glib2 && \
    dnf -y remove console-login-helper-messages

RUN dnf group install -y --nobest \
    -x rsyslog* \
    -x cockpit \
    -x cronie* \
    -x crontabs \
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

RUN dnf -y install --skip-broken \
    -x PackageKit \
    -x PackageKit-command-not-found \
    -x gnome-software-fedora-langpacks \
    -x gnome-extensions-app \
    -x gnome-software \
    "NetworkManager-adsl" \
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
    "papers-thumbnailer" \
    "ptyxis" \
    "gnome-disk-utility" \
    "sane-backends-drivers-scanners" \
    "xdg-desktop-portal-gnome" \
    "xdg-user-dirs-gtk" \
    "yelp-tools"

RUN dnf -y install \
    plymouth \
    plymouth-system-theme \
    fwupd \
    fuse \
    fuse-common \
    tuned-ppd \
    systemd-{resolved,container,oomd} \
    libcamera{,-{v4l2,gstreamer,tools}}

RUN dnf -y install \
    firewalld \
    firewall-config \
    NetworkManager-openconnect \
    NetworkManager-openvpn \
    cups cups-pk-helper && \
    curl -fsSLo /usr/lib/firewalld/zones/FedoraWorkstation.xml "https://src.fedoraproject.org/rpms/firewalld/raw/rawhide/f/FedoraWorkstation.xml" && \
    grep -F -e '<port protocol="udp" port="1025-65535"/>' /usr/lib/firewalld/zones/FedoraWorkstation.xml && sed -i 's|^DefaultZone=.*|DefaultZone=FedoraWorkstation|g' /etc/firewalld/firewalld.conf && \
    sed -i 's|^IPv6_rpfilter=.*|IPv6_rpfilter=loose|g' /etc/firewalld/firewalld.conf && \
    grep -F -e "DefaultZone=FedoraWorkstation" /etc/firewalld/firewalld.conf && \
    grep -F -e "IPv6_rpfilter=loose" /etc/firewalld/firewalld.conf


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

RUN dnf install -y almalinux-backgrounds almalinux-backgrounds-extras almalinux-logos

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
