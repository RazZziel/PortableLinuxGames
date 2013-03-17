#!/bin/bash

run_oss() { [ $(which padspp 2>/dev/null) ] && padsp $@ || $@; }

get_resolution() { xrandr | grep \* | cut -d' ' -f4; }
set_resolution() { xrandr -s $1; }
