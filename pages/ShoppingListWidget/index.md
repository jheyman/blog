---
layout: page
title: ShoppingList android widget
tagline: A custom shopping list widget for Android devices
tags: android
---
{% include JB/setup %}

This app was developed in the context of my [HomeHub]({{ site.baseurl }}/pages/HomeHubTablet) project, as a replacement for our pen-and-paper shopping list. The main feature I wanted to have is the ability to add/remove something in the list from anywhere, i.e. from my smartphone, while storing the actual list data on my server at home and being able to display it on (and update from) the homehub tablet.

The app is made of two parts:

* a **database** storing the shopping list items
* an **Android front-end app** to view/add/remove items from the list

The database side uses SQLite3, running on the web server on my raspberry pi at home.
The android apps gets data from the database through a HTTP request, and receives JSON data in return.

![ShoppingList Overview]({{ site.baseurl }}/assets/images/ShoppingListWidget/shoppinglist_overview.png)

### Server side

The three php files used to interact with the database are very simple, and of very poor quality (error management is mostly missing, no protection against SQL injections, you name it...). This is just the absolute minimum to get things working, and it suits my purpose :)
The three files are available [here](https://github.com/jheyman/ShoppingList_ServerSide)

### Android side

Since the shopping list is meant to be constantly accessible directly from the homescreen, the application was created as a Widget app, which is significantly different than a regular Android app (and comes with some limitations too). The base idea is that the widget being displayed is a RemoteViews provided by something else (typically a regular android app). The widget gets refresh notifications from the system at a preconfigured period (greater than 30 minutes though). The widget core is an AppWidgetProvider, which is a broadcast receiver that is registered for these refresh/update messages. It manages the overall widget, controls its layout, deals with the user clicks, etc...
Since the main part of the layout is a ListView, the AppWidgetProvider delegates another class (a RemoteViewsService) as the content provided for the actual content of the list. 

A high-level view of the app is given below:

![ShoppingList app Architecture]({{ site.baseurl }}/assets/images/ShoppingListWidget/ShoppingListWidget_arch.png)

The code is available [here](https://github.com/jheyman/ShoppingListWidget)

<br>

