#!/bin/bash
#Kali NetHunter Kernel Config Checker
#from config.gz(result may not reliable) or from kernel defconfig

#Heavily Based On: https://github.com/moby/moby/blob/master/contrib/check-config.sh

set -e

CONFIG=$1
KVERSION='$(uname -r)'

if [ "$CONFIG" == "/proc/config.gz" ];then
zgrep(){
     zcat "$2" | grep "$1"
}

gioGrep() { 
 zcat /proc/config.gz 2>/dev/null | grep -q "$1" | cut -d'=' -f2
 }

gioGrepSama() { 
 zcat /proc/config.gz 2>/dev/null | grep "$1" | cut -d'=' -f2
 }

else 
zgrep(){
     cat "$2" | grep "$1"
}

gioGrep() {
cat "$CONFIG" 2>/dev/null | grep -q "$1" | cut -d'=' -f2
}
gioGrepSama() { 
 cat "$CONFIG" 2>/dev/null | grep "$1" | cut -d'=' -f2
 }

fi

as_builtin(){
  zgrep "CONFIG_$1=y" "$CONFIG" > /dev/null
}

as_modules(){
  zgrep "CONFIG_$1=m" "$CONFIG" > /dev/null
}

disabled_as_builtin(){
  zgrep "#CONFIG_$1=y" "$CONFIG" > /dev/null
}

disabled_as_modules(){
  zgrep "#CONFIG_$1=m" "$CONFIG" > /dev/null
}

exists(){
  zgrep "$1=y" "$CONFIG" > /dev/null
}

disabled(){
   zgrep "CONFIG_$1=n" "$CONFIG" > /dev/null
}

bold_text(){
    text="$1"
    shift
    echo -en '\033['"1"'m'
    echo -n "$text"
    echo -en '\033['""'m'
    echo
}

wrap_color(){
   text="$1"
   color="$2"
   shift
   echo -en '\033['"$color"'m'
   echo -n "$text"
   echo -en '\033['""'m'
   echo
}

wrap_good() {
	echo "$(wrap_color "$1" "37"): $(wrap_color "$2" "92")"
}

wrap_bad() {
	echo "$(bold_text "$1"): $(wrap_color "$2" "31")"
}

check_flag() {
	if disabled_as_builtin "$1"; then
		wrap_bad "CONFIG_$1" 'disabled[with #]'
	elif disabled_as_modules "$1"; then
		wrap_bad "CONFIG_$1" 'disabled[with #]'
	elif as_builtin "$1"; then
		wrap_good "CONFIG_$1" 'enabled'
	elif as_modules "$1"; then
		wrap_good "CONFIG_$1" 'enabled'
 elif exists "$1"; then
		wrap_good "$1" 'enabled'
    else
		wrap_bad "CONFIG_$1" 'missing'
	EXITCODE=1
	fi
}

check_flags() {
	for flag in "$@"; do
		echo -n "- "
		check_flag "$flag"
	done
}

check_host(){
   host=$(gioGrepSama "CONFIG_DEFAULT_HOSTNAME=")
   if [ "$host" == '"(kali)"' ];then
   wrap_good "- CONFIG_DEFAULT_HOSTNAME" '(kali)'
   elif [  "$host" == 'kali' ];then
   wrap_good "- CONFIG_DEFAULT_HOSTNAME" 'kali'
  else
  wrap_bad "- CONFIG_DEFAULT_HOSTNAME" "missing $(echo -ne '\033['"93"'m'
   echo -ne "(not set as kali)"
   echo -en '\033['""'m')"
  fi
}

echo -ne '\033['"1"'m'
echo "NETHUNTER KERNEL CONFIG CHECKER:"
echo -en '\033['""'m'
wrap_color "READING CONFIG FROM: $(echo -ne '\033['"1"'m'
echo -ne '\033['"36"'m'
echo -ne "$CONFIG" | tr '[:lower:]' '[:upper:]'
echo -en '\033['""'m')" 37

