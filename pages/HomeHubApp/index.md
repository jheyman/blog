---
layout: page
title: Home automation hub Android app 
tagline: An Android app as a comman center for home automation
tags: android, home automation
---
{% include JB/setup %}

* TOC
{:toc}

---

### Overview

A few years ago I installed a large touchscreen in the main entrance of our house, to centralize various information and provide access to some home automation features.
The hardware setup has been quite stable so far:

* a VSD220 **display with touchscreen**, running Android (described [here]({{ site.baseurl }}/pages/HomeHubTablet))
* an **IR sensor** used to detect when someone walks by the display, and wake it up from sleep mode (described [here]({{ site.baseurl }}/pages/AndroidAutoWake))

But the software application side has changed a lot over time, based on experience from actual day-to-day usefulness of the various features. The one requirement that never changed so far is to have all information & controls available on a single page/screen, with no need to navigate anywhere else. The content shown and implementation is what changed most over time. I initially went for the approach to implement individual homescreen widgets, and place them all on one page. Links to the implementations of these individual widgets is included in ([here]({{ site.baseurl }}/pages/HomeHubTablet)) 

But over time I encountered two issues with this approach:

* the (OLD!) Android version installed on the VSD220 is 4.0.5, and on this device at least, happens to leave quite a lot of screen real estate inaccessible (yellow areas below) to homescreen widgets:
![Space lost]({{ site.baseurl }}/assets/images/HomeHubApp/screenshot_spacelost.png)

* the use of many individual homescreen widgets puts a heavy load on the memory and the processor, which may be fine on a decent smartphone, but makes my 2013 VSD220 display struggle to keep up. 

Overall, the result was no as robust as I needed it to be. So I decided to reuse most of the code from these individual widgets, and integrate them into a single fullscreen application. 

Here is a screenshot of the resulting app:

![Screenshot]({{ site.baseurl }}/assets/images/HomeHubApp/screenshot.png)

### Structure

The app currently includes the following features:

* a **graph viewer**, showing water consumption and ping history from home network devices
* a **photo frame**, that displays a randomly picked image from our NAS
* a **weather information & agenda** for the next few days
* a **music player**, that controls music streaming in the living room
* a **shopping list** (which content is also accessible remotely)
* a prioritized **TODO list**
* a **Z-wave devices status & control**
* a **network devices status** monitor

![Structure]({{ site.baseurl }}/assets/images/HomeHubApp/overallstructure.png)

---

### Implementation 

The app is mostly a front-end to many external resources, accessed over Wifi from the VSD220:

![Context]({{ site.baseurl }}/assets/images/HomeHubApp/homehubapp_context.png)

* the **HomeDataLogging database** stored on the NAS is documented [here]({{ site.baseurl }}/pages/HomeDataLoggingServer), and used by both the [wireless water meter]({{ site.baseurl }}/pages/WirelessWaterMeter) and the [Ping monitor](https://github.com/jheyman/HealthMonitor)
* the web interface (PHP) to the **Photo database** is described in the [original photo frame widget]({{ site.baseurl }}/pages/PhotoFrameWidget) page
* the web interface to the **Z-wave server** is described in the [original z-wave widget]({{ site.baseurl }}/pages/ZWaveWidget) page, though the code was refactored in the process.
* the web interface (PHP) to the **Shopping list database** is described in the [original shopping list widget]({{ site.baseurl }}/pages/ShoppingListWidget) page, and the 
access to the **Todo list database** is very similar.
* the music player interfaces with an external **Logitech Media Server**, that accesses music files on the NAS
* the **weather info** is retrieved through the OpenWeatherMap web API, and the **agenda events** are retrieved through the Google Calendar API

#### Top level layout

Each individual feature is package as an Android `Fragment`, that has its own internal layout definition. All fragments are assembled into the overall application layout with the following structure:

![DetailedLayout]({{ site.baseurl }}/assets/images/HomeHubApp/homehubapp_detailedlayout.png)

Even though `Fragments` are mostly useful when dealing with responsive/dynamically reconfigurable layouts, I find them useful to manage a complex layout hierarchy. 

Relative **sizing** of the areas is adjusted mostly through the `layout_weight` attributes of each layout level.

---

#### Common Fragment implementation

Each Fragment is implemented around a common baseline:

##### Main class

Deriving from `Fragment` base class, it inflates the specific fragment layout inside the view:

<pre><code>@Override
public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

    super.onCreateView(inflater, container, savedInstanceState);
    return inflater.inflate(R.layout.[fragment_name]_layout, container, false);
}</code></pre>

