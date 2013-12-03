#!/bin/bash

XSLT=`dirname $0`/langlinks.xsl
INPUT=$1
OUTPUT=$INPUT

if [ -z $INPUT ]; then
  echo "usage: $0 <wiki-page>"
  exit 1
fi

xsltproc --novalid --html -o $OUTPUT $XSLT $INPUT 2>/dev/null &
