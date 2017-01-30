---
layout: page
title: Oldschool demo effects with OpenGL
tagline: Oldschool demo effects with OpenGL
tags: OpenGL, demo, C++
---
{% include JB/setup %}

While I was looking through my archives, I stumbled upon this old piece of code I did back in 2004, when I was experimenting with openGL programming. It renders a few simple effects that have an oldschool-PC-demo feel, and it brought back fond memories so I figured I would archive it properly, and make a video capture of it before it was too late (i.e. SW environments tend to change a lot over the course of a decade, so I may not be able to execute this piece of code a few years from now...)<br>

* TOC
{:toc}

--- 

## Overview

First up, a text scroller over raster lines and a starfield:
![part1]({{ site.baseurl }}/assets/images/OpenGLOldschool/part1_small.png)

Then, more rasters and a sine scroller with typical chrome-like font:
![part2]({{ site.baseurl }}/assets/images/OpenGLOldschool/part2_small.png)

3D tunnel (slightly modernized with 3D text scroller):
![part3]({{ site.baseurl }}/assets/images/OpenGLOldschool/part3_small.png)

Variation around rasters gone wild and a 3D sine scroller:
![part4]({{ site.baseurl }}/assets/images/OpenGLOldschool/part4_small.png)

Anyone remembers when vertical rasters were a wow effect ?
![part5]({{ site.baseurl }}/assets/images/OpenGLOldschool/part5_small.png)

Twist scroller and sine deformation over a rotozoom:
![part6]({{ site.baseurl }}/assets/images/OpenGLOldschool/part6_small.png)

And finally rising water with bubbles, as a (remote) tribute to the legendary [fishtro](https://www.youtube.com/watch?v=gyzMYzwA6G8)!
![part7]({{ site.baseurl }}/assets/images/OpenGLOldschool/part7_small.png)

## Reviving the source code

The implementation is in C++, using OpenGL for graphical rendering, and the BASS library for playing a soundtrack.<br>

The source code is very poorly written, it has all sorts of "wow, I would never do it this way nowadays" parts, but it did put a smile on my face after 12 years (nostalgia!), so it deserves to end up in my github repo if only for that reason.<br>

The code was originally developed in 2004 with whatever version of Visual Studio I had at that time. To rebuild it, I downloaded the latest free version of Visual Studio, i.e. Visual Studio Community 2015, and was pleasantly surprised that the automatic project migration worked just fine !<br>

Only two settings were modified to get the code to build & run:

* remove `glaux.lib` from the kiner dependencies (this library is obsolete and does not exist  / is not necessary anymore)
* disable the `SAFESEH` option (in Linker advanced options), since the old BASS.dll library I am using is not compatible with this option.

<br>There is an additional compilation option issue while building in Debug mode, which I did not care investigating.

## Video

<iframe width="560" height="315" src="https://www.youtube.com/embed/nfCnZal1CzI" frameborder="0" allowfullscreen></iframe>

The soundtrack is "Fellowship" from 1994 by [Lizardking](https://en.wikipedia.org/wiki/Gustaf_Grefberg), possibly one of the greatest demo music composer of old days.




