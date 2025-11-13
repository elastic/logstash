---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ea-integrations.html
---

# Using Logstash with Elastic integrations [ea-integrations]

You can take advantage of the extensive, built-in capabilities of Elastic {{integrations}}--such as managing data collection, transformation, and visualization—​and then use {{ls}} for additional data processing and output options. {{ls}} can further expand capabilities for use cases where you need additional processing, or if you need your data delivered to multiple destinations.


## Elastic {{integrations}}: ingesting to visualizing [integrations-value]

[Elastic {{integrations}}](integration-docs://reference/index.md) provide quick, end-to-end solutions for:

* ingesting data from a variety of data sources,
* ensuring compliance with the [Elastic Common Schema (ECS)](ecs://reference/index.md),
* getting the data into the {{stack}}, and
* visualizing it with purpose-built dashboards.

{{integrations}} are available for [popular services and platforms](integration-docs://reference/all_integrations.md), such as Nginx, AWS, and MongoDB, as well as many generic input types like log files. Each integration includes pre-packaged assets to help reduce the time between ingest and insights.

To see available integrations, go to the {{kib}} home page, and click **Add {{integrations}}**. You can use the query bar to search for integrations you may want to use. When you find an integration for your data source, the UI walks you through adding and configuring it.


## Extend {{integrations}} with {{ls}} [integrations-and-ls]

Logstash can run the ingest pipeline component of your Elastic integration when you use the Logstash `filter-elastic_integration` plugin in your {{ls}} pipeline.

Adding the `filter-elastic_integration` plugin as the *first* filter plugin keeps the pipeline’s behavior as close as possible to the behavior you’d expect if the bytes were processed by the integration in {{es}}. The more you modify an event before calling the `elastic_integration` filter, the higher the risk that the modifications will have meaningful effect in how the event is transformed.

::::{admonition} How to
Create a {{ls}} pipeline that uses the [elastic_agent input](logstash-docs-md://lsr/plugins-inputs-elastic_agent.md) plugin, and the [elastic_integration filter](logstash-docs-md://lsr/plugins-filters-elastic_integration.md) plugin as the *first* filter in your {{ls}} pipeline. You can add more filters for additional processing, but they must come after the `logstash-filter-elastic_integration` plugin in your configuration. Add one or more output plugins to complete your pipeline.
::::


**Sample pipeline configuration**

```ruby
input {
  elastic_agent {
    port => 5044
  }
}

filter {
  elastic_integration{ <1>
    cloud_id => "<cloud id>"
    cloud_auth => "<your_cloud-auth"
  }

  translate { <2>
    source => "[http][host]"
    target => "[@metadata][tenant]"
    dictionary_path => "/etc/conf.d/logstash/tenants.yml"
  }
}

output { <3>
  if [@metadata][tenant] == "tenant01" {
    elasticsearch {
      cloud_id => "<cloud id>"
      api_key => "<api key>"
    }
  } else if [@metadata][tenant] == "tenant02" {
    elasticsearch {
      cloud_id => "<cloud id>"
      api_key => "<api key>"
    }
  }
}
```

1. Use `filter-elastic_integration` as the first filter in your pipeline
2. You can use additional filters as long as they follow `filter-elastic_integration`
3. Sample config to output data to multiple destinations



### Using `filter-elastic_integration` with `output-elasticsearch` [es-tips]

Elastic {{integrations}} are designed to work with [data streams](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data-streams) and [ECS-compatible](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#_compatibility_with_the_elastic_common_schema_ecs) output. Be sure that these features are enabled in the [`output-elasticsearch`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) plugin.

* Set [`data-stream`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data_stream) to `true`.<br> (Check out [Data streams](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-data-streams) for additional data streams settings.)
* Set [`ecs_compatibility`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ecs_compatibility) to `v1` or `v8`.

Check out the [`output-elasticsearch` plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) docs for additional settings.
