# Requirements to build:
#   rsync
#   wget or curl
#
JRUBY_VERSION=1.7.11
ELASTICSEARCH_VERSION=1.1.1

WITH_JRUBY=java -jar $(shell pwd)/$(JRUBY) -S
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_URL=http://jruby.org.s3.amazonaws.com/downloads/$(JRUBY_VERSION)/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_CMD=bin/logstash env java -jar $(JRUBY)

ELASTICSEARCH_URL=http://download.elasticsearch.org/elasticsearch/elasticsearch
ELASTICSEARCH=vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION)
TYPESDB=vendor/collectd/types.db
COLLECTD_VERSION=5.4.0
TYPESDB_URL=https://collectd.org/files/collectd-$(COLLECTD_VERSION).tar.gz
GEOIP=vendor/geoip/GeoLiteCity.dat
GEOIP_URL=http://logstash.objects.dreamhost.com/maxmind/GeoLiteCity-2013-01-18.dat.gz
GEOIP_ASN=vendor/geoip/GeoIPASNum.dat
GEOIP_ASN_URL=http://logstash.objects.dreamhost.com/maxmind/GeoIPASNum-2014-02-12.dat.gz
KIBANA_URL=https://download.elasticsearch.org/kibana/kibana/kibana-3.0.1.tar.gz
PLUGIN_FILES=$(shell find lib -type f| egrep '^lib/logstash/(inputs|outputs|filters|codecs)/[^/]+$$' | egrep -v '/(base|threadable).rb$$|/inputs/ganglia/')
QUIET=@
ifeq (@,$(QUIET))
	QUIET_OUTPUT=> /dev/null 2>&1
endif

WGET=$(shell which wget 2>/dev/null)
CURL=$(shell which curl 2>/dev/null)

# OS-specific options
TARCHECK=$(shell tar --help|grep wildcard|wc -l|tr -d ' ')
ifeq (0, $(TARCHECK))
TAR_OPTS=
else
TAR_OPTS=--wildcards
endif

#spec/outputs/graphite.rb spec/outputs/email.rb)
default:
	@echo "Make targets you might be interested in:"
	@echo "  tarball -- builds the tarball package"
	@echo "  tarball-test -- runs the test suite against the tarball package"

