---
title: release notes for %VERSION%
layout: content_right
---

# %VERSION% - Release Notes

This document is targeted at existing users of Logstash who are upgrading from
an older version to version %VERSION%. This document is intended to supplement
a the [changelog
file](https://github.com/elasticsearch/logstash/blob/v%VERSION%/CHANGELOG) by
providing more details on certain changes.

### tarball 

With Logstash 1.4.0, we stopped shipping the jar file and started shipping a
tarball instead.

Past releases have been a single jar file which included all Ruby and Java
library dependencies to eliminate deployment pains. We still ship all
the dependencies for you! The jar file served us well, but over time we found
Java’s default heap size, garbage collector, and other settings weren’t well
suited to Logstash.

In order to provide better Java defaults, we’ve changed to releasing a tarball
(.tar.gz) that includes all the same dependencies. What does this mean to you?
Instead of running `java -jar logstash.jar ...` you run `bin/logstash ...` (for
Windows users, `bin/logstash.bat`)

One pleasant side effect of using a tarball is that the Logstash code itself is
much more accessible and able to satisfy any curiosity you may have.

The new way to do things is:

* Download logstash tarball
* Unpack it (`tar -zxf logstash-%VERSION%.tar.gz`)
* `cd logstash-%VERSION%`
% Run it: `bin/logstash ...`

The old way to run logstash of `java -jar logstash.jar` is now replaced with
`bin/logstash`. The command line arguments are exactly the same after that.
For example:

    # Old way:
    % java -jar logstash-1.3.3-flatjar.jar agent -f logstash.conf

    # New way:
    % bin/logstash agent -f logstash.conf

### contrib plugins

Logstash has grown brilliantly over the past few years with great contributions
from the community. Now having 165 plugins, it became hard for us (the Logstash
engineering team) to reliably support all the wonderful technologies in each
contributed plugin. We combed through all the plugins and picked the ones we
felt strongly we could support, and those now ship by default with Logstash.

All the other plugins are now available in a contrib package. All plugins
continue to be open source and free, of course! Installing plugins from the
contrib package is very easy:

    % cd /path/to/logstash-%VERSION%/
    % bin/plugin install contrib

A bonus effect of this decision is that the default Logstash download size
shrank by 19MB compared to the previous release because we were able to shed
some lesser-used dependencies.

You can learn more about contrib plugins on the [contrib plugins
page](http://logstash.net/docs/%VERSION%/contrib-plugins)
