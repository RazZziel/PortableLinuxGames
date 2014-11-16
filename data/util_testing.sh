#!/bin/sh
# Author : Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

link_overlay_setup()
{
	# Example: link_overlay_setup "${APPDIR}/drive_c/StarCraft" "${WINEPREFIX}/drive_c/StarCraft"

	local from="$(readlink -f "$1")"
	local to="$(readlink -fm "$2")"
	local filesToCopy=".*\.\(ini\|cfg\|dat\)$"

	pushd "$from"
	#find -type d -exec mkdir -vp "$to/{}" \;
	find -type d -exec echo -en "$to/{}\0" \; | xargs -0 mkdir -vp
	find -type f      -regex "$filesToCopy" -exec cp -vn "$PWD/{}" "$to/{}" \; &
	find -type f -not -regex "$filesToCopy" -exec ln -nfs "$PWD/{}" "$to/{}" \; &
	wait
	popd
}
