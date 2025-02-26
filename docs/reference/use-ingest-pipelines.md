---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/use-ingest-pipelines.html
---

# Use ingest pipelines for parsing [use-ingest-pipelines]

When you use {{filebeat}} modules with {{ls}}, you can use the ingest pipelines provided by {{filebeat}} to parse the data. You need to load the pipelines into {{es}} and configure {{ls}} to use them.

**To load the ingest pipelines:**

On the system where {{filebeat}} is installed, run the `setup` command with the `--pipelines` option specified to load ingest pipelines for specific modules. For example, the following command loads ingest pipelines for the system and nginx modules:

```shell
filebeat setup --pipelines --modules nginx,system
```

A connection to {{es}} is required for this setup step because {{filebeat}} needs to load the ingest pipelines into {{es}}. If necessary, you can temporarily disable your configured output and enable the {{es}} output before running the command.

**To configure {{ls}} to use the pipelines:**

On the system where {{ls}} is installed, create a {{ls}} pipeline configuration that reads from a {{ls}} input, such as {{beats}} or Kafka, and sends events to an {{es}} output. Set the `pipeline` option in the {{es}} output to `%{[@metadata][pipeline]}` to use the ingest pipelines that you loaded previously.

Here’s an example configuration that reads data from the Beats input and uses {{filebeat}} ingest pipelines to parse data collected by modules:

```yaml
input {
  beats {
    port => 5044
  }
}

output {
  if [@metadata][pipeline] {
    elasticsearch {
      hosts => "https://061ab24010a2482e9d64729fdb0fd93a.us-east-1.aws.found.io:9243"
      manage_template => false
      index => "%{[@metadata][beat]}-%{[@metadata][version]}" <1>
      action => "create" <2>
      pipeline => "%{[@metadata][pipeline]}" <3>
      user => "elastic"
      password => "secret"
    }
  } else {
    elasticsearch {
      hosts => "https://061ab24010a2482e9d64729fdb0fd93a.us-east-1.aws.found.io:9243"
      manage_template => false
      index => "%{[@metadata][beat]}-%{[@metadata][version]}" <1>
      action => "create"
      user => "elastic"
      password => "secret"
    }
  }
}
```

1. If data streams are disabled in your configuration, set the `index` option to `%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}`. Data streams are enabled by default.
2. If you are disabling the use of Data Streams on your configuration, you can remove this setting, or set it to a different value as appropriate.
3. Configures {{ls}} to select the correct ingest pipeline based on metadata passed in the event.


See the {{filebeat}} [Modules](beats://docs/reference/filebeat/filebeat-modules-overview.md) documentation for more information about setting up and running modules.

For a full example, see [Example: Set up {{filebeat}} modules to work with Kafka and {{ls}}](/reference/use-filebeat-modules-kafka.md).

