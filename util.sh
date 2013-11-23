#!/bin/sh
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

die() { echo $@; exit 1; }
trimp() { sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g'; }
trim() { echo $@ | trimp; }

desktopFile_getParameter() { file=$1; parameter=$2; grep "${parameter}=" "$file" | cut -d= -f2- | cut -d\" -f2 | trimp; }
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

get_resolution() { xrandr | grep \* | cut -d' ' -f4; }
set_resolution() { xrandr -s $1; }

run_withLocalLibs() { LD_LIBRARY_PATH="$APPDIR/usr/lib/:$LD_LIBRARY_PATH" exec "$@"; }
run_shell() { if [[ $(tty) = "not a tty" ]]; then xterm -e "$@"; else $@; fi; }

setup_aoss() { [ -d /proc/asound ] && export LD_PRELOAD="libaoss.so"${LD_PRELOAD:+:$LD_PRELOAD}; }
setup_padsp() { [ $(which pulseaudio 2>/dev/null) ] && export LD_PRELOAD="libpulsedsp.so"${LD_PRELOAD:+:$LD_PRELOAD}; }

setup_keepResolution()
{
	resolution=$(get_resolution)

	restore_resolution() {
		if [ "$(get_resolution)" != "$resolution" ]; then
			echo "Restoring display resolution to $resolution ..."
			set_resolution "$resolution"
		fi
	}

	trap restore_resolution EXIT
}
run_keepResolution()
{
	setup_keepResolution

	$@

	restore_resolution
}

unionfs_overlay_setup()
{
	local ro_data_path="$(readlink -f "$1")"
	local config_dir="$(readlink -fm $2)"

	local rw_data_path="${config_dir}_rw_data"
	overlay_path="$config_dir"

	overlay_cleanup() {
		if [ -d "$overlay_path" ]; then
			echo "Unmounting overlay '$overlay_path'..."
			fusermount -u -z "$overlay_path"
			rmdir "$overlay_path"
		fi
	}

	overlay_cleanup
	[ -d "$overlay_path" ] && die "'$overlay_path' is not properly unmounted"

	echo "Mounting overlay '$overlay_path'..."
	mkdir -p "$overlay_path" || return 1
	mkdir -p "$rw_data_path" || return 1
	#unionfs -o cow,umask=0000 "$rw_data_path"=RW:"$ro_data_path"=RO "$overlay_path" || return 1
	unionfs-fuse -o cow,umask=0000 "$rw_data_path"=RW:"$ro_data_path"=RO "$overlay_path" || return 1

	trap overlay_cleanup EXIT
}

link_overlay_setup()
{
	# Example: link_overlay_setup "${APPDIR}/drive_c/StarCraft" "${WINEPREFIX}/drive_c/StarCraft"

	spawn()
	{
		local from="$1"
		local to="$2"


		[ ! -d "$to" ] && mkdir -vp "$to"
		for i in "$from"/*; do
			if [ -d "$i" ]; then
				spawn "$i" "$to/$(basename "$i")" &
			elif [ -f "$i" ]; then
				case "$i" in
					*.ini | *.cfg | *.dat) cp -vn "$i" "$to/" || exit 1 ;;
					*) ln -nfs "$i" "$to/" || exit 1 ;;
				esac
			fi
		done
	}

	spawn "$(readlink -f "$1")" "$(readlink -fm "$2")"
	
	wait
}


build_report()
{
	local logfile="$1"
	local bin="$2"

	echo "<html><body>"
	echo "<p>Looks like the package has crashed, sorry about that!</p>"
	echo "<p>Please help us fix this error sending this log file to <a href='mailto:tux@portablelinuxgames.org'>tux@portablelinuxgames.org</a>, if possible commenting how the game crashed.</p>"
	echo "The binary returned $ret"

	echo "<h2>System information</h2>"
	echo "<pre>"
	echo "** Uname: $(uname -a)"
	for i in /etc/*-release; do
		echo "** $i:"
		cat "$i"
	done
	echo "</pre>"

	if [ -f "$logfile" ]; then
		echo "<h2>Game output</h2>"
		echo "<pre>"
		cat "$logfile"
		echo "</pre>"
	fi

	if [ -f "$bin" ]; then
		echo "<h2>ldd output</h2>"
		echo "<pre>"
		ldd "$bin"
		echo "</pre>"
	fi

	echo "</body></html>"
}

show_usage()
{
        usage_file="$1"
        [ -f "$usage_file" ] && cat "$usage_file"
}

