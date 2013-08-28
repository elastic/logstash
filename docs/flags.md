---
title: Command-line flags - logstash
layout: content_right
---
# Command-line flags

## Agent

The logstash agent has the following flags (also try using the '--help' flag)

<dl>
<dt> -f, --config CONFIGFILE </dt>
<dd> Load the logstash config from a specific file, directory, or a
wildcard. If given a directory or wildcard, config files will be read
from the directory in alphabetical order. </dd>
<dt> -e CONFIGSTRING </dt>
<dd> Use the given string as the configuration data. Same syntax as the
config file. If not input is specified, 'stdin { type => stdin }' is
default. If no output is specified, 'stdout { debug => true }}' is
default. </dd>
<dt> -w, --filterworkers COUNT </dt>
<dd> Run COUNT filter workers (default: 1) </dd>
<dt> --watchdog-timeout TIMEOUT </dt>
<dd> Set watchdog timeout value in seconds. Default is 10.</dd>
<dt> -l, --log FILE </dt>
<dd> Log to a given path. Default is to log to stdout </dd>
<dt> -v </dt>
<dd> Increase verbosity. There are multiple levels of verbosity available with
'-vv' currently being the highest </dd>
<dt> --pluginpath PLUGIN_PATH </dt>
<dd> A colon-delimted path to find other logstash plugins in </dd>
</dl>
