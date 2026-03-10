image_name := env("BUILD_IMAGE_NAME", "alma-bootc")
image_tag := env("BUILD_IMAGE_TAG", "latest")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")
selinux := env("BUILD_SELINUX", "true")
image := env("IMAGE_NAME", "localhost/alchemist-mkosi:latest")

options := if selinux == "true" { "-v /var/lib/containers:/var/lib/containers:Z -v /etc/containers:/etc/containers:Z -v /sys/fs/selinux:/sys/fs/selinux --security-opt label=type:unconfined_t" } else { "-v /var/lib/containers:/var/lib/containers -v /etc/containers:/etc/containers" }
container_runtime := env("CONTAINER_RUNTIME", `command -v podman >/dev/null 2>&1 && echo podman || echo docker`)

build:
    mkosi -B -f

load:
    #!/usr/bin/env bash
    set -x
    sudo podman load -i "$(find mkosi.profiles/oci/mkosi.output/* -maxdepth 0 -type d -printf "%T@ ,%p\n" -iname "_*" -print0 | sort -n | head -n1 | cut -d, -f2)" -q | cut -d: -f3 | xargs -I{} sudo podman tag {} {{image}}

ostree-rechunk:
    #!/usr/bin/env bash
    sudo podman run --rm \
          --privileged \
          -t \
          -v /var/lib/containers:/var/lib/containers \
          "quay.io/centos-bootc/centos-bootc:stream10" \
          /usr/libexec/bootc-base-imagectl rechunk \
          "{{image}}" \
          "{{image}}" || exit 1

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/selinux:/etc/selinux:ro \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers:Z \
        -v /dev:/dev \
        -v "${BUILD_BASE_DIR:-.}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image}}" bootc {{ARGS}}

generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${base_dir}/bootable.img" ] ; then
        fallocate -l 60G "${base_dir}/bootable.img"
    fi
    # just bootc install to-disk --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe --bootloader grub
    just bootc install to-disk --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe