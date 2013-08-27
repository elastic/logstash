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

* Make sure all tests pass (make test)
  * `ruby bin/logstash test`
  * `java -jar logstash-x.y.z-flatjar.jar test`
* Update VERSION.rb
  * VERSION=$(ruby -r./VERSION -e 'puts LOGSTASH_VERSION')
* Ensure CHANGELOG is up-to-date
* `git tag v$VERSION; git push origin master; git push --tags`
* Build binaries
  * `make jar`
* make docs
  * copy build/docs to ../logstash.github.com/docs/$VERSION
  * Note: you will need to use C-ruby 1.9.2 for this.
  * You'll need 'bluecloth' and 'cabin' rubygems installed.
* cd ../logstash.github.com
  * `make clean update VERSION=$VERSION`
  * `git add docs/$VERSION docs/latest.html index.html _layouts/*`
  * `git commit -m "version $VERSION docs" && git push origin master`
* Publish binaries
  * Stage binaries at `carrera.databits.net:/home/jls/s/files/logstash/`
* Update #logstash IRC /topic
* Send announcement email to logstash-users@, include relevant download URLs &
  changelog (see past emails for a template)
