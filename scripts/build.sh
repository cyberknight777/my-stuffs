#!/usr/bin/bash
# Author: kNIGHT
# mk4
# again edit the script if you need to!

BOLD="\033[1m"

if [ -d "compiler/" ];then
    :
else
    echo -e "${BOLD}Compiler Not Found! Exitting..."
    exit 0
fi
#if [ ! -d "$HOME/anykernel3/" ];then
#    echo -e "${BOLD}Place Anykernel3 in ~/"
#    exit 0
#else
#    :
#fi
#if [ -f zipsigner.jar ];then
#    :
#else
#    curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/AnyKernel2/master/zipsigner-3.0.jar
#    mv zipsigner-3.0.jar zipsigner.jar
#fi
#if ! hash clang 2>/dev/null;then
#    echo -e "${BOLD} Clang Not Installed!"
#    exit 0
#else
 #   :
#fi
if ! hash ld.lld 2>/dev/null;then
    echo -e "${BOLD} ld.lld Not Installed!"
    exit 0
else
    :
fi
if ! hash java 2>/dev/null;then
    echo -e "${BOLD} java Not Installed!"
    exit 0
else
    :
fi
echo -e "${BOLD}
############o.O##############
┌───────────────────────────┐
│┏┓╻┏━╸╺┳╸┏━╸┏━┓┏┓╻┏━╸╻  ┏━┓│
│┃┗┫┣╸  ┃ ┣╸ ┣┳┛┃┗┫┣╸ ┃  ┗━┓│
│╹ ╹┗━╸ ╹ ┗━╸╹┗╸╹ ╹┗━╸┗━╸┗━┛│
└───────────────────────────┘
#######Kernel-Builder########
"
echo -ne "${BOLD}Enter Defconfig Name: "
read -r defconfig
echo -ne "${BOLD}Enter Device Codename: "
read -r codename
echo -ne "${BOLD}Enter Amount Of Cores To Use: "
read -r core
expr ${core} + 1 2> /dev/null
case $? in
    0)
	:
	;;
    *)
	echo "error: Not a number"
	exit 1
	;;
esac
export ARCH=arm64
export SUBARCH=arm64
export CONFIG=${defconfig}
DIR="$(pwd)"
export DIR
KERNELVER="$(make kernelversion)"
export KERNELVER
export CROSS_COMPILE=${DIR}/compiler/toolchains/gcc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=${DIR}/compiler/toolchains/gcc/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export CLANG_TRIPLE=aarch64-linux-gnu
MD5="$(md5sum NetErnels-"${codename}"-"${KERNELVER}"-signed.zip | cut -d' ' -f1)"
export MD5
BUILDER="$(whoami)"
export BUILDER
tg_send_msg(){
    curl -fsSL -X POST https://api.telegram.org/botBOTTOKEN/sendMessage -d "chat_id=-CHATID" -d "parse_mode=html" -d "text=${1}" &>/dev/null
}

tg_send_build(){
    curl -fsSL -X POST -F document=@"${1}" https://api.telegram.org/botBOTTOKEN/sendMessage \
	 -F "chat_id=CHATID" \
	 -F "disable_web_page_preview=true" \
	 -F "parse_mode=html" \
	 -F caption="${2}" &>/dev/null
}
zip_gen(){
    tg_send_msg "<b>${BUILDER}</b>: <code>Zipping into a flashable zip ${codename}-${KERNELVER}</code>"
    echo -e "${BOLD}Zipping into a flashable zip!"
    mv ../compiled_code_"${codename}"/arch/arm64/boot/Image.gz ~/anykernel3/
    zip -r NetErnels-"${codename}"-"${KERNELVER}".zip ~/anykernel3/*
    cp NetErnels-"${codename}"-"${KERNELVER}".zip ./
    echo -e "${BOLD}Preparing final zip!"
    tg_send_msg "<b>${BUILDER}</b>: <code>Signing Zip file with AOSP keys ${codename}-${KERNELVER}</code>"
    java -jar zipsigner.jar NetErnels-"${codename}"-"${KERNELVER}".zip NetErnels-"${codename}"-"${KERNELVER}"-signed.zip
    tg_send_msg "<b>${BUILDER}</b>: <code>Build took : $((DIFF /60)) minute(s) and $((DIFF % 60)) second(s)</code>"
    echo -e "${BOLD}Build took: $((DIFF /60)) minute(s) and $((DIFF % 60)) second(s)"
}
tg_send_msg "<b>${BUILDER}</b>: <code>Build Triggered! ${codename}-${KERNELVER}</code>"
echo -ne "${BOLD}Do you want to do a clean build or a dirty build?(Y/n): "
read -r build
case ${build} in
    Y|y)
	tg_send_msg "<b>${BUILDER}</b>: <code>Clean Build Commenced! ${codename}-${KERNELVER}</code>"
	echo -e "${BOLD}Clean Build Commenced!"
	make clean && make mrproper
	if [ ! -d "../compiled_code_${codename}" ];then
	    :
	else
	    rm -rf ../compiled_code_"${codename}"
	fi
	;;
    N|n)
	tg_send_msg "<b>${BUILDER}</b>: <code>Dirty Build Commenced! ${codename}-${KERNELVER}</code>"
	echo -e "${BOLD}Dirty Build Commenced!"
	:
	;;
    *)
	echo -e "${BOLD}Wrong Option Entered!"
	exit 0
	;;
esac
tg_send_msg "<b>${BUILDER}</b>: <code>Making Menuconfig! ${codename}-${KERNELVER}</code>"
echo -e "${BOLD}Making Menuconfig..."
make O=../compiled_code_"${codename}" "${CONFIG}"
make O=../compiled_code_"${codename}" menuconfig
cp ../compiled_code_"${codename}"/.config arch/arm64/configs/"${CONFIG}"

BUILD_START=$(date +"%s")
tg_send_msg "<b>${BUILDER}</b>: <code>Starting Build! ${codename}-${KERNELVER}</code>"
echo -e "${BOLD}Starting Build..."
make O=../compiled_code_"${codename}" -j${core} CC=clang "${CONFIG}"
make O=../compiled_code_"${codename}" -j${core} CC=clang 2>&1 | tee error.log

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

if [ -f "${DIR}/../compiled_code_${codename}/arch/arm64/boot/Image.gz" ];then
    tg_send_msg "<b>${BUILDER}</b>: <code>Kernel Successfully Compiled! ${codename}-${KERNELVER}</code>"
    echo -e "${BOLD}Kernel Successfully Compiled..."
    zip_gen
    tg_send_build "NetErnels-${codename}-${KERNELVER}-signed.zip" "<b>${codename}-${KERNELVER}</b> | <b>MD5 Checksum</b>: <code>${MD5}</code>"
    exit 0
else
    tg_send_msg "<b>${BUILDER}</b>: <code>Build failed to compile after $((DIFF / 60)) minutes and $((DIFF % 60)) seconds ${codename}-${KERNELVER}</code>"
    echo -e "${BOLD}Build failed to compile..."
    tg_send_build "error.log" "<b>Log of build</b>"
    exit 0
fi
