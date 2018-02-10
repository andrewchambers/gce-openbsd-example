#! /bin/sh

set -x
set -e
set -u

iso=$1
autoinstall=$2
output=$3

qemu-img create -f qcow2 $output 10G

tmp=`mktemp -d`

cleanup() {
	rm -rf $tmp
}

trap cleanup EXIT INT

cp $iso $tmp/install.iso
cp $autoinstall $tmp/autoinstall.conf
echo 'set tty com0' > $tmp/boot.conf

growisofs -M "$tmp/install.iso" -l -R -graft-points \
  /autoinstall.conf="$tmp/autoinstall.conf" \
  /etc/boot.conf="$tmp/boot.conf"

expect <<EOF
set timeout 600

spawn qemu-system-x86_64 -nographic \
  -drive if=virtio,file=$output,format=qcow2 -cdrom "$tmp/install.iso" \
  -net nic,model=virtio -net user -boot once=d -smp 2 -m 2048

expect timeout { exit 1 } "\(I\)nstall, \(U\)pgrade, \(A\)utoinstall or \(S\)hell\?"
send "S\n"

expect timeout { exit 1 } "# "
send "mount /dev/cd0c /mnt\n"
send "cp /mnt/autoinstall.conf /\n"
send "umount /mnt\n"
send "install -af /autoinstall.conf\n"
expect timeout { exit 1 } "CONGRATULATIONS"
expect timeout { exit 1 } "# "
send "halt -p\n"
expect timeout { exit 1 } "The operating system has halted"
EOF
echo ""