---
layout: page
title: Home intercom/paging system 
tagline: Leveraging raspberry pi to build an intercom system
tags: raspberry pi, SIP, PBX, Asterisk
---
{% include JB/setup %}

After deploying a multi-room audio system at home (see [here]({{ site.baseurl }}/pages/MultiRoomHomeAudio)), I figured it would be interesting to leverage the installed raspberry pis as a way to stream voice from room to room ("diner's ready", without having to shout). <br>

* TOC
{:toc}

### Requirements

For this project I wanted to have:

* multiple push-to-talk stations available at several locations
* streaming of voice to all other audio stations
* reasonable latency
* the ability to add more stations if needed

### HW overview

The setup is as follows:

![Overview]({{ site.baseurl }}/assets/images/Intercom/overview.png)

* One raspberry pi running a PBX (Asterisk)
* One raspberry pi for each station
	* with a USB audio device to sound input and output
	* running an SIP client (PJSIP) and streaming audio to/from other stations
	* using one GPIO to handle the push-to-talk button triggering calls to other stations

### SW setup 

The credits go to [this guy](http://marpoz.blogspot.fr/2013/01/door-berry-10_9.html) for installing Asterisk & PJSIP.

#### Raspberry pi install

I used a Raspbian light image, but any distro will do.

#### Asterix PBX install

	sudo apt-get install alsaplayer-alsa python2.7-dev python-daemon python-lockfile libv4l-dev libx264-dev libssl-dev libasound2-dev asterisk

#### PJSIP install

	wget http://www.pjsip.org/release/2.3/pjproject-2.3.tar.bz2
	tar xvfj pjproject-2.3.tar.bz2
	cd pjproject-2.3/
	./configure --disable-video --disable-l16-codec --disable-gsm-codec  --disable-g722-codec --disable-g7221-codec --disable-ilbc-codec

Then create a custom config header:
	
	nano pjlib/include/pj/config_site.h

And fill it with:

	#define PJMEDIA_AUDIO_DEV_HAS_ALSA       1
	#define PJMEDIA_AUDIO_DEV_HAS_PORTAUDIO  0
	#define PJMEDIA_CONF_USE_SWITCH_BOARD    1

And finally build it:

	make
	sudo make install

#### PJSUA/Python wrapper install

	cd pjsip-apps/src/python
	make
	sudo make install

#### Asterisk configuration

I used a very basic Asterisk configuration to allow the stations to register to the PBX and call each other:


And in `sip.conf`:

	[2000]
	type=friend
	context=home-phones
	secret=1234
	host=dynamic

	[2001]
	type=friend
	context=home-phones
	secret=1234
	host=dynamic

	[2002]
	type=friend
	context=home-phones
	secret=1234
	host=dynamic

A dialplan must be configured in `extensions.conf`. Here is the one I used:

* a "home-phones" **Context** to hold our extension rules
* a set of **extensions**:
	* Format is `exten => name,priority/step(stepname),application(...)`


	[home-phones]
	exten => 2000,1,Dial(SIP/2000)
	exten => 2001,1,Dial(SIP/2001)
	exten => 2002,1,Dial(SIP/2002)

### Python intercom management script 
 TODO

