#!/bin/bash
set -euxo pipefail

# Xbox Wireless Dongle (MT76) firmware for the xone kmods (extra/xone).
#
# The blobs are Microsoft's, shipped in public Windows driver catalog CABs —
# same source and hashes as upstream xone's install/firmware.sh and
# negativo17's xone-kmod-common (what Bazzite ships). Fetch and hash-pin at
# build time instead of committing the binaries.
#
# Runs after 20-install-kernel.sh so the files are in place when
# 55-generate-initramfs.sh runs dracut (the 92armada-xone dracut module pins
# them into the initramfs). cabextract comes from 10-base-packages.sh.

# "<cab-sha256> <url> <member> <bin-sha256> <dest-name>"
firmwares=(
    "d89a72e8dc10b7c4f16d5c887fe7f54c34c22005ac1f360704d5d9462258ef32 https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2017/03/2ea9591b-f751-442c-80ce-8f4692cdc67b_6b555a3a288153cf04aec6e03cba360afe2fce34.cab FW_ACC_00U.bin 080ce4091e53a4ef3e5fe29939f51fd91f46d6a88be6d67eb6e99a5723b3a223 xone_dongle_02e6.bin"
    "65736a84ff4036645b8f8ec602bed91ab6353019c9cb3233decab9feec0f6f04 https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/07/1cd6a87c-623f-4407-a52d-c31be49e925c_e19f60808bdcbfbd3c3df6be3e71ffc52e43261e.cab FW_ACC_00U.bin 48084d9fa53b9bb04358f3bb127b7495dc8f7bb0b3ca1437bd24ef2b6eabdf66 xone_dongle_02fe.bin"
    "90dd91fb67460d387407fd8109c0e7d0f18f4b659be0f62db858a1849ead2ee0 https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/06/1dbd7cb4-53bc-4857-a5b0-5955c8acaf71_9081931e7d664429a93ffda0db41b7545b7ac257.cab FW_ACC_CL.bin 0023a7bae02974834500c665a281e25b1ba52c9226c84989f9084fa5ce591d9b xone_dongle_02f9.bin"
    "5a8fbad9521e58cc697a8734720ca497673098022d61d91a88be433002ccd8f2 https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2017/08/aeff215c-3bc4-4d36-a3ea-e14bfa8fa9d2_e58550c4f74a27e51e5cb6868b10ff633fa77164.cab FW_ACC_BR.bin e2710daf81e7b36d35985348f68a81d18bc537a2b0c508ffdfde6ac3eae1bad7 xone_dongle_091e.bin"
)

workdir=$(mktemp -d)
trap 'rm -rf "${workdir}"' EXIT

for entry in "${firmwares[@]}"; do
    read -r cab_sha url member bin_sha dest <<<"${entry}"
    cab="${workdir}/$(basename "${url}")"
    curl --retry 3 --retry-delay 2 -fsSL -o "${cab}" "${url}"
    echo "${cab_sha}  ${cab}" | sha256sum -c --quiet
    cabextract -q -F "${member}" "${cab}" -d "${workdir}/ext"
    echo "${bin_sha}  ${workdir}/ext/${member}" | sha256sum -c --quiet
    install -m 0644 "${workdir}/ext/${member}" "/usr/lib/firmware/${dest}"
    rm -rf "${workdir}/ext"
done

ls -la /usr/lib/firmware/xone_dongle_*.bin
