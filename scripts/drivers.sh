#!/usr/bin/bash
# Author: kNIGHT
# Co-Author: ABHackerOfficial

ver8188eus=v5.3.9
ver8812=v5.6.4.2
ver8814=v5.8.5.1
check1=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8188eus | jq .default_branch | sed -e "s/\"//g")
check2=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8812au | jq .default_branch | sed -e "s/\"//g")
check3=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8814au | jq .default_branch | sed -e "s/\"//g")
gsa() {
    if [[ ${ver8188eus} == ${check1} ]];then
       :
    else
	ver8188eus=$check1
    fi
    if [[ ${ver8812} == ${check2} ]];then
	:
    else
	ver8812=$check2
    fi
    if [[ ${ver8814} == ${check3} ]];then
	:
    else
	ver8814=$check3
    fi
    git subtree add --prefix=drivers/staging/rtl8188eus https://github.com/aircrack-ng/rtl8188eus $ver8188eus
    git subtree add --prefix=drivers/staging/rtl8812au  https://github.com/aircrack-ng/rtl8812au $ver8812
    git subtree add --prefix=drivers/staging/rtl8814au  https://github.com/aircrack-ng/rtl8814au $ver8814 
}
gsp() {
    if [[ ${ver8188eus} == ${check1} ]];then
	:
    else
	ver8188eus=$check1
    fi
    if [[ ${ver8812} == ${check2} ]];then
	:
    else
	ver8812=$check2
    fi
    if [[ ${ver8814} == ${check3} ]];then
	:
    else
	ver8814=$check3
    fi
    git subtree pull --prefix=drivers/staging/rtl8188eus https://github.com/aircrack-ng/rtl8188eus $ver8188eus
    git subtree pull --prefix=drivers/staging/rtl8812au  https://github.com/aircrack-ng/rtl8812au $ver8812
    git subtree pull --prefix=drivers/staging/rtl8814au  https://github.com/aircrack-ng/rtl8814au $ver8814 
}
if [[ $1 != "" && $1 == "add" ]]; then
    gsa
elif [[ $1 != "" && $1 == "pull" ]]; then
    gsp
fi
