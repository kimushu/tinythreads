#!/bin/bash -e
cd $(dirname $0)
top=$(pwd)
ddir=dist
export SRC_DIR=$top/src
export INC_DIR=$top/include
export DOCS="$top/README.md $top/LICENSE"
mkdir -p $ddir
tag=$(git describe --always --tags --dirty)
for pack in platform/*/.pack; do
	pdir=$(dirname $pack)
	name=$(basename $pdir)
	echo "Packaging $name ..."
	export DEST_DIR=$top/$ddir/$name
	rm -rf $DEST_DIR
	mkdir $DEST_DIR
	cd $top/$pdir
	bash -e .pack
	cd $DEST_DIR
	out=$ddir/tinythreads-$name-$tag.tar.gz
	tar czf $top/$out --group=0 --owner=0 *
	echo " => $out"
	out=$ddir/tinythreads-$name-$tag.zip
	zip -rq $top/$out *
	echo " => $out"
done
