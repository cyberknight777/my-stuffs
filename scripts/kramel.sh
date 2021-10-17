#!/usr/bin/bash
# Written by: cyberknight777

export CONFIG=dragonheart_defconfig
CURRENTDIR=$(pwd)
export CURRENTDIR
export LINKER="ld.lld"
export DEVICE="OnePlus 7 Series"
export CODENAME="op7"
export REPO_URL="https://github.com/cyberknight777/dragonheart_kernel_oneplus_sm8150"
COMMIT_HASH=$(git rev-parse --short HEAD)
export COMMIT_HASH
export SILENT=0
export CHATID=-1001361882613
PROCS=$(nproc --all)
export PROCS
export COMPILER=gcc
if [[ "${COMPILER}" = gcc ]]; then
	if [ ! -d "gcc64" ]; then
		wget -O "${CURRENTDIR}"/64.zip https://github.com/mvaisakh/gcc-arm64/archive/1a4410a4cf49c78ab83197fdad1d2621760bdc73.zip
		unzip 64.zip
		mv gcc-arm64-1a4410a4cf49c78ab83197fdad1d2621760bdc73 gcc64
	fi
	if [ ! -d "gcc32" ]; then
		wget -O 32.zip https://github.com/mvaisakh/gcc-arm/archive/c8b46a6ab60d998b5efa1d5fb6aa34af35a95bad.zip
		unzip 32.zip
		mv gcc-arm-c8b46a6ab60d998b5efa1d5fb6aa34af35a95bad gcc32
	fi
	KBUILD_COMPILER_STRING=$(gcc64/bin/aarch64-elf-gcc --version | head -n 1)
	export KBUILD_COMPILER_STRING
	export PATH=$CURRENTDIR/gcc32/bin:$CURRENTDIR/gcc64/bin:/usr/bin/:${PATH}
	MAKE+=(
		ARCH=arm64
		O=out
		CROSS_COMPILE=aarch64-elf-
		CROSS_COMPILE_ARM32=arm-eabi-
		LD=aarch64-elf-"${LINKER}"
		AR=aarch64-elf-ar
		OBJDUMP=aarch64-elf-objdump
		STRIP=aarch64-elf-strip
		CC=aarch64-elf-gcc
	)
