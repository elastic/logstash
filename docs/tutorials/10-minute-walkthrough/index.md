---
title: Logstash 10-Minute Tutorial
layout: content_right
---
# Logstash 10-minute Tutorial

## Step 1 - Download

### Download logstash:

* [logstash-%VERSION%.tar.gz](https://download.elasticsearch.org/logstash/logstash/logstash-%VERSION%.tar.gz)

    curl -O https://download.elasticsearch.org/logstash/logstash/logstash-%VERSION%.tar.gz

### Unpack it

    tar -xzf logstash-%VERSION%.tar.gz
    cd logstash-%VERSION%

### Requirements:

* Java

### The Secret:

Logstash is written in JRuby, but I release standalone jar files for easy
deployment, so you don't need to download JRuby or most any other dependencies.

I bake as much as possible into the single release file.

## Step 2 - A hello world.

### Download this config file:

* [hello.conf](hello.conf)

### Run it:

    bin/logstash agent -f hello.conf

Type stuff on standard input. Press enter. Watch what event Logstash sees.
Press ^C to kill it.

## Step 3 - Add ElasticSearch

### Download this config file:

* [hello-search.conf](hello-search.conf)

### Run it:

    bin/logstash agent -f hello-search.conf

Same config as step 2, but now we are also writing events to ElasticSearch. Do
a search for `*` (all):

    curl 'http://localhost:9200/_search?pretty=1&q=*'

### Download

* [apache-parse.conf](apache-parse.conf)
* [apache_log.1](apache_log.1) (a single apache log line)

### Run it

    bin/logstash agent -f apache-parse.conf

Logstash will now be listening on TCP port 3333. Send an Apache log message at it:

    nc localhost 3333 < apache_log.1

The expected output can be viewed here: [step-5-output.txt](step-5-output.txt)

## Step 6 - real world example + search

Same as the previous step, but we'll output to ElasticSearch now.

### Download

* [apache-elasticsearch.conf](apache-elasticsearch.conf)
* [apache_log.2.bz2](apache_log.2.bz2) (2 days of apache logs)

### Run it

    bin/logstash agent -f apache-elasticsearch.conf

Logstash should be all set for you now. Start feeding it logs:

    bzip2 -d apache_log.2.bz2

    nc localhost 3333 < apache_log.2

## Want more?

For further learning, try these:

* [Watch a presentation on logstash](http://www.youtube.com/embed/RuUFnog29M4)
* [Getting started 'standalone' guide](http://logstash.net/docs/%VERSION%/tutorials/getting-started-simple)
* [Getting started 'centralized' guide](http://logstash.net/docs/%VERSION%/tutorials/getting-started-centralized) -
  learn how to build out your logstash infrastructure and centralize your logs.
* [Dive into the docs](http://logstash.net/docs/%VERSION%/)
