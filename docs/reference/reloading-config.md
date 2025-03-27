---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/reloading-config.html
---

# Reloading the Config File [reloading-config]

You can set Logstash to detect and reload configuration changes automatically.

To enable automatic config reloading, start Logstash with the `--config.reload.automatic` (or `-r`) command-line option specified. For example:

```shell
bin/logstash -f apache.config --config.reload.automatic
```

::::{note}
The `--config.reload.automatic` option is not available when you specify the `-e` flag to pass in configuration settings from the command-line.
::::


By default, Logstash checks for configuration changes every 3 seconds. To change this interval, use the `--config.reload.interval <interval>` option,  where `interval` specifies how often Logstash checks the config files for changes (in seconds).

Note that the unit qualifier (`s`) is required.

## Force reloading the config file [force-reload]

If Logstash is already running without auto-reload enabled, you can force Logstash to reload the config file and restart the pipeline. Do this by sending a SIGHUP (signal hangup) to the process running Logstash. For example:

```shell
kill -SIGHUP 14175
```

Where 14175 is the ID of the process running Logstash.

::::{note}
This functionality is not supported on Windows OS.
::::



## How automatic config reloading works [_how_automatic_config_reloading_works]

When Logstash detects a change in a config file, it stops the current pipeline by stopping all inputs, and it attempts to create a new pipeline that uses the updated configuration. After validating the syntax of the new configuration, Logstash verifies that all inputs and outputs can be initialized (for example, that all required ports are open). If the checks are successful, Logstash swaps the existing pipeline with the new pipeline. If the checks fail, the old pipeline continues to function, and the errors are propagated to the console.

During automatic config reloading, the JVM is not restarted. The creating and swapping of pipelines all happens within the same process.

Changes to [grok](logstash-docs-md://lsr/plugins-filters-grok.md) pattern files are also reloaded, but only when a change in the config file triggers a reload (or the pipeline is restarted).

In general, Logstash is not watching or monitoring any configuration files used or referenced by inputs, filters or outputs.


## Plugins that prevent automatic reloading [plugins-block-reload]

Input and output plugins usually interact with OS resources. In some circumstances those resources can’t be released without a restart. For this reason some plugins can’t be simply updated and this prevents pipeline reload.

The [stdin input](logstash-docs-md://lsr/plugins-inputs-stdin.md) plugin, for example, prevents reloading for these reasons.


