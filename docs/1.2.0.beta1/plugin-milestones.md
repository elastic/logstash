---
title: Plugin Milestones - logstash
layout: content_right
---
# Plugin Milestones

Plugins (inputs/outputs/filters/codecs) have a milestone label in logstash.
This is to provide an indicator to the end-user as to the kinds of changes
a given plugin could have between logstash releases.

The desire here is to allow plugin developers to quickly iterate on possible
new plugins while conveying to the end-user a set of expectations about that
plugin.

## Milestone 1

Plugins at this milestone need your feedback to improve! Plugins at this
milestone may change between releases as the community figures out the best way
for the plugin to behave and be configured.

## Milestone 2

Plugins at this milestone are more likely to have backwards-compatibility to
previous releases than do Milestone 1 plugins. This milestone also indicates
a greater level of in-the-wild usage by the community than the previous
milestone.

## Milestone 3

Plugins at this milestone have strong promises towards backwards-compatibility.
This is enforced with automated tests to ensure behavior and configuration are
consistent across releases.

## Milestone 0

This milestone appears at the bottom of the page because it is very
infrequently used.

This milestone marker is used to generally indicate that a plugin has no
active code maintainer nor does it have support from the community in terms
of getting help.
