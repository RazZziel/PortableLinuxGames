#!/bin/bash
# Authors : Simon Peter, Ismael Barros² <ismael@barros2.org>
# License : BSD http://en.wikipedia.org/wiki/BSD_license

set -e
# set -x

HERE=$(dirname $(readlink -f "${0}"))
export PATH=$HERE:$PATH

OSIMAGE="$1"
APPIMAGE="$2"

WORKDIR="/tmp/squashfs"
MOUNTPOINT_UNION="$WORKDIR/union"
MOUNTPOINT_UNIONFS="$WORKDIR/unionfs"
MOUNTPOINT_ISO="$WORKDIR/iso"


trap atexit EXIT
atexit() {
	set +e
	echo "Cleaning up..."
	sleep 1
	killall unionfs
	sudo umount -l "$APPIMAGE"
	sudo umount -l "$MOUNTPOINT_UNION/var/lib/dbus"
	sudo umount -l "$MOUNTPOINT_UNION/etc/resolv.conf"
	sudo umount -l "$MOUNTPOINT_UNION/dev/pts"
	sudo umount -l "$MOUNTPOINT_UNION/sys/"
	sudo umount -l "$MOUNTPOINT_UNION/dev"
	sudo umount -l "$MOUNTPOINT_UNION/proc"
	#sudo umount "$MOUNTPOINT_UNION/boot"
#	fusermount -u "$MOUNTPOINT_UNION/automake" 2>/dev/null # Puppy
	#fusermount -u "$MOUNTPOINT_UNION"
	sudo umount -l "$MOUNTPOINT_UNION"
	sudo umount -l "$MOUNTPOINT_UNIONFS/root" 2>/dev/null
	fusermount -u "$MOUNTPOINT_ISO" 2>/dev/null
	fusermount -u "$MOUNTPOINT_ISO" 2>/dev/null
	fusermount -u "$MOUNTPOINT_ISO" 2>/dev/null
	rmdir "$MOUNTPOINT_UNIONFS/root"
	rm -rf "$MOUNTPOINT_UNIONFS/rw"
	rmdir "$MOUNTPOINT_UNIONFS"
	rmdir "$MOUNTPOINT_UNION"
	#rmdir "$MOUNTPOINT_ISO"
	rmdir "$WORKDIR"
}



if [ "x$OSIMAGE" == "x" ] ; then
	echo "Please specify a ISO or squashfs base system to run the AppImage on"
	exit 1
fi

if [ "x$APPIMAGE" == "x" ] ; then
	echo "Please specify an AppDir or AppImage to be run"
	exit 1
fi

mkdir -p "$MOUNTPOINT_UNIONFS/root" # Unionfs read-only
mkdir -p "$MOUNTPOINT_UNIONFS/rw" # Unionfs rw
mkdir -p "$MOUNTPOINT_UNION" # Overlay

