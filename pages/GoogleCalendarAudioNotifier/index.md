---
layout: page
title: Audio notifications from Google calendars
tagline: Playing audio reminders of events extracted from google calendars
tags: google, calendar, python, text-to-speech, audio, raspberry pi, microsoft
---
{% include JB/setup %}

The purpose of this project was to leverage the audio system I installed at home (see [here]({{ site.baseurl }}/pages/MultiRoomHomeAudio)) to broadcast audio notifications upon specific triggers. The main usecase for me was to get audio reminders of important "todo" tasks. I was already using Google calendar regularly and its built-in notifications are just fine, but a pop-up and sound on my phone are not so efficient when the phone happens to be in another room...<br><br>

So, the idea is to create a program that will continuously poll my google calendar, and play an audio notification when a given calendar event's start time is reached. Several steps are involved:<br><br>

* **Retrieving calendar events**: this requires authenticating and interfacing with Google Calendar API, which turned out to be easy enough once on the right track. <br><br>
* **Generating an audio notification** corresponding to the event: I chose to use text-to-speech voice synthesis, mostly as an experiment to figure out if this would turn out to be annoying or convenient on the long run.<br><br>
* **Executing the polling loop as a background task/daemon**:  my home's main raspberry pi server once again turned out to be the perfect place to host this.<br><br>

Here's a high level overview of the system:
![overview]({{ site.baseurl }}/assets/images/GoogleCalendarAudioNotifier/gcalnotifier_overview.png)

* TOC
{:toc}

---

### Raspberry pi setup

As usual, everything begins with installing a default Raspbian distribution from raspberrypi.org

1) transfer raspbian image to SD card:

    sudo dd bs=1M if=XXX-raspbian.img of=/dev/xxx

2) plug-in a mouse/keyboard/HDMI display and boot-up

3) Use `raspi-config` to configure the raspberry as required (e.g. keyboard layout). Specifically for this project, don't forget to set the correct time zone (In `Internationalization options` => select appropriate area and city)

4) Plug wi-fi dongle, boot to graphical environment, configure wifi settings.<br><br>

The required configuration steps for the audio part are described in [this project]({{ site.baseurl }}/pages/MultiRoomHomeAudio), especially the ALSA configuration required to be able to use a single audio output for both these calendar notifications, other audio services.

### Setting up the Google (calendar) API

Google provides an API to very easily access your calendar data, and a Python client is available for this API. It does require however a slightly complex authentication process, which is the part that required the most effort to get right, especially since instructions out there on the internet usually do not specify which API version they are based on. Since Google calendar v2 API was deprecated in November 2014, the instructions below apply to v3 API<br><br>

The authentication process will require you to have two things available:

* A **client Id**for the OAuth2 authentication protocol, and the associated secret code
* An **API key** (a.k.a. **developerKey**)<br><br>

1. Go to [http:\\console.developers.google.com](http:\\console.developers.google.com)
2. Create a new project
3. In the `API & auth \ APIs` section, make sure calendar API is enabled
4. In the `API & auth \ Credentials` section, create an **OAuth client ID** (type: "Web application")
	* configure consent screen (no useful if like me you intend to only use this client ID for personal purposes, but still required)
	* the generated client id will look something like this: `xxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com`
	* a "client secret" is also generated: click on `Download JSON` to get the client secret conveniently stored inside a file (e.g. `client_secret.json`) 
	* I also had to add `https://localhost:8080/` in the `Authorized javascript origins` and `Authorized Redirect URIs` sections, to complete the first-time authentication.
5. Create an **API key** (type: "Server key")<br><br>

Once you have these clientID, client secret, and developer/API key, a one-time authentication process is required: this involves connecting to the API through a client of your choosing, and completing the authentication process in a browser window. Since I am using a headless Raspberry pi setup, it was not quite convenient to perfom this initialization directly on the pi. Not to worry, this step can just as well be performed on the host machine, and the generated file will be usable on the pi as is.<br><br>

So, to install the Python client for Google API (on both the host and the raspi):

	sudo apt-get install python-setuptools 
	sudo easy_install --upgrade google-api-python-client
	sudo easy_install --upgrade pytz
	sudo apt-get install python-gflags 

