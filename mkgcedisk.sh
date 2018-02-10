#! /bin/sh

set -x
set -e
set -u

input=$1
output=$2


tmp=`mktemp -d`

cleanup() {
	rm -rf $tmp
}

trap cleanup EXIT INT

qemu-img convert $input $tmp/disk.raw
(cd $tmp && tar -Szc disk.raw) > $output