---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/connecting-to-cloud.html
---

# Sending data to {{ech}} [connecting-to-cloud]

[{{ech}}](https://cloud.elastic.co/) simplifies safe, secure communication between {{ls}} and {{es}}.
When you configure the Elasticsearch output plugin to use [`cloud_id`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id) with either the [`cloud_auth` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_auth) or the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key), no additional SSL configuration is needed.

Examples:



* `output {elasticsearch { cloud_id => "<cloud id>" cloud_auth => "<cloud auth>" } }`
* `output {elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" } }`

Note that the value of the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) is in the format `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).

{{ess-leadin-short}}

## Cloud ID [cloud-id]

{{ls}} uses the Cloud ID, found in the Elastic Cloud web console, to build the Elasticsearch and Kibana hosts settings. It is a base64 encoded text value of about 120 characters made up of upper and lower case letters and numbers. If you have several Cloud IDs, you can add a label, which is ignored internally, to help you tell them apart. To add a label, prefix your Cloud ID with a label and a `:` separator in this format "<label>:<cloud-id>".


## Cloud Auth [cloud-auth]

Cloud Auth is optional. Construct this value by following this format "<username>:<password>". Use your Cloud username for the first part. Use your Cloud password for the second part, which is given once in the Cloud UI when you create a cluster. If you change your Cloud password in the Cloud UI, remember to change it here, too.


## Using Cloud ID and Cloud Auth with plugins [cloud-id-plugins]

The Elasticsearch input, output, and filter plugins, as well as the Elastic_integration filter plugin, support cloud_id and cloud_auth in their configurations.

* [Elasticsearch input plugin](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-cloud_id)
* [Elasticsearch filter plugin](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-cloud_id)
* [Elasticsearch output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id)
* [Elastic_integration filter plugin](logstash-docs-md://lsr/plugins-filters-elastic_integration.md#plugins-filters-elastic_integration-cloud_id)


## Using {{ls}} Central Pipeline Management with {{ech}} [cloud-id-mgmt]

These settings in the `logstash.yml` config file can help you get set up to use Central Pipeline Management in Elastic Cloud:

* `xpack.management.elasticsearch.cloud_id`
* `xpack.management.elasticsearch.cloud_auth`

You can use the `xpack.management.elasticsearch.cloud_id` setting as an alternative to `xpack.management.elasticsearch.hosts`.

You can use the `xpack.management.elasticsearch.cloud_auth` setting as an alternative to both `xpack.management.elasticsearch.username` and `xpack.management.elasticsearch.password`. The credentials you specify here should be for a user with the logstash_admin role, which provides access to .logstash-* indices for managing configurations.


