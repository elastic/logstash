---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/multiple-pipelines.html
---

# Multiple Pipelines [multiple-pipelines]

If you need to run more than one pipeline in the same process, Logstash provides a way to do this through a configuration file called `pipelines.yml`. This file must be placed in the `path.settings` folder and follows this structure:

```yaml
- pipeline.id: my-pipeline_1
  path.config: "/etc/path/to/p1.config"
  pipeline.workers: 3
- pipeline.id: my-other-pipeline
  path.config: "/etc/different/path/p2.cfg"
  queue.type: persisted
```

This file is formatted in YAML and contains a list of dictionaries, where each dictionary describes a pipeline, and each key/value pair specifies a setting for that pipeline. The example shows two different pipelines described by their IDs and  configuration paths. For the first pipeline, the value of `pipeline.workers` is set to 3, while in the other, the persistent queue feature is enabled. The value of a setting that is not explicitly set in the `pipelines.yml` file will fall back to the default specified in the `logstash.yml` [settings file](/reference/logstash-settings-file.md).

When you start Logstash without arguments, it will read the `pipelines.yml` file and instantiate all pipelines specified in the file. On the other hand, when you use `-e` or `-f`, Logstash ignores the `pipelines.yml` file and logs a warning about it.

## Usage Considerations [multiple-pipeline-usage]

Using multiple pipelines is especially useful if your current configuration has event flows that don’t share the same inputs/filters and outputs and are being separated from each other using tags and conditionals.

Having multiple pipelines in a single instance also allows these event flows to have different performance and durability parameters (for example, different settings for pipeline workers and persistent queues). This separation means that a blocked output in one pipeline won’t exert backpressure in the other.

That said, it’s important to take into account resource competition between the pipelines, given that the default values are tuned for a single pipeline. So, for example, consider reducing the number of pipeline workers used by each pipeline, because each pipeline will use 1 worker per CPU core by default.

Persistent queues and dead letter queues are isolated per pipeline, with their locations namespaced by the `pipeline.id` value.


