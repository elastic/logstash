---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/config-setting-files.html
---

# Logstash Configuration Files [config-setting-files]

Logstash has two types of configuration files: *pipeline configuration files*, which define the Logstash processing pipeline, and *settings files*, which specify options that control Logstash startup and execution.

## Pipeline Configuration Files [pipeline-config-files]

You create pipeline configuration files when you define the stages of your Logstash processing pipeline. On deb and rpm, you place the pipeline configuration files in the `/etc/logstash/conf.d` directory. Logstash tries to load only files with `.conf` extension in the `/etc/logstash/conf.d directory` and ignores all other files.

See [*Creating a {{ls}} pipeline*](/reference/creating-logstash-pipeline.md) for more info.


## Settings Files [settings-files]

The settings files are already defined in the Logstash installation. Logstash includes the following settings files:

**`logstash.yml`**
:   Contains Logstash configuration flags. You can set flags in this file instead of passing the flags at the command line. Any flags that you set at the command line override the corresponding settings in the `logstash.yml` file. See [logstash.yml](/reference/logstash-settings-file.md) for more info.

**`pipelines.yml`**
:   Contains the framework and instructions for running multiple pipelines in a single Logstash instance. See [Multiple Pipelines](/reference/multiple-pipelines.md) for more info.

**`jvm.options`**
:   Contains JVM configuration flags. Use this file to set initial and maximum values for total heap space. You can also use this file to set the locale for Logstash. Specify each flag on a separate line. All other settings in this file are considered expert settings.

**`log4j2.properties`**
:   Contains default settings for `log4j 2` library. See [Log4j2 configuration](/reference/logging.md#log4j2) for more info.


