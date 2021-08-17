#!/usr/bin/env bash
# Thanks to mochi for the script :P

gsa() {
	git subtree add --prefix=drivers/staging/qcacld-3.0 https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 $1
	git subtree add --prefix=drivers/staging/fw-api https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/fw-api $1
	git subtree add --prefix=drivers/staging/qca-wifi-host-cmn https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn $1
	git subtree add --prefix=techpack/audio https://source.codeaurora.org/quic/la/platform/vendor/opensource/audio-kernel $1
	git subtree add --prefix=techpack/data https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/data-kernel $1
}
gsp() {
	git subtree pull --prefix=drivers/staging/qcacld-3.0 https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qcacld-3.0 $1
	git subtree pull --prefix=drivers/staging/fw-api https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/fw-api $1
	git subtree pull --prefix=drivers/staging/qca-wifi-host-cmn https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/qca-wifi-host-cmn $1
	git subtree pull --prefix=techpack/audio https://source.codeaurora.org/quic/la/platform/vendor/opensource/audio-kernel $1
	git subtree pull --prefix=techpack/data https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/data-kernel $1
}
if [[ $1 != "" && $1 == "add" ]]; then
	gsa $2
else
	if [[ $1 != "" && $1 == "pull" ]]; then
		gsp $2
	fi
fi
