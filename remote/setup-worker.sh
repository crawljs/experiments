#!/bin/bash
# setup a crawl.js worker
# worker: the vm hosting one crawler

GROUP=$1
BLOCK=$2
CONFIG=$3

HOSTNAME="worker${GROUP}-${BLOCK}"
APT_GET="apt-get -y"
USER="ubuntu"
INSTALL_DIR="/home/$USER/crawl.js"
LOG_DIR="/home/$USER/logs"
SOURCE="https://github.com/cederigo/crawl.js.git"

if [ -z $BLOCK ] || [ -z $GROUP ]; then
  echo "usage: $0 <group> <block>"
  exit 1
fi

echo "about to setup $HOSTNAME"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# open up for update
iptables -F

# system
#$APT_GET update && $APT_GET upgrade
$APT_GET install git
$APT_GET install build-essential

#hostname
echo $HOSTNAME > /etc/hostname

#/etc/hosts
if [ ! -e /etc/hosts.bak ]; then
  cp /etc/hosts /etc/hosts.bak
fi
cp ./setup-worker/hosts /etc/hosts

#autostart worker
cat << EOF > /etc/rc.local
#clean logs
rm -fr $LOG_DIR
su - $USER -c "mkdir $LOG_DIR"

#precautions, block outgoing external traffic
iptables -F
iptables -A OUTPUT -p tcp --dport 80 -d 192.168.98.0/24 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j REJECT --reject-with tcp-reset

#crawl.js group: $GROUP, block: $BLOCK
su - $USER -c "cd $INSTALL_DIR && forever start\
 --minUptime 1000ms\
 --spinSleepTime 1000ms\
 -l $LOG_DIR/forever-$GROUP-$BLOCK.log\
 -e $LOG_DIR/err-$GROUP-$BLOCK.log\
 -o $LOG_DIR/out-$GROUP-$BLOCK.log\
 crawl.js $GROUP $BLOCK"
EOF

chmod +x /etc/rc.local

#node.js (via nvm)
su $USER -c "wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh"
su $USER -c "source ~/.nvm/nvm.sh && nvm install v0.10 && nvm alias default 0.10"

#forever
su - $USER -c "npm install -g forever"

#crawl.js
if [ -e $INSTALL_DIR ]; then
  #update repo
  rm $INSTALL_DIR/config.json #git pull fails otherwise because of local changes
  su $USER -c "cd $INSTALL_DIR && git pull"
else
  su $USER -c "git clone $SOURCE $INSTALL_DIR"
fi

su - $USER -c "cp setup-worker/$CONFIG $INSTALL_DIR/config.json"
su - $USER -c "cd $INSTALL_DIR && npm install"

su - $USER -c "forever stopall"
sleep 3
service rc.local start

echo "# Done. Reboot if needed #"
