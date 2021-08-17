#!/usr/bin/bash
# Author: Knight

which wget &>/dev/null || echo -e "\033[1;31mInstall wget!\033[0m"

if [ -z $1 ]; then
	echo -e "\033[1;31mExecute script with path to kernel tree as argument!\033[0m"
	exit 1
else
	if ! cd $1 &>/dev/null; then
		echo -e "\033[1;31mdirectory $1 not found!\033[0m"
		exit 1
	else
		cd $1
		mkdir docker
		cd docker
		wget https://raw.githubusercontent.com/Neternels/android_kernel_oneplus_sm8150/master/docker/Kconfig
		cd ..
		echo '
source "docker/Kconfig" ' >>arch/arm64/Kconfig
		cd ..
		wget https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh
		chmod 777 check-config.sh
		echo -e "\033[1;36m Run make menuconfig and enable all options in Utilities \033[0m"
		echoe -e "\033[1;36m Once that is done, run ./check-config.sh <pathtodefconfig> to see options which are not enabled yet to enable them as they are important for network in docker's containers \033[0m"
		exit 0
	fi
fi
