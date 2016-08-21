---
layout: page
title: Home data logging server
tagline: Storing homedata with InfluxDB on Raspberry pi
tags: raspberry pi, influxdb, database
---
{% include JB/setup %}

For various projects I had the need of a centralized repository for logging data from multiple sensors at home. I initially cooked up a small SQLite database and associated PHP scripts to access it, but this turned out to be impractical and not scaling well to a large amount of logging data. I stumbled upon **InfluxDB**, which is a Time Series Database, i.e. a database optimized for storing and retrieving timestamped data. It is implemented in Go language (which does not matter much except during installation)<br><br>

InfluxDB is used to store values captured from various sensors and pushed to the database via HTTP POST requests. It also serves the HTTP GET requests from the display application(s).

![Overview]({{ site.baseurl }}/assets/images/HomeDataLoggingServer/overview.png)

* TOC
{:toc}

---

![influxDB logo]({{ site.baseurl }}/assets/images/HomeDataLoggingServer/influx_logo.png)

### InfluxDB installation

Installing Go Version Manager and Go 1.5.2

	bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
	source /home/pi/.gvm/scripts/gvm
	sudo apt-get install bison
	gvm install go1.4
	gvm use go1.4
	export GOROOT_BOOTSTRAP=$GOROOT
	gvm install go1.5.2
	gvm use go1.5.2 --default

Installing dependencies

	sudo apt-get install ruby-dev gcc
	sudo gem install fpm

Installing InfluxDB 0.9.6:

	gvm pkgset create influxdb
	gvm pkgset use influxdb
	go get github.com/tools/godep
	go get -t -d github.com/influxdb/influxdb
	cd .gvm/pkgsets/go1.5.2/influxdb/src/github.com/influxdb/influxdb
	./package.sh -t deb -p 0.9.6
	sudo dpkg -i influxdb_0.9.6_armhf.deb
	reboot

### Functional tests

#### Web interface

Once up & running, InfluxDB can be accessed/administered through a web interface available at `http://(IP of the raspberry):8083`
(unless port number was customized in config file)

#### Creating the database

Using the web interface, I initialized a database named `homelog` for storing all logging data:

	CREATE DATABASE "homelog"

#### HTTP API

The InfluxDB HTTP API is available on port 8086 (by default). 

##### Reading from the database

For reading, a GET request is used: 

<pre><code>URL = "http://(IP of the raspberry):8086/query?db=homelog&q=(url-encoded request string)
</code></pre>

It returns JSON-encoded resuls, in the format:

	{
	    "results": [
	        {
	            "series": [
	                {
	                    "name": "<measurement name>",
	                    "columns": [
	                        "time",
	                        "<tag name>",
	                        "<field name>"
	                    ],
	                    "values": [
	                        [
	                            "<timestamp>",
	                            "<tag name>",
	                            <value>
	                        ],
	                    ]
	                }
	            ]
	        }
	    ]
	}

##### Writing to the database

For writing a new entry, a POST request containing data formatted using InfluxDB `line protocol` (e.g. *measurement_name,tag1=value1,tag2=value2 field1=value1,field2=value2 timestamp*) must be made on the following URL:

<pre><code>http://(IP of the raspberry):8086/write?db=(your database name)
</code></pre>

If the explicit timestamp is omitted, the data gets timestamps by influxDB itself (which I chose to do, to be sure that all timestamps are consistent by design)

#### Retention policy

By default, entries added to the database are kept forever. There is however an interesting feature that allows to automatically delete entries older than a predefined age. For example, I defined a retention policy (arbitrarily named `clean-up_policy`) of 100 weeks (~2 years) on my `homelog`database, and made it the default retention policy for this database, using this query:

	CREATE RETENTION POLICY clean_up_policy ON homelog DURATION 100w REPLICATION 1 DEFAULT

### Performance tests

To verify influxDB performance for my target usecase, I created a database with artificially created entries, covering a period of 5 years with timestamps 5 minutes apart (i.e. more than 500.000 entries in the database)
On my raspberry pi (model B), the query to retrieve the last 4 days worth of data returns in approximately **300ms**, which is fine with me.<br><br>
The test files for creating this test database and for measuring query time are available [here](https://github.com/jheyman/influxdb).

### Configuration

For my specific setup I modified a few configuration parameters:

* the network port on which the Web user interface is available, changed from 8083 to 8085 (since 8083 conflicted with my Z-way-server installed on the same rasperry pi). 
* the data storage location and WAL (Write-Ahead Logging) storage locations, modified to point to an external USB disk plugged on the pi (since relying on the Pi's internal flash to store the database would sooner or later have become a problem, both due to the growing size of the database and to the induced wearout on the flash memory).
* Note that I had to add the option `umask=0000` in `etc/fstab` on the line mounting the USB disk, otherwise influxDB would report a permission denied error at startup (due to influxdb user not having the appropriate write permissions to this USB mount point).<br><br> 

I archived my configuration file [here](https://github.com/jheyman/influxdb/blob/master/influxdb.conf).

### Database backup and restore

A backup of the database can be performed (even with influxd running) like this:

	influxd backup /path/to/backup


I chose to to trig such a backup every Monday at 1am to my NAS, and adding this line to `crontab` to do so:

	0 3 * * 1 influxd backup /mnt/logdata/backup >> /home/pi/backups/influxdb_backup.log

To restore a database, shutdown influxd (`sudo service influxdb stop`) and use:

	influxd restore -config /path/to/influxdb.conf /path/to/backup


### Database storage over NFS

I tested using an NFS share as the directory for data/WAL storage, and got a robustness issue occurring on the Pi a few minutes after launch:

	runtime/cgo: pthread_create failed: Resource temporarily unavailable
	SIGABRT: abort 

It turns out that this occurred when used an NFS share mounted without the `nolock` option. Just adding this option fixed the issue.

