#!/bin/bash

#a wiki language, pick any from http://dumps.wikimedia.org/other/static_html_dumps/current
# examples
# lang	size-compressed	size	#articles 
# bs	52M		1.1G	57151
# af	30M		582M	35308
# bn	34M		1.2G	74931
WIKI_LANG=$1

WWW_ROOT="/var/www"
SERVER_NAME="$WIKI_LANG.wikipedia.org"
WIKI_DUMP="http://dumps.wikimedia.org/other/static_html_dumps/current/$WIKI_LANG/wikipedia-$WIKI_LANG-html.tar.7z"
APT_GET="apt-get -y"
WGET="wget -nc"

if [ -z $WIKI_LANG ]; then
  echo "usage: $0 <wiki-lang>"
  echo "wiki-lang: pick any from http://dumps.wikimedia.org/other/static_html_dumps/current"
  exit 1
fi

echo "about to setup $SERVER_NAME"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#hostname
echo "wiki-$WIKI_LANG" > /etc/hostname

$APT_GET update

#www root
if [ ! -d $WWW_ROOT ]; then
  mkdir -p $WWW_ROOT
  #tmpfs
  umount $WWW_ROOT
  mount -t tmpfs -o size=1500m tmpfs $WWW_ROOT
fi

#get & extract wikidump
if [ ! -d $WWW_ROOT/$WIKI_LANG ]; then
  if [ -e wiki-$WIKI_LANG.tgz ]; then
    #much faster
    tar -C $WWW_ROOT -xf wiki-$WIKI_LANG.tgz
  else
    $APT_GET install p7zip-full xsltproc
    
    $WGET $WIKI_DUMP
    7z -so e wikipedia-$WIKI_LANG-html.tar.7z | tar -C $WWW_ROOT -x

    #remove links of languages we dont want + rewrite language links to point to individual servers
    #This may take a while
    find $WWW_ROOT/$WIKI_LANG -name *.html -exec ./setup-wiki/langlinks.sh {} \;
  fi
fi

#nginx
$APT_GET install nginx

cat << EOF > /etc/nginx/sites-available/wiki
server {
	
	root $WWW_ROOT/$WIKI_LANG;
	index index.html index.htm;
	server_name $SERVER_NAME;

}
EOF

rm /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/wiki /etc/nginx/sites-enabled/

/etc/init.d/nginx restart

echo "# Done. Reboot if needed #"
