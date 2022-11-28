#!/usr/bin/env bash
# Written by: cyberknight777
# Fastboot Flash Script (FFS) v1.0

# --- Initialize relevant variables. ---

PART=(
    boot
    dtbo
    recovery
    vendor_boot
    vbmeta
    vbmeta_system
)

DYNAMIC_PART=(
    odm
    product
    system
    system_ext
    vendor
)

MANUAL=1

ARCH=$(uname -m)

# --- Dump payload.bin using payload-dumper-go (Special thanks to @ssut for creating it). ---

if [ ! -f payload-dumper-go ]; then
if [ "$ARCH" == "x86_64" ]; then
    wget -c https://github.com/ssut/payload-dumper-go/releases/download/1.2.2/payload-dumper-go_1.2.2_linux_amd64.tar.gz -O - | tar -xz
else
    echo -e "\e[1mDownload and extract payload-dumper-go from https://github.com/ssut/payload-dumper-go/releases !\e[0m"
    exit 1
fi
fi

./payload-dumper-go payload.bin
mv extracted* img

# --- Set up platform-tools and device. ---

wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip || exit
unzip platform-tools-latest-linux.zip || exit
cd platform-tools/ || exit
./adb reboot bootloader

if [ "$MANUAL" == "1" ]; then
# --- Flash non-dynamic partitions. ---

    for i in "${PART[@]}"
    do
	echo -e "\e[1;36mFlashing ${i}... \e[0m\n"
	sleep 0.3
	./fastboot flash "${i}"_a ../img/"${i}".img
	./fastboot flash "${i}"_b ../img/"${i}".img
    done

# --- Flash dynamic partitions. ---

    ./fastboot reboot fastboot

    for i in "${DYNAMIC_PART[@]}"
    do
	echo -e "\e[1;36mFlashing ${i}... \e[0m\n"
	sleep 0.3
	./fastboot flash --slot=all "${i}" ../img/"${i}".img
    done

else
    touch ../img/android-info.txt
    zip -r9 build.zip ../img/*
    ./fastboot update --skip-reboot build.zip
    getslot=$(./fastboot getvar all 2>&1 | grep -o 'current-slot:[a-b]' | cut -d ':' -f2)
    if [ "${getslot}" == "a" ]; then
        fastboot --set-active=b
    else
        fastboot --set-active=a
    fi
    fastboot reboot bootloader
    ./fastboot update --skip-reboot build.zip

fi

# -- Format data. ---

./fastboot reboot bootloader
./fastboot format:f2fs --fs-options=casefold,projid,compress userdata

# -- Reboot to system. ---

./fastboot reboot