TESTS=$(wildcard spec/*.rb spec/**/*.rb spec/**/**/*.rb)

# The 'version' is generated based on the logstash version, git revision, etc.
.VERSION.mk: REVISION=$(shell git rev-parse --short HEAD | tr -d ' ')
.VERSION.mk: RELEASE=$(shell awk -F\" '/LOGSTASH_VERSION/ {print $$2}' lib/logstash/version.rb | tr -d ' ')
#.VERSION.mk: TAGGED=$(shell git tag --points-at HEAD | egrep '^v[0-9]')
.VERSION.mk: DEV=$(shell echo $RELEASE | egrep '\.dev$$')
.VERSION.mk: MODIFIED=$(shell git diff --shortstat --exit-code > /dev/null ; echo $$?)
.VERSION.mk:
	$(QUIET)echo "RELEASE=${RELEASE}" > $@
	$(QUIET)echo "REVISION=${REVISION}" >> $@
	$(QUIET)echo "DEV=${DEV}" >> $@
	$(QUIET)echo "MODIFIED=${MODIFIED}" >> $@
	$(QUIET)if [ -z "${DEV}" ] ; then \
		if [ "${MODIFIED}" -eq 1 ] ; then \
			echo "VERSION=${RELEASE}-modified" ; \
		else \
			echo "VERSION=${RELEASE}" ; \
		fi ; \
	else \
		if [ "${MODIFIED}" -eq 1 ] ; then \
			echo "VERSION=${RELEASE}-${REVISION}-modified" ; \
		else \
			echo "VERSION=${RELEASE}-${REVISION}" ; \
		fi ; \
	fi >> $@

-include .VERSION.mk

version:
	@echo "Version: $(VERSION)"

# Figure out if we're using wget or curl
.PHONY: wget-or-curl
wget-or-curl:
ifeq ($(CURL),)
ifeq ($(WGET),)
	@echo "wget or curl are required."
	exit 1
else
DOWNLOAD_COMMAND=wget -q --no-check-certificate -O
endif
else
DOWNLOAD_COMMAND=curl -s -L -k -o
endif

# Compile config grammar (ragel -> ruby)
.PHONY: compile-grammar
compile-grammar: lib/logstash/config/grammar.rb
lib/logstash/config/grammar.rb: lib/logstash/config/grammar.treetop
	$(QUIET)$(MAKE) -C lib/logstash/config grammar.rb

.PHONY: clean
clean:
	@echo "=> Cleaning up"
	-$(QUIET)rm -rf .bundle
	-$(QUIET)rm -rf build
	-$(QUIET)rm -f pkg/*.deb
	-$(QUIET)rm .VERSION.mk

.PHONY: vendor-clean
vendor-clean:
	-$(QUIET)rm -rf vendor/kibana vendor/geoip vendor/collectd
	-$(QUIET)rm -rf vendor/jar vendor/ua-parser

.PHONY: clean-vendor
clean-vendor:
	-$(QUIET)rm -rf vendor

.PHONY: compile
compile: compile-grammar compile-runner | build/ruby

.PHONY: compile-runner
compile-runner: build/ruby/logstash/runner.class
build/ruby/logstash/runner.class: lib/logstash/runner.rb | build/ruby $(JRUBY)
	$(QUIET)(cd lib; java -jar ../$(JRUBY) -rjruby/jrubyc -e 'exit JRuby::Compiler::compile_argv(ARGV)' -- -t ../build/ruby logstash/runner.rb)

.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root
	$(QUIET)rsync -a --include "*/" --include "*.rb" --include "*.yaml" --exclude "*" ./lib/ ./test/ ./build/ruby
	$(QUIET)rsync -a ./spec ./build/ruby
	$(QUIET)rsync -a ./locales ./build/ruby
	@# Delete any empty directories copied by rsync.
	$(QUIET)find ./build/ruby -type d -empty -delete

vendor:
	$(QUIET)mkdir $@

vendor/jar: | vendor
	$(QUIET)mkdir $@

vendor-jruby: $(JRUBY)

$(JRUBY): | vendor/jar
	$(QUIET)echo "=> Downloading jruby $(JRUBY_VERSION)"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(JRUBY_URL)

vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz: | wget-or-curl vendor/jar
	@echo "=> Fetching elasticsearch"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ $(ELASTICSEARCH_URL)/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz

vendor/jar/graphtastic-rmiclient.jar: | wget-or-curl vendor/jar
	@echo "=> Fetching graphtastic rmi client jar"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ http://cloud.github.com/downloads/NickPadilla/GraphTastic/graphtastic-rmiclient.jar

.PHONY: vendor-elasticsearch
vendor-elasticsearch: $(ELASTICSEARCH)
$(ELASTICSEARCH): $(ELASTICSEARCH).tar.gz | vendor/jar
	@echo "=> Pulling the jars out of $<"
	$(QUIET)tar -C $(shell dirname $@) -xf $< $(TAR_OPTS) --exclude '*sigar*' \
		'elasticsearch-$(ELASTICSEARCH_VERSION)/lib/*.jar'

vendor/geoip: | vendor
	$(QUIET)mkdir $@

.PHONY: vendor-geoip
vendor-geoip: $(GEOIP) $(GEOIP_ASN)
$(GEOIP): | vendor/geoip
	$(QUIET)$(DOWNLOAD_COMMAND) $@.tmp.gz $(GEOIP_URL)
	$(QUIET)gzip -dc $@.tmp.gz > $@.tmp
	$(QUIET)rm "$@.tmp.gz"
	$(QUIET)mv $@.tmp $@

$(GEOIP_ASN): | vendor/geoip
	$(QUIET)$(DOWNLOAD_COMMAND) $@.tmp.gz $(GEOIP_ASN_URL)
	$(QUIET)gzip -dc $@.tmp.gz > $@.tmp
	$(QUIET)rm "$@.tmp.gz"
	$(QUIET)mv $@.tmp $@

vendor/collectd: | vendor
	$(QUIET)mkdir $@

.PHONY: vendor-collectd
vendor-collectd: $(TYPESDB)
$(TYPESDB): | vendor/collectd
	$(QUIET)$(DOWNLOAD_COMMAND) $@.tar.gz $(TYPESDB_URL)
	$(QUIET)tar zxf $@.tar.gz -O "collectd-$(COLLECTD_VERSION)/src/types.db" > $@
	$(QUIET)rm $@.tar.gz

# Always run vendor/bundle
.PHONY: fix-bundler
fix-bundler:
	-$(QUIET)rm -rf .bundle

.PHONY: vendor-gems
vendor-gems: | vendor/bundle

.PHONY: vendor/bundle
vendor/bundle: | vendor $(JRUBY)
	@echo "=> Ensuring ruby gems dependencies are in $@..."
	$(QUIET)USE_JRUBY=1 bin/logstash deps $(QUIET_OUTPUT)
	@# Purge any junk that fattens our jar without need!
	@# The riak gem includes previous gems in the 'pkg' dir. :(
	-$(QUIET)rm -rf $@/jruby/1.9/gems/riak-client-1.0.3/pkg
	@# Purge any rspec or test directories
	-$(QUIET)rm -rf $@/jruby/1.9/gems/*/spec $@/jruby/1.9/gems/*/test
	@# Purge any comments in ruby code.
	@#-find $@/jruby/1.9/gems/ -name '*.rb' | xargs -n1 sed -i -e '/^[ \t]*#/d; /^[ \t]*$$/d'

.PHONY: build
build:
	-$(QUIET)mkdir -p $@

build/ruby: | build
	-$(QUIET)mkdir -p $@

vendor/ua-parser/: | build
	$(QUIET)mkdir $@

vendor/ua-parser/regexes.yaml: | vendor/ua-parser/
	@echo "=> Fetching ua-parser regexes.yaml"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ https://raw.github.com/tobie/ua-parser/master/regexes.yaml

.PHONY: test
test: QUIET_OUTPUT=
test: | $(JRUBY) vendor-elasticsearch vendor-geoip vendor-collectd vendor-gems
	$(SPEC_ENV) USE_JRUBY=1 bin/logstash rspec $(SPEC_OPTS) --order rand --fail-fast $(TESTS)

.PHONY: reporting-test
reporting-test: SPEC_ENV=JRUBY_OPTS=--debug
reporting-test: SPEC_OPTS=--format CI::Reporter::RSpec
reporting-test: | test

.PHONY: docs
docs: docgen doccopy docindex

doccopy: $(addprefix build/,$(shell find docs -type f | grep '^docs/')) | build/docs
docindex: build/docs/index.html

docgen: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))
docgen: build/docs/tutorials/getting-started-with-logstash.md