The class embeds a self-refresh mechanism for the Fragment, based on a `Handler` relaunching a `Runnable` function at regular time intervals:

<pre><code>public Handler handler = new Handler();
private static int REFRESH_DELAY = 60000;

Runnable refreshView = new Runnable()
{
    @Override
    public void run() {
        refresh();
        handler.postDelayed(this, REFRESH_DELAY);
    }
};

@Override
public void onActivityCreated(Bundle savedInstanceState) {

    [...]
    handler.post(refreshView);
    [...]
}</code></pre>

It also implements a `BroadcastReceiver`, and its `onReceive` function, that will manage all incoming `Intents`

##### Service class

All long-running actions of the Fragment (e.g. HTTP requests to remote servers) are executed in the context of a specific `IntentService`, i.e. as a background action to avoid blocking the UI thread. Upon completion of the background action, the service class sends a specific `Intent` back to the main class to notify of action completion.

##### Item class

In several of the Fragments, `ListView` objects are used, and specific classes implemented the items that will populate these lists.

---

#### Graph Viewer Fragment

The graph viewer fragment is a direct adaptation of my [original graph viewer homescreen widget]({{ site.baseurl }}/pages/GraphViewerWidget), with some clean-up of the code that was specific to homescreen widget mechanics. It gets  data by querying my HomeData **InfluxDB** database, for the last XX hours.

![GraphViewer]({{ site.baseurl }}/assets/images/HomeHubApp/graphviewer.png)

---

#### Photo Frame Fragment

The photo frame fragment is a direct adaptation of my [original photo frame homescreen widget]({{ site.baseurl }}/pages/PhotoFrameWidget), with some clean-up of the code that was specific to homescreen widget mechanics. It accesses the NAS shared photo folder, randomly picks a photo file, and displays it. The photo is automatically refreshed every minute.

The envelope icon allows to send the current photo as an attachment in an email.

![Photoframe]({{ site.baseurl }}/assets/images/HomeHubApp/photoframe.png)

---

#### Z-Wave devices control Fragment

The z-wave status & control fragment is a direct adaptation of my [original z-wave homescreen widget]({{ site.baseurl }}/pages/ZWaveWidget), with some clean-up of the code that was specific to homescreen widget mechanics. It queries the remote Z-way server, gets the state of the each device, and updates the corresponding bitmap accordingly (active or inactive). Also, a click action is registered on each bitmap: when the user clicks on the bulb/plug icon, it sends a corresponding toggle command to the Z-way server to turn it on or off.

![ZWaveDevices]({{ site.baseurl }}/assets/images/HomeHubApp/zwavedevices.png)

---

#### Network devices monitor Fragment

The Network devices monitor fragment was created specifically for this app, it basically just shows the latest ping status of each predefined device, from the data already gathered by the Graph Viewer fragment from the Home database. Depending on the status retrieved, it updates the bitmap image accordingly to the green or red version.

![PingMonitor]({{ site.baseurl }}/assets/images/HomeHubApp/pingmonitor.png)

---

#### Weather & Agenda Fragment

This fragment implements two features:

* querying and showing the weather forecast for the next 5 days
* querying and showing the calendar events for the next 5 days

![Weather]({{ site.baseurl }}/assets/images/HomeHubApp/weatheragenda.png)

##### Weather information

