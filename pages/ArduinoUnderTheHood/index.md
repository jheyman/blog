---
layout: page
title: Arduino under the hood
tagline: Some details about how arduino programs actually work
tags: arduino, ATmega, avr
---
{% include JB/setup %}

This page collects bits of information that I found useful for my own needs, regarding the way an Arduino program is actually compiled, loaded on the board, and how it behaves at runtime

### Compilation & load process

A simplified view of the build and load process is as follows:

![Arduino build process]({{ site.baseurl }}/assets/images/ArduinoUnderTheHood/Arduino_build_and_load_process.png)

### Memory model

Most arduino boards have three kinds of memory on board:
- **EEPROM** (non-volatile) to store e.g. configuration info; 1KB on the Arduino Uno
- **Flash** (non-volatile) to store program binary; 32 KB on the Arduino Uno
- **SRAM** (volatile) to store variables during program execution; 2KB on the Arduino Uno

These are relatively small, but a good fit for the typical usage scenarios of an Arduino. I did face a few cases where I ran out of SRAM, and it bites real hard since the behavior of the chip then becomes quite weird. You would expect it to just crash/freeze, but sometimes it doesn't and just produces unexpected behaviors.
Since then, I have made an habit of specifically checking how much SRAM I am currently using, to figure out what kind of margin I have left at any time during development. 

Here is the code snippet I borrowed to do this:

	int freeRam () {
	  extern int __heap_start, *__brkval; 
	  int v; 
	  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
	}

A good tip to **spare some SRAM** is to store all the large read-only buffers in Flash instead. This is possible via the `PROGMEM` keyword. For example, I used it in the arduino code for my [LEDMatrixStrip]({{ site.baseurl }}/pages/LEDMatrixStrip):

	prog_char alphabet[][8] PROGMEM = {
	<large data set here....>
	}



