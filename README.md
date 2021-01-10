What is this?
-------------

**PortableLinuxGames** packs and distributes great Linux games as portable, self-contained packages that will (or should) run on any Linux system out there.

I uses the [AppImage](http://appimage.org/) package format, and some [script magic](https://github.com/RazZziel/PortableLinuxGames).

How does it work?
-----------------

These games are distributed in a package format called [AppImage](https://appimage.org/), and it's a big deal. AppImages are stand-alone, executable packages, that bring the _"one app, one file"_ philosophy to Linux.

AppImages are two types of file at the same time:

*   **An ELF executable**. So you can just run them and play these awesome games.
*   **An ISO file**. You can mount them (_mount -o loop_, _fuseiso_, _acetoneiso_, etc.) and peek what's inside.  
    Inside an AppImage you'll find two things:
    *   The app installation, next to all its dependencies, and sometimes even a minimal Wine or Perl installation
    *   A little script (AppRun) to glue it all together when you run the package

About these packages
--------------------

All I'm doing here is packing some games I like, and sharing them just in case someone finds them useful.

I'm only sharing the games I think I'm free to distribute (I've also packaged some commercial games I've bought, but I'm not sharing those!). If you're the owner of any of these games and you don't like them being here without your explicit permission, please let me know and I'll take it down. I just want to share something I think it's cool, and I'm not making any profit (other than maybe Internet Karma™).

All these packages are working on my system (64bit ArchLinux on Dell XPS L502X), but I don't have the spare time to test every package as well as I should on different distros, so if any package fails to run on your machine, please send me an email with the exact error message and I'll try to fix it (when I find time). Or uncompress the package, fix it yourself, pack it back up and share it if you want; your AppImage, your rules.

BTW, if you have a pure **64bit** system, please note that 32bit AppImages won't work by default. Please check [this tutorial](https://github.com/RazZziel/PortableLinuxGames/wiki/Setup-a-64bit-system-to-run-32bit-appimages) to see how to configure a 64bit operative system to run 32bit AppImages.

But why?
--------

I was just a casual gamer that had no space left on his laptop for games (or anything work-unrelated for that matter). I was also tired of the state of release segmentation between Linux distributions, or having some old nightly game version I enjoyed playing every now and then stop working because the library it was linked against suddenly no longer existed, because my distribution decided to deprecate it. So I discovered this AppImage thingy, and decided to contribute back. I like it, and I'd like to see it converted in the future of Linux package distribution.

I fell in love with the stuff the very moment I saw I could package Starcraft together with a minimal Wine install in an AppImage, copy it to an USB drive, take it to my college's lab (se used Ubuntu on all labs), and have Starcraft running with one click, just like that. Share the USB drive with among some friends, and you're got a Starcraft party going. On Linux. No drugs needed. _Woah_.

Now I can stash the games I'm not usually playing in some external or cloud drive, and rescue them anytime I feel like playing them again, knowing that every single dependency will still be in its place. Also, games usually take less space, because I can play them without uncompressing, and performance is not affected; how cool is that?

I want to contribute
--------------------

*   Got any constructive feedback? Does any game fail to run in your machine? Go [here](https://portablelinuxgames.uservoice.com/) or drop me [an email](mailto:tux@portablelinuxgames.org)
*   Help improve the base [AppImageKit](https://github.com/AppImage/AppImageKit) project
*   Help improve the [PortableLinuxGames](https://github.com/RazZziel/PortableLinuxGames) scripts and utilities
*   Just use these resources to pack and distribute your own applications and games!

Join the chat at https://gitter.im/RazZziel/PortableLinuxGames
