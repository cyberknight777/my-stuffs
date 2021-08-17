#!/usr/bin/bash
# Author: kNIGHT

# fn main() {
#    println!("why are you reading commented rust code?");
# }

BOLD="\033[1m"

if [ -d "$HOME/Anykernel3/" ]; then
	:
	echo -e "${BOLD}Place Anykernel3 in ~/"
	exit 0
fi

if [ -f zipsigner.jar ]; then
	:
else
	curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/baalajimaestro/Anykernel3/master/zipsigner-3.0.jar
	mv zipsigner-3.0.jar zipsigner.jar
fi
if ! hash clang 2>/dev/null; then
	echo -e "${BOLD} Clang Not Installed!"
	exit 0
else
	:
fi
if ! hash ld.lld 2>/dev/null; then
	echo -e "${BOLD} ld.lld Not Installed!"
	exit 0
else
	:
fi
if ! hash java 2>/dev/null; then
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
KERNEL_DIR=$PWD
Anykernel_DIR=$KERNEL_DIR/Anykernel3
echo -ne "${BOLD}Enter Defconfig Name: "
read -r defconfig
echo -ne "${BOLD}Enter Device Codename: "
read -r codename
export ARCH=arm
export SUBARCH=arm
export CONFIG=${defconfig}
DIR="$(pwd)"
export DIR
KERNELVER="$(make kernelversion)"
export KERNELVER
export PATH=$(pwd)/toolchain/arm-eabi-4.8/bin:$PATH
export CROSS_COMPILE=$(pwd)/toolchain/arm-eabi-4.8/bin/arm-eabi-
STARTTIME="$(date +%T)"
export STARTTIME
ENDTIME="$(date +%T)"
export ENDTIME
tg_send_msg() {
	curl -fsSL -X POST https://api.telegram.org/botBOTTOKEN/sendMessage -d "chat_id=CHATID" -d "text=${1}" &>/dev/null
}

tg_send_build() {
	MD5=$(md5sum "${1}" | cut -d' ' -f1)
	curl -fsSL -X POST -F document=@"${1}" https://api.telegram.org/botBOTTOKEN/sendMessage \
		-F "chat_id=CHATID" \
		-F "disable_web_page_preview=true" \
		-F "parse_mode=html" \
		-F caption="${2} | <b>md5 checksum: </b><code>$MD5</code>" &>/dev/null
}
zip_gen() {
	tg_send_msg "${TIME}: Zipping into a flashable zip ${codename}-${KERNELVER}"
	echo -e "${BOLD}Zipping into a flashable zip..."
	cp ../compiled_code/arch/arm/boot/zImage $Anykernel_DIR/
	cd $Anykernel_DIR || exit 0
	zip -r NetErnels-"${codename}"-"${KERNELVER}".zip ./*
	echo -e "${BOLD}Preparing final zip..."
	tg_send_msg "<code>${TIME}: Signing Zip file with AOSP keys...${codename}-${KERNELVER}</code>"
	java -jar ../zipsigner.jar NetErnels-"${codename}"-"${KERNELVER}".zip NetErnels-"${codename}"-"${KERNELVER}"-signed.zip
	tg_send_build "$Neternels-${codename}-${KERNELVER}-signed.zip" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
	echo -e "${BOLD}Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
}
tg_send_msg "Build Triggered! ${codename}-${KERNELVER}"
tg_send_msg "Cleaning Sources! ${codename}-${KERNELVER}"
echo -e "${BOLD}Cleaning sources..."
make clean && make mrproper && rm -rf ../compiled_code && mkdir ../compiled_code

tg_send_msg "Making  Menuconfig! ${codename}-${KERNELVER}"
echo -e "${BOLD}Making Menuconfig..."
make O=../compiled_code "${CONFIG}"
make O=../compiled_code menuconfig
cp ../compiled_code/.config arch/arm/configs/"$CONFIG"

BUILD_START=$(date +"%s")
tg_send_msg "${STARTTIME}: Starting Build! ${codename}-${KERNELVER}"
echo -e "${BOLD}Starting Build..."
make O=../compiled_code "${CONFIG}"
make O=../compiled_code -j2 2>&1 | tee error.log

BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

if [ -f "${DIR}/../compiled_code/arch/arm/boot/zImage" ]; then
	make O=../compiled_code modules_prepare

	make O=../compiled_code modules_install INSTALL_MOD_PATH=../modules

	make O=../compiled_code modules INSTALL_MOD_PATH=../modules
	tg_send_msg "${ENDTIME}: Kernel Successfully Compiled! ${codename}-${KERNELVER}"
	echo -e "${BOLD}Kernel Successfully Compiled..."
	zip_gen
	exit 0
else
	tg_send_build "error.log" "$<b>${ENDTIME}: Build failed to compile after $((DIFF / 60)) minutes and $((DIFF % 60)) seconds</b> ${codename}-${KERNELVER}"
	echo -e "${BOLD}Build failed to compile..."
	exit 0
fi