elif [[ "${COMPILER}" = clang ]]; then
	if [ ! -d "proton-clang" ]; then
		wget https://github.com/kdrag0n/proton-clang/archive/refs/heads/master.zip
		unzip master.zip
		mv proton-clang-master proton-clang
	fi
	KBUILD_COMPILER_STRING=$(proton-clang/bin/clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')
	export KBUILD_COMPILER_STRING
	export PATH=$CURRENTDIR/proton-clang/bin/:/usr/bin/:${PATH}
	MAKE+=(
		ARCH=arm64
		O=out
		CROSS_COMPILE=aarch64-linux-gnu-
		CROSS_COMPILE_ARM32=arm-linux-gnueabi-
		LD="${LINKER}"
		AR=llvm-ar
		AS=llvm-as
		NM=llvm-nm
		OBJDUMP=llvm-objdump
		STRIP=llvm-strip
		CC=clang
	)
fi

if [ -z "${kver}" ]; then
	echo -e "\e[1;31m[!] Pass kver=<version number> before running script! \e[0m"
	exit 1
else
	export KBUILD_BUILD_VERSION=${kver}
fi
if [ -z "${zipn}" ]; then
	echo -e "\e[1;31m[✗] Pass zipn=<zip name> before running script! \e[0m"
	exit 1
fi
if [ ! -d "anykernel3-dragonheart/" ]; then
	git clone --depth=1 https://github.com/cyberknight777/anykernel3 -b op7 anykernel3-dragonheart
fi

exit_on_signal_SIGINT() {
	echo -e "\n\n\e[1;31m[✗] Received INTR call - Exiting...\e[0m"
	exit 0
}
trap exit_on_signal_SIGINT SIGINT

tg() {
	if [[ "${SILENT}" != "1" ]]; then
		curl -sX POST https://api.telegram.org/bot"${TOKEN}"/sendMessage -d chat_id="${CHATID}" -d parse_mode=Markdown -d disable_web_page_preview=true -d text="$1" &>/dev/null
	fi
}

tgs() {
	MD5=$(md5sum "$1" | cut -d' ' -f1)
	if [[ "${SILENT}" != "1" ]]; then
		curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TOKEN}"/sendDocument \
			-F "chat_id=${CHATID}" \
			-F "parse_mode=Markdown" \
			-F "caption=$2 | *MD5*: \`$MD5\`"
	fi
}

clean() {
	echo -e "\n\e[1;93m[*] Cleaning source and out/ directory! \e[0m" | pv -qL 30
	make clean && make mrproper && rm -rf out
}

mcfg() {
	echo -e "\e[1;93m[*] Making Menuconfig! \e[0m" | pv -qL 30
	make "${MAKE[@]}" $CONFIG | tee log.txt
	make "${MAKE[@]}" menuconfig
	cp -rf "${CURRENTDIR}"/out/.config "${CURRENTDIR}"/arch/arm64/configs/$CONFIG
	echo -e "\n\e[1;32m[✓] Saved Modifications! \e[0m" | pv -qL 30
}
img() {
	tg "
*Build Number*: \`${kver}\`
*Builder*: \`$(whoami)\`
*Device*: \`${DEVICE} [${CODENAME}]\`
*Kernel Version*: \`$(make kernelversion 2>/dev/null)\`
*Date*: \`$(date)\`
*Zip Name*: \`${zipn}\`
*Compiler*: \`${KBUILD_COMPILER_STRING}\`
*Linker*: \`$(${LINKER} -v | head -n1 | sed 's/(compatible with [^)]*)//' |
		head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')\`
*Branch*: \`$(git rev-parse --abbrev-ref HEAD)\`
*Last Commit*: [${COMMIT_HASH}](${REPO_URL}/commit/${COMMIT_HASH})
"

	echo -e "\n\e[1;93m[*] Building Kernel! \e[0m" | pv -qL 30
	BUILD_START=$(date +"%s")
	make "${MAKE[@]}" $CONFIG
	time make -j"$PROCS" "${MAKE[@]}" Image dtbo.img dtb.img | tee log.txt
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	if [ -f "out/arch/arm64/boot/Image" ]; then
		tg "*Kernel Built after $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)*"
		echo -e "\n\e[1;32m[✓] Built Kernel! \e[0m" | pv -qL 30
	else
		tgs "log.txt" "*Build failed*"
		echo -e "\n\e[1;32m[✗] Build Failed! \e[0m"
		exit 1
	fi
}
dtb() {
	echo -e "\n\e[1;32m[*] Building DTBS! \e[0m" | pv -qL 30
	make "${MAKE[@]}" $CONFIG
	time make -j"$PROCS" "${MAKE[@]}" dtbs dtbo.img dtb.img
	echo -e "\n\e[1;32m[✓] Built DTBS! \e[0m" | pv -qL 30
}
mod() {
	tg "*Building Modules!*"
	echo -e "\n\e[1;32m[*] Building Modules! \e[0m" | pv -qL 30
	mkdir -p out/modules
	make "${MAKE[@]}" modules_prepare
	make -j"$PROCS" "${MAKE[@]}" modules INSTALL_MOD_PATH="${CURRENTDIR}"/out/modules
	make "${MAKE[@]}" modules_install INSTALL_MOD_PATH="${CURRENTDIR}"/out/modules
	find out/modules -type f -iname '*.ko' -exec cp {} anykernel3-dragonheart/modules/system/lib/modules/ \;
	echo -e "\n\e[1;32m[✓] Built Modules! \e[0m" | pv -qL 30
}
mkzip() {
	tg "*Building zip!*"
	echo -e "\n\e[1;32m[*] Building zip! \e[0m" | pv -qL 30
	mv out/arch/arm64/boot/dtbo.img anykernel3-dragonheart
	mv out/arch/arm64/boot/dtb.img anykernel3-dragonheart
	mv out/arch/arm64/boot/Image anykernel3-dragonheart
	cd anykernel3-dragonheart || exit 1
	zip -r9 "$zipn".zip ./*
	echo -e "\n\e[1;32m[✓] Built zip! \e[0m" | pv -qL 30
	tgs "${zipn}.zip" "*#${kver} ${KBUILD_COMPILER_STRING}*"
}

helpmenu() {
	echo -e "\e[1m
usage: kver=<version number> zipn=<zip name> ./build.sh <arg>

example: kver=69 zipn=Kernel-Beta ./build.sh mcfg
example: kver=420 zipn=Kernel-Beta ./build.sh mcfg img
example: kver=69420 zipn=Kernel-Beta ./build.sh mcfg img mkzip

	 mcfg Runs make menuconfig
	 img  Builds Kernel
	 dtb  Builds dtb(o).img
	 mod  Builds out-of-tree modules
	 mkzip  Builds anykernel3 zip
\e[0m"
}

if [[ -z $* ]]; then
	helpmenu
	exit 1
fi

for arg in "$@"; do
	case "${arg}" in
	"mcfg")
		mcfg
		;;
	"img")
		img
		;;
	"dtb")
		dtb
		;;
	"mod")
		mod
		;;
	"mkzip")
		mkzip
		;;
	"help")
		helpmenu
		exit 1
		;;
	*)
		helpmenu
		exit 1
		;;
	esac
done
