---
title: Installation options - logstash
layout: content_right
---
# LogStash Installation

There are a few ways to install logstash:

* standalone runnable jar file  (monolithic)
* normal runnable jar (ruby deps + jruby included, no elasticsearch)
* gem install logstash

## 'standalone runnable jar'

This jar is the normal runnable jar with elasticsearch libs included. To use
it, use it the same way as documented below for 'normal runnable jar'

## 'normal runnable jar'

If you want to include elasticsearch, you'll need to download it and set the
CLASSPATH environment variable to include any elasticsearch jar files.

### web interface

    java -jar logstash-0.9.1.jar web

### agent 

    java -jar logstash-0.9.1.jar agent -f youragent.conf

## 'gem install logstash'

Using this method to download logstash will install all ruby dependencies.

* You must have jruby already
* If you use elasticsearch, you'll have to it and its jars add that to the java
  classpath. ( See below for web interface notes 
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
