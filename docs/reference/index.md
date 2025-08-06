---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/index.html
  - https://www.elastic.co/guide/en/logstash/current/introduction.html
  - https://www.elastic.co/guide/en/serverless/current/elasticsearch-ingest-data-through-logstash.html
---

# Logstash [introduction]

Logstash is an open source data collection engine with real-time pipelining capabilities.
Logstash can dynamically unify data from disparate sources and normalize the data into destinations of your choice.
Cleanse and democratize all your data for diverse advanced downstream analytics and visualization use cases.

While Logstash originally drove innovation in log collection, its capabilities extend well beyond that use case.
Any type of event can be enriched and transformed with a broad array of input, filter, and output plugins, with many native codecs further simplifying the ingestion process.
Logstash accelerates your insights by harnessing a greater volume and variety of data.

::::{admonition} {{ls}} to {{serverless-full}}
You’ll use the {{ls}} [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) to send data to {{serverless-full}}.
Note these differences between {{es-serverless}} and both {{ech}} and self-managed {{es}}:

* Use [**API keys**](/reference/secure-connection.md#ls-api-keys) to access {{serverless-full}} from {{ls}} as it does not support native user authentication.
  Any user-based security settings in your [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) configuration are ignored and may cause errors.
* {{serverless-full}} uses **data streams** and [{{dlm}} ({{dlm-init}})](docs-content://manage-data/lifecycle/data-stream.md) instead of {{ilm}} ({{ilm-init}}). Any {{ilm-init}} settings in your [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) configuration are ignored and may cause errors.
* **{{ls}} monitoring** is available through the [{{ls}} Integration](https://github.com/elastic/integrations/blob/main/packages/logstash/_dev/build/docs/README.md) in [Elastic Observability](docs-content://solutions/observability.md) on {{serverless-full}}.

**Known issue for Logstash to Elasticsearch Serverless.**
The logstash-output-elasticsearch `hosts` setting defaults to port :9200.
Set the value to port :443 instead.

::::
