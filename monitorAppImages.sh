#!/bin/bash
#
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license
#
# Monitors one or more directories, waiting for AppImages to be added or deleted,
# creating or removing menu entries accordingly.
#
# By default, directory ~/Applications/ will always be monitored,
# but additional directories can be specified as arguments.
#
# Usage:
#         ./monitorAppImages.sh [directories...]


desktops="/$HOME/.local/share/applications"


add() {
	local app="$1"
	shift
	[ ! -n "$app" ] && return 1;

	echo "Added ${i}..."
	local tmp="/tmp/AppImage-$(basename "$app").desktop"
	tmp=${tmp// /_} # xdg-desktop-menu hates spaces
	#icon=$("$app" --icon | cut -d" " -f2)
	echo -e "[Desktop Entry]\nType=Application\nName=$(basename "$app")\nExec=\"$(readlink -f "$app")\"\nIcon=$icon" > "$tmp"
	xdg-desktop-menu install "$tmp" $@
}

del() {
	local app="$1"
	shift
	[ ! -n "$app" ] && return 1;

	echo "Removed ${i}..."
	local tmp="$desktops/AppImage-$(basename "$app").desktop"
	tmp=${tmp// /_} # xdg-desktop-menu hates spaces
	xdg-desktop-menu uninstall "$tmp" $@
}


dirs="$HOME/Applications/"
for dir in $@; do
	[ -d "$dir" ] || continue
	dirs+=" $dir"
done

echo "Watching ${dirs}..."

for dir in $dirs; do
	for i in $dir/*.run; do
		add "$i" --noupdate &
	done
done
wait
update-desktop-database "$desktops"

inotifywait -m -r -e CREATE -e DELETE -e MOVED_FROM -e MOVED_TO --format '%e:%w%f' $dirs |
	while read event; do
		case "$event" in
			CREATE:*|MOVED_TO:*)
				add "${event#*:}"
				;;
			DELETE:*|MOVED_FROM:*)
				del "${event#*:}"
				;;
		esac
	done
