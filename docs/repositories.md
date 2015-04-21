---
title: repositories - logstash
layout: content_right
---
# Logstash repositories

We also have Logstash available as APT and YUM repositories.

Our public signing key can be found on the [Elasticsearch packages apt GPG signing key page](https://packages.elasticsearch.org/GPG-KEY-elasticsearch)

## Apt based distributions

Add the key:

    wget -O - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

Add the repo to /etc/apt/sources.list

    deb http://packages.elasticsearch.org/logstash/1.4/debian stable main


## YUM based distributions

Add the key:

    rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch

Add the repo to /etc/yum.repos.d/ directory

    [logstash-1.4]
    name=logstash repository for 1.4.x packages
    baseurl=https://packages.elasticsearch.org/logstash/1.4/centos
    gpgcheck=1
    gpgkey=https://packages.elasticsearch.org/GPG-KEY-elasticsearch
    enabled=1
