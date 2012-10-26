# Requirements to build:
#   ant
#   cpio
#   wget or curl
#
JRUBY_VERSION=1.7.0
ELASTICSEARCH_VERSION=0.19.10
JODA_VERSION=2.1
#VERSION=$(shell ruby -r./lib/logstash/version -e 'puts LOGSTASH_VERSION')
VERSION=$(shell awk -F\" '/LOGSTASH_VERSION/ {print $$2}' lib/logstash/version.rb )

WITH_JRUBY=java -jar $(shell pwd)/$(JRUBY) -S
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
JRUBY_URL=http://repository.codehaus.org/org/jruby/jruby-complete/$(JRUBY_VERSION)
JRUBY_CMD=java -jar $(JRUBY)
JRUBYC=$(WITH_JRUBY) jrubyc
ELASTICSEARCH_URL=http://github.com/downloads/elasticsearch/elasticsearch
ELASTICSEARCH=vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION)
JODA=vendor/jar/joda-time-$(JODA_VERSION)/joda-time-$(JODA_VERSION).jar
GEOIP=vendor/geoip/GeoCityLite.dat
GEOIP_URL=http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
PLUGIN_FILES=$(shell git ls-files | egrep '^lib/logstash/(inputs|outputs|filters)/' | egrep -v '/(base|threadable).rb$$|/inputs/ganglia/')
GEM_HOME=build/gems
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

default: jar

# Figure out if we're using wget or curl
.PHONY: wget-or-curl
wget-or-curl:
ifeq ($(WGET),)
ifeq ($(CURL),)
	@echo "wget or curl are required."
	exit 1
else
DOWNLOAD_COMMAND=curl -L -k -o
endif
else
DOWNLOAD_COMMAND=wget --no-check-certificate -O
endif

# Compile config grammar (ragel -> ruby)
.PHONY: compile-grammar
compile-grammar: lib/logstash/config/grammar.rb
lib/logstash/config/grammar.rb: lib/logstash/config/grammar.rl
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
	$(QUIET)(cd lib; $(JRUBYC) -5 -t ../build/ruby logstash/runner.rb)

# TODO(sissel): Stop using cpio for this
.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root.
	$(QUIET)find ./lib -name '*.rb' | sed -e 's,^\./lib/,,' \
	| (cd lib; cpio -p --make-directories ../build/ruby)
	$(QUIET)find ./test -name '*.rb' | sed -e 's,^\./test/,,' \
	| (cd test; cpio -p --make-directories ../build/ruby)

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

vendor/jar/joda-time-$(JODA_VERSION)-dist.tar.gz: | wget-or-curl vendor/jar
	$(DOWNLOAD_COMMAND) $@ "http://downloads.sourceforge.net/project/joda-time/joda-time/$(JODA_VERSION)/joda-time-$(JODA_VERSION)-dist.tar.gz"

vendor/jar/joda-time-$(JODA_VERSION)/joda-time-$(JODA_VERSION).jar: vendor/jar/joda-time-$(JODA_VERSION)-dist.tar.gz | vendor/jar
	tar -C vendor/jar -zxf $< joda-time-$(JODA_VERSION)/joda-time-$(JODA_VERSION).jar

vendor/geoip: | vendor
	$(QUIET)mkdir $@

$(GEOIP): | vendor/geoip
	$(QUIET)wget -q -O - http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz \
		| gzip -dc - > $@

# Always run vendor/bundle
.PHONY: fix-bundler
fix-bundler:
	-$(QUIET)rm -rf .bundle

.PHONY: vendor-gems
vendor-gems: | vendor/bundle

$(GEM_HOME)/bin/bundle: | $(JRUBY)
	@echo "=> Installing bundler ($@)"
	$(QUIET)GEM_HOME=$(GEM_HOME) $(WITH_JRUBY) gem install bundler

.PHONY: vendor/bundle
vendor/bundle: | $(GEM_HOME)/bin/bundle fix-bundler
	@echo "=> Installing gems to $@..."
	$(QUIET)GEM_HOME=$(GEM_HOME) $(JRUBY_CMD) --1.9 $(GEM_HOME)/bin/bundle install --deployment
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
build/monolith: $(ELASTICSEARCH) $(JRUBY) $(JODA) $(GEOIP) vendor-gems | build
build/monolith: compile copy-ruby-files vendor/jar/graphtastic-rmiclient.jar
	-$(QUIET)mkdir -p $@
	@# Unpack all the 3rdparty jars and any jars in gems
	$(QUIET)find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| (cd $@; xargs -n1 jar xf)
	@# copy openssl/lib/shared folders/files to root of jar - need this for openssl to work with JRuby
	$(QUIET)mkdir -p $@/openssl
	$(QUIET)mkdir -p $@/jopenssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/openssl/* $@/openssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/jopenssl/* $@/jopenssl
	$(QUIET)cp -r $$PWD/vendor/bundle/jruby/1.9/gems/jruby-openss*/lib/shared/openssl.rb $@/openssl.rb
	@# Make sure joda-time gets unpacked last, so it overwrites the joda jruby
	@# ships with.
	$(QUIET)find $$PWD/vendor/jar/joda-time-$(JODA_VERSION) -name '*.jar' \
	| (cd $@; xargs -tn1 jar xf)
	@# Purge any extra files we don't need in META-INF (like manifests and
	@# signature files)
	-$(QUIET)rm -f $@/META-INF/*.LIST
	-$(QUIET)rm -f $@/META-INF/*.MF
	-$(QUIET)rm -f $@/META-INF/*.RSA
	-$(QUIET)rm -f $@/META-INF/*.SF
	-$(QUIET)rm -f $@/META-INF/NOTICE $@/META-INF/NOTICE.txt
	-$(QUIET)rm -f $@/META-INF/LICENSE $@/META-INF/LICENSE.txt
	$(QUIET)cp $(GEOIP) $@/

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
	$(QUIET)jar cfe $@ logstash.runner $(JAR_ARGS)
	$(QUIET)jar i $@
	@echo "Created $@"

update-jar: copy-ruby-files
	$(QUIET)jar uf build/logstash-$(VERSION)-monolithic.jar -C build/ruby .

.PHONY: test
test: | $(JRUBY) vendor-elasticsearch
	$(QUIET)$(JRUBY_CMD) bin/logstash test

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
