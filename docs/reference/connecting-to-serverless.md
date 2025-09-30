---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/connecting-to-cloud.html
---

# Sending data to {{es-serverless}} [logstash-to-elasticsearch-serverless]

When you use Elasticsearch on Elastic Cloud Serverless you don’t need to worry about managing the infrastructure that keeps Elasticsearch distributed and available. These resources are automated on the serverless platform and are designed to scale up and down with your workload.

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

## Communication between {{ls}} and {{es-serverless}} [connecting-to-elasticsearch-serverless]

[{{es-serverless}}](docs-content://solutions/search/serverless-elasticsearch-get-started.md) simplifies safe, secure communication between {{ls}} and {{es}}.
When you configure the Elasticsearch output plugin to use [`cloud_id`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id) and an [`api_key`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key), no additional SSL configuration is needed.

Example:

* `output {elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" } }`

Note that the value of the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) is in the format `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).


### Cloud ID [cloud-id]

{{ls}} uses the Cloud ID, found in the Elastic Cloud web console, to build the Elasticsearch and Kibana hosts settings. It is a base64 encoded text value of about 120 characters made up of upper and lower case letters and numbers. If you have several Cloud IDs, you can add a label, which is ignored internally, to help you tell them apart. To add a label, prefix your Cloud ID with a label and a `:` separator in this format "<label>:<cloud-id>".


### API key [api-key]

When you create an API key for {{ls}}, select **Logstash** from the **API key format** dropdown.
This option formats the API key in the correct `id:api_key` format required by {{ls}}.

:::{image} images/logstash_api_key_format.png
:alt: API key format dropdown set to {{ls}}:
:screenshot:
:width: 400px
:::

The UI for API keys may look different depending on the deployment type.

## Using Cloud ID with plugins [cloud-id-serverless]

The Elasticsearch input, output, and filter plugins, as well as the Elastic_integration filter plugin, support cloud_id in their configurations.

* [Elasticsearch input plugin](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-cloud_id)
* [Elasticsearch filter plugin](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-cloud_id)
* [Elasticsearch output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id)
* [Elastic_integration filter plugin](logstash-docs-md://lsr/plugins-filters-elastic_integration.md#plugins-filters-elastic_integration-cloud_id)



## Using {{ls}} Central Pipeline Management with {{es-serverless}} [cpm-serverless]

This setting in the `logstash.yml` config file can help you get set up to use Central Pipeline management in Elastic Cloud:

* `xpack.management.elasticsearch.cloud_id`

You can use the `xpack.management.elasticsearch.cloud_id` setting as an alternative to `xpack.management.elasticsearch.hosts`.

