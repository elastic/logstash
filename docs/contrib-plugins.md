---
title: Logstash Contrib plugins
layout: content_right
---

# contrib plugins

As logstash has grown, we've accumulated a massive repository of plugins. Well
over 100 plugins, it became difficult for the project maintainers to adequately
support everything effectively.

In order to improve the quality of popular plugins, we've moved the
less-commonly-used plugins to a separate repository we're calling "contrib".
Concentrating common plugin usage into core solves a few problems, most notably
user complaints about the size of logstash releases, support/maintenance costs,
etc.

It is our intent that this separation will improve life for users. If it
doesn't, please file a bug so we can work to address it!

If a plugin is available in the 'contrib' package, the documentation for that
plugin will note this boldly at the top of that plugin's documentation.

Contrib plugins reside in a [separate github project](https://github.com/elasticsearch/logstash-contrib).

# Packaging

At present, the contrib modules are available as a tarball.

# Automated Installation

The `bin/plugin` script will handle the installation for you:

    cd /path/to/logstash
    bin/plugin install contrib

# Manual Installation

The contrib plugins can be extracted on top of an existing Logstash installation. 

For example, if I've extracted `logstash-%VERSION%.tar.gz` into `/path`, e.g.
 
    cd /path
    tar zxf ~/logstash-%VERSION%.tar.gz

It will have a `/path/logstash-%VERSION%` directory, e.g.

    $ ls
    logstash-%VERSION%

The method to install the contrib tarball is identical.

    cd /path
    wget http://download.elasticsearch.org/logstash/logstash/logstash-contrib-%VERSION%.tar.gz
    tar zxf ~/logstash-contrib-%VERSION%.tar.gz

This will install the contrib plugins in the same directory as the core
install. These plugins will be available to logstash the next time it starts.

