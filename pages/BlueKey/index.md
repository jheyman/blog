---
layout: page
title: BlueKey, a bluetooth hardware password manager
tagline: BlueKey, a bluetooth hardware password manager
tags: arduino, bluetooth, security, password, eeprom, OLED
---
{% include JB/setup %}

* TOC
{:toc}

---

## Overview

I have been thinking about improving my password management routine, and looking at existing password managers. My main requirements were that it should:

* be usable from all platforms I use (Windows, Linux, Android)
* be reasonably secure (for moderately critical login/passwords, since I will still memorize my most critical passwords and/or use SMS-based two-factor authentication when available)
* NOT involve cloud-base storage, or any internet connection for that matter
* be low-cost

As far as I can tell there are basically two main approaches:

* **Software-based** password vaults: many free and paid versions exist, but call me paranoid, I won't blindly trust a huge pile of closed-source SW connecting to the internet (as most commercial password managers do to support synchronization over supported platforms) with my passwords.
* **Hardware devices** (e.g. USB key/dongles), mostly used for supporting two-factor authentication. These are great, but until every single site/service I need to log into supports 2FA and whatever keyfob I would buy, then this is not practical enough.

I was leaning on the hardware side when I stumbled on this project: [The FinalKey](http://finalkey.net)

![FinalKey]({{ site.baseurl }}/assets/images/BlueKey/finalkey.png)

This little DIY hardware password manager is an arduino in a 3D-printed case that pretends to be a USB keyboard, and it will type in passwords for you after selecting the service to be accessed from a neat little SW client on the computer, and pushing the button on the device (as a security measure).

This thing is absolutely AWESOME, super low cost, and open source, and matches pretty much all of my requirements. Hats off to [Jimmy](http://dk.linkedin.com/in/jichr) for creating this. I immediately felt a DIY itch that needed scratching. So I decided to roll my custom version of a FinalKey, with some modifications to better suit my needs. Mostly, the one usecase that is not covered by the original FinalKey is usability with a smartphone: plugging a USB cable to use the FinalKey is not very convenient on a phone, and I would have had to develop an Android version of the FinalKey software too.

So I took a slightly different approach:

* I wanted the master key to be input on the device itself, not from the computer/phone connected to it (call it paranoia again), so I included a **keypad**.
* to remove the need for connecting a USB cable, I added a **Bluetooth module** supporting **HID profile**, which means the device presents itself to any nearby Bluetooth-enabled computer/phone as a **bluetooth keyboard**
* I wanted to be able to use the device with zero specific software installed on the target computer/phone:
    * as the device emulates a standard Bluetooth keyboard, no specific SW is required to receive characters over the wireless link
    * I intentionnally gave up the functionality of being able to update the internal password database from the host computer, and instead only kept the original FinalKey's capability to **generate new passwords**, store them internally and send them out.

Hence the **BlueKey** concept:
![concept]({{ site.baseurl }}/assets/images/BlueKey/bluekey_concept.png)

## Breadboard prototype #1

### Hardware 

Below is a description of the parts I used for the first prototype.

#### Arduino board
I used a Funduino Pro Mini 5V/16MHz (but pretty much any arduino could be used) => about 5$
![funduino]({{ site.baseurl }}/assets/images/BlueKey/funduino.jpg)
![funduino pro mini pinout]({{ site.baseurl }}/assets/images/BlueKey/funduino-pro-mini-pinout.png)

* **GND/5V/RX/TX/DTR** at the bottom can be connected to a USB programmer to upload sketches in the arduino
* **RX** and **TX** are connected to the bluetooth module's UART
* **pin2** and **pin3** are used for interrupts
* **A4** and **A5** are used for I2C communication with the display and EEPROM
* GPIOs **4,5,6,7,8,9,10,11** are used to scan the keypad matrix
* GPIO **12** is used for reading direction of the rotary encoder
* GPIO **A0** is used for reading switch status of the rotary encoder

#### Keypad
4x4 matrix keypad, 4$ on ebay. The keypad is HUGE compared to the other parts, but I could not find any smaller (while equally cheap) ones
![keypad]({{ site.baseurl }}/assets/images/BlueKey/keypad.png)

#### Bluetooth module 
I bought this RN42 module with HID profile (this is important) for about 25$. This is by far the most costly part of the list. There are a lot of much cheaper (HC-05/06) bluetooth modules, but they usually do not come with a firmware supporting HID profile. Yes, there are ways to get the firmware from an RN42 and install it on a cheapo HC-0x module, but this is not legal and the time I spared buying an actual RN42 module is well worth the 25 bucks anyway. Be aware that this thing is SMALL, soldering leads to it was not a piece of cake.
![RN42]({{ site.baseurl }}/assets/images/BlueKey/RN42.png)

The module has the following pinout: 

![RN42 pinout]({{ site.baseurl }}/assets/images/BlueKey/RN42_pinout.png)

* **pin1** is connected to GND
* **pin11** is connected to the regulated 3.3V power supply
* **pin12** is connected to GND
* **pin13 (UART_RX)** is connected to a the TX pin of the funduino through a simple voltage divider (to drop the arduino's 5V TX level to around 3V)
* **pin14 (UART_TX)** is connected to the RX pin of the funduino
* **pin15 (UART_RTS)** and **pin16 (UART_CTS)** are connected together since no HW flow control is required
* **pin 19 (GPIO2)** is connected to an LED (with 2k ohm resistor in series) to show the status of connection (LED OFF when connected)
* **pin 21 (GPIO5)** is connected to an LED (with 2k ohm resistor in series) to show the status of connection (blinking when waiting for connection)

#### EEPROM
24LC512 with I2C interface, got 4 for 10$
![eeprom]({{ site.baseurl }}/assets/images/BlueKey/eeprom.png)

The pinout is as follows:
![24LC512 pînout]({{ site.baseurl }}/assets/images/BlueKey/24LC512_pinout.png)

* **A0/A1/A2** are connected to GND (this sets the I2C address)
* **VSS** (GND) is connected to the GND
* **VCC** is connected to the Funduino's 5V rail which is ok since the component can take anywhere between 2.5V and 5.5V
* **WP** (Write Protect) is connected to GND, I don't need this feature for now.
* **SDA** and **SCL** (the I2C interface) are connected to the funduino's I2C bus.

#### OLED display
I picked the cheapest module I found, a 128x32pixels display with I2C interface, for about 10$. It is quite tiny, but suits my usecase, I only need a few lines of text to be displayed and read at arms' length.
![oled]({{ site.baseurl }}/assets/images/BlueKey/oled.png)

* **VCC** is connected to the funduino's 5V rail, which is ok since the component accepts a Vcc range of 2.8V to 5.5V
* **GND** is connected to the circuit's GND
* **SDA** and **SCL** are connected to the funduino's I2C bus (this is the beauty of I2C, there is no issue to have both the EEPROM and display on the same I2C interface, their specific address will be used to speak to one of the other) 

#### Rotary encoder
I happened to use a KY-040 module, bought for 2$ on ebay. This is used as the main user interface to scroll through text lines. It includes a switch (activated by pushing on the shaft itself). 
![encoder]({{ site.baseurl }}/assets/images/BlueKey/rotaryencoder.png)

* **CLK** is the main signal that will be pulsed when the shaft is turned
* **DATA** is the secondary signal that will be used to determine rotation direction
* **SW** is the signal for the switch embedded in the encoder shaft
* **+** is connected to the funduino's 5V
* **GND** is connected to the circuit's GND

#### Other stuff
* **5V to 3.3V converter** (about 2$). This is only necessary because I used a 5V arduino model, while the RN42 module requires 3.3V power supply.
* 4 x **1N4148 diodes** (~0$). These are used in the keypad readout mechanism.
* two **LEDs** (~0$). They are used to show the current state of the RN42 module (connecting/connected status)
* a few **resistors** (~0$)

### Breadboard assembly

The setup is as follows:

![fritzing_proto1]({{ site.baseurl }}/assets/images/BlueKey/fritzing_proto1.png)

And here is the messy breadboard result:

![breadboard]({{ site.baseurl }}/assets/images/BlueKey/breadboard_setup.png)

---

### Software

#### RN42 bluetooth module

By default, the module is configured for **SPP** (Serial Port Profile) and for communicating over its UART interface at 115200 bauds. Once wired as described above and powered, it should show up as an available bluetooth device in any nearby bluetooth-enabled phone (or computer). 

To verify proper operation of the module, I:

*  set the Serial bitrate to 115200 in the arduino code (instead of the typical 9600 value)
*  used the `BlueTerm` application for Android
*  sent a message from the arduino to the module, using a simple `Serial.print`
*  and saw the message showing up in the BlueTerm window. So far so good.

Now, what I really needed was to use the **HID** (Human Interface Device) profile of the module, so that the module presents itself as a wireless keyboard.
To do this, from either the local serial link or over the wireless serial terminal (e.g. BlueTerm), type in the following commands

    S~,6

then hit enter: this enables HID profile, and the device answers with `AOK`

Then type

    R,1

and hit enter: the device answers `Reboot!` and... reboots.

I then un-paired the device, relaunched a bluetooth scan, re-associated the device, and sure enough it now showed as a keyboard/input device on the phone:

![pairing]({{ site.baseurl }}/assets/images/BlueKey/bluetooth_pairing.png)

**Note**: the whole User Guide of the RN42 module is available [here](http://ww1.microchip.com/downloads/en/DeviceDoc/bluetooth_cr_UG-v1.0r.pdf), see chapter 5 about support for the HID profile. 

#### Keypad management

The matrix keypad if basically just a set of wires organized in 4 rows and 4 columns, which come in electrical contact under the key that is pushed. The 8 wires are connected to 8 GPIOs on the arduino, and then some code is required to scan the continuity between the rows and columns and figure out if a key was pushed (and which one).

There are existing arduino libraries to manage keypads, but most of those I found rely on polling of row/column lines at regular intervals from the main loop, and I wanted to avoid this (since there is then a strong dependency between the reactivity of the keypad and the main loop execution time, which tends to change over time as code is added). A much better option in my opinion is to use interrupts to only execute code when a key is pushed. 

Based on the example from this [Atmel keypad application note](http://www.atmel.com/Images/doc1232.pdf), I therefore wired the keypad as follows:
![keypad]({{ site.baseurl }}/assets/images/BlueKey/keypad_concept.png)

* Row lines are connected to arduino GPIOs that are configured as **inputs with pull-ups**.
* Column lines are connected to arduino GPIOs that are configured as **outputs initially set to LOW/GND state**
* each rows is connected to one arduino GPIO that is configured as an **interrupt pin** (on the arduino model I use, only pins 2 & 3 have this capability), configured as with a pull-up, and triggered upon FALLING edges of the signal.
    * the diodes are there to avoid conflicts between multiple rows, they implement a kind of **OR operation** into the interrupt pin.
* when any key is pushed, the corresponding row is then connected to GND via the column that the key belongs to.
* this pulls the interrupt line LOW, which triggers an interrupt
* the **interrupt service routine** then scans the rows & columns to determine the pushed key:
    * it resets all columns lines to HIGH state
    * it then loops through columns, setting them to LOW/GND one by one, and loops through reading all row values for each column : only the column/row combination corresponding to the pushed key will read a "LOW" state.
    * it then resets all columns lines to LOW/GND state for next time

This does not take care of multiple simultaneous key push, but for my usecase this is no big deal.

**Note**: playing with the columns output states within the interrupt service routine could theoretically trig a nested interrupt, and things would get ugly quickly. Fortunately, the arduino (this model at least) implicitly disables interrupts when entering an ISR, and re-enables them automatically upon exiting the ISR. 

#### Display management

The OLED display I used is based on the SSD1306 component, and is interfaced over IC2. Executing the [I2C scanner](http://playground.arduino.cc/Main/I2cScanner) sketch revealed that its address happens to be `0x3c`.
I downloaded and installed two great libraries from Adafruit that happen to support this display:

[Adafruit_SSD1306](https://github.com/adafruit/Adafruit_SSD1306) and [Adafruit-GFX-Library](https://github.com/adafruit/Adafruit-GFX-Library)

(modern arduino IDE can import libraries, for older ones just copy & paste the library folder into the `/libraries` folder of the arduino IDE, and restart. The only catch is that the library folder name MUST match the library sketch file name)

An example sketch `ssd1306_128x32_i2c.ino` is available in `AdafruitSSD1306` library, and I did not even have to adjust the I2C address of the display, it worked out of the box.
I don't need all the fancy graphics routine, the `print` function is all I needed to start with.

![oled_debug]({{ site.baseurl }}/assets/images/BlueKey/oled_debug.png)

#### EEPROM access

I reused the EEPROM read/write code from the `I2Ceep` of the FinalKey project, which is available [here](https://github.com/DusteDdk/FinalKey).
It boils down to the following sequence:

* For each chunk of 32 bytes:
    * initialize I2C communication to address 0x50
    * write MSB and LSB of target address to be read (or written)
        * for write, send the data to be written byte by byte, and end I2C communication
        * for read, end I2C communication, request and read incoming data
    * wait a few ms before looping to read/write next chunk

**Note**: the original FinalKey code I used at the time contained a value of 4ms for the delay, which turned out to produce write errors for consecutive writes with the EEPROM I was using. I increased the delay to 8ms and it works fine.

#### Rotary encoder management

The **CLK** signal of the rotary encoder is connected to interrupt pin #3 of the arduino, which is configured to trig an interrupt whenever it sees a FALLING edge of the signal.

The **DATA** pulse will begin either before of after CLK pulse, depending on the direction of the shaft rotation.

So the interrupt service routine checks the current state of the **DATA** signal at the time it is called, and increments or decrements a counter accordingly.

![encoder_nocaps]({{ site.baseurl }}/assets/images/BlueKey/encoder_nocaps.png)


## Breadboard prototype #2

On further thought, the keypad did not look practical enough, so I got rid of it and decided to use the knob as the single way to manage user input.

![concept2]({{ site.baseurl }}/assets/images/BlueKey/Bluekey2.png)

### Knob-based user input

TODO


### Better rotary encoder management

While turning the knob, sometimes the counter registered two increments, while only turning by one step. Zooming way in on the CLK signal falling edge reveals multiple short glitches:

![encoder_nocaps_zoomed]({{ site.baseurl }}/assets/images/BlueKey/encoder_nocaps_zoomed.png)

This results in the interrupt routine being called multiple times, and therefore wrongly incrementing the count multiple times on a single step turn.

Just plugging a 100nF capacitor be between CLK and GND, and another one between DATA and GND allows to filter out the glitches, and get a nice and clean timeline:

![encoder_100nF_caps]({{ site.baseurl }}/assets/images/BlueKey/encoder_100nF_caps.png)

Finally, a basic timing check is included in the ISR to reject calls that happen less than 10ms after the previous one (as inspired by [this guy's page](https://bigdanzblog.wordpress.com/2014/08/16/using-a-ky040-rotary-encoder-with-arduino/)).


### Updated breadboard assembly

![fritzing_proto2]({{ site.baseurl }}/assets/images/BlueKey/fritzing_proto2.png)


## An unexpected detour in low-memory land

Everything was going fine until I started adding significant amounts of code, when after a while the arduino started misbehaving seemingly randomly. It smelled like memory-related issues, yet the memory status reported by the compiler was nowhere near the limits:

    Sketch uses 21650 bytes (70%) of program storage space. Maximum is 30720 bytes.
    Global variables use 1576 bytes (76%) of dynamic memory, leaving 472 bytes for local variables. Maximum is 2048 bytes.

How could I encounter problems with 472 bytes of free SRAM left ?

SRAM is mapped as follows:

![SRAMMap]({{ site.baseurl }}/assets/images/BlueKey/SRAMMap.png)

Quick check of the executable with `avr-size` tool:

    etabli@bids-etabli:~/arduino-1.8.1/hardware/tools/avr/bin$ ./avr-size /tmp/arduino_build_525269/BlueKeyFat.ino.elf
       text    data     bss     dec     hex filename
      20834     816     760   22410    578a /tmp/arduino_build_525269/BlueKeyFat.ino.elf

So, 816 bytes of initialized data, and 760 bytes of uninitialized data. I used the `avr-nm` to check the list of these data:

    ./avr-nm -Crtd --size-sort /tmp/arduino_build_807388/BlueKey.ino.elf  | grep -i ' [dbv] '

Which returned:

    00000512 D _ZL6buffer.lto_priv.70
    00000242 B ES
    00000157 B Serial
    00000046 B display
    00000034 B TwoWire::txBuffer
    00000034 B TwoWire::rxBuffer
    00000034 b twi_txBuffer
    00000034 b twi_rxBuffer
    00000034 B twi_masterBuffer.lto_priv.65
    00000032 B gWDT_entropy_pool
    00000032 b gWDT_buffer
    00000024 d vtable for Adafruit_SSD1306
    00000016 d vtable for TwoWire
    00000016 d vtable for HardwareSerial
    00000012 B Wire
    00000008 d Adafruit_SSD1306::drawFastVLineInternal(int, int, int, unsigned int)::postmask
    00000008 d Adafruit_SSD1306::drawFastVLineInternal(int, int, int, unsigned int)::premask
    00000008 B Entropy
    [...and many others of smaller size]

* 512 bytes is the `buffer` in the **LCD library**: 128 cols * 32 lines * 1 bit  = 512 bytes
* 242 bytes for **EncryptedStorage object**
    * makes sense since EncryptedStorage object contains an AES object, that itself contains a 240 bytes `key_sched` work buffer
* **Serial** has two 64 bytes RX/TX buffers, as well as others variables, justifiying the 157 used bytes
* **displayobject** is an instance of Adafruit_SSD1306, derived from Adafruit_GFX, which has a bunch of internal variables, the 46 bytes make sense.
* **I2C** (TwoWire) library uses TX/RX buffers too.
* **vtable** entries are the price to pay for the convenience of using C++

So, nothing suspicious and nothing I could really spare. This should indeed theoretically leave 472 free bytes (2048 - 816  - 760) for dynamic allocations (mallocs, which I don't use) and for the stack.

To verify this at runtime, I implemented the following debug function, and called it at the very beginning of `setup()` to figure out memory limits at the beginning of execution:

    void printSRAMMap() {
        int dummy;
        int free_ram; 
        extern int __heap_end;
        extern int __heap_start;
        extern int __stack;
        extern int __bss_start;  

        extern int __data_end;
        extern int __data_start; 
        extern int * __brkval; 
        extern int __bss_end; 

        int stack=&__stack; 
        free_ram =  (int) &dummy - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
      
        Serial.print("\nMemory map:");

        Serial.print("\n,  __data_start=");
        Serial.print((int)&__data_start); 
            
        Serial.print("\n,  __data_end=");
        Serial.print((int)&__data_end);   

        Serial.print("\n, __bss_start=");
        Serial.print((int)&__bss_start);   
            
        Serial.print("\n, __bss_end=");
        Serial.print((int)&__bss_end);  

        Serial.print("\n, __heap_start=");
        Serial.print((int)&__heap_start);

        Serial.print("\n, __brkval=");
        Serial.print((int)__brkval);   
        
        Serial.print("\n, __heap_end=");
        Serial.print((int)&__heap_end);   

        Serial.print("\n, free=");
        Serial.print(free_ram);
        
        Serial.print("\n, stack bottom=");
        Serial.print((int)&dummy);
             
        Serial.print("\n, __stack top=");
        Serial.print((int)&__stack);  
            
        Serial.print("\n, RAMEND=");
        Serial.print(RAMEND);
    }

This returned:

    Memory map:
    ,  __data_start=256
    ,  __data_end=1072
    , __bss_start=1072
    , __bss_end=1832
    , __heap_start=1832
    , __brkval=0
    , __heap_end=0
    , free=105
    , stack bottom=1937
    , __stack top=2303
    , RAMEND=2303

* data segment starts at address 256, which is normal (addresses 0 to 255 is where the processor registers live)
* data segment ends at 1072, consistent with 816 bytes of data
* BSS segment is next, 760 bytes from 1072 to 1832
* Heap lives on top of that, but is unused (as indicated by brkval=0, i.e. no malloc was performed)
* Wait, what ? only 105 bytes of free RAM before stack space ? Way too low for comfort, and no wonder the later execution misbehaved, most probably due to running out of stack space.
* at the top of memory, stack uses bytes 1937 to 2303, which means...366 bytes of used stack, before program loop execution starts!

So among the 472 precious bytes of available SRAM, 366 directly went into the stack, before a single instruction of the main loop was called.

Time for a little code disassembly, for example on this snippet of the code:

    //  knobIncrementChanged=false;
    knobIndexIncreased=false;
    knobIndexDecreased=false;
    knobSwitchPushed=false;

    if(!ES.readHeader(devName)) {
    [...]
    }

which is supposed to call this function:


    bool EncryptedStorage::readHeader(char* deviceName)
    {
      byte buf[HEADER_EEPROM_IDENTIFIER_LEN];
      uint16_t offset = I2E_Read(0, buf, HEADER_EEPROM_IDENTIFIER_LEN);
      
      [...]
    }

The following command will disassemble the executable, showing assembly instructions with the original C code lines inserted for reference

    ./avr-objdump -m avr -C -S /tmp/arduino_build_583982/BlueKey.ino.elf > ~/Desktop/dump.asm

The relevant part of the output is:

    //  knobIncrementChanged=false;
    knobIndexIncreased=false;
    1716:   10 92 b2 04     sts 0x04B2, r1  ; 0x8004b2 <knobIndexIncreased>
    knobIndexDecreased=false;
    171a:   10 92 b1 04     sts 0x04B1, r1  ; 0x8004b1 <knobIndexDecreased>
    knobSwitchPushed=false;
    171e:   10 92 3f 04     sts 0x043F, r1  ; 0x80043f <knobSwitchPushed>

    bool EncryptedStorage::readHeader(char* deviceName)
    {
      byte buf[HEADER_EEPROM_IDENTIFIER_LEN];
      uint16_t offset = I2E_Read(0, buf, HEADER_EEPROM_IDENTIFIER_LEN);
        
        1722:   20 e0           ldi r18, 0x00   ; 0
        1724:   4c e0           ldi r20, 0x0C   ; 12
        1726:   b7 01           movw    r22, r14
        1728:   80 e0           ldi r24, 0x00   ; 0
        172a:   90 e0           ldi r25, 0x00   ; 0
        172c:   0e 94 6d 17     call    0x2eda  ; 0x2eda <EEPROM::dataOp(unsigned int, unsigned char*, unsigned char, unsigned char) [clone .constprop.24]>
        1730:   28 e6           ldi r18, 0x68   ; 104
        1732:   30 e0           ldi r19, 0x00   ; 0
        1734:   cd 5d           subi    r28, 0xDD   ; 221
        1736:   de 4f           sbci    r29, 0xFE   ; 254
        1738:   39 83           std Y+1, r19    ; 0x01
        173a:   28 83           st  Y, r18
        173c:   c3 52           subi    r28, 0x23   ; 35
        173e:   d1 40           sbci    r29, 0x01   ; 1
        1740:   f9 01           movw    r30, r18
        1742:   d7 01           movw    r26, r14
        1744:   2c e0           ldi r18, 0x0C   ; 12
        1746:   2e 0d           add r18, r14

I would have expected a `call` instruction to the `readHeader` function somewhere, but it turns out there is none because the function has been automatically **inlined** by the compiler.
This is generally a good optimisation for performance (spares the overhead of a function call) BUT in my specific case the unexpected effect was that since all this inlined code ended up inside the main function, the compiler allocated
all local variables corresponding to all inlined functions on the stack AT THE SAME TIME, i.e. at the beginning of execution, resulting in significant stack use, and the miserable free memory margin I noticed.

So I grabbed my anti-inlining axe, in the form of the `__attribute__ ((noinline))` compilation directive added in the prototype of the function implementation:

    bool __attribute__ ((noinline)) EncryptedStorage::readHeader(char* deviceName)
    
The generated assembly became:

    //  knobIncrementChanged=false;
    knobIndexIncreased=false;
    47a4:   10 92 7f 04     sts 0x047F, r1  ; 0x80047f <knobIndexIncreased>
    knobIndexDecreased=false;
    47a8:   10 92 7e 04     sts 0x047E, r1  ; 0x80047e <knobIndexDecreased>
    knobSwitchPushed=false;
    47ac:   10 92 1e 07     sts 0x071E, r1  ; 0x80071e <knobSwitchPushed>

    if(!ES.readHeader(devName)) {
    47b0:   c8 01           movw    r24, r16
    47b2:   0e 94 50 20     call    0x40a0  ; 0x40a0 <EncryptedStorage::readHeader(char*) [clone .constprop.16]>

Now the function is properly CALL'ed. Now let's disable inlining for all relevant functions in the code, recompile, and see what happens on the overall memory usage: 

    Sketch uses 21544 bytes (70%) of program storage space. Maximum is 30720 bytes.
    Global variables use 1576 bytes (76%) of dynamic memory, leaving 472 bytes for local variables. Maximum is 2048 bytes.

Code size is slightly smaller (a good side effect of disabling inlining), and DATA+BSS size is still identical to the original values. However at runtime the situation has changed: 

    Memory map:
      __data_start=256
      __data_end=1072
    , __bss_start=1072
    , __bss_end=1832
    , __heap_start=1832
    , __brkval=0
    , __heap_end=0
    , free=388
    , stack bottom=2220
    , __stack top=2303
    , RAMEND=2303

There you go, the stack now starts with only 83 bytes used, leaving 388 bytes free for later use. Much better than the original 105 bytes!
Even though this margin is still relatively small, it was enough to come back to a situation where the program was executing reliably again.

## Packaged prototype

Coming soon...


## Source Code

The source code is available [here](https://github.com/jheyman/BlueKey).

## Todo list

* invert RN42 LED status logic (should be ON when connected)
* password management SW
* random password generation 
* integrate in a proper packaging
* put arduino to sleep and wake-up on knob turn
* support local USB connection for emulating a leyboard (as the original FinalKey does)
* optionnally get rid of external EEPROM memory (64kB) and use arduino's internal EEPROM (1KB only, could store 16 entries of 2x32 bytes)
* deactivate inlining globally at makefile level

## Lessons learned

* The initial prototype was assembled very quickly, with cheapo components from ebay that worked out of the box: I just love the arduino ecosystem
* I need to improve my soldering skills
* I never thought implementing an emulated Bluetooth keyboard would require close to zero effort with the right BT module.
* The arduino IDE is such that it only compiles/links the library functions that are *actually* called in the main sketch. This is extremely cool when using a single function of a large library.


