---
title: Release Engineering - logstash
layout: content_right
---

# logstash rel-eng.

The version patterns for logstash are x.y.z

* In the same x.y release, no backwards-incompatible changes will be made.
* Between x.y.z and x.y.(z+1), deprecations are allowed but should be
  functional through the next release.
* Any backwards-incompatible changes should be well-documented and, if
  possible, should include tools to help in migrating.
* It is OK to add features, plugins, etc, in minor releases as long as they do
  not break existing functionality.

I do not suspect the 'x' (currently 1) will change frequently. It should only change
if there are major, backwards-incompatible changes made to logstash, and I'm
trying to not make those changes, so logstash should forever be at 1.y,z,
right? ;)
