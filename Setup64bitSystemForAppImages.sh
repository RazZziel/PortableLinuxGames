#!/bin/bash

sudo apt-get update

for i in libc6-i386 libglib2.0-0:i386 libgl1-mesa-glx-lts-quantal:i386 libpulse0:i386 libvorbisfile3:i386; do
	sudo apt-get install "$i"
done

libfuse="/lib32/libfuse.so.2"
if [ -f "$libfuse" ]; then
	echo "Fuse support already installed"
else
	pushd /tmp/
	wget http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2_2.8.1-1.1ubuntu2_i386.deb
	ar x libfuse2_2.8.1-1.1ubuntu2_i386.deb data.tar.gz
	tar -xhf data.tar.gz ./lib/libfuse.so.2.8.1
	sudo install -o root lib/libfuse.so.2.8.1 "$libfuse"
	rm lib/libfuse.so.2.8.1 data.tar.gz libfuse2_2.8.1-1.1ubuntu2_i386.deb
	rmdir lib
	sudo ldconfig
	popd
fi
