---
title: Logstash 10-Minute Tutorial
layout: content_right
---
# Logstash 10-minute Tutorial

## Step 1 - Download

### Download logstash:

* [logstash-1.2.0.beta1-flatjar.jar](http://logstash.objects.dreamhost.com/release/logstash-1.2.0.beta1-flatjar.jar)

### Requirements:

* java

### The Secret:

logstash is written in JRuby, but I release standalone jar files for easy
deployment, so you don't need to download JRuby or most any other dependencies.

I bake as much as possible into the single release file.

## Step 2 - A hello world.

### Download this config file:

* [hello.conf](hello.conf)

### Run it:

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f hello.conf

Type stuff on standard input. Press enter. Watch what event logstash sees.
Press ^C to kill it.

## Step 3 - Add ElasticSearch

### Download this config file:

* [hello-search.conf](hello-search.conf)

### Run it:

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f hello-search.conf

Same config as step 2, but now we are also writing events to ElasticSearch. Do
a search for `*` (all):

    curl 'http://localhost:9200/_search?pretty=1&q=*'

## Step 4 - logstash web

The previous step is good, but a better frontend on elasticsearch would help!

The same config as step 3 is used.

### Run it:

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f hello-search.conf -- web --backend 'elasticsearch://localhost/'

The above runs both the agent and the logstash web interface in the same
process. Useful for simple deploys.

### Use it:

Go to the logstash web interface in browser: <http://localhost:9292/>

Type stuff on stdin on the agent, then search for it in the web interface.

## Step 5 - real world example

Let's backfill some old apache logs.  First, let's use grok.

Use the ['grok'](../../filters/grok) logstash filter to parse logs. 

### Download

* [apache-parse.conf](apache-parse.conf)
* [apache_log.1](apache_log.1) (a single apache log line)

### Run it

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f apache-parse.conf

Logstash will now be listening on TCP port 3333. Send an apache log message at it:

    nc localhost 3333 < apache_log.1

The expected output can be viewed here: [step-5-output.txt](step-5-output.txt)

## Step 6 - real world example + search

Same as the previous step, but we'll output to ElasticSearch now.

### Download

* [apache-elasticsearch.conf](apache-elasticsearch.conf)
* [apache_log.2.bz2](apache_log.2.bz2) (2 days of apache logs)

### Run it

    java -jar logstash-1.2.0.beta1-flatjar.jar agent -f apache-elasticsearch.conf -- web --backend 'elasticsearch://localhost/'

Logstash should be all set for you now. Start feeding it logs:

    bzip2 -d apache_log.2.bz2

    nc localhost 3333 < apache_log.2 

Go to the logstash web interface in browser: <http://localhost:9292/>

Try some search queries. To see all the data, search for `*` (no quotes). Click
on some results, drill around in some logs.

## Want more?

For further learning, try these:

* [Watch a presentation on logstash](http://www.youtube.com/embed/RuUFnog29M4)
* [Getting started 'standalone' guide](http://logstash.net/docs/1.2.0.beta1/tutorials/getting-started-simple)
* [Getting started 'centralized' guide](http://logstash.net/docs/1.2.0.beta1/tutorials/getting-started-centralized) - 
  learn how to build out your logstash infrastructure and centralize your logs.
* [Dive into the docs](http://logstash.net/docs/1.2.0.beta1/)
