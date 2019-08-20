#!/bin/bash -e
cd $(dirname $0)
top=$(pwd)
ddir=dist
export SRC_DIR=$top/src
export INC_DIR=$top/include
export DOCS="$top/README.md $top/LICENSE"
mkdir -p $ddir
tag=$(git describe --always --dirty)
for pack in platform/*/.pack; do
	pdir=$(dirname $pack)
	name=$(basename $pdir)
	echo "Packaging $name ..."
	rm -rf $top/$ddir/$name
	rsync -a $top/$pdir --exclude .pack $top/$ddir/
	cd $top/$ddir/$name
	bash -e $top/$pdir/.pack
	out=$ddir/tinythreads-$name-$tag.tar.gz
	tar czf $top/$out *
	echo " => $out"
done
