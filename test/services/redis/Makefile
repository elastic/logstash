VERSION?=2.4.17
TARBALL=redis-$(VERSION).tar.gz
DIR=redis-$(VERSION)
BASEURL=http://redis.googlecode.com/files

default: build

run: | build
	$(DIR)/src/redis-server

fetch: $(TARBALL)
extract: $(DIR) | fetch

build: $(DIR)/src/redis-server

$(DIR)/src/redis-server: | extract
	cd $(DIR); make

clean:
	-rm -rf $(DIR)

distclean:
	-rm -f $(TARBALL)

$(TARBALL):
	wget $(BASEURL)/$@

$(DIR): | $(TARBALL)
	tar -zxf $(TARBALL)
