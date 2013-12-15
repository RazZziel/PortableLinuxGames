#!/bin/sh
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

GOOD=$'\e[32;01m'
WARN=$'\e[33;01m'
BAD=$'\e[31;01m'
NORMAL=$'\e[0m'
HILITE=$'\e[36;01m'
BRACKET=$'\e[34;01m'

# http://stackoverflow.com/questions/6841143/how-to-set-font-color-for-stdout-and-stderr
color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1

die() { echo -e ${BAD}$@${NORMAL}; exit 1; }
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

