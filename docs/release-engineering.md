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

# building a release.

* Make sure all tests pass (rake test)
  * rake test
* Update VERSION.rb
  * set this: VERSION=$(ruby -r./VERSION -e 'puts LOGSTASH_VERSION')
* Fix version links in the docs
  * sed -i -re "s/logstash-[0-9]\.[0-9]\.[0-9]+(rc.)?/logstash-$VERSION/" docs/**/*.md
  * sed -i -re "s@logstash/versions/[0-9]\.[0-9]\.[0-9]+(rc.)?@logstash/versions/$VERSION@" docs/**/*.md
  * sed -i -re "s@gem install logstash -v [0-9]\.[0-9]\.[0-9]+(rc.)?@gem install logstash -v $VERSION@" docs/**/*.md
  * Verify diff and commit.
* Ensure CHANGELOG is up-to-date
* git tag v$VERSION
* git push origin master
* git push --tags
* Build binaries
  * rake package:gem
  * rake package:monolith:jar
* rake docs output=../logstash.github.com/docs/$VERSION
  * Note: you will need to use c-ruby for this (ruby 1.8.7, etc)
  * You'll need 'bluecloth' rubygem installed.
* cd ../logstash.github.com
  * make clean update VERSION=$VERSION
  * git add docs/$VERSION docs/latest.html index.html _layouts/*
  * git commit -m "version $VERSION docs" && git push origin master
* Publish binaries
  * Stage binaries at `carrera.databits.net:/home/jls/s/files/logstash/`
  * rake publish
* Update #logstash IRC /topic
* Send announcement email to logstash-users@, include relevant download URLs &
  changelog (see past emails for a template)
