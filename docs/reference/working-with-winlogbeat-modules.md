---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/winlogbeat-modules.html
---

# Working with Winlogbeat modules [winlogbeat-modules]

{{winlogbeat}} comes packaged with pre-built [modules](beats://reference/winlogbeat/winlogbeat-modules.md) that contain the configurations needed to collect, parse, enrich, and visualize data from various Windows logging providers. Each {{winlogbeat}} module consists of one or more filesets that contain ingest node pipelines, {{es}} templates, {{winlogbeat}} input configurations, and {{kib}} dashboards.

You can use {{winlogbeat}} modules with {{ls}}, but you need to do some extra setup. The simplest approach is to [set up and use the ingest pipelines](#use-winlogbeat-ingest-pipelines) provided by {{winlogbeat}}.


## Use ingest pipelines for parsing [use-winlogbeat-ingest-pipelines]

When you use {{winlogbeat}} modules with {{ls}}, you can use the ingest pipelines provided by {{winlogbeat}} to parse the data. You need to load the pipelines into {{es}} and configure {{ls}} to use them.

**To load the ingest pipelines:**

On the system where {{winlogbeat}} is installed, run the `setup` command with the `--pipelines` option specified to load ingest pipelines for specific modules. For example, the following command loads ingest pipelines for the security and sysmon modules:

```shell
winlogbeat setup --pipelines --modules security,sysmon
```

A connection to {{es}} is required for this setup step because {{winlogbeat}} needs to load the ingest pipelines into {{es}}. If necessary, you can temporarily disable your configured output and enable the {{es}} output before running the command.

**To configure {{ls}} to use the pipelines:**

On the system where {{ls}} is installed, create a {{ls}} pipeline configuration that reads from a {{ls}} input, such as {{beats}} or Kafka, and sends events to an {{es}} output. Set the `pipeline` option in the {{es}} output to `%{[@metadata][pipeline]}` to use the ingest pipelines that you loaded previously.

Here’s an example configuration that reads data from the Beats input and uses {{winlogbeat}} ingest pipelines to parse data collected by modules:

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


See the {{winlogbeat}} [Modules](beats://reference/winlogbeat/winlogbeat-modules.md) documentation for more information about setting up and running modules.

