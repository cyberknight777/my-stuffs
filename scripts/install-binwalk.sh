#!/usr/bin/env bash

mkdir tmp
cd tmp
curl -sL https://archive.archlinux.org/packages/b/binwalk/binwalk-2.4.2-1-any.pkg.tar.zst | tar --zstd -xvf -
mkdir -p $HOME/.local/lib/binwalk-packages/
mkdir -p $HOME/.local/bin
mv usr/lib/python3.12/site-packages/* $HOME/.local/lib/binwalk-packages/
sed -i '1s|^#!/usr/bin/python$|#!/usr/bin/env -S PYTHONPATH=/home/cyberknight/.local/lib/binwalk-packages python|' usr/bin/binwalk
mv usr/bin/binwalk $HOME/.local/bin/binwalk
cd ..
rm -rf tmp
