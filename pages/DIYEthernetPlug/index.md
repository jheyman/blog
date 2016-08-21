---
layout: page
title: DIY Emergency Ethernet Plug
tagline: manually crimping an Ethernet plug with no appropriate tool
tags: Ethernet, crimping, RJ45
---
{% include JB/setup %}

Every once in a while, I need to make custom Ethernet cabling. Since I did not bother buying an appropriate RJ45 crimping tool, below are a few notes to manually crimp an RJ45 connector at the end of an Ethernet cable, in desperate situations. The quality of the resulting connection is much less predictable than with a proper tool, but with a lot of caution it works well enough to cover the occasional Ethernet hack emergency.

* Get an empty RJ45 connector housing

![overview]({{ site.baseurl }}/assets/images/DIYEthernetPlug/empty_housing.png)

* Cut the CAT5 cable in a nice straight cut.
* Strip off about ~2cm/1inch of the jacket, then order the wires as follows:
  * white/orange
  * orange
  * white/green
  * blue
  * white/blue
  * green
  * white/brown
  * brown 

![overview]({{ site.baseurl }}/assets/images/DIYEthernetPlug/before_insertion.png)

* the tricky part: insert the wires in the RJ45 housing, and push until the wires block against the front of plastic housing, **while ensuring that the wires stay in the same order**:

![overview]({{ site.baseurl }}/assets/images/DIYEthernetPlug/in_housing.png) 

* Use a small, thin, flat precision screwdriver like this one:

![overview]({{ site.baseurl }}/assets/images/DIYEthernetPlug/screwdriver.png) 

* Using the screwdriver and a small hammer, gently push each individual pin inside the plug, one by one. Here it is halfway done, with the three middle pins already hammered in:

![overview]({{ site.baseurl }}/assets/images/DIYEthernetPlug/halfway_done.png) 

* Also push in the plastic thingy that will hold the cable jacket itself, and finally install the plug cover (if any). 

* Hope for the best and test the cable. 