build/docs: build
	$(QUIET)-mkdir $@

build/docs/tutorials: build/docs
	$(QUIET)-mkdir $@


build/docs/inputs build/docs/filters build/docs/outputs build/docs/codecs: | build/docs
	$(QUIET)-mkdir $@

build/docs/tutorials/getting-started-with-logstash.md: build/docs/tutorials/getting-started-with-logstash.xml | build/docs/tutorials
	$(QUIET)( \
		echo "---"; \
		echo "title: Metrics from Logs - logstash"; \
		echo "layout: content_right"; \
		echo "---"; \
		pandoc -f docbook -t markdown $< \
	) \
	| sed -e 's/%VERSION%/$(VERSION)/g' \
	| sed -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' > $@

build/docs/tutorials/getting-started-with-logstash.xml: docs/tutorials/getting-started-with-logstash.asciidoc | build/docs/tutorials
	$(QUIET)asciidoc -b docbook -o $@ $<

build/docs/inputs/%.html: lib/logstash/inputs/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/inputs
	$(QUIET)$(JRUBY_CMD) docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -e 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@
build/docs/filters/%.html: lib/logstash/filters/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/filters
	$(QUIET)$(JRUBY_CMD) docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -e 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@
build/docs/outputs/%.html: lib/logstash/outputs/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/outputs
	$(QUIET)$(JRUBY_CMD) docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -e 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@
build/docs/codecs/%.html: lib/logstash/codecs/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/codecs
	$(QUIET)$(JRUBY_CMD) docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -e 's/%VERSION%/$(VERSION)/g' $@

build/docs/%: docs/% lib/logstash/version.rb Makefile
	@echo "Copying $< (to $@)"
	-$(QUIET)mkdir -p $(shell dirname $@)
	$(QUIET)cp $< $@
	$(QUIET)case "$(suffix $<)" in \
		.gz|.bz2|.png|.jpg) ;; \
		*) \
			sed -i -e 's/%VERSION%/$(VERSION)/g' $@ ; \
			sed -i -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@ ; \
			;; \
	esac

build/docs/index.html: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))
build/docs/index.html: docs/generate_index.rb lib/logstash/version.rb docs/index.html.erb Makefile
	@echo "Building documentation index.html"
	$(QUIET)$(JRUBY_CMD) $< build/docs > $@
	$(QUIET)sed -i -e 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -e 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@

