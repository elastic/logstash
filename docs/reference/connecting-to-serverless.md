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
To send data to a {{serverless-short}} project, configure the {{ls}} {{es}} output plugin to connect using the project's **{{es}} endpoint URL** and an **API key**.

```ruby
output {elasticsearch { hosts => "ELASTICSEARCH_ENDPOINT_URL" api_key => "<api key>" } }
```

The value of the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) is in the format `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).


### {{es}} endpoint URL 

1. Log in to [Elastic Cloud](https://cloud.elastic.co/).

2. Find your **{{es}} endpoint URL**:

    Select **Manage** next to your project. Then find the {{es}} endpoint under **Application endpoints, cluster and component IDs**. 

    Alternatively, open your project, select the help icon, then select **Connection details**.


### API key [api-key]    

Create an **API key** with the appropriate privileges. Refer to [Create API key](docs-content://solutions/search/search-connection-details.md#create-an-api-key-serverless) for detailed steps. For information on the required privileges, refer to [Grant access using API keys](/reference/secure-connection.md#ls-create-api-key).

When you create an API key for {{ls}}, select **Logstash** from the **API key format** dropdown.
This option formats the API key in the correct `id:api_key` format required by {{ls}}.

:::{image} images/logstash_api_key_format.png
:alt: API key format dropdown set to {{ls}}:
:screenshot:
:width: 400px
:::

## Using {{ls}} Central Pipeline Management with {{es-serverless}} [cpm-serverless]

To set up Central Pipeline management in {{es-serverless}}, update the `logstash.yml` config file to provide the API key and set the value for `xpack.management.elasticsearch.hosts` to your Elasticsearch endpoint URL.
