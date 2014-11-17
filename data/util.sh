#!/bin/bash
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

die() { echo $@; exit 1; }

get_resolution() { xrandr | grep \* | cut -d' ' -f4; }
set_resolution() { xrandr -s $1; }

run_withLocalLibs() { LD_LIBRARY_PATH="$APPDIR/usr/lib/:$LD_LIBRARY_PATH" "$@"; }
run_shell() { if tty -s <&1; then "$@"; else xterm -e "$@"; fi; }
run_elf() { $APPRUN_HELPERS $RUNELF_HELPERS "$@"; }

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

setup_fixInvisibleMouse()
{
	# Workaround for https://bugs.launchpad.net/ubuntu/+source/gnome-settings-daemon/+bug/1238410

	[ ! $(which gsettings 2>/dev/null) ] && return # No gsettings support

	if [ "$(gsettings get org.gnome.settings-daemon.plugins.cursor active)" = "true" ]; then

		restore_gsettings() {
			gsettings set org.gnome.settings-daemon.plugins.cursor active true
		}

		trap restore_gsettings EXIT

		gsettings set org.gnome.settings-daemon.plugins.cursor active false
	fi
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

		wait
	}

	local from="$(readlink -f "$1")"
	local to="$(readlink -fm "$2")"
	spawn "$from" "$to"
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

patch_relative_paths()
{
	local output=()
	for i in "$@"; do
		if [ -f "$i" ]; then
			abs="$(readlink -f "$i")"
			echo "[AppImage] Converting parameter '$i' into '$abs'" >&2
			i="$abs"
		fi
		output+=("\"$i\"")
	done
	echo "(${output[@]})"
}
