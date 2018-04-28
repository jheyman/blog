---
layout: page
title: Qt On Raspberry Pi
tagline: Qt On Raspberry Pi
tags: Qt raspberry pi
---
{% include JB/setup %}

## Overview

A few years after developing an [Android app]({{ site.baseurl }}/pages/HomeHubApp) to manage my home automation, it was time to upgrade it. The VSD220 touch display with its embedded ARM processor running Android was a cool device to use, but it struggled to keep up with the load, and things were not a smooth as I would have liked. Also, Android development feels so awkward and overly complicated sometimes, so I needed some fresh air.

I considered buying a regular/non-smart display monitor with touch capability, and plugging it to a Raspberry Pi3. But then I checked the VSD220 user manual and found out that not only is there an HDMI connector to use the display with an external source, but also the touch capability is available by just connecting to the microUSB port on the side. Perfect ! 

The next good surprise was that when plugging the VSD220 to the Raspberry pi3 (via HDMI + USB) installed with a Raspbian Stretch (Mar 2018 / Desktop version), the touch capabilty worked out of the box. Cool!

I then considered various GUI frameworks, but not for long, as I have a (positive) bias towards Qt: it's been there for ever (I remember hacking basic GUI in the 2000's), it still has a decent open source version, and its internal mechanics just feel so simple and right. 

So the next step was to get Qt installed on the Raspberry Pi. One choice that must be made is whether one wants to develop on the Raspberry itself (in the desktop environment, which after all is very usable on an RPi3), or use a separate host PC to cross-compile code for the Pi. I want for the latter, even though it is (slightly) more complex to setup. No regrets, it's just so convenient to use QtCreator on a real PC, and just hit "Run" to execute the app remotely on the Pi.


* TOC
{:toc}

---

## Qt Install on Host PC and on Raspberry Pi 

