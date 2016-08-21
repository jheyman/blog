---
layout: page
title: Android debug tips and tricks
tagline: Various android debugging tips I keep forgetting about
tags: android, tips, adb
---
{% include JB/setup %}

Below is a set of notes to myself regarding various Android debugging tips and tricks, mostly using `adb` command-line utility from Android SDK.

* TOC
{:toc}

--- 

### Unlocking developer options menu (device)
* Locate the Build number field in the options, and tap it 7 times.

### Detecting devices (host)
* To be able to properly detect/see connected devices without running  `adb` as root:
	* determine USB vendorId of the target device using `lsusb`
	* create a udev rules file (e.g. /etc/udev/rules.d/51-android.rules)
	* edit it and add `SUBSYSTEM=="usb", ATTR{idVendor}=="<vendorId>", MODE="0666", GROUP="plugdev"`
	* restart udev: `sudo service udev restart`
	* kill adb: `sudo killall adb̀`
	* unplug and replug device
	* device should now be listed properly when executing `adb devices`

### Handling multiple connected devices (host)
* To target `adb` commands at one specific device when several are connected, use: `adb -s <target device ID> shell` 

### Get logs (host)
* To get the timestamped logcat traces from a remote host : `adb logcat -v time > logcat.txt`
* To clear the logcat: `adb logcat -c`

### Install application (host)
* To force the (re)install of an application package: `adb install -r app.apk`

### Launch application (host)
* To launch a specific app: `./adb shell am start -n <packageName>/<packageName>.<ActivityName>`

### Simulate user inputs (host)
* Simulate a wake/power-on : `adb shell input keyevent 224`
* Simulate a power toggle : `adb shell input keyevent 26`
* Simulate a user touch at coordinates x,y : `adb shell input tap x y`

### Get system info (host)
* LARGE system info dump : `adb shell dumpsys`
* Power management system info dump : `adb shell dumpsys power`
* Dumpable subcategories: `adb shell dumpsys | grep "DUMP OF SERVICE"`

### Get touch coordinates (device)
* Activate the associated function in `Developer Options` menu in the device's settings: a bar at the top of the screen will show x and y coordinates of any touched point. 

### Remote screenshot (host)
* To grab a screenshot from the host: `adb shell screencap -p | perl -pe 's/\x0D\x0A/\x0A/g' > screenshot.png`


