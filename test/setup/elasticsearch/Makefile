
elasticsearch-%.zip:
	wget --no-check-certificate http://github.com/downloads/elasticsearch/elasticsearch/$@

elasticsearch-%:
	$(MAKE) $@.zip
	unzip $@.zip

run-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	cd elasticsearch-$*; \
	bin/plugin install river-rabbitmq; \
	bin/elasticsearch -f

wipe-elasticsearch-%:
	$(MAKE) elasticsearch-$*
	rm -rf elasticsearch-$*/{work,data}

remove-elasticsearch-%:
	rm -rf elasticsearch-$* elasticsearch-$*.zip
