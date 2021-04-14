#!/sbin/sh
# Install Kali chroot

tmp=$(readlink -f "$0")
tmp=${tmp%/*/*}
. "$tmp/env.sh"

ZIPFILE=$1

console=$(cat /tmp/console)
[ "$console" ] || console=/proc/$$/fd/1

print() {
	echo "ui_print - $1" > $console
	echo
}


get_bb() {
    cd $tmp/tools
    BB_latest=`(ls -v busybox_nh-* 2>/dev/null || ls busybox_nh-*) | tail -n 1`
    BB=$tmp/tools/$BB_latest #Use NetHunter Busybox from tools
    chmod 755 $BB #make busybox executable
    echo $BB
    cd - >/dev/null
}

BB=$(get_bb)


NHSYS=/data/local/nhsystem
#ref:https://developer.android.com/ndk/guides/abis and wikipedia
arch="$(getprop ro.product.cpu.abi)"
case $arch in
     armeabi-v7a|armv7*) nh_arch="armhf" ;;
     arm64-v8a|arm64*|armv8l) nh_arch="arm64" ;;
     x86|x86_32) nh_arch="i386" ;; 
     x86_64) nh_arch="amd64" ;;
     *) return 1 ;;
esac

verify_fs() {
	# valid architecture?
	case $FS_ARCH in
		armhf|arm64|i386|amd64) ;;
		*) return 1 ;;
	esac
	# valid build size?
	case $FS_SIZE in
		full|minimal) ;;
		*) return 1 ;;
	esac
	return 0
}

# do_install [optional zip containing kalifs]
do_install() {
	print "Found Kali chroot to be installed: $KALIFS"

	mkdir -p "$NHSYS"

	# HACK 1/2: Rename to kali-(arm64,armhf,amd64,i386) as NetHunter App supports searching these directory after first boot
	CHROOT="$NHSYS/kali-$nh_arch" # Legacy rootfs directory prior to 2020.1
	ROOTFS="$NHSYS/kalifs"  # New symlink allowing to swap chroots via nethunter app on the fly
	PRECHROOT=`find $NHSYS -type d -iname kali-* | head -n 1`  #Generic previous chroot location
    
	# Remove previous chroot
	[ -d "$PRECHROOT" ] && {
		print "Previous Chroot Detected!"
		print "Removing previous chroot..."
		rm -rf "$PRECHROOT"
		rm -f "$ROOTFS"
	}

	# Extract new chroot
	print "Extracting Kali rootfs, this may take up to 25 minutes..."
	if [ "$1" ]; then
		unzip -p "$1" "$KALIFS" | $BB tar -xJf - -C "$NHSYS" --exclude "kali-$FS_ARCH/dev"
	else
		$BB tar -xJf "$KALIFS" -C "$NHSYS" --exclude "kali-$FS_ARCH/dev"
	fi

	[ $? = 0 ] || {
		print "Error: Kali $FS_ARCH $FS_SIZE chroot failed to install!"
		print "Maybe you ran out of space on your data partition?"
		exit 1
	}

	# HACK 2/2: Rename to kali-(arm64,armhf,amd64,i386) based on env.sh for legacy reasons and create a link to be used by apps effective 2020.1
	mv "$NHSYS/kali-$FS_ARCH" "$CHROOT"
        ln -sf "$CHROOT" "$ROOTFS"

	mkdir -m 0755 "$CHROOT/dev"
	print "Kali $FS_ARCH $FS_SIZE chroot installed successfully!"

	# We should remove the rootfs archive to free up device memory or storage space (if not zip install)
	[ "$1" ] || rm -f "$KALIFS"

	exit 0
}

#check free space in /data before chroot installation
check_space() {
   #Determine Free space before installing the chroot & abort if fdata is less then 8000 mb
    fdata=$($BB df -m /data | tail -n 1 | tr -s ' ' | cut -d' ' -f4)
    if [ -z $fdata ]; then
	print "Warning: Could not get free space status on /data, continuing anyway!"
	
    else
    
    [ ! "$fdata" -gt "8000" ] && {
    print "Warning: You don't have enough space in your DATA partition for chroot installation."
    print "Aborting chroot installation..."
    exit 1
    }
    fi
}

# Check zip for kalifs-* first
[ -f "$ZIPFILE" ] && {
	KALIFS=$(unzip -lqq "$ZIPFILE" | awk '$4 ~ /^kalifs-/ { print $4; exit }')
	# Check other locations if zip didn't contain a kalifs-*
	[ "$KALIFS" ] || return

	FS_ARCH=$(echo "$KALIFS" | awk -F[-.] '{print $2}')
	FS_SIZE=$(echo "$KALIFS" | awk -F[-.] '{print $3}')
	check_space && verify_fs && do_install "$ZIPFILE"
}

# Check these locations in priority order
for fsdir in "$tmp" "/data/local" "/sdcard" "/external_sd"; do

	# Check location for kalifs-[arch]-[size].tar.xz name format
	for KALIFS in "$fsdir"/kalifs-*-*.tar.xz; do
		[ -s "$KALIFS" ] || continue
		FS_ARCH=$(basename "$KALIFS" | awk -F[-.] '{print $2}')
		FS_SIZE=$(basename "$KALIFS" | awk -F[-.] '{print $3}')
		check_space && verify_fs && do_install
	done

	# Check location for kalifs-[size].tar.xz name format
	for KALIFS in "$fsdir"/kalifs-*.tar.xz; do
		[ -f "$KALIFS" ] || continue
		FS_ARCH=armhf
		FS_SIZE=$(basename "$KALIFS" | awk -F[-.] '{print $2}')
		check_space && verify_fs && do_install
	done

done

print "No Kali rootfs archive found. Skipping..."
exit 0
