#!/bin/bash
# Bundles the xone GIP dongle stack and the MT76 dongle firmware into the
# initramfs. dracut's default selection skips out-of-tree extra/ modules and
# firmware whose names are composed at runtime, so list them explicitly;
# instmods fails the build if a module is missing. xone_wired is deliberately
# absent: in-tree xpad handles wired controllers.

check() {
    # 255 = explicit --add only, matching the other armada modules.
    return 255
}

depends() {
    echo systemd bash
    return 0
}

installkernel() {
    instmods xone_gip xone_dongle \
        xone_gip_gamepad xone_gip_headset xone_gip_chatpad \
        xone_gip_madcatz_strat xone_gip_madcatz_glam xone_gip_pdp_jaguar

    inst /usr/lib/firmware/xone_dongle_02e6.bin \
        /usr/lib/firmware/xone_dongle_02fe.bin \
        /usr/lib/firmware/xone_dongle_02f9.bin \
        /usr/lib/firmware/xone_dongle_091e.bin
}
