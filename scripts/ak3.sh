#!/usr/bin/env bash
# Author: kNIGHT
# AnyKernel3.zip Maker For Device

echo -ne "\e[1m\e[96mAre You Running This In The Kernel Source Directory?(Y/N):  \e[0m"
read opt
case $opt in
    y | Y)
	read -p $'\n\e[36;1mWhat name do you wish to give to kernel?: \e[0m' name
	cp ../compiled_code/arch/arm64/boot/Image.gz ~/anykernel3
	cd ~/anykernel3
	zip -r9 ${name}.zip *
	echo -e "\e[32;1mYour ${name}.zip Can Be Found At: ~/anykernel3/${name}.zip \033[0m"
	;;
    n | N)
	echo -e "\e[31mMove To Kernel Source Directory And Run This Again! \e[0m"
	exit 0
	;;
esac