The weather information is retrieved using the [Open Weather Map](https://openweathermap.org/) API, with a free account.

A simple POST request to the url `http://api.openweathermap.org/data/2.5/weather?q=[location]&APPID=[accountAPI ID]` allows to get the 5-day forecast, in 3h steps. The returned JSON-formatted data is then parsed to create a `WeatherItem` for each 3h time step, which includes an ID corresponding to the OpenWeatherMap code for the forecasted weather, a temperature forecast, and a humidity forecast.

The excellent Weather Icons set from [https://github.com/erikflowers/weather-icons](https://github.com/erikflowers/weather-icons) is used, to get a bitmap corresponding to the weather ID.

##### Calendar events

The calendar events are retrieved from the device's local calendar (which happens to be sync'ed to one of my gmail accounts) through a query to the Android `CalendarContract`:

<pre><code>String[] EVENT_PROJECTION = new String[]{
        CalendarContract.Events.TITLE,
        CalendarContract.Events.EVENT_LOCATION,
        CalendarContract.Instances.BEGIN,
        CalendarContract.Instances.END,
        CalendarContract.Events.ALL_DAY};

ContentResolver resolver = getContentResolver();
Uri.Builder eventsUriBuilder = CalendarContract.Instances.CONTENT_URI.buildUpon();

// get the next 5 days worth of events
long timestamp_start = Utilities.getCurrentTimeStamp();
long timestamp_end = timestamp_start + 5*24*60*60*1000;

ContentUris.appendId(eventsUriBuilder, timestamp_start);
ContentUris.appendId(eventsUriBuilder, timestamp_end);

Uri eventUri = eventsUriBuilder.build();

mDataCursor = resolver.query(eventUri, EVENT_PROJECTION, null, null, CalendarContract.Instances.BEGIN + " ASC");</code></pre>

The list of events for the day is then shown below the corresponding day of the weather forecast.

---

#### Music player Fragment

The music player is only just a front-end to a remote Logitech Media Server running in my main raspberry Pi, and to a Squeezelite client driving the audio in our living room.

The app interacts with LMS using its command line interface (CLI) available over **Telnet**. LMS echoes back any incoming command, then providing result data (if any), and finally sending a newline character. The only catch is that potential parameters need to be URL-encoded, and returned data URL-decoded. 

A typical Telnet command to a LMS client includes the MAC address of the client followed by the command:

	b8:27:eb:d4:00:99 title ?

which returns the echoed command and title of the song currently at the top of the playlist:

	b8%3A27%3Aeb%3Ad4%3A00%3A99 title Sweet%20Home%20Chicago

##### Album database query

Upon startup, the music player fragment queries LMS to get the full list of available albums:

	b8:27:eb:d4:00:99 albums 0 999 tags:jla sort:artflow

the "tags:jla" option specifies to return artwork_track_id (j) and album_name (l) and artist name (a), and sorts returned list by artist.

The album cover art can be retrieved from the server using the `artwork_track_id` value also returned (when available), through a request at the following address:

	http://[LMS IP address]:[LMS port]/music/[artwork_track_id]/cover_[size]x[size].jpg?player=[MAC address]

The music player fragment stores the list of returned album info & artwork, and randomly loads one of them.
Later, when user clicks on the album cover image, a specific fullscreen Activity is started to display in a `GridView` the full list of available albums, and let the user select one:

![Album list]({{ site.baseurl }}/assets/images/HomeHubApp/albumlist.png)

##### Info & Controls

The interface shows the currently selected album cover, artist name, album name, and current song, and has control icons that will send corresponding actions to the LMS.

![Music player]({{ site.baseurl }}/assets/images/HomeHubApp/musicplayer.png)

A click on the second icon pops-up the song list of the current album:

![Song list]({{ site.baseurl }}/assets/images/HomeHubApp/songlist.png)

---

#### Shopping List Fragment

The shopping list fragment is a direct adaptation of my [original shopping list widget]({{ site.baseurl }}/pages/ShoppingListWidget), with some clean-up of the code that was specific to homescreen widget mechanics. The look & feel of this fragment is not really consistent with other fragments on the page, but I kinda like it this way.

Nothing fancy, this is a simple ListView populated with data from a remote SQLite database, with simple layout tricks to make it look like a paperpad.

![Shopping list]({{ site.baseurl }}/assets/images/HomeHubApp/shoppinglist.png)

---

#### Todo List Fragment

The Todo list fragment is a new take on my [original post-it list widget]({{ site.baseurl }}/pages/PostitListWidget), with a simpler ListView style display of the todo notes gathered from a remote SQLite database. 

![Todo list]({{ site.baseurl }}/assets/images/HomeHubApp/todolist.png)

---

#### Various implementation tips

##### Custom text font

In my previous widget implementations, I took the hard path to using custom text fonts: rendering them manually at specific coordinates inside a bitmap. Silly me, it turns out there is a MUCH simpler way:

* put a font file (e.g. TTF file) in the `assets\font` directory of the app project
* then define a custom class derived from TextView using this font file:

<pre><code>public class CustomTextView extends TextView {

	[...]

    @Override
    public void setTypeface(Typeface tf, int style) {
        Typeface normalTypeface = Typeface.createFromAsset(getContext().getAssets(), [path to REGULAR font]);
        Typeface boldTypeface = Typeface.createFromAsset(getContext().getAssets(), [path to BOLD font]);
        Typeface italicTypeface = Typeface.createFromAsset(getContext().getAssets(), [path to ITALIC font]);

        if (style == Typeface.BOLD) {
            super.setTypeface(boldTypeface);
        }
        else if (style == Typeface.ITALIC) {
            super.setTypeface(italicTypeface);
        } else {
            super.setTypeface(normalTypeface);
        }
    }

}</code></pre>

The `CustomTextView` type can then be used in the app's XML layout files, just like a regular `TextView`, e.g.:

```xml
<com.gbbtbb.homehub.CustomTextView
    android:id="@+id/textView"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:gravity="center"
    android:text="custom font !"
    android:textColor="#000000"
/>
```

##### Exception logger

When the app is running on the VSD220, if something bad happens it may be difficult to figure out what went wrong, since android logs have a limited size and traces of the problem will likely be gone when the problem is detected. For lack of a good permanent logging system (someday, maybe) as a minimum measure I added a handler at application level that catches any unhandled exception, and logs the stack trace to a timestamped file for later analysis.

<pre><code>public class HomeHubApplication extends Application
{
    [...]

    public void onCreate ()
    {
        loggingPath = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS).toString();
        Log.i(TAG, "App crashes will be logged into " + loggingPath);

        // All crash log code adapted from here: http://stackoverflow.com/questions/19897628/need-to-handle-uncaught-exception-and-send-log-file
        Thread.setDefaultUncaughtExceptionHandler (new Thread.UncaughtExceptionHandler()
        {
            @Override
            public void uncaughtException (Thread thread, Throwable e)
            {
                handleUncaughtException (thread, e);
            }
        });
    }

    [implementation of handleUncaughtException...]
}</code></pre>

