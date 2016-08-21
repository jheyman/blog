---
layout: page
title: PostitList android widget
tagline: A custom post-it list widget for Android devices
tags: android
---
{% include JB/setup %}

This app was developed in the context of my [HomeHub]({{ site.baseurl }}/pages/HomeHubTablet) project, as a replacement for our paper post-it notes. The main feature I wanted to have is the ability to add/remove a note from anywhere, i.e. from my smartphone, while storing the actual list data on my server at home and being able to display it on (and update from) the homehub tablet.

The app is made of two parts:

- a **database** storing the notes
- an **Android front-end** app to view/add/remove notes from the list

The database side uses SQLite3, running on the web server on my raspberry pi at home.
The android apps gets data from the database through a HTTP request, and receives JSON data in return.

![ShoppingList Overview]({{ site.baseurl }}/assets/images/PostitListWidget/postitlist_board.png)

### Server side

The three php files used to interact with the database are very simple, and of very poor quality (error management is mostly missing, no protection against SQL injections, you name it...). This is just the absolute minimum to get things working, and it suits my purpose :)
The three files are available [here](https://github.com/jheyman/PostitList_ServerSide)


### Android side

The android side consists in a stack widget, with app mechanics being very very similar to what I describe in [ShoppingListWidget]({{ site.baseurl }}/pages/ShoppingListWidget)  

The code is available [here](https://github.com/jheyman/PostitListWidget)

<br>



