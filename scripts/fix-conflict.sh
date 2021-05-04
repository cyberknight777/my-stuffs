#!/usr/bin/bash

exit_on_signal_SIGINT () {
    echo -e "\n\n\e[1;31m[✗] Received INTR call - Exiting...\e[0m"
    exit 0
}
trap exit_on_signal_SIGINT SIGINT
tag=ba0007851b47
while true
do
echo -ne "\e[96mEnter path to file which needs fixing: \e[0m"
read -r path
sed -i "s/>>>>>>> ${tag} (configs)//g" ${path}
sed -i "s/=======//g" ${path}
sed -i "s/<<<<<<< HEAD//g" ${path}
done