I must admit this was not a piece of cake, there are many tutorials/instructions out there, and I struggled to get something running. 
The most useful resources for me was [this page](https://wiki.qt.io/RaspberryPi2EGLFS#Qt_Creator), so I stuck to that as much as possible, with a few tweaks along the way. For my own convenience I captured everything below, but this is 99% taken from there.

I chose to install **Qt5.10**, on a **Raspberry Pi3 Model B+**, installed with a **Raspbian Stretch** desktop image (2018-03-13-raspbian-stretch.img), and use a Linux host running **Ubuntu 16.04 LTS**

### RPi preparation 

Flash the Raspbian Strech image to the Pi's SD Card. XXX is whatever drive the SD Card is mounted to


	sudo dd if=2018-03-13-raspbian-stretch.img of=/dev/XXXX bs=4M

Connect keyboard/mouse/screen to the Rpi and boot to desktop. 
From the settings menu, change the GPU memory to 256 MB.

Make sure you have the latest and greatest firwmware on the Pi:

	[on RPi] sudo rpi-update
	[on RPi] reboot

prepare for installing required libraries:

	[on RPi] sudo nano /etc/apt/sources.list

Uncomment the 'deb-src' line, and save.

Installed the bunch of required libs:

	[on RPi] sudo apt-get update
	[on RPi] sudo apt-get build-dep qt4-x11
	[on RPi] sudo apt-get build-dep libqt5gui5
	[on RPi] sudo apt-get install libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0
	[on RPi] sudo mkdir /usr/local/qt5pi
	[on RPi] sudo chown pi:pi /usr/local/qt5pi

Now, on the host PC, prepare a sysroot that will later get copied onto the Pi, and the cross-compiling toolchain:

	[on Host PC] mkdir ~/raspi
	[on Host PC] cd ~/raspi
	[on Host PC] git clone https://github.com/raspberrypi/tools
	[on Host PC] mkdir sysroot sysroot/usr sysroot/opt
	[on Host PC] rsync -avz pi@raspberrypi.local:/lib sysroot
	[on Host PC] rsync -avz pi@raspberrypi.local:/usr/include sysroot/usr
	[on Host PC] rsync -avz pi@raspberrypi.local:/usr/lib sysroot/usr
	[on Host PC] rsync -avz pi@raspberrypi.local:/opt/vc sysroot/opt
	[on Host PC] wget https://raw.githubusercontent.com/riscv/riscv-poky/priv-1.10/scripts/sysroot-relativelinks.py
	[on Host PC] chmod +x sysroot-relativelinks.py
	[on Host PC] ./sysroot-relativelinks.py sysroot

Proceed to download Qt

	[on Host PC] wget http://download.qt.io/official_releases/qt/5.10/5.10.1/single/qt-everywhere-src-5.10.1.tar.xz
	[on Host PC] tar xf qt-everywhere-src-5.10.1.tar.xz

And to configure it. This is an important step to get right.

	[on Host PC] cd qt-everywhere-src-5.10.1
	[on Host PC] ./configure -release -skip qtwayland -skip qtlocation -nomake tests -nomake examples -opengl es2 -device linux-rasp-pi3-g++ -device-option CROSS_COMPILE=~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf- -sysroot ~/raspi/sysroot -opensource -confirm-license -make libs -prefix /usr/local/qt5pi -extprefix ~/raspi/qt5pi -hostprefix ~/raspi/qt5 -v -no-use-gold-linker

I added the "-skip wayland" and "-skip qtlocation" because the had build errors in my setup, related to a silly conflict somehwere between OpenGL ES2 and ES3 versions (error about glShaderSource function declaration conflict...). Since I will not need those features anyway, no point in debugging their build.

Make sure this configure step completes with no indication of errors, and proceed to cross-compile Qt: 

	[on Host PC] make -j4 all
	[on Host PC] make install

Note: at some point I had an issue requiring to apt-get a library on the Host, and got this error:

	libperl5.22 : Depends: perl-modules-5.22 (>= 5.22.1-9ubuntu0.2) but 5.22.1-9 is to be installed

which I fixed with this :

	sudo apt-get install --reinstall perl-modules-5.22

Now, copy the full result of the build to the RPi:

	[on Host PC] cd ~/raspi
	[on Host PC] rsync -avz qt5pi pi@(IP address of the Rpi):/usr/local

Now SSH to the RPi to fix some library links:

	[on RPi] echo /usr/local/qt5pi/lib | sudo tee /etc/ld.so.conf.d/00-qt5pi.conf
	[on RPi] sudo ldconfig
	[on RPi] sudo mv /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0 /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0_backup
	[on RPi] sudo mv /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0 /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0_backup
	[on RPi] sudo ln -s /opt/vc/lib/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0
	[on RPi] sudo ln -s /opt/vc/lib/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0
	[on RPi] sudo ln -s /opt/vc/lib/libEGL.so /opt/vc/lib/libEGL.so.1
	[on RPi] sudo ln -s /opt/vc/lib/libGLESv2.so /opt/vc/lib/libGLESv2.so.2

--- 

## QtCreator setup on the Host

The IDE that comes with Qt, QtCreator, is quite nice. It can be configured to talk to the Raspberry Pi as an embedded device target for the projects being built.

It's all very well explained in [this page](https://www.ics.com/blog/configuring-qt-creator-raspberry-pi), but again for my own convenience I capture the steps here.

* Go to Options -> Devices
  * Add
    * Generic Linux Device
    * Enter IP address, user & password
    * Finish
* Go to Options -> Compilers
  * Add
    * GCC
    * Compiler path: ~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/arm-linux-gnueabihf-g++
* Go to Options -> Debuggers
  * Add
    * ~/raspi/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/arm-linux-gnueabihf-gdb
* Go to Options -> Qt Versions
  * Check if an entry with ~/raspi/qt5/bin/qmake shows up. If not, add it.
  
* Go to Options -> Build & Run
  * Kits
    * Add
      * Generic Linux Device
      * Device: the one we just created
      * Sysroot: ~/raspi/sysroot
      * Compiler: the one we just created
      * Debugger: the one we just created
      * Qt version: the one we saw under Qt Versions
      * Qt mkspec: leave empty


When creating a new projet, add this 

	INSTALLS        = target
	target.files    = (whateverfilenameyoulike)
	target.path     = /home/pi

At the end of the `.pro` file

--- 

## Compilation of the Virtual Keyboard

To redo my homehub app, I needed to make sure I would get all required features from the Qt install. One that was not immediately obvious was the virtual keyboard, which given the fact that I am doing a touch-only application is vital to have, and is not included by default. 

Struggled a bit, found help [here](https://stackoverflow.com/questions/42576436/how-to-use-the-qtvirtualkeyboard), and did it this way:

* In QtCreator, navigate to `qt-everywhere / .... /qtvirtualkeyboard`, open the `virtualkeyboard.pro` project file, and configure the build to "Raspberry / Release", then Build.
* I could not figure out (nor wanted to spend time to figure out) how to deploy resulting files to the target, so I copied them by hand on the Rpi:
  * the whole directory  `/build-qtvirtualkeyboard-Raspi3_Homehub-Debug/qml/QtQuick/VirtualKeyboard` must be copied into `~/raspi/qt5pi/qml/QtQuick`
  * the file `/home/etabli/qt-everywhere-src-5.10.1/build-qtvirtualkeyboard-Raspi3_Homehub-Debug/plugins/platforminputcontexts/libqtvirtualkeyboardplugin.so` must be copied to `~/raspi/qt5pi/plugins/platforminputcontexts`
  * then rsync the ~raspi folder, as done previously, to actually transfer files onto the RPi.

At this point, launching a simple application with a unique text input field worked fine on the Pi, with the Virtual Keyboard showing up automatically when touching the text input field. 

### Configuring the locale

By default, the virtual keyboard builds with English as the only language/locale for the keyboard. To add my own locale (French) I did this:

* added the option `CONFIG+=lang-all` in the additional build options for qmake in QtCreator's project settings.
* rebuild the virtual keyboard project in QtCreator
* did the folder sync thing again

And finally, in the `main.qml` file of the project itself, inside the `InputPanel` item that should be there, I added this :

	Component.onCompleted: {
	    VirtualKeyboardSettings.locale = "fr_FR";
	}

