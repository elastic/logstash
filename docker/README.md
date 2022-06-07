## Description

This repository contains the official [Logstash][logstash] Docker image from
[Elastic][elastic].

Documentation can be found on the [Elastic website](https://www.elastic.co/guide/en/logstash/current/docker.html).

[logstash]: https://www.elastic.co/products/logstash
[elastic]: https://www.elastic.co/

## Supported Docker versions

The images have been tested on Docker version 18.09.2, build 6247962

## Requirements
A full build requires:
* Docker
* GNU Make
* Python 3.5 with Virtualenv
* JRuby 9.1+

## Running a build
To build an image check out the corresponding branch for the version and run the rake task
Like this:
```
git checkout 7.0
rake artifact:docker
# and for the OSS package
rake artifact:docker_oss
```

This image is built on [Ubuntu 20.04][ubuntu-20.04].

[ubuntu-20.04]: https://hub.docker.com/_/ubuntu/