Then, a template python script to generate the credential file is available on google developer site ([here](https://developers.google.com/google-apps/calendar/instantiate)). Alternatively, I archived it [here](https://github.com/jheyman/gcalnotifier/blob/master/credentials_gen.py). It is the same file, except I renamed `calendar.dat` into `credentials.dat` which sounded clearer to me.<br><br>

Execute the script, it should open a browser window where you can complete the process. Once this is done, a `calendar.dat` (`credentials.dat` in my version of the template) file will have been generated, containing the appropriate information for permanent access to the Google API  

---

### Retrieving calendar events

Once the authentication part is ok, retrieving all the calendar events is as simple as creating a `service` object and executing a command like so:

	events = service.events().list(singleEvents=True, calendarId='<your calendar Id').execute()	

To verify what your calendar Id is, log to your calendar the usual way, go to the settings page, the calendar Id is mentionned in the "Calendar Address" section. Mine just equals my email address.
The format of the returned events is available in the Google Calendar API reference ([here](https://developers.google.com/google-apps/calendar/v3/reference/events))

---

### Generating audio notifications

There are some open source voice synthesis solutions, but after testing a few (Espeak with MBROLA voices, PICO) I quickly came to the conclusion that their quality was not at the right level (especially in terms of WAF for a home installation). Since this project required a permanent internet connection anyway (for google calendar polling) I looked at online services.<br><br>
I initially used the Google translate text to speech API, which has superb quality. However, free use of this API is largely undocumented, Google Translate is mostly a paid service. It worked fine for a while (throughout 2014) but broke a first time due to some API change, which I fixed mid-2015 (see below). When the API broke a second time in December 2015 due to Google's decision to require specific tokens in the requests, I gave up and looked for an alternative.<br><br>

Ironically enough, the easiest way out I found was to migrate to **Microsoft Translate** service, which was done in 15 minutes and produces speech quality which is just as good as Google's service, and is (for now) free of charge for very low frequency requests, with a well documented API.<br><br>

All was good until December 2016, when Microsoft dedided to suspend its translate API on Azure DataMarket and I had to migrate the code to use the new "Cognitive Services" on their new Azure platform (keeping track of the names they are using is a job by itself...). That required a moderate effort, but this keeps reminding me that I would need a LOCAL speech engine with equivalent quality, to get out of this endless loop of migration every year or so...

---

#### Setting up and using Microsoft's Bing Text To Speech API

As of end of 2016, the Microsoft Translate API on azure datamarket is being closed. I had to update the code to use the new Microsoft text to speech service ("Bing Text To Speech API" that comes as part of Microsoft Cognitive Services on Azure platform)

The API is documented [here](https://www.microsoft.com/cognitive-services/en-us/Speech-api/documentation/API-Reference-REST/BingVoiceOutput).<br><br>

Steps:

* Register to get a free account [here](https://www.microsoft.com/cognitive-services/en-US/subscriptions)
* Write down "Key 1" value, it is used in the python code to get an access token to use the text to speech service:<br><br>

The code to get the token boils down to:

<pre><code>headers = {"Ocp-Apim-Subscription-Key": microsoftKey}
url = 'https://api.cognitive.microsoft.com/sts/v1.0/issueToken'
r = requests.post(url, data = {'key':'value'}, headers=headers)
accesstoken = r.text.decode("UTF-8")</code></pre>

Once the token is available, it can be used to submit a text to speech request, and get raw sound data returned:

<pre><code>def speak(theText):

	f = open("tmp.wav", 'wb')

	body = "<speak version='1.0' xml:lang='fr-FR'><voice xml:lang='fr-FR' xml:gender='Female' name='Microsoft Server Speech Text to Speech Voice (fr-FR, Julie, Apollo)'>"+theText+"</voice></speak>"

	headers = {"Content-type": "application/ssml+xml", 
	            "X-Microsoft-OutputFormat": "riff-16khz-16bit-mono-pcm", 
	            "Authorization": "Bearer " + accesstoken, 
	            "X-Search-AppId": "07D3234E49CE426DAA29772419F436CA", 
	            "X-Search-ClientID": "1ECFAE91408841A480F00935DC390960", 
	            "User-Agent": "TTSForPython"}
            
	url = 'https://speech.platform.bing.com/synthesize'

	r = requests.post(url, data = body, headers=headers)
	logger.info(str(r.status_code))
	logger.info(r.reason)

	f.write(r.content)
	f.close()

	os.system("aplay tmp.wav")</code></pre>

 

#### (OBSOLETE) Setting up and using Microsoft Translate API on DataMarket

* If necessary, create a Microsoft account.
* Register it on [Microsoft Azure Marketplace] (https://datamarket.azure.com/home)
* Subscribe to the [Translator API service](http://www.aka.ms/TranslatorADM), and select the free service option (limited to processing 2 million characters per month)
* Register [here](https://datamarket.azure.com/developer/applications/register) with a `clientID` and `clientSecret` of your choosing.<br><br>

Once this is done, it is then possible to make requests to the Microsoft Translate online API, and among other things to get voice data corresponding to a string of text. There is a multitude of ways to access the API, I of course chose the python way, using the very nice [mstranslator](https://pypi.python.org/pypi/mstranslator) library.

	sudo apt-get install python-pip
	sudo pip install mstranslator

I just use the `speak_to_file` function of this library, then issue a system command from Python to play the generated WAV file.

<pre><code>from mstranslator import Translator
trans = Translator([MicrosoftClientID], [microsoftClientSecret])
f = open("tmp.wav", 'wb')
trans.speak_to_file(f, theText, "fr", format='audio/wav', best_quality=True)
os.system("aplay tmp.wav")</code></pre>

**Note**: to avoid an SSL connexion warning, I also had to do this:

	sudo apt-get install build-essential
	sudo apt-get install libffi-dev
	sudo pip install pyopenssl ndg-httpsclient pyasn1

    
#### (OBSOLETE) Setting up and using Google translate

The conversion of a text string to a voice output boils down to a one-liner command, stored in the `tts.sh` script:

	#!/bin/bash
	say() { local IFS=+;/usr/bin/mplayer -ao alsa -really-quiet -noconsolecontrols -http-header-fields 'User-Agent: dummy' "http://translate.google.com/translate_tts?tl=fr&q=$*&client=t"; }
	say $*

**Note**: you might need to install mplayer if not already present 

	sudo apt-get install mplayer

**Note**: I added the `User-Agent: dummy`and `&client=t` parts during August 2015, after Google decided to protect its translate/tts API with a captcha mechanism, making the previous basic HTTP request fail. See [this link](http://stackoverflow.com/a/31791632/1473219) for details.<br><br>

**Note**: I adjusted the `tl` parameter in the URI to select French voice synthesis. Use `tl=en` for English voice synthesis.<br><br>

**Note**: As of December 2015, a `token` parameter is required for this to (maybe) work again. People willing to hack their way around can look at [this](http://stackoverflow.com/questions/9893175/google-text-to-speech-api) thread, personally I gave up.

---

### Polling & notification script

I cooked up a Python script that performs the following operations:<br><br>

* Read a config file (using `ConfigParser` python lib) to retrieve my developer key, specify the list of calendar Ids I want to manage audio notifications for, the path to the voice synthesis script, the name of the file the script will log traces into, and a default value for the reminder time to use if calendar events do not have a reminder time set: 

<pre><code>[config]
developerKey = xxxxxxxxxxxxxxxxxxxx
microsoftKey = xxxxxxxxxxxxxxxxxxxx
calendars = xxxxcalendarID1,xxxxcalendarID2
log_filename = /tmp/gcalendarpolling.log
reminder_minutes_default = 5
</code></pre>

* Setup the logging file: I borrowed the excellent piece of code from [here](http://blog.scphillips.com/2013/07/getting-a-python-script-to-run-in-the-background-as-a-service-on-boot/)
<br><br>
* Authenticate to Google API, using the `credentials.dat` and `client_secret.json` files, and the developer key from the config file
<br><br>

* Enter the polling & notification loop<br><br>
    * Get the events from all specified calendars, filtering the request for start times between "now" and "now + 30 days".<br><br>
    * For each event, retrieve its reminder time value, if any.<br><br>
    * If the time is equal to the start time of the event minus the reminder time, call the voice synthesis script to announce the event, using the calendar event summary as the input text.<br><br>
    * Sleep for 30 seconds before looping to check events again.<br><br>

**Note**: I retrieve events planned for the next 30 days, just to cover the unlikely case where I would have set a very very long reminder of several days. 30 days-worth of calendar events is not a huge amount of data to deal with anyway.

### Making the script a background service/daemon

Once the script was finalized, I turned it into a background service/daemon on the raspberry, using [these](http://blog.scphillips.com/2013/07/getting-a-python-script-to-run-in-the-background-as-a-service-on-boot/) great instructions. My version is available [here](https://github.com/jheyman/gcalnotifier/blob/master/gcalnotifier.sh), I just added the `--chdir` option in the `start-stop-daemon` command to set the working directory of the service to be the one the script and its associated files are stored in, so that no absolute paths need to be specified inside the script. Just copy this script to `/etc/init.d`, make sure it has execution rights, then add activate this service using:

	sudo update-rc.d gcalnotifier.sh defaults

### Source code

The python script & config files is available [here](https://github.com/jheyman/gcalnotifier).

--- 

### Integration with MultiRoomHomeAudio

Since I happened to host this polling & notification script on the same raspberry pi as one already hosting a music streaming client (see [this project]({{ site.baseurl }}/pages/MultiRoomHomeAudio)), I modified the script to interact with the audio controller: 

* when the script is about to announce an event, it first notifies the audio controller, that will mute the ongoing music playback (if any) and activate the audio amplifier (if required). 
* a start jingle is played
* the event name is played, and repeated once
* and end jingle is played
* the script then notifies the audio controller again, to resume music playback (if applicable) and disable the audio amplifier again (if applicable). Note also that this integration requires the ability to share the sound card output, as explained in the setup part.


