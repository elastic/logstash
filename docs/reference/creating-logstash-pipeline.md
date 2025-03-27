---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/configuration.html
---

# Creating a Logstash Pipeline [configuration]

You can create a pipeline by stringing together plugins--[inputs](logstash-docs-md://lsr/input-plugins.md), [outputs](logstash-docs-md://lsr/output-plugins.md), [filters](logstash-docs-md://lsr/filter-plugins.md), and sometimes [codecs](logstash-docs-md://lsr/codec-plugins.md)--in order to process data. To build a Logstash pipeline, create a config file to specify which plugins you want to use and the settings for each plugin.

A very basic pipeline might contain only an input and an output. Most pipelines include at least one filter plugin because that’s where the "transform" part of the ETL (extract, transform, load) magic happens. You can reference event fields in a pipeline and use conditionals to process events when they meet certain criteria.

Let’s step through creating a simple pipeline config on your local machine and then using it to run Logstash. Create a file named "logstash-simple.conf" and save it in the same directory as Logstash.

```ruby
input { stdin { } }
output {
  elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" }
  stdout { codec => rubydebug }
}
```

Then, run {{ls}} and specify the configuration file with the `-f` flag.

```ruby
bin/logstash -f logstash-simple.conf
```

Et voilà! Logstash reads the specified configuration file and outputs to both Elasticsearch and stdout. Before we move on to [more complex examples](/reference/config-examples.md), let’s take a look at what’s in a pipeline config file.






