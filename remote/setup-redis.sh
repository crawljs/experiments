#!/bin/bash

HOSTNAME="redis1"
APT_GET="apt-get -y"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

$APT_GET install python-software-properties
apt-add-repository -y ppa:chris-lea/redis-server

$APT_GET update && $APT_GET upgrade

$APT_GET install redis-server

cp ./setup-redis/redis.conf /etc/redis/redis.conf

#hostname
echo $HOSTNAME > /etc/hostname

cat << EOF > /etc/rc.local
#see https://groups.google.com/forum/#!topic/redis-db/3Eh2hhsXQ1g
echo 1 > /proc/sys/vm/overcommit_memory
exit 0
EOF

/etc/init.d/rc.local start

echo "# Done. Reboot if needed #"
