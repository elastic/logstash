---
title: Command-line flags - logstash
layout: content_right
---
# Command-line flags

## Agent

The logstash agent has the following flags (also try using the '--help' flag)

<dl>
<dt> --config CONFIGFILE </dt>
<dd> Load the logstash config from a specific file </dd>
<dt> --log FILE </dt>
<dd> Log to a given path. Default is to log to stdout </dd>
<dt> -v </dt>
<dd> Increase verbosity. There are multiple levels of verbosity available with
'-vvv' currently being the highest </dd>
<dt> --pluginpath PLUGIN_PATH </dt>
<dd> A colon-delimted path to find other logstash plugins in </dd>
</dl>

## Web UI

<dl>
<dt> --log FILE </dt>
<dd> Log to a given path. Default is stdout. </dd>
<dt> --address ADDRESS </dt>
<dd> Address on which to start webserver. Default is 0.0.0.0. </dd>
<dt> --port PORT </dt>
<dd> Port on which to start webserver. Default is 9292. </dd>
<dt> --backend URL </dt>
<dd> The backend URL to use. Default is elasticsearch://localhost:9200/ </dd>
</dl>
