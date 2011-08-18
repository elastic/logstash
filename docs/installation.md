---
title: Installation options - logstash
layout: content_right
---
# LogStash Installation

There are a few ways to install logstash:

* standalone runnable jar file  (monolithic)
* gem install logstash

## 'standalone runnable jar'

This jar is a runnable jar with elasticsearch and most other dependencies
included. To use it, do the following:

### web interface

    java -jar logstash-%VERSION%-monolithic.jar web

### agent 

    java -jar logstash-%VERSION%-monolithic.jar agent -f youragent.conf

### Combined

You can run both the agent and web interface (or any number of separate agents)
in the same java process. Just use '--' indicate the start of a new command
line:

    java -jar logstash-%VERSION%-monolithic.jar agent -f myagent.conf -- web

## 'gem install logstash'

Using this method to download logstash will install all ruby dependencies.

* You must have JRuby already
* If you use elasticsearch, you'll have to add that to the java classpath.
  (See below for web interface notes)
* If you use grok, you'll need libgrok installed.

### web interface

* You have elasticsearch already
* You'll need to know the path to your elasticsearch lib directory.

    % CLASSPATH=$(ls /opt/elasticsearch/lib/*.jar | tr '\n' ':')  logstash-web
   Thin web server (v1.2.7 codename No Hup)
   Maximum connections set to 1024
   Listening on 0.0.0.0:9292, CTRL+C to stop

For the above, replace '/opt/elasticsearch/lib' with wherever you downloaded
and unpacked elasticsearch.

### agent

    % logstash -f youragent.conf

    # Or if you need elasticsearch:
    % CLASSPATH=$(ls /opt/elasticsearch/lib/*.jar | tr '\n' ':') logstash -f youragent.conf
