#!/usr/bin/bash

# Select arch
export EMAIL=
export ARCH=arm64
export SUBARCH=arm64
export CONFIG=codename_defconfig
export CURRENTDIR=$(pwd)
export CLANG_TRIPLE=aarch64-linux-gnu

# Use GCC toolchains from this dir
export CROSS_COMPILE=$CURRENTDIR/compiler/toolchains/gcc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$CURRENTDIR/compiler/toolchains/gcc/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export CLANG_TOOLCHAIN=$CURRENTDIR/compiler/toolchains/clang-pwn/bin/clang-10

echo $CROSS_COMPILE
echo $CROSS_COMPILE_ARM32
echo $CLANG_TOOLCHAIN

# Compile kernel itself
echo "#"
echo "# [1/2]: Set defconfig for compiler to follow and compile it afterwards"
echo "#"

START=$(date +"%s")

make O=../compiled_code_codename CC=clang $CONFIG
make O=../compiled_code_codename CC=clang

# Build anykernel3.zip
echo "#"
echo "# [2/2]: Making Anykernel3.zip"
echo "#"

bash ak3.sh

END=$(date +"%s")
BUILD=$((END - START))

echo -e "\033[1;96mBuild took : $((BUILD / 60)) minute(s) and $((BUILD % 60)) second(s)"
exit 0
# Compile modules + Header
#echo "#"
#echo "# [2/3]: Compile set of modules to ../compiled_modules"
#echo "#"

#make O=../compiled_code_codename CC=clang modules_prepare;

#make O=../compiled_code_codename CC=clang modules_install INSTALL_MOD_PATH=../compiled_modules_codename;

#make O=../compiled_code_codename CC=clang modules INSTALL_MOD_PATH=../compiled_modules_codename
