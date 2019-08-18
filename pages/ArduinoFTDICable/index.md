---
layout: page
title: FTDI Programmer for Arduino
tagline: How to make a cheap programmer for arduino custom PCBs
tags: FTDI,homemade,arduino
---
{% include JB/setup %}

When programming a regular arduino board, a USB cable is enough. But when rolling out your own standalone arduino circuits, it soon becomes as hassle to plug the ATmega chip into an Arduino board, or use a breadboard setup for the chip and use the Arduino as a programmer. An easy alternative is to equip your custom circuit 
with a header for connecting an FTDI cable (i.e. a cable that has USB on end to plug into the host computer, and a serial interface on the other end to connect to
the ATmega RX/TX/Reset pins.)<br>

As usual, I tried to find the cheapest option and stumbled upon this tutorial on how to hack a Nokia phone cable into an Arduino FTDI cable:
[http://letsmakerobots.com/node/23728](http://letsmakerobots.com/node/23728)

Simple enough, and I now have my own FTDI cable for 5$:

![ArduinoFTDICable]({{ site.baseurl }}/assets/images/ArduinoFTDICable/ArduinoFTDICable.png)

EDIT: it is now getting harder to find this Nokia USB cable, but anyway actual FTDI adapters for Arduino are available for about 6$ (e.g. [this](http://www.dx.com/p/ftdi-basic-breakout-arduino-usb-to-ttl-upload-tool-for-mwc-black-142041#.VKkBd3WG-zc))

