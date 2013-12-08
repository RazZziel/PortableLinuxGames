#!/bin/sh
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

die() { echo $@; exit 1; }
trimp() { sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'; }
trim() { echo $@ | trimp; }

desktopFile_getParameter() { file=$1; parameter=$2; grep "^${parameter}=" "$file" | cut -d= -f2- | cut -d\" -f2 | trimp; }
desktopFile_setParameter() { file=$1; parameter=$2; value=$3; sed -i -e "s|${parameter}=.*|${parameter}=$value|" "$file"; }

xml_extract_node() {
        local node="$1"
        local file="$2"
        grep -Pzo "(?s)<$node.*?>.*?</$node>" "$file"
}
xml_extract_property() {
        local property="$1"
        local line="$2"
        echo "$line" | egrep -o "$property=\"[^\"]*\"" | cut -d\" -f2
}

