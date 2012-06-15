---
title: Plugin Status - logstash
layout: content_right
---
# Plugin Status

Plugins (inputs/outputs/filters) have a status in logstash. This is to provide
an indicator to the end-user as to the 'state' of the plugin.

Terminology is still being worked out but there are three general states -
experimental, beta, stable.

The desire here is to allow people to quickly iterate on possible new plugins
while conveying to the end-user a set of expectations about that plugin. This
allows you to make more informed decisions about when and where to use the
functionality provided by the new plugin.

## Experimental

When a plugin is in the `experimental` state, it is essentially untested. This
does not mean that it does not have any associated unit tests. This applies
more to in-the-wild usage. Most new plugins will probably fit in this category.
There is a chance that experimental plugins may be removed at some point. It is
possible that an experimental plugin will be broken mid-release.

## Beta

Beta plugins are plugins that are in the process of being stabalized into a
final form. Beta plugins will have a bit more wide-spread usage in the
community. The API for these plugins has stabilized and is unlikely to change
mid-release. Test cases may or may not exist.

## Stable

Stable plugins are plugins that you can comfortably rely on in production.
These have full test cases.

# A note about output plugins

It's worth reminding users that `output` plugins are currently blocking (by
design). If any output plugin fails, all output plugins are blocked. Please
keep this in mind when using experimental output plugins as it could cause
unintended side-effects.
