#! /bin/sh

set -x
set -e
set -u

echo "https://ftp.openbsd.org/pub/OpenBSD" > /etc/installurl
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/pool.ntp.org/metadata.google.internal/g' /etc/ntpd.conf

# needed to download metadata in firsttime.sh
pkg_add curl

# The following packages are purely a performance optimisation.
# If these lines are commented out, the system should still work, if they don't, its a bug.
pkg_add python%2.7
pkg_add postgresql-client
pkg_add haproxy

cat <<EOF > /etc/rc.firsttime
echo "setting hostname..."
/usr/local/bin/curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/hostname -o /etc/myname
echo "" >> /etc/myname
hostname -s `cat /etc/myname`

echo "getting authorized_keys..."
/usr/local/bin/curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/authorized-keys -o /root/.ssh/authorized_keys

echo "running syspatch..."
syspatch

echo "enabling sshd..."
rcctl enable sshd
rcctl start sshd
EOF

# Disable ssh so that provision scripts will only successfully connect
# after rc.firsttime reenables it.
rcctl disable sshd
