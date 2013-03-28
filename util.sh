#!/bin/bash

get_resolution() { xrandr | grep \* | cut -d' ' -f4; }
set_resolution() { xrandr -s $1; }

run_oss() { if [ $(which padspp 2>/dev/null) ]; then padsp $@; else $@; fi; }
run_shell() { if [[ $(tty) = "not a tty" ]]; then xterm -e "$@"; else $@; fi; }
run_keepResolution() {
	resolution=$(get_resolution)
	trap atexit set_resolution "$resolution"
	$@
	set_resolution "$resolution"
}
