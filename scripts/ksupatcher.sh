#!/system/bin/sh

WDIR=$(pwd)
LATESTKSUM=$(curl -s https://api.github.com/repos/cyberknight777/ksu-lkm/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)
LATESTMBOOT=$(curl -s https://api.github.com/repos/cyberknight777/magisk_bins_ndk/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)

if [[ ${WDIR} != /data/local/tmp ]]; then
	echo -e "\e[1;31mScript needs to be placed in /data/local/tmp! \e[0m"
	exit 1
fi

workinit() {
	mkdir -p ${WDIR}/work || exit 1

	cd ${WDIR}/work || exit 1

	if [[ ${NEED_UNZIP} == "1" ]]; then
		curl -sL ${URL}/${LATEST}/${KSUD} -o ${WDIR}/work/ksud.zip || exit 1
		unzip -j ksud.zip aarch64-linux-android/release/ksud || exit 1
		rm ksud.zip
	else
		curl -sL ${URL}/${LATEST}/${KSUD} -o ${WDIR}/work/ksud || exit 1
	fi

	curl -sL https://github.com/cyberknight777/magisk_bins_ndk/releases/download/${LATESTMBOOT}/magiskboot -o ${WDIR}/work/magiskboot || exit 1

	curl -sL https://github.com/cyberknight777/ksu-lkm/releases/download/${LATESTKSUM}/${KSUM} -o ${WDIR}/work/${KSUM} || exit 1

	chmod +x ksud magiskboot || exit 1
}

patch() {
	if [[ -z $OTA ]]; then
		./ksud boot-patch -b /sdcard/boot.img --kmi android12-5.10 --magiskboot ${WDIR}/work/magiskboot --module ${WDIR}/work/${KSUM} -o /sdcard/Download/ || exit 1
	else
		./ksud boot-patch -b /sdcard/boot.img --kmi android12-5.10 --magiskboot ${WDIR}/work/magiskboot --module ${WDIR}/work/${KSUM} || exit 1
		mv kernelsu_* ksu.img
	fi
}

flash() {
	if [[ -n $OTA ]]; then
		rocheck=$(su -c "blockdev --getro /dev/block/by-name/boot_${NEXTSLOT}")
		if [[ $rocheck == "1" ]]; then
			su -c "blockdev --setrw /dev/block/by-name/boot_${NEXTSLOT}" || exit 1
		fi
		su -c "dd if=/data/local/tmp/work/ksu.img of=/dev/block/by-name/boot_${NEXTSLOT}" || exit 1
	fi
}

cleanup() {
	cd ${WDIR} || exit 1
	rm -rf ${WDIR}/work || exit 1
}

VARIANT=$1
MODE=$2

if [[ $# -lt 1 || $# -gt 2 ]]; then
	echo -e "\e[1;31mUsage: $0 <ksu|ksun> [ota]\e[0m"
	exit 1
fi

case $VARIANT in
ksu)
	URL="https://github.com/Tiann/KernelSU/releases/download"
	LATEST=$(curl -s https://api.github.com/repos/Tiann/KernelSU/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)
	KSUD="ksud-aarch64-linux-android"
	KSUM="kernelsu.ko"
	;;
ksun)
	URL="https://github.com/KernelSU-Next/KernelSU-Next/releases/download"
	LATEST=$(curl -s https://api.github.com/repos/KernelSU-Next/KernelSU-Next/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)
	KSUD="ksud_magic-aarch64-linux-android.zip"
	NEED_UNZIP=1
	KSUM="kernelsu_next.ko"
	;;
*)
	echo -e "\e[1;31mIncorrect KSU variant chosen. Available options are: ksu|ksun \e[0m"
	exit 1
	;;
esac

if [[ -z ${MODE} ]]; then
	:

elif [[ ${MODE} == "ota" ]]; then

	otacheck=$(getprop ota.other.vbmeta_digest)

	if [[ -z $otacheck ]]; then
		echo -e "\e[1;31mOTA option is only usable after installing an update (before rebooting)! \e[0m"
		exit 1
	fi

	if ! command -v su >/dev/null 2>&1; then
		echo -e "\e[1;31mOTA option requires you to be rooted with KernelSU / KernelSU-Next prior! \e[0m"
		exit 1
	fi

	curslot=$(getprop ro.boot.slot_suffix)

	case $curslot in
	_a | a)
		NEXTSLOT="b"
		;;
	_b | b)
		NEXTSLOT="a"
		;;
	*)
		echo -e "\e[1;31mCurrent slot not identified! \e[0m"
		exit 1
		;;
	esac

	su -c "dd if=/dev/block/by-name/boot_${NEXTSLOT} of=/sdcard/boot.img" || exit 1

	OTA=1

else
	echo -e "\e[1;31mIncorrect mode chosen. Available option is: ota \e[0m"
	exit 1
fi

workinit
patch
flash
cleanup

if [[ -z $OTA ]]; then
	echo -e "\n\e[1;92mPatched boot image is available at /sdcard/Download. \e[0m"
else
	echo -e "\n\e[1;92mPatched image has been flashed to boot_${NEXTSLOT}. Proceed with a reboot.\e[0m"
fi
