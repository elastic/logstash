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

## {{ls}} to {{serverless-full}} [plugins-outputs-elasticsearch-serverless]

You'll use the {{ls}} [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) to send {{ls}} data to {{serverless-full}}. Note the following differences between {{es-serverless}} and both {{ech}} and self-managed {{es}}:

* Use **API keys** to access {{serverless-full}} from {{ls}}. Any user-based security settings in your [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) configuration are ignored and may cause errors.

* {{serverless-full}} uses **data streams** and [{{dlm}} ({{dlm-init}})](docs-content://manage-data/lifecycle/data-stream.md) instead of {{ilm}} ({{ilm-init}}). Any {{ilm-init}} settings in your [{{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) configuration are ignored and may cause errors.

* **{{ls}} monitoring** is available through the [{{ls}} Integration](https://github.com/elastic/integrations/blob/main/packages/logstash/_dev/build/docs/README.md) in [Elastic Observability](https://docs.elastic.co/serverless/observability/what-is-observability-serverless) on {{serverless-full}}.

::::{admonition} Known issue for {{ls}} to {{es-serverless}}
The logstash-output-elasticsearch `hosts` setting on {{serverless-short}} defaults to port 9200. Set the value to port 443 instead.

::::

### API key format for {{ls}}

When configuring {{ls}} for {{serverless-full}}, you must provide the value of the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) in the format `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key). Note that base64 encoded API keys are not supported in this configuration.

If you create the API key on the {{serverless-full}} UI, make sure you select **Logstash** from the dropdown to copy the API key in the correct `id:api_key` format.

:::{image} images/logstash_api_key_format.png
:alt: API key format dropdown set to {{ls}}:
:screenshot:
:width: 500px
:::
