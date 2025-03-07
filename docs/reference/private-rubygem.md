---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/private-rubygem.html
---

# Private Gem Repositories [private-rubygem]

The Logstash plugin manager connects to a Ruby gems repository to install and update Logstash plugins. By default, this repository is [http://rubygems.org](http://rubygems.org).

Some use cases are unable to use the default repository, as in the following examples:

* A firewall blocks access to the default repository.
* You are developing your own plugins locally.
* Airgap requirements on the local system.

When you use a custom gem repository, be sure to make plugin dependencies available.

Several open source projects enable you to run your own plugin server, among them:

* [Geminabox](https://github.com/geminabox/geminabox)
* [Gemirro](https://github.com/PierreRambaud/gemirro)
* [Gemfury](https://gemfury.com/)
* [Artifactory](http://www.jfrog.com/open-source/)

## Editing the Gemfile [_editing_the_gemfile]

The gemfile is a configuration file that specifies information required for plugin management. Each gem file has a `source` line that specifies a location for plugin content.

By default, the gemfile’s `source` line reads:

```shell
# This is a Logstash generated Gemfile.
# If you modify this file manually all comments and formatting will be lost.

source "https://rubygems.org"
```

To change the source, edit the `source` line to contain your preferred source, as in the following example:

```shell
# This is a Logstash generated Gemfile.
# If you modify this file manually all comments and formatting will be lost.

source "https://my.private.repository"
```

After saving the new version of the gemfile, use [plugin management commands](/reference/working-with-plugins.md) normally.

The following links contain further material on setting up some commonly used repositories:

* [Geminabox](https://github.com/geminabox/geminabox/blob/master/README.md)
* [Artifactory](https://www.jfrog.com/confluence/display/RTF/RubyGems+Repositories)
* Running a [rubygems mirror](http://guides.rubygems.org/run-your-own-gem-server/)