##### Rounder corners

All fragments in the app have round corners. This is achieved by creating a custom shape, stored under `res/drawable/[name].XML`, with content similar to this: 

```xml
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#FFFFFF"/>
    <stroke android:width="2dip" android:color="#000000" />
    <corners android:radius="10dip"/>
    <padding android:left="0dp" android:top="0dp" android:right="0dp" android:bottom="0dp" />
</shape>
```

and then declaring the fragment's layout background as being this shape:

<pre><code>android:background="@drawable/[name of the XML file]"
</code></pre>

##### Dynamically measuring View dimensions

In a few parts of the code, there is a need to determine the actual dimensions in pixels of a given View on the screen. Since layouts are rendered dynamically at startup, a safe way to read a View's dimensions is to register a callback on the layout engine, that will be executed only once everything has been rendered:

<pre><code>ViewGroup parentLayout = ((ViewGroup) getView().getParent());
parentLayout.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
    @Override
    @SuppressWarnings("deprecation")
    public void onGlobalLayout() {

        //dimensions could be measured here

        // remove observer now
        hsv.getViewTreeObserver().removeGlobalOnLayoutListener(this);

        // It is now also safe to refresh the agenda itself, with correct dimensions
        handler.post(refreshView);
    }
});</code></pre>

### Source Code

The whole source code for this app is available [here](https://github.com/jheyman/HomeHub), as an Android Studio project.

### Todo list

* robustify the heck out of the app, to gracefully handle any possible wrong inputs, network errors, low memory, so that it can run for months. Not quite the case yet.
* improve the music player with features we'll feel are most useful to us after using this version for a while

### Lessons learned

* Code for a regular Android app is SO much more straightforward than the nightmare of developing robust homescreen widgets on a low-end android device. This is refreshing...
* OpenWeatherMap free API was quite simple to use, let's hope it won't break or turn into a paid scheme anytime soon.
* Projects that I begin thinking "hey, I could maybe JUST repackage this existing code into a slightly better version" often turn out to become multi-weeks refactoring parties.
* but mostly, so far I am quite pleased with the actual day to day value of the app.
