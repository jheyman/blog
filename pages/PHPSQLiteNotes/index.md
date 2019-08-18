---
layout: page
title: PHP SQLite notes
tagline: Various notes about using PHP and SQLite
tags: php, sqlite, web
---
{% include JB/setup %}

### Local testing of php files

When developing a PHP script serving an HTTP request, I find it useful to be able to test the execution of the script locally on the server without having to involve the remote client. 
To emulate the reception of values from the client inside the HTTP request, the following tip can be used:

* Add something like this at the beginning of the script:

<pre><code>if (!isset($_SERVER["HTTP_HOST"])) {
	parse_str($argv[1], $_REQUEST);
}</code></pre>

* the script can parse the _REQUEST var as it will do in the real execution context, e.g.:

<pre><code>$dataId =  $_REQUEST['dataId'];
$value = $_REQUEST['value'];</code></pre>

* to execute the script locally, passing along parameters from the command line: 

<pre><code>php script.php 'dataId=123&value=456'</code></pre>




