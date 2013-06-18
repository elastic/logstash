# Requirements to build:
#   rsync
#   wget or curl
#
JRUBY_VERSION=1.7.4
ELASTICSEARCH_VERSION=0.90.0
#VERSION=$(shell ruby -r./lib/logstash/version -e 'puts LOGSTASH_VERSION')
VERSION=$(shell awk -F\" '/LOGSTASH_VERSION/ {print $$2}' lib/logstash/version.rb)

WITH_JRUBY=java -jar $(shell pwd)/$(JRUBY) -S
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_URL=http://repository.codehaus.org/org/jruby/jruby-complete/$(JRUBY_VERSION)
JRUBY_CMD=java -jar $(JRUBY)
JRUBYC=$(WITH_JRUBY) jrubyc
ELASTICSEARCH_URL=http://download.elasticsearch.org/elasticsearch/elasticsearch
ELASTICSEARCH=vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION)
GEOIP=vendor/geoip/GeoLiteCity.dat
GEOIP_URL=http://logstash.objects.dreamhost.com/maxmind/GeoLiteCity-2013-01-18.dat.gz
KIBANA_URL=https://github.com/elasticsearch/kibana/archive/master.tar.gz
PLUGIN_FILES=$(shell git ls-files | egrep '^lib/logstash/(inputs|outputs|filters)/[^/]+$$' | egrep -v '/(base|threadable).rb$$|/inputs/ganglia/')
QUIET=@

WGET=$(shell which wget 2>/dev/null)
CURL=$(shell which curl 2>/dev/null)

# OS-specific options
TARCHECK=$(shell tar --help|grep wildcard|wc -l|tr -d ' ')
ifeq (0, $(TARCHECK))
TAR_OPTS=
else
TAR_OPTS=--wildcards
endif

