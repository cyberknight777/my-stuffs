#!/usr/bin/bash

# Select arch
export ARCH=arm64
export SUBARCH=arm64
export CONFIG=codename_defconfig
export CURRENTDIR=$(pwd)

# Use GCC toolchains from this dir
export CROSS_COMPILE=$CURRENTDIR/compiler/toolchains/gcc/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$CURRENTDIR/compiler/toolchains/gcc/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export CLANG_TOOLCHAIN=$CURRENTDIR/compiler/toolchains/clang-pwn/bin/clang-10

echo "#"
echo "# [1/1]: Menuconfig"
echo "#"

make O=../compiled_code_codename $CONFIG
make O=../compiled_code_codename menuconfig
cp -rf ../compiled_code_codename/.config arch/arm64/configs/$CONFIG
