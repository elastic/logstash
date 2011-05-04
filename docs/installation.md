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

### web interface

* You have elasticsearch already
* You'll need to know the path to your elasticsearch lib directory.

    % CLASSPATH=elasticsearch-0.16.0/lib/*.jar logstash-web
    >> Thin web server (v1.2.7 codename No Hup)
    >> Maximum connections set to 1024
    >> Listening on 0.0.0.0:9292, CTRL+C to stop

### agent

    % logstash -f youragent.conf
