image := env("IMAGE_FULL", "localhost/alchemist:latest")
filesystem := env("BUILD_FILESYSTEM", "xfs")

default:
    #!/usr/bin/env bash
    set -xeuo pipefail
    /home/linuxbrew/.linuxbrew/bin/just build
    sudo /home/linuxbrew/.linuxbrew/bin/just load
    sudo /home/linuxbrew/.linuxbrew/bin/just lint
    sudo /home/linuxbrew/.linuxbrew/bin/just ostree-rechunk
    sudo /home/linuxbrew/.linuxbrew/bin/just disk-image
    vmbuddy -f ./bootable.img

build:
    rm mkosi.version || true
    rm Alchemist_* initrd* || true
    mkosi -f -B --root-password=kitty

lint:
    podman run --rm -it  --entrypoint=bootc {{ image }} container lint

load:
    #!/usr/bin/env bash
    set -x
    podman load -i "$(find mkosi.profiles/bootc-ostree/mkosi.output/* -maxdepth 0 -type d -printf "%T@ ,%p\n" -iname "_*" -print0 | sort -n | head -n1 | cut -d, -f2)" -q | cut -d: -f3 | xargs -I{} podman tag {} {{image}}

ostree-rechunk:
    #!/usr/bin/env bash
    sudo podman run --rm \
          --privileged \
          --network=host \
          -t \
          -v /var/lib/containers:/var/lib/containers \
          "quay.io/centos-bootc/centos-bootc:stream10" \
          /usr/libexec/bootc-base-imagectl rechunk --max-layers 67 \
          "{{image}}" \
          "{{image}}" || exit 1

bootc *ARGS:
    podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -v "${BUILD_BASE_DIR:-.}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image}}" bootc {{ARGS}}

disk-image $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${BUILD_BASE_DIR:-.}/bootable.img" ] ; then
        fallocate -l 20G "${BUILD_BASE_DIR:-.}/bootable.img"
    fi
    just bootc install to-disk --generic-image --bootloader=grub --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe

vm:
    vmbuddy Alchemist_1.raw

clean:
    mkosi clean
    sudo rm -r mkosi.tools/ mkosi.cache/