#!/system/bin/sh

WDIR=$(pwd)
LATESTKSUM=$(curl -s https://api.github.com/repos/cyberknight777/ksu-lkm/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)
LATESTMBOOT=$(curl -s https://api.github.com/repos/cyberknight777/magisk_bins_ndk/releases | grep -o '"html_url": *"[^"]*"' | sed -E 's/.*\/tag\/([^"]*)".*/\1/' | head -n1)

if [[ ${WDIR} != /data/local/tmp ]]; then
    echo -e "\e[1;31mScript needs to be placed in /data/local/tmp! \e[0m"
    exit 1
fi

case $1 in
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

./ksud boot-patch -b /sdcard/boot.img --kmi android12-5.10 --magiskboot ${WDIR}/work/magiskboot --module ${WDIR}/work/${KSUM} -o /sdcard/Download/ || exit 1

cd ${WDIR} || exit 1
rm -rf ${WDIR}/work || exit 1

echo "\e[1;92mPatched boot image is available at /sdcard/Download. \e[0m"
