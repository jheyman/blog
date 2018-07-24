---
layout: page
title: Python tips and tricks
tagline: Various Python tips I keep forgetting about
tags: linux, tips
---
{% include JB/setup %}

This is a memo to myself of python things I have found useful to keep at hand.

* TOC
{:toc}

--- 

### Profiling the execution of a script

The following command runs the given script and prints out stats of where time was spent during code execution. Extremely useful when performance is important, to figure out where to start.
	
	python -m cProfile -s cumtime script_being_profiled.py

---

### Configuration file

Config file has sections (name in brackets) and  params

	[config]
	param = paramValue

Then from the script:

	from ConfigParser import SafeConfigParser

	parser = SafeConfigParser()
	parser.read('config.ini')

	MY_PARAM = parser.get('config', 'param')

---

### Logging to file

Python's logging facility is very simple to use, and so much better than to sprinkle "print" statements all over the code. 

The following boilerplate init code works fine for me:

	import logging
	import logging.handlers

	LOG_LEVEL = logging.INFO  # Could be e.g. "DEBUG" or "WARNING"

	# Give the logger a unique name (good practice)
	logger = logging.getLogger(__name__)

	# Set the log level to LOG_LEVEL
	logger.setLevel(LOG_LEVEL)

	# Make a handler that writes to a file, making a new file at midnight and keeping 3 backups
	#handler = logging.handlers.TimedRotatingFileHandler(LOG_FILENAME, when="midnight", backupCount=3)
	# Handler writing to a file, rotating the file every 50MB
	handler = logging.handlers.RotatingFileHandler(LOG_FILENAME, maxBytes=50000000)
	# Format each log message like this
	#formatter = logging.Formatter('%(asctime)s %(message)s')
	formatter = logging.Formatter("%(asctime)s %(message)s", "%d/%m %H:%M:%S")

	# Attach the formatter to the handler
	handler.setFormatter(formatter)
	# Attach the handler to the logger
	logger.addHandler(handler)

	# Make a class we can use to capture stdout and sterr in the log
	class MyLogger(object):
		def __init__(self, logger, level):
			"""Needs a logger and a logger level."""
			self.logger = logger
			self.level = level

		def write(self, message):
			# Only log if there is a message (not just a new line)
			if message.rstrip() != "":
				self.logger.log(self.level, message.rstrip())

	# Replace stdout with logging to file at INFO level
	sys.stdout = MyLogger(logger, logging.INFO)
	# Replace stderr with logging to file at ERROR level
	sys.stderr = MyLogger(logger, logging.ERROR)


then just use logger.info (or debug, or warning, ...) instead of print wherever:

	logger.info( '%s:OK' % myString)


--- 

