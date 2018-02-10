#! /bin/sh

set -x
set -e
set -u

url=$1
expectedsha256=$2
out=$3

curl -o $out $url
echo "$expectedsha256 $out" | sha256sum -c -