# If ISO was specified, then mount it and find contained filesystem
if [ ${OSIMAGE##*.} == "iso" ] ; then
	ISO="$OSIMAGE"

	echo "Mounting ISO $ISO on $MOUNTPOINT_ISO"

	#mkdir -p "$MOUNTPOINT_ISO"
	#sudo mount -o loop,ro "$ISO" "$MOUNTPOINT_ISO"
	fuseiso -p "$ISO" "$MOUNTPOINT_ISO" -o allow_other

	# Ubuntu-like ISOs
	if [ -e "$MOUNTPOINT_ISO/casper/filesystem.squashfs" ] ; then
		SQUASHFS="$MOUNTPOINT_ISO/casper/filesystem.squashfs"

	# Fedora-like ISOs
	elif [ -e "$MOUNTPOINT_ISO/LiveOS/squashfs.img" ] ; then
		SQUASHFS="$MOUNTPOINT_ISO/LiveOS/ext3fs.img" || exit 1
		sudo mount -o loop,ro "$MOUNTPOINT_ISO/LiveOS/squashfs.img" "$MOUNTPOINT_ISO/"
	
	else
		echo "Unknown distro"
		exit 1
	fi
else
	SQUASHFS="$OSIMAGE"
fi

echo "Using SquashFS $SQUASHFS"
sudo mount -o loop,ro "$SQUASHFS" "$MOUNTPOINT_UNIONFS/root" || exit 1

#unionfs-fuse -o allow_other,use_ino,suid,dev,nonempty -ocow,chroot=$MOUNTPOINT_UNIONFS/,max_files=32768 /rw=RW:/root=RO $MOUNTPOINT_UNION
unionfs -o allow_other,use_ino,suid,dev,nonempty -o cow "$MOUNTPOINT_UNIONFS/rw"=RW:"$MOUNTPOINT_UNIONFS/root"=RO "$MOUNTPOINT_UNION" || exit 1

ls "$MOUNTPOINT_UNION/boot" >/dev/null && MNT=/boot
#ls "$MOUNTPOINT_UNION/automake" >/dev/null && MNT=/automake || echo "" # Puppy

if [ "x$MNT" == "x" ]; then
	echo "Could not find free mountpoint"
	exit 1
fi

if [ -f "$APPIMAGE" ] ; then # AppImage
	sudo mount "$APPIMAGE" "$MOUNTPOINT_UNION/$MNT" -o loop
elif [ -d "$APPIMAGE" ] ; then # AppDir
	sudo mount "$APPIMAGE" "$MOUNTPOINT_UNION/$MNT" -o bind
fi

cat > "$MOUNTPOINT_UNION/run.sh" <<EOF
#!/bin/sh
export PATH=/bin:/usr/bin
cat /etc/*release
echo ""
rm -rf /etc/pango
mkdir -p /etc/pango
pango-querymodules > '/etc/pango/pango.modules' # otherwise only squares instead of text
[ -f /si-chroot ] && ln -s /lib/ld-lsb.so.3 /lib/ld-linux.so.2
echo ""
echo "===================================================="
echo ""
LD_LIBRARY_PATH="$MNT/usr/lib:$MNT/lib/:$LD_LIBRARY_PATH" ldd "$MNT"/usr/bin/* "$MNT"/usr/lib/* 2>/dev/null | grep "not found" | sort | uniq
echo ""
echo "===================================================="
echo ""
export HOME="/root" 
export LANG="en_EN.UTF-8"
# export QT_PLUGIN_PATH=./lib/qt4/plugins ###################### !!!
cd "$MNT"
./AppRun
#bash
EOF

chmod a+x "$MOUNTPOINT_UNION/run.sh"
sudo mount -t proc proc "$MOUNTPOINT_UNION/proc"
sudo mount -t sysfs sys "$MOUNTPOINT_UNION/sys/"
sudo mount --bind /dev "$MOUNTPOINT_UNION/dev"
sudo mount --bind /dev/shm "$MOUNTPOINT_UNION/dev/shm"
sudo mount -t devpts pts "$MOUNTPOINT_UNION/dev/pts"
sudo mount --bind /var/run "$MOUNTPOINT_UNION/var/run" # pulse
#sudo mount --bind /tmp "$MOUNTPOINT_UNION/tmp" # pulse
sudo mount --bind /var/lib/dbus "$MOUNTPOINT_UNION/var/lib/dbus" # pulse (and more)
sudo mkdir "$MOUNTPOINT_UNION/root/.pulse" # pulse
sudo mount --bind ~/.pulse "$MOUNTPOINT_UNION/root/.pulse" # pulse
sudo touch "$MOUNTPOINT_UNION/etc/resolv.conf" || echo ""
sudo mount --bind /etc/resolv.conf "$MOUNTPOINT_UNION/etc/resolv.conf"
xhost local: # otherwise "cannot open display: :0.0"

echo ""
echo "===================================================="
echo ""
sudo chroot "$MOUNTPOINT_UNION" /run.sh # $MNT/AppRun
#cd "$MOUNTPOINT_UNION"
#sudo systemd-nspawn
echo ""
echo "===================================================="
echo ""

exit $?
