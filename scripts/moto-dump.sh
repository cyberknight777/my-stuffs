#!/usr/bin/env bash

wdir=$(pwd)
prefix="cancunf"
last=$(printf '%s\n' ${prefix}[0-9]* 2>/dev/null |
	sed -n "s/^${prefix}\([0-9]\+\)$/\1/p" |
	sort -n |
	tail -1)
name="${prefix}$((${last:-0} + 1))"

abort() {
	echo -e "\n\e[1;31m[✗] ${1}\e[0m"
	exit 1
}

mkdir -p "${wdir}/${name}" || abort "Failed to create ${wdir}/${name}!"
unzip "${1}" -d "${wdir}/${name}" || abort "Failed to unzip ${1} to ${wdir}/${name}!"

cd "${wdir}/${name}" || abort "Failed to change directory to ${wdir}/${name}!"

mapfile -t superchunks < <(find . -name 'super.img_sparsechunk.*' | sort -V)

[ "${#superchunks[@]}" -gt 0 ] || abort "No superchunks detected!"

simg2img "${superchunks[@]}" super.img || abort "Failed to convert sparse images to super image!"

rm "${superchunks[@]}" || abort "Failed to remove sparse images!"

lpunpack super.img || abort "Failed to extract partition images from super!"

for part in system system_ext vendor vendor_dlkm product; do
	rm -f "${part}_b.img"
	mv "${part}_a.img" "${part}.img" || abort "Failed to rename ${part}_a.img!"
done
