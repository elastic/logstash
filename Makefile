VERSION=$(shell ruby -r./VERSION -e 'puts LOGSTASH_VERSION')

JRUBY_VERSION=1.6.4
JRUBY_URL=http://repository.codehaus.org/org/jruby/jruby-complete/$(JRUBY_VERSION)
JRUBY=vendor/jar/jruby-complete-$(JRUBY_VERSION).jar
ELASTICSEARCH_VERSION=0.17.6
ELASTICSEARCH_URL=http://github.com/downloads/elasticsearch/elasticsearch
ELASTICSEARCH=vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION)

PLUGIN_FILES=$(shell git ls-files | egrep '^lib/logstash/(inputs|outputs|filters)/' | egrep -v '/base.rb$$')

default: compile

# Compile config grammar (ragel -> ruby)
.PHONY: compile-grammar
compile-grammar: lib/logstash/config/grammar.rb
lib/logstash/config/grammar.rb: lib/logstash/config/grammar.rl
	$(MAKE) -C lib/logstash/config grammar.rb

.PHONY: clean
clean:
	-rm -rf .bundle
	-rm -rf build
	-rm -rf vendor

.PHONY: compile
compile: compile-grammar compile-runner | build/ruby

.PHONY: compile-runner
compile-runner: build/ruby/logstash/runner.class
build/ruby/logstash/runner.class: lib/logstash/runner.rb | build/ruby
	(cd lib; jrubyc -t ../build/ruby logstash/runner.rb) 

# TODO(sissel): Stop using cpio for this
.PHONY: copy-ruby-files
copy-ruby-files: | build/ruby
	@# Copy lib/ and test/ files to the root.
	git ls-files | grep '^lib/.*\.rb$$' | sed -e 's,^lib/,,' \
	| (cd lib; cpio -p --make-directories ../build/ruby)
	git ls-files | grep '^test/.*\.rb$$' | sed -e 's,^test/,,' \
	| (cd test; cpio -p --make-directories ../build/ruby)

vendor: 
	mkdir $@

vendor/jar: | vendor
	mkdir $@

.PHONY: vendor-jruby
vendor-jruby: $(JRUBY)
$(JRUBY): | vendor/jar
	wget -O $@ $(JRUBY_URL)/$(shell basename $@)

vendor/jar/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz: | vendor/jar
	@# --no-check-certificate is for github and wget not supporting wildcard
	@# certs sanely.
	wget --no-check-certificate \
		-O $@ $(ELASTICSEARCH_URL)/elasticsearch-$(ELASTICSEARCH_VERSION).tar.gz

.PHONY: vendor-elasticsearch
vendor-elasticsearch: $(ELASTICSEARCH)
$(ELASTICSEARCH): $(ELASTICSEARCH).tar.gz | vendor/jar
	@echo "Pulling the jars out of $<"
	tar -C $(shell dirname $@) -xf $< --exclude '*sigar*' \
		'elasticsearch-$(ELASTICSEARCH_VERSION)/lib/*.jar'

# Always run vendor/bundle
.PHONY: fix-bundler
fix-bundler:
	-rm -rf .bundle

.PHONY: vendor-gems
vendor-gems: | vendor/bundle

.PHONY: vendor/bundle
vendor/bundle: | fix-bundler
	@echo "=> Installing gems to vendor/bundle/..."
	bundle install --path vendor/bundle

gem: logstash-$(VERSION).gem

logstash-$(VERSION).gem: compile 
	gem build logstash.gemspec

build:
	-mkdir -p $@

build/ruby: | build
	-mkdir -p $@

# TODO(sissel): Update this to be like.. functional.
# TODO(sissel): Skip sigar?
# Run this one always? Hmm..
.PHONY: build/monolith
build/monolith: vendor-elasticsearch vendor-jruby vendor-gems | build
build/monolith: compile copy-ruby-files
	-mkdir -p $@
	@# Unpack all the 3rdparty jars and any jars in gems
	find $$PWD/vendor/bundle $$PWD/vendor/jar -name '*.jar' \
	| (cd $@; xargs -tn1 jar xf)
	@# Purge any extra files we don't need in META-INF (like manifests and
	@# TODO(sissel): Simplify this.
	-rm -f $@/META-INF/{INDEX.LIST,MANIFEST.MF,ECLIPSEF.RSA,ECLIPSEF.SF}

# Learned how to do pack gems up into the jar mostly from here:
# http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar
jar: build/logstash-$(VERSION)-monolithic.jar
build/logstash-$(VERSION)-monolithic.jar: | build/monolith
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS=-C build/ruby .
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C build/monolith .
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C vendor/bundle/jruby/1.8 gems
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C vendor/bundle/jruby/1.8 specifications
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C lib logstash/web/public
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=-C lib logstash/web/views
build/logstash-$(VERSION)-monolithic.jar: JAR_ARGS+=patterns
build/logstash-$(VERSION)-monolithic.jar:
	jar cfe $@ logstash.runner $(JAR_ARGS)
	jar i $@

.PHONY: test
test: 
	ruby bin/logstash test

.PHONY: docs
docs: docgen doccopy docindex

doccopy: $(addprefix build/,$(shell git ls-files | grep '^docs/')) | build/docs
docindex: build/docs/index.html

docgen: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))

build/docs: build
	-mkdir $@

build/docs/inputs build/docs/filters build/docs/outputs: | build/docs
	-mkdir $@

build/docs/inputs/%.html: lib/logstash/inputs/%.rb | build/docs/inputs
	ruby docs/docgen.rb -o build/docs $<
build/docs/filters/%.html: lib/logstash/filters/%.rb | build/docs/filters
	ruby docs/docgen.rb -o build/docs $<
build/docs/outputs/%.html: lib/logstash/outputs/%.rb | build/docs/outputs
	ruby docs/docgen.rb -o build/docs $<

build/docs/%: docs/%
	@-mkdir -p $(shell dirname $@)
	sed -re 's/%VERSION%/$(VERSION)/g' $< > $@

build/docs/index.html: $(addprefix build/docs/,$(subst lib/logstash/,,$(subst .rb,.html,$(PLUGIN_FILES))))
build/docs/index.html: docs/generate_index.rb
	ruby $< build/docs > $@

publish: | gem
	gem push logstash-$(VERSION).gem
