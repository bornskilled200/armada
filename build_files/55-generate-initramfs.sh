#!/bin/bash
set -euxo pipefail

# Runs after 40-vendor-system-files: the initramfs bundles the armada splash,
# which is not yet installed when the kernel step runs.
KVER="$(ls /usr/lib/modules)"
IMG="/usr/lib/modules/${KVER}/initramfs.img"

# fedora-bootc ships /root -> var/roothome, absent in the build container;
# dracut-install aborts resolving /root without the target.
mkdir -p /var/roothome

dracut \
    --force \
    --no-hostonly \
    --reproducible \
    --kver "${KVER}" \
    --add ostree \
    --add armada-splash \
    --add armada-ostree-fallback \
    --add armada-xone \
    "${IMG}" "${KVER}"

# dracut drops modules silently: fail the build rather than ship without.
# Exact match: a substring test lets armada-splash-launcher pass for the binary.
required=(
    usr/lib/systemd/system/armada-splash-initrd.service \
    usr/lib/systemd/system/dracut-pre-mount.service.d/armada-splash.conf \
    usr/libexec/armada/armada-splash \
    usr/libexec/armada/armada-splash-launcher \
    usr/libexec/armada/device-env \
    usr/share/armada/splash/splash.asp \
    usr/libexec/armada/armada-ostree-fallback \
    usr/lib/systemd/system/ostree-prepare-root.service.d/armada-fallback.conf \
    usr/lib/ostree/ostree-prepare-root

    # xone GIP dongle stack (see system_files/etc/modprobe.d/xone.conf)
    usr/lib/modules/${KVER}/extra/xone/xone_gip.ko \
    usr/lib/modules/${KVER}/extra/xone/xone_dongle.ko \
    usr/lib/modules/${KVER}/extra/xone/xone_gip_gamepad.ko \
    usr/lib/firmware/xone_dongle_02e6.bin \
    usr/lib/firmware/xone_dongle_02fe.bin \
    usr/lib/firmware/xone_dongle_02f9.bin \
    usr/lib/firmware/xone_dongle_091e.bin
)

if ! lsinitrd "${IMG}" | awk '
    BEGIN {
        count = ARGC - 1
        for (i = 1; i <= count; i++) {
            paths[i] = ARGV[i]
            required[ARGV[i]] = 1
        }
        ARGC = 1
    }
    $NF in required { found[$NF] = 1 }
    END {
        for (i = 1; i <= count; i++) {
            if (!(paths[i] in found)) {
                print "ERROR: " paths[i] " missing from initramfs" > "/dev/stderr"
                missing = 1
            }
        }
        exit missing
    }
' "${required[@]}"; then
    dracut --list-modules --kver "${KVER}" | grep -i armada || true
    exit 1
fi

echo "initramfs generated for ${KVER} with armada-splash"
