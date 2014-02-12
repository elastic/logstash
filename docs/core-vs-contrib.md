---
title: Logstash Core and Contrib - logstash
layout: content_right
---

# core and contrib plugins

Starting in version 1.4.0, core and contributed plugins will be separated.  
Contrib plugins reside in a [separate github project](https://github.com/elasticsearch/logstash-contrib).

# Packaging
At present, the contrib modules are available as a tarball.

# Installation
The tarball build defaults to extract on top of an existing Logstash tarball installation. 
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

# Building contrib
Building your own contrib plugin collection tarball is important if you wish to 
add your own custom plugins and then distribute those to your Logstash installations. 

* Clone the repository, e.g. 

```git clone https://github.com/elasticsearch/logstash-contrib.git```

* Checkout the correct version (e.g. v1.4.0) to match your core Logstash installation, e.g.

```git checkout v1.4.0```

* (If you have code or changes to add/remove, make them at this point, if not proceed to 
  the next step.)
* Build the tarball package:

```make tarball```

* The resulting `logstash-contrib-${VERSION}.tar.gz` will be in the `build` directory

