---
layout: page
title: Setup Nginx and PHP on Raspberry Pi
tagline: Setting up Nginx and PHP on Raspberry Pi
tags: raspberry pi, nginx, php
---
{% include JB/setup %}

This page logs the installation steps to get **Nginx** web server and **PHP** server up and running on Raspberry pi. I use them in particular in ([this]({{ site.baseurl }}/pages/ShoppingListWidget)) and ([this]({{ site.baseurl }}/pages/PostitListWidget)) projects, and more generally as the basis for all web-based applications I am running on my home's main raspberry pi.

### Install & configuration 

First install nginx and php, and create the main directory that will contain the required html/php files to be served:

	sudo apt-get install nginx php5-fpm php5-cgi php5-cli php5-common
	sudo useradd www-data
	sudo groupadd www-data 
	sudo usermod -g www-data www-data 
	sudo mkdir /var/www 
	sudo chmod 775 /var/www -R 
	sudo chown www-data:www-data /var/www 

Create a site config file in `/etc/nginx/sites-available/` (replace MYSITE by actual site name, and MYPORT by desired http port the site will be available on, e.g. 80)

	sudo nano /etc/nginx/sites-available/MYSITE

Here is a basic template I am using:

	server {
	        listen       MYPORT;
	        server_name  MYSITE;
	        root   /var/www/MYSITE;
	        index  index.html index.htm index.php;

	        location ~ \.php$ {
        	fastcgi_pass   127.0.0.1:9001;
        	fastcgi_index  index.php;
        	fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        	include /etc/nginx/fastcgi_params;
		}
	}

Finally create a symbolic link in `/etc/nginx/sites-enabled/` to activate this site:

	sudo ln -s /etc/nginx/sites-available/MYSITE /etc/nginx/sites-enabled/MYSITE

You can create as many sites as needed, and enable/disable them at will by just adding/removing such a simlink in the `/etc/nginx/sites-enabled` directory.

### Compatibility with Logitech Media Server

By default, the PHP CGI interface is using port 9000 on localhost. This turned out to be a problem for me, as it conflicts with the installation of Logitech Media Server that also uses port 9000, and that I am using in [this]({{ site.baseurl }}/pages/MultiRoomHomeAudio) project. So I updated the PHP config file to change the port number from 9000 to 9001:

	sudo nano /etc/php5/fpm/pool.d/www.conf 

replacing the existing `listen` line by:

	listen = 127.0.0.1:9001

Consequently, one also needs to update the CGI port number to 9001 in Nginx sites config files (i.e. inside all files in `/etc/nginx/sites-available`)

Finally, restart PHP and Nginx:

	sudo service php5-fpm restart 
	sudo service nginx restart