if [ "$CONFIG" == "/proc/config.gz" ]; then
echo -ne '\033['"1"'m'
echo -ne '\033['"31"'m'"WARNING!!"'\033[0m'
echo -ne ":$(echo -ne '\033['"1"'m'
echo -ne '\033['"36"'m'
echo -ne "$CONFIG" | tr '[:lower:]' '[:upper:]'
echo -en '\033['""'m') MAY NOT GIVE PROPER CONFIG RESULT"
echo -en '\033['""'m'
fi

echo

echo $(wrap_color "GENERAL:" "36")
check_host
check_flags SYSVIPC
echo
echo $(wrap_color "MODULE CONFIGURATION:" "36")
check_flags MODULES MODULE_UNLOAD MODULE_FORCE_UNLOAD MODVERSIONS
echo

echo $(wrap_color "KERNEL IMAGE:" "36")
check_flags BUILD_ARM64_APPENDED_DTB_IMAGE IMG_GZ_DTB 
echo

echo $(wrap_color "BLUETOOTH:" "36")
check_flags BT BT_RFCOMM BT_RFCOMM_TTY BT_HCIBTUSB BT_HCIBTUSB_BCM BT_HCIBTUSB_RTL BT_HCIUART BT_HCIBCM203X BT_HCIBPA10X BT_HCIBFUSB
echo

echo $(wrap_color "MAC80211:" "36")
check_flags CFG80211_WEXT MAC80211 MAC80211_MESH
echo

echo $(wrap_color "ETHERNET:" "36")
check_flags USB_RTL8150 USB_RTL8152
echo


echo $(wrap_color "SDR:" "36")
check_flags MEDIA_DIGITAL_TV_SUPPORT MEDIA_SDR_SUPPORT USB_AIRSPY USB_HACKRF USB_MSI2500 

MSA=$(gioGrep "CONFIG_MEDIA_SUBDRV_AUTOSELECT=")

if [ "$MSA" == 'y' ];then
   wrap_bad "- CONFIG_MEDIA_SUBDRV_AUTOSELECT" "enabled $(echo -ne '\033['"93"'m'
   echo -ne "(Disable Wen!!)"
   echo -en '\033['""'m')"
  else
  wrap_bad "- CONFIG_MEDIA_SUBDRV_AUTOSELECT" "missing $(echo -ne '\033['"32"'m'
   echo -ne "(Good Sign!!)"
   echo -en '\033['""'m')"
  fi
check_flags DVB_RTL2830 DVB_RTL2832 DVB_RTL2832_SDR DVB_SI2168 DVB_ZD1301_DEMOD
echo

echo $(wrap_color "USB MODEM:" "36")
check_flags USB_ACM
echo

echo $(wrap_color "USB GADGET SUPPORT:" "36")
check_flags HID HID_GENERIC HIDRAW USB_CONFIGFS_SERIAL USB_CONFIGFS_ACM USB_CONFIGFS_OBEX USB_CONFIGFS_NCM USB_CONFIGFS_ECM USB_CONFIGFS_ECM_SUBSET USB_CONFIGFS_RNDIS USB_CONFIGFS_MASS_STORAGE
echo

echo $(wrap_color "WIRELESS LAN:" "36")
echo "# $(wrap_color 'ATHEROS DRIVERS:' 93):"
check_flags WLAN_VENDOR_ATH ATH9K_HTC CARL9170 ATH6KL ATH6KL_USB
echo "# $(wrap_color 'MEDIATEK DRIVERS:' 93):"
check_flags WLAN_VENDOR_MEDIATEK MT7601U
echo "# $(wrap_color 'RALINK DRIVERS:' 93):"
check_flags WLAN_VENDOR_RALINK RT2X00 RT2500USB RT73USB RT2800USB RT2800USB_RT33XX RT2800USB_RT35XX RT2800USB_RT3573 RT2800USB_RT53XX RT2800USB_UNKNOWN 
echo "# $(wrap_color 'REALTEK DRIVERS:' 93):"
check_flags WLAN_VENDOR_REALTEK RTL8187 RTL_CARDS RTL8192CU RTL8XXXU_UNTESTED
echo "# $(wrap_color 'ZYDAS DRIVERS:' 93):"
check_flags WLAN_VENDOR_ZYDAS USB_ZD1201 ZD1211RW USB_NET_RNDIS_WLAN
echo