TESTS=$(wildcard spec/support/*.rb spec/filters/*.rb spec/examples/*.rb spec/codecs/*.rb spec/conditionals/*.rb spec/event.rb spec/outputs/graphite.rb spec/outputs/email.rb)
default: 
	@echo "Make targets you might be interested in:"
	@echo "  flatjar -- builds the flatjar jar"
	@echo "  flatjar-test -- runs the test suite against the flatjar"
	@echo "  jar -- builds the monolithic jar"
	@echo "  jar-test -- runs the test suite against the monolithic jar"

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
	-$(QUIET)rm -rf vendor

.PHONY: compile
compile: compile-grammar compile-runner | build/ruby

.PHONY: compile-runner
compile-runner: build/ruby/logstash/runner.class
build/ruby/logstash/runner.class: lib/logstash/runner.rb | build/ruby $(JRUBY)
	#$(QUIET)(cd lib; $(JRUBYC) -5 -t ../build/ruby logstash/runner.rb)
	$(QUIET)(cd lib; $(JRUBYC) -t ../build/ruby logstash/runner.rb)

.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root
	$(QUIET)rsync -a --include "*/" --include "*.rb" --exclude "*" ./lib/ ./test/ ./build/ruby
	$(QUIET)rsync -a ./spec ./build/ruby
	$(QUIET)rsync -a ./locales ./build/ruby
	@# Delete any empty directories copied by rsync.
	$(QUIET)find ./build/ruby -type d -empty -delete

vendor:
	$(QUIET)mkdir $@

vendor/jar: | vendor
	$(QUIET)mkdir $@

build-jruby: $(JRUBY)

$(JRUBY): | vendor/jar
	$(QUIET)echo " ==> Downloading jruby $(JRUBY_VERSION)"
	$(QUIET)$(DOWNLOAD_COMMAND) $@ http://repository.codehaus.org/org/jruby/jruby-complete/$(JRUBY_VERSION)/jruby-complete-$(JRUBY_VERSION).jar

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

$(GEOIP): | vendor/geoip
	$(QUIET)wget -q -O - $(GEOIP_URL) | gzip -dc - > $@

# Always run vendor/bundle
.PHONY: fix-bundler
fix-bundler:
	-$(QUIET)rm -rf .bundle

.PHONY: vendor-gems
vendor-gems: | vendor/bundle

.PHONY: vendor/bundle
vendor/bundle: | vendor $(JRUBY)
	@echo "=> Installing gems to $@..."
	@#$(QUIET)GEM_HOME=$(GEM_HOME) $(JRUBY_CMD) --1.9 $(GEM_HOME)/bin/bundle install --deployment
	$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 ./gembag.rb logstash.gemspec
	@# Purge old version of json
	#$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 -S gem uninstall json -v 1.6.5
	@# Purge old versions of gems installed because gembag doesn't do 
	@# dependency resolution correctly.
	$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 -S gem uninstall addressable -v 2.2.8
	@# uninstall the newer ffi (1.1.5 vs 1.3.1) because that's what makes
	@#dependencies happy (launchy wants ffi 1.1.x)
	#$(QUIET)GEM_HOME=./vendor/bundle/jruby/1.9/ GEM_PATH= $(JRUBY_CMD) --1.9 -S gem uninstall ffi -v 1.3.1
	@# Purge any junk that fattens our jar without need!
	@# The riak gem includes previous gems in the 'pkg' dir. :(
	-rm -rf $@/jruby/1.9/gems/riak-client-1.0.3/pkg
	@# Purge any rspec or test directories
	-rm -rf $@/jruby/1.9/gems/*/spec $@/jruby/1.9/gems/*/test
	@# Purge any comments in ruby code.
	@#-find $@/jruby/1.9/gems/ -name '*.rb' | xargs -n1 sed -i -re '/^[ \t]*#/d; /^[ \t]*$$/d'
	touch $@

build:
	-$(QUIET)mkdir -p $@

build/ruby: | build
	-$(QUIET)mkdir -p $@

# TODO(sissel): Update this to be like.. functional.
# TODO(sissel): Skip sigar?
# Run this one always? Hmm..
.PHONY: build/monolith
build/monolith: $(ELASTICSEARCH) $(JRUBY) $(GEOIP) vendor-gems | build
build/monolith: vendor/ua-parser/regexes.yaml
build/monolith: vendor/kibana
build/monolith: compile copy-ruby-files vendor/jar/graphtastic-rmiclient.jar
	-$(QUIET)mkdir -p $@
	@# Unpack all the 3rdparty jars and any jars in gems
	$(QUIET)find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| (cd $@; xargs -n1 jar xf)
	@# Merge all service file in all 3rdparty jars
	$(QUIET)mkdir -p $@/META-INF/services/
	$(QUIET)find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| xargs $(JRUBY_CMD) extract_services.rb -o $@/META-INF/services
	@# copy openssl/lib/shared folders/files to root of jar 
	@#- need this for openssl to work with JRuby
	$(QUIET)mkdir -p $@/openssl
	$(QUIET)mkdir -p $@/jopenssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/openssl/* $@/openssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/jopenssl/* $@/jopenssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/openssl.rb $@/openssl.rb
	@# Purge any extra files we don't need in META-INF (like manifests and
	@# signature files)
	-$(QUIET)rm -f $@/META-INF/*.LIST
	-$(QUIET)rm -f $@/META-INF/*.MF
	-$(QUIET)rm -f $@/META-INF/*.RSA
	-$(QUIET)rm -f $@/META-INF/*.SF
	-$(QUIET)rm -f $@/META-INF/NOTICE $@/META-INF/NOTICE.txt
	-$(QUIET)rm -f $@/META-INF/LICENSE $@/META-INF/LICENSE.txt
	-$(QUIET)mkdir -p $@/vendor/ua-parser
	-$(QUIET)cp vendor/ua-parser/regexes.yaml $@/vendor/ua-parser
	$(QUIET)cp $(GEOIP) $@/
	-$(QUIET)rsync -a vendor/kibana/ $@/vendor/kibana/

vendor/ua-parser/: | build
	$(QUIET)mkdir $@

vendor/ua-parser/regexes.yaml: | vendor/ua-parser/
	$(QUIET)$(DOWNLOAD_COMMAND) $@ https://raw.github.com/tobie/ua-parser/master/regexes.yaml

# Learned how to do pack gems up into the jar mostly from here:
# http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar
VENDOR_DIR=$(shell ls -d vendor/bundle/*ruby/*)
jar: build/logstash-$(VERSION)-monolithic.jar
build/logstash-$(VERSION)-monolithic.jar: | build/monolith
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS=-C build/ruby .
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C build/monolith .
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C $(VENDOR_DIR) gems
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C $(VENDOR_DIR) specifications
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C lib logstash/web/public
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C lib logstash/certs
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C lib logstash/web/views
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=patterns
build/logstash-$(VERSION)-monolithic.jar:
	$(QUIET)rm -f $@
	$(QUIET)jar cfe $@ logstash.runner $(JAR_ARGS)
	@echo "Created $@"

.PHONY: build/logstash-$(VERSION)-monolithic.jar

build/flatgems: | build vendor/bundle
	mkdir $@
	for i in $(VENDOR_DIR)/gems/*/lib $(VENDOR_DIR)/gems/*/data; do \
		rsync -a $$i/ $@/$$(basename $$i) ; \
	done
	@# Until I implement something that looks at the 'require_paths' from
	@# all the gem specs.
	$(QUIET)rsync -a $(VENDOR_DIR)/gems/jruby-openssl-*/lib/shared/jopenssl.jar $@/lib
	#$(QUIET)rsync -a $(VENDOR_DIR)/gems/sys-uname-*/lib/unix/ $@/lib
	@# Other lame hacks to get crap to work.
	$(QUIET)rsync -a $(VENDOR_DIR)/gems/sass-*/VERSION_NAME $@/root/
	$(QUIET)rsync -a $(VENDOR_DIR)/gems/user_agent_parser-*/vendor/ua-parser $@/vendor

flatjar-test:
	cd build && GEM_HOME= GEM_PATH= java -jar logstash-$(VERSION)-flatjar.jar rspec $(TESTS)
	cd build && GEM_HOME= GEM_PATH= java -jar logstash-$(VERSION)-flatjar.jar rspec spec/jar.rb

jar-test:
	cd build && GEM_HOME= GEM_PATH= java -jar logstash-$(VERSION)-monolithic.jar rspec $(TESTS)
	cd build && GEM_HOME= GEM_PATH= java -jar logstash-$(VERSION)-monolithic.jar rspec spec/jar.rb

flatjar-test-and-report:
	GEM_HOME= GEM_PATH= java -jar build/logstash-$(VERSION)-flatjar.jar rspec $(TESTS) --format h --out build/results.flatjar.html

jar-test-and-report:
	GEM_HOME= GEM_PATH= java -jar build/logstash-$(VERSION)-monolithic.jar rspec $(TESTS) --format h --out build/results.monolithic.html

flatjar: build/logstash-$(VERSION)-flatjar.jar
build/jar: | build build/flatgems build/monolith
	$(QUIET)mkdir build/jar
	$(QUIET)rsync -va build/flatgems/root/ build/flatgems/lib/ build/monolith/ build/ruby/ patterns build/flatgems/data build/jar/
	$(QUIET)(cd lib; rsync -a --delete logstash/web/public/ ../build/jar/logstash/web/public)
	$(QUIET)(cd lib; rsync -a --delete logstash/web/views/ ../build/jar/logstash/web/views)
	$(QUIET)(cd lib; rsync -a --delete logstash/certs/ ../build/jar/logstash/certs)

build/logstash-$(VERSION)-flatjar.jar: | build/jar
	$(QUIET)rm -f $@
	$(QUIET)jar cfe $@ logstash.runner -C build/jar .
	@echo "Created $@"

update-jar: copy-ruby-files compile build/ruby/logstash/runner.class
	$(QUIET)jar uf build/logstash-$(VERSION)-monolithic.jar -C build/ruby .

update-flatjar: copy-ruby-files compile build/ruby/logstash/runner.class
	$(QUIET)jar uf build/logstash-$(VERSION)-flatjar.jar -C build/ruby .

.PHONY: test
test: | $(JRUBY) vendor-elasticsearch
	@#$(JRUBY_CMD) bin/logstash test
	GEM_HOME= GEM_PATH= bin/logstash rspec $(TESTS)

.PHONY: docs
docs: docgen doccopy docindex

doccopy: $(addprefix build/,$(shell git ls-files | grep '^docs/')) | build/docs
docindex: build/docs/index.html

docgen: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))

