#!/usr/bin/env bash
tmpdir="$PWD/.binwalktmp"
bwbin="usr/bin/binwalk"
if [ ! -d "$tmpdir" ]; then
	mkdir -p $tmpdir
else
	echo "$tmpdir already exists"
	unset tmpdir
	read -p "Path to use for temporary files: " tmpdir
fi
cd $tmpdir
curl -sL https://archive.archlinux.org/packages/b/binwalk/binwalk-2.4.2-1-any.pkg.tar.zst | tar --zstd -xf -
mkdir -p $HOME/.local/lib/binwalk-packages/
mkdir -p $HOME/.local/bin 2>/dev/null #ignore any already exists errors
mv usr/lib/python3.12/site-packages/* $HOME/.local/lib/binwalk-packages/
printf '#!/usr/bin/env -S ' > $bwbin
printf "PYTHONPATH=$HOME/.local/lib/binwalk-packages python\n" >> $bwbin
cat <<'EOF' >> $bwbin
import re
import sys
from binwalk.__main__ import main
if __name__ == "__main__":
	sys.argv[0] = re.sub(r"(-script\.pyw|\.exe)?$", "", sys.argv[0])
	sys.exit(main())
EOF
mv $bwbin $HOME/.local/bin/binwalk
cd ..
rm -rf "$tmpdir"
