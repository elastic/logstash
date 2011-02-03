
elasticsearch-%.tar.gz:
	wget --no-check-certificate http://github.com/downloads/elasticsearch/elasticsearch/$@

elasticsearch-%:
	$(MAKE) $@.tar.gz
	tar -zxf $@.tar.gz

run-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	cd elasticsearch-$*; \
	bin/plugin install river-rabbitmq; \
	bin/elasticsearch -f
