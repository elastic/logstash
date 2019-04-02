## Description

This repository contains the official [Logstash][logstash] Docker image from
[Elastic][elastic].

Documentation can be found on the [Elastic website](https://www.elastic.co/guide/en/logstash/current/docker.html).

[logstash]: https://www.elastic.co/products/logstash
[elastic]: https://www.elastic.co/

## Supported Docker versions

The images have been tested on Docker version 18.09.2, build 6247962

## Requirements
A full build and test requires:
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

## Contributing, issues and testing

Acceptance tests for the image are located in the `test` directory, and can
be invoked with `make test`.

This image is built on [Centos 7][centos-7].

[centos-7]: https://github.com/CentOS/sig-cloud-instance-images/blob/50281d86d6ed5c61975971150adfd0ede86423bb/docker/Dockerfile