build/docs: build
	-$(QUIET)mkdir $@

build/docs/inputs build/docs/filters build/docs/outputs: | build/docs
	-$(QUIET)mkdir $@

# bluecloth gem doesn't work on jruby. Use ruby.
build/docs/inputs/%.html: lib/logstash/inputs/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/inputs
	$(QUIET)ruby docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -re 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -re 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@
build/docs/filters/%.html: lib/logstash/filters/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/filters
	$(QUIET)ruby docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -re 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -re 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@
build/docs/outputs/%.html: lib/logstash/outputs/%.rb docs/docgen.rb docs/plugin-doc.html.erb | build/docs/outputs
	$(QUIET)ruby docs/docgen.rb -o build/docs $<
	$(QUIET)sed -i -re 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -re 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@

build/docs/%: docs/% lib/logstash/version.rb Makefile
	@echo "Copying $< (to $@)"
	-$(QUIET)mkdir -p $(shell dirname $@)
	$(QUIET)cp $< $@
	$(QUIET)sed -i -re 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -re 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@

build/docs/index.html: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))
build/docs/index.html: docs/generate_index.rb lib/logstash/version.rb docs/index.html.erb Makefile
	@echo "Building documentation index.html"
	$(QUIET)ruby $< build/docs > $@
	$(QUIET)sed -i -re 's/%VERSION%/$(VERSION)/g' $@
	$(QUIET)sed -i -re 's/%ELASTICSEARCH_VERSION%/$(ELASTICSEARCH_VERSION)/g' $@

rpm: build/logstash-$(VERSION)-monolithic.jar
	rm -rf build/root
	mkdir -p build/root/opt/logstash
	cp -rp patterns build/root/opt/logstash/patterns
	cp build/logstash-$(VERSION)-monolithic.jar build/root/opt/logstash
	(cd build; fpm -t rpm -d jre -a noarch -n logstash -v $(VERSION) -s dir -C root opt)

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
	$(QUIET)ruby pull_release_note.rb

package:
	[ ! -f build/logstash-$(VERSION)-flatjar.jar ] \
		&& make build/logstash-$(VERSION)-flatjar.jar ; \
	(cd pkg; \
		./build.sh ubuntu 12.10; \
		./build.sh centos 6; \
		./build.sh debian 6; \
	)

vendor/kibana: | build
	$(QUIET)mkdir vendor/kibana || true
	$(DOWNLOAD_COMMAND) - $(KIBANA_URL) | tar -C $@ -zx --strip-components=1
