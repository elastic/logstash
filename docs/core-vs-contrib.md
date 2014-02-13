---
title: Logstash Core and Contrib
layout: content_right
---

# core and contrib plugins

Starting in version 1.4.0, core and contributed plugins will be separated.  
Contrib plugins reside in a [separate github project](https://github.com/elasticsearch/logstash-contrib).

# Packaging
At present, the contrib modules are available as a tarball.

# Automated Installation
The `bin/plugin` script will handle the installation for you:

```
cd /path/to/logstash
bin/plugin install contrib
```

# Manual Installation (if you're behind a firewall, etc.)
The contrib plugins can be extracted on top of an existing Logstash installation. 

For example, if I've extracted `logstash-1.4.0.tar.gz` into `/path`, e.g.
 
```
cd /path
tar zxf ~/logstash-1.4.0.tar.gz
```

It will have a `/path/logstash-1.4.0` directory, e.g.

```
$ ls
logstash-1.4.0
```

The method to install the contrib tarball is identical.

```
cd /path
tar zxf ~/logstash-contrib-1.4.0.tar.gz
```

This will install the contrib plugins in the same directory as the core install.

The download link is http://download.elasticsearch.org/logstash/logstash/logstash-contrib-${VERSION}.tar.gz
where ${VERSION} is the same version of Logstash you currently have installed, e.g. 1.4.0
