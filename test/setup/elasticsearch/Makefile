
elasticsearch-%.zip:
	wget --no-check-certificate http://github.com/downloads/elasticsearch/elasticsearch/$@

elasticsearch-%:
	$(MAKE) $@.zip
	#unzip $@.zip
	jar xf $@.xip

init-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	cd elasticsearch-$*; bin/plugin install river-rabbitmq

run-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	cd elasticsearch-$*; \
	bin/elasticsearch -f $(ESFLAGS)

wipe-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	rm -rf elasticsearch-$*/work elasticsearch-$*/data

remove-elasticsearch-%:
	rm -rf elasticsearch-$* elasticsearch-$*.zip
