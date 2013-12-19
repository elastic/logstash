---
title: repositories - logstash
layout: content_right
---
# LogStash repositories

We also have Logstash available als APT and YUM repositories.

Our public signing key can be found [here](http://packages.elasticsearch.org/GPG-KEY-elasticsearch)

## Apt based distributions

Add the key:

     wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

Add the repo to /etc/apt/sources.list

     deb http://packages.elasticsearch.org/logstash/1.3/debian stable main


## YUM based distributions

Add the key:

     rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch

Add the repo to /etc/yum.repos.d/ directory

     [logstash-1.3]
     name=logstash repository for 1.3.x packages
     baseurl=http://packages.elasticsearch.org/logstash/1.3/centos
     gpgcheck=1
     gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
     enabled=1
