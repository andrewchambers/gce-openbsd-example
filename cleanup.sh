#! /bin/sh

set -x
set -e
set -u

rcctl stop sshd
rm /root/.ssh/authorized_keys
rm /etc/ssh/ssh_host_*
nohup sh -c "sleep 2 && halt -p" &
