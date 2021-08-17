#!/usr/bin/bash
# Author: kNIGHT
# Co-Author: ABHackerOfficial
# thanks to mochi for the original idea

ver8188eus=v5.3.9
ver8812=v5.6.4.2
ver8814=v5.8.5.1

! hash curl 2>/dev/null && echo -e "\033[1;31m Install curl !\033[0m"
! hash jq 2>/dev/null && echo -e "\033[1;31m Install jq !\033[0m"
! hash git 2>/dev/null && echo -e "\033[1;31m Install git !\033[0m"

check1=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8188eus | jq -r .default_branch)
check2=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8812au | jq -r .default_branch)
check3=$(curl -sL https://api.github.com/repos/aircrack-ng/rtl8814au | jq -r .default_branch)

gsa() {
	if [[ ${ver8188eus} == ${check1} ]]; then
		git remote add eus https://github.com/aircrack-ng/rtl8188eus
		git fetch eus $ver8188eus
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8188eus -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8188eus from https://github.com/aircrack-ng/rtl8188eus" -m "This is an auto generated commit."
	else
		ver8188eus=$check1
		git remote add eus https://github.com/aircrack-ng/rtl8188eus
		git fetch eus $ver8188eus
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8188eus -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8188eus from https://github.com/aircrack-ng/rtl8188eus" -m "This is an auto generated commit."
	fi
	if [[ ${ver8812} == ${check2} ]]; then
		git remote add 12 https://github.com/aircrack-ng/rtl8812au
		git fetch 12 $ver8812
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8812au -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8812au from https://github.com/aircrack-ng/rtl8812au" -m "This is an auto generated commit."
	else
		ver8812=$check2
		git remote add 12 https://github.com/aircrack-ng/rtl8812au
		git fetch 12 $ver8812
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8812au -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8812au from https://github.com/aircrack-ng/rtl8812au" -m "This is an auto generated commit."
	fi
	if [[ ${ver8814} == ${check3} ]]; then
		git remote add 14 https://github.com/aircrack-ng/rtl8814au
		git fetch 14 $ver8814
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8814au -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8814au from https://github.com/aircrack-ng/rtl8814au" -m "This is an auto generated commit."
	else
		ver8814=$check3
		git remote add 14 https://github.com/aircrack-ng/rtl8814au
		git fetch 14 $ver8814
		git merge -S -s ours --no-commit --allow-unrelated-histories --squash FETCH_HEAD
		git read-tree --prefix=drivers/staging/rtl8814au -u FETCH_HEAD
		git commit -S -s -m "Imported rtl8814au from https://github.com/aircrack-ng/rtl8814au" -m "This is an auto generated commit."
	fi
}
gsp() {
	if [[ ${ver8188eus} == ${check1} ]]; then
		:
	else
		ver8188eus=$check1
		git fetch eus $ver8188eus
		git merge -X subtree=drivers/staging/rtl8188eus --squash FETCH_HEAD
		git commit -S -s -m "Updated rtl8188eus drivers to $ver8188eus" -m "This is an auto generated commit."
	fi
	if [[ ${ver8812} == ${check2} ]]; then
		:
	else
		ver8812=$check2
		git fetch 12 $ver8812
		git merge -X subtree=drivers/staging/rtl8812au --squash FETCH_HEAD
		git commit -S -s -m "Updated rtl8812au drivers to $ver8812" -m "This is an auto generated commit."
	fi
	if [[ ${ver8814} == ${check3} ]]; then
		:
	else
		ver8814=$check3
		git fetch 14 $ver8814
		git merge -X subtree=drivers/staging/rtl8814au --squash FETCH_HEAD
		git commit -S -s -m "Updated rtl8814au drivers to $ver8814" -m "This is an auto generated commit."
	fi
}
if [[ $1 != "" && $1 == "add" ]]; then
	gsa
elif [[ $1 != "" && $1 == "pull" ]]; then
	gsp
elif [[ $1 == "" ]]; then
	echo -e "\033[1m
usage: ./drivers.sh [arg]

example: ./drivers.sh add
example: ./drivers.sh pull

     add   Newly add drivers
     pull  Update added drivers
\033[1m"
	exit 1
fi
