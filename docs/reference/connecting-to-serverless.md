---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/connecting-to-cloud.html
---

# Sending data to {{es-serverless}} [connecting-to-elasticsearch-serverless]

[{{es-serverless}}](docs-content://solutions/search/serverless-elasticsearch-get-started.md) simplifies safe, secure communication between {{ls}} and {{es}}.
When you configure the Elasticsearch output plugin to use [`cloud_id`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id) and an [`api_key`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key), no additional SSL configuration is needed.

Example:

* `output {elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" } }`

Note that the value of the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) is in the format `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).

{{ess-leadin-short}}

## Cloud ID [cloud-id]

{{ls}} uses the Cloud ID, found in the Elastic Cloud web console, to build the Elasticsearch and Kibana hosts settings. It is a base64 encoded text value of about 120 characters made up of upper and lower case letters and numbers. If you have several Cloud IDs, you can add a label, which is ignored internally, to help you tell them apart. To add a label, prefix your Cloud ID with a label and a `:` separator in this format "<label>:<cloud-id>".



## Sending {{ls}} management data to {{es-serverless}} [mgmt-data]

These settings in the `logstash.yml` config file can help you get set up to send management data to Elastic Cloud:

* `xpack.management.elasticsearch.cloud_id`
* `xpack.management.elasticsearch.cloud_auth`

<!-- Cloud_auth isn't supported for Serverless, so Line 30 will need to be updated appropriately. -->

You can use the `xpack.management.elasticsearch.cloud_id` setting as an alternative to `xpack.management.elasticsearch.hosts`.

You can use the `xpack.management.elasticsearch.cloud_auth` setting as an alternative to both `xpack.management.elasticsearch.username` and `xpack.management.elasticsearch.password`. The credentials you specify here should be for a user with the logstash_admin role, which provides access to .logstash-* indices for managing configurations.







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