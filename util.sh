#!/bin/bash

run_oss() { if [ $(which padspp 2>/dev/null) ]; then padsp $@; else $@; fi; }
run_shell() { if [[ $(tty) = "not a tty" ]]; then xterm -e "$@"; else $@; fi; }

get_resolution() { xrandr | grep \* | cut -d' ' -f4; }
set_resolution() { xrandr -s $1; }