.PHONY: patterns
patterns:
	curl https://nodeload.github.com/logstash/grok-patterns/tarball/master | tar zx
	mv logstash-grok-patterns*/* patterns/
	rm -rf logstash-grok-patterns*

## JIRA Interaction section
JIRACLI=/path/to/your/jira-cli-3.1.0/jira.sh

sync-jira-components: $(addprefix create/jiracomponent/,$(subst lib/logstash/,,$(subst .rb,,$(PLUGIN_FILES))))
	-$(QUIET)$(JIRACLI) --action run --file tmp_jira_action_list --continue > /dev/null 2>&1
	$(QUIET)rm tmp_jira_action_list

create/jiracomponent/%:
	$(QUIET)echo "--action addComponent --project LOGSTASH --name $(subst create/jiracomponent/,,$@)" >> tmp_jira_action_list

## Release note section (up to you if/how/when to integrate in docs)
# Collect the details of:
#  - merged pull request from GitHub since last release
#  - issues for FixVersion from JIRA

# Note on used Github logic
# We parse the commit between the last tag (should be the last release) and HEAD
# to extract all the notice about merged pull requests.

# Note on used JIRA release note URL
# The JIRA Release note list all issues (even open ones)
# with Fix Version assigned to target version
# So one must verify manually that there is no open issue left (TODO use JIRACLI)

# This is the ID for a version item in jira, can be obtained by CLI
# or through the Version URL https://logstash.jira.com/browse/LOGSTASH/fixforversion/xxx
JIRA_VERSION_ID=10820

releaseNote:
	-$(QUIET)rm releaseNote.html
	$(QUIET)curl -si "https://logstash.jira.com/secure/ReleaseNote.jspa?version=$(JIRA_VERSION_ID)&projectId=10020" | sed -n '/<textarea.*>/,/<\/textarea>/p' | grep textarea -v >> releaseNote.html
	$(QUIET)$(JRUBY_CMD) pull_release_note.rb

package: build/logstash-$(VERSION).tar.gz
	(cd pkg; \
		./build.sh ubuntu 12.04; \
		./build.sh centos 6 \
	)

vendor/kibana: | vendor
	@echo "=> Fetching kibana"
	$(QUIET)mkdir vendor/kibana || true
	$(DOWNLOAD_COMMAND) - $(KIBANA_URL) | tar -C $@ -zx --strip-components=1

build/tarball: | build
	mkdir $@
build/tarball/logstash-%: | build/tarball
	mkdir $@

show:
	echo $(VERSION)

.PHONY: prepare-tarball
prepare-tarball tarball zip: WORKDIR=build/tarball/logstash-$(VERSION)
prepare-tarball: vendor/kibana $(ELASTICSEARCH) $(JRUBY) $(GEOIP) $(TYPESDB) vendor-gems
prepare-tarball: vendor/ua-parser/regexes.yaml
prepare-tarball:
	@echo "=> Preparing tarball"
	$(QUIET)$(MAKE) $(WORKDIR)
	$(QUIET)rsync -a --relative bin lib spec locales patterns vendor/bundle/jruby vendor/geoip vendor/jar vendor/kibana vendor/ua-parser vendor/collectd LICENSE README.md --exclude 'vendor/bundle/jruby/1.9/cache' --exclude 'vendor/bundle/jruby/1.9/gems/*/doc' --exclude 'vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz'  $(WORKDIR)
	$(QUIET)sed -i -e 's/^LOGSTASH_VERSION = .*/LOGSTASH_VERSION = "$(VERSION)"/' $(WORKDIR)/lib/logstash/version.rb
	$(QUIET)sed -i -e 's/%JRUBY_VERSION%/$(JRUBY_VERSION)/' $(WORKDIR)/bin/logstash.bat

.PHONY: tarball
tarball: | build/logstash-$(VERSION).tar.gz
build/logstash-$(VERSION).tar.gz: | prepare-tarball
	$(QUIET)tar -C $$(dirname $(WORKDIR)) -c $$(basename $(WORKDIR)) \
		| gzip -9c > $@
	@echo "=> tarball ready: $@"

.PHONY: zip
zip: | build/logstash-$(VERSION).zip
build/logstash-$(VERSION).zip: | prepare-tarball
	$(QUIET)(cd $$(dirname $(WORKDIR)); find $$(basename $(WORKDIR)) | zip $(PWD)/$@ -@ -9)$(QUIET_OUTPUT)
	@echo "=> zip ready: $@"

.PHONY: tarball-test
tarball-test: #build/logstash-$(VERSION).tar.gz
	$(QUIET)-rm -rf build/test-tarball/
	$(QUIET)mkdir -p build/test-tarball/
	tar -C build/test-tarball --strip-components 1 -xf build/logstash-$(VERSION).tar.gz
	(cd build/test-tarball; USE_JRUBY=1 bin/logstash rspec $(TESTS) --fail-fast)
