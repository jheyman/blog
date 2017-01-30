---
layout: page
title: Arduino tips and tricks
tagline: Various arduino tips I keep forgetting about
tags: arduino, tips
---
{% include JB/setup %}

Below is a set of notes to myself regarding various Arduino debugging tips and tricks<br>

* TOC
{:toc}

--- 

### Enable non-root access to serial port(s) in Arduino IDE

When launching the arduino IDE without root privileges, by default access to serial ports to communicate with the boards is not permitted and will produce an error when trying to flash a program. The following command allows to grant access to user [username] to serial ports, e.g. `/dev/ttyS0` or `/dev/ttyACM0`:

	sudo usermod -a -G dialout [username]

Then logout, log back in, launch arduino IDE normally, and access should be possible.


