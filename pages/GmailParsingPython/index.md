---
layout: page
title: Gmail parsing using Python on Raspberry Pi
tagline: Gmail parsing using Python on Raspberry Pi
tags: Gmail raspberry pi python
---
{% include JB/setup %}

## Overview

I wanted a dead simple way to log "todo" items remotely in my todolist server (which uses a simple PHP access to an SQlite database hosted on a raspberry pi, see [here](https://github.com/jheyman/TodoList_ServerSide)
The todo list is accessible via HTTP requests, so I initially wrote an Android app to view and create new items, but it turned out that I did not use it much, and after a few weeks I was back to sending emails to myself to keep track of things to do. And then the todo email would get burried under loads of subsequent emails, and I would forget about it.

So, new plan: instead of fighting my natural tendency to send emails to myself, I embraced it and created a small Python script that runs on a rasperry pi, regularly checks a dedicated gmail account of mine, and checks for any email in the inbox with "todo" in the subject: if it finds any, it then performs an HTTP request on the todolist server, to create a new item with this email's subject as the content/description. This lets me capture things todo from anywhere, and be confident that the action will not get lost in my inbox. 

![overview]({{ site.baseurl }}/assets/images/GmailParsingPython/overview.png)

Note: of course there is no need to use two separate raspberry pis to do this, it just so happens that my todolist server runs on one of my raspberry, while I wanted to install this gmail monitoring script on another one. 

It is one of those (rare) projects where you think you will struggle for hours to get something running, but then try the first google link that looks right, and...succeed in 10 minutes. 
I followed instructions from [this page](http://storiknow.com/automatic-cat-feeder-using-raspberry-pi-part-two/), and it all worked perfectly, so a tip of my hat to the author of this page.

As I usually do, I duplicated the exact steps **I** took (which are 99% those from the pages...but not quite), in case the link gets broken, and more generally because there is a higher likelihood that I will understand my own notes than someone else's, when I inevitably have to fix this two years from now...

* TOC
{:toc}

---

## Prerequisites

I am using a Raspberry Pi3 Model B+, installed with Raspbian Stretch. Not that it matters much, as long as it has python and pip. For the script to work, two python libraries must be installed though:

* the email client to access the gmail account
* the library to perform HTTP requests

To do so:

	sudo pip install imapclient
	sudo pip install requests

## Source code

The code is derived from [this page](http://storiknow.com/automatic-cat-feeder-using-raspberry-pi-part-two/) again, and stored in a dedicated github [repo](https://github.com/jheyman/gmailtodogateway.git) of mine.
It's just a big infinite loop, that does the following every 15 minutes:

* search for emails in the inbox with "todo" in the subject
* if any is found, use the rest of the subject line as text to create a new todo item via an HTTP request
* logout from the server.

## Getting an application password from Gmail
To access the Gmail server, an application password is required:

* Log into your gmail account
* Go to the [Sign-in and security page](https://myaccount.google.com/security)
* Under the Signing in to Google section, click the 2-Step Verification menu, then follow the instructions to **enable 2-Step Verification**
* Back in the Sign-in and security page right under the 2-Step Verification button go to the **App passwords** section. 
* Generate a password (16 digits+3 spaces) .

## Installing the service

To make the script into a background service

* create a `/home/pi/gmailtodogateway directory` on the pi
* copy `gmailtodogateway.py` in it and make sure it has execution rights
* copy `gmailtodogateway.ini` in it and update it for your own case (gmail account name, and application code retrieved above)
* copy the `gmailtodogateway.sh` script to `/etc/init.d`, make sure it has execution rights too

Then activate this service using:

	sudo update-rc.d gmailtodogateway.sh defaults

Upon next reboot (or `sudo service gmailtodogateway start`), the script should run, and capture logs in `gmailtodogateway.log` in the same directory.
Then just send an email to the account mentionned in the .ini file, with "todo [whatever text]" in the subject (body can stay empty), it should be picked up by the script.










