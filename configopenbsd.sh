#! /bin/sh

set -x
set -e
set -u

baseimage=$1
setup=$2
output=$3

qemu-img create -f qcow2 -o backing_file=$baseimage $output

timeout 10m qemu-system-x86_64 -nographic \
  -drive if=virtio,file=$output,format=qcow2 \
  -net nic,model=virtio -net user -boot once=d -smp 1 -m 2048 -redir tcp:2222::22 &


scpargs="-o NoHostAuthenticationForLocalhost=yes -i id_rsa_insecure -P 2222"
sshargs="-o NoHostAuthenticationForLocalhost=yes -i id_rsa_insecure -p 2222"

while ! ssh $sshargs root@127.0.0.1 true
do
	echo "waiting for ssh..."
    sleep 5
done

# Give openbsd some time to finish booting...
sleep 10

scp $scpargs $setup root@127.0.0.1:/tmp/setup.sh
scp $scpargs ./cleanup.sh root@127.0.0.1:/tmp/cleanup.sh
ssh $sshargs root@127.0.0.1 sh /tmp/setup.sh
ssh $sshargs root@127.0.0.1 sh /tmp/cleanup.sh

wait