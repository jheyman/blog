---
layout: page
title: Music server on Raspberry pi
tagline: How to install a DLNA/UPnP music server on Raspberry Pi
tags: UPnP, Raspberry Pi, linux, music, home automation
---
{% include JB/setup %}

This page tracks some notes regarding the installation of a music streaming server on raspberry pi running linux, with remote control capability from an Android device. The underlying technology is the DLNA (Digital Living Network Alliance) interoperability standard, using the UPnP (Universal Plug and Play) protocol for communication between difference devices in (typically) a home automation setup.

In practice, we will use the **minidlna** server (now called ReadyMedia) to provide media content, and the **BubbleUPnP** server on top of that for adding advanced functions (access from the internet, OpenHome renderer for unified playlist...)

![setup overview]({{ site.baseurl }}/assets/images/UPnPOnRaspberryPi/DLNA-UPNP_on_Raspi.png)

## Server part

The installation was performed by following [these](http://blog.scphillips.com/2013/01/using-a-raspberry-pi-with-android-phones-for-media-streaming/) instructions, as is.

Notes:

- at the time this was installed, a hard-float version of java for raspberry pi was required. It could be found [here](http://jdk8.java.net/fxarmpreview/)
- `ffmpeg` is required to be installed on the raspi
- to refresh the minidlna database on the raspi:

<pre><code>sudo service minidlna force-reload</code></pre>


Once the BubbleUPnP server is installed, a login/password should be configured using the admin panel accessible via `http://[IP address of the raspi]:58050`

## Android client part

Just install the BubbleUPnP app on any Android device, configure the IP address/post of the UPnP server (and renderer) running on the raspi.





