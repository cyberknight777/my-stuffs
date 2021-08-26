#!/usr/bin/bash

echo -ne "\033[1;36mEnter version of emacs you would like to install \033[0m"
read -r version

[ -z $version ] && version=27.2

mkdir -p emacs-build
cd emacs-build

lonk=https://ftp.gnu.org/gnu/emacs/emacs-$version.tar.gz

wget $lonk
tar -xvf emacs-$version.tar.gz

cd emacs-$version
ac_cv_lib_gif_EGifPutExtensionLast=yes ./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib --localstatedir=/var --with-x-toolkit=gtk3 --with-xft --with-wide-int --with-modules --with-xwidgets

make -j$(nproc --all)

pkexec make install PREFIX=/usr/bin

echo -e "\033[1memacs-$version installed successfully!! \033[0m"
