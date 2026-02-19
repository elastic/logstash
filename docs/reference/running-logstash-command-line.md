---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/running-logstash-command-line.html
---

# Running Logstash from the Command Line [running-logstash-command-line]

::::{admonition} macOS Gatekeeper warnings
:class: important

Apple’s rollout of stricter notarization requirements affected the notarization of the {{version.stack}} {{ls}} artifacts. If macOS Catalina displays a dialog when you first run {{ls}} that interrupts it, you will need to take an action to allow it to run. To prevent Gatekeeper checks on the {{ls}} files, run the following command on the downloaded `.tar.gz` archive or the directory to which was extracted:

```sh
xattr -d -r com.apple.quarantine <archive-or-directory>
```

For example, if the `.tar.gz` file was extracted to the default logstash-{{version.stack}} directory, the command is:

```sh subs=true
xattr -d -r com.apple.quarantine logstash-{{version.stack}}
```

Alternatively, you can add a security override if a Gatekeeper popup appears by following the instructions in the *How to open an app that hasn’t been notarized or is from an unidentified developer* section of [Safely open apps on your Mac](https://support.apple.com/en-us/HT202491).

::::


To run Logstash from the command line, use the following command:

```shell
bin/logstash [options]
```

To run Logstash from the Windows command line, use the following command:

```shell
bin/logstash.bat [options]
```

Where `options` are [command-line](#command-line-flags) flags that you can specify to control Logstash execution. The location of the `bin` directory varies by platform. See [Logstash Directory Layout](/reference/dir-layout.md) to find the location of `bin\logstash` on your system.

The following example runs Logstash and loads the Logstash config defined in the `mypipeline.conf` file:

```shell
bin/logstash -f mypipeline.conf
```

Any flags that you set at the command line override the corresponding settings in [logstash.yml](/reference/logstash-settings-file.md), but the file itself is not changed. It remains as-is for subsequent Logstash runs.

Specifying command line options is useful when you are testing Logstash. However, in a production environment, we recommend that you use [logstash.yml](/reference/logstash-settings-file.md) to control Logstash execution. Using the settings file makes it easier for you to specify multiple options, and it provides you with a single, versionable file that you can use to start up Logstash consistently for each run.

## Command-Line Flags [command-line-flags]

Logstash has the following flags. You can use the `--help` flag to display this information.

**`--node.name NAME`**
:   Specify the name of this Logstash instance. If no value is given it will default to the current hostname.

**`-f, --path.config CONFIG_PATH`**
:   Load the Logstash config from a specific file or directory. If a directory is given, all files in that directory will be concatenated in lexicographical order and then parsed as a single config file. Specifying this flag multiple times is not supported. If you specify this flag multiple times, Logstash uses the last occurrence (for example, `-f foo -f bar` is the same as `-f bar`).

    You can specify wildcards ([globs](/reference/glob-support.md)) and any matched files will be loaded in the order described above. For example, you can use the wildcard feature to load specific files by name:

    ```shell
    bin/logstash --debug -f '/tmp/{one,two,three}'
    ```

    With this command, Logstash concatenates three config files, `/tmp/one`, `/tmp/two`, and `/tmp/three`, and parses them into a single config.


**`-e, --config.string CONFIG_STRING`**
:   Use the given string as the configuration data. Same syntax as the config file. If no input is specified, then the following is used as the default input: `input { stdin { type => stdin } }` and if no output is specified, then the following is used as the default output: `output { stdout { codec => rubydebug } }`. If you wish to use both defaults, please use the empty string for the `-e` flag. The default is nil.

**`--plugin-classloaders`**
:   (Beta) Load Java plugins in independent classloaders to isolate their dependencies.

**`--pipeline.id ID`**
:   Sets the ID of pipeline. The default is `main`.

**`-w, --pipeline.workers COUNT`**
:   Sets the number of pipeline workers to run. This option sets the number of workers that will, in parallel, execute the filter and output stages of the pipeline. If you find that events are backing up, or that  the CPU is not saturated, consider increasing this number to better utilize machine processing power. The default is the number of the host’s CPU cores.

**`--pipeline.ordered ORDERED`**
:   Preserves events order. Possible values are `auto` (default), `true` and `false`. This setting will work only when also using a single worker for the pipeline. Note that when enabled, it may impact the performance of the filters and output processing. The `auto` option will automatically enable ordering if the `pipeline.workers` setting is set to `1`. Use `true` to enable ordering on the pipeline and prevent logstash from starting if there are multiple workers. Use `false` to disable any extra processing necessary for preserving ordering.

**`-b, --pipeline.batch.size SIZE`**
:   Size of batches the pipeline is to work in. This option defines the maximum number of events an individual worker thread will collect from inputs before attempting to execute its filters and outputs. The default is 125 events. Larger batch sizes are generally more efficient, but come at the cost of increased memory overhead. You may need to increase JVM heap space in the `jvm.options` config file. See [Logstash Configuration Files](/reference/config-setting-files.md) for more info.

**`-u, --pipeline.batch.delay DELAY_IN_MS`**
:   When creating pipeline batches, how long to wait while polling for the next event. This option defines how long in milliseconds to wait while polling for the next event before dispatching an undersized batch to filters and outputs. The default is 50ms.

**`--pipeline.batch.output_chunking.growth_threshold_factor FACTOR`**
:   Controls how a batch is sent to outputs. If a batch increases in size after being passed through filters by a factor exceeding this growth threshold factor, the batch is split into chunks of the configured batch size and sent to the outputs. This helps manage memory when filters significantly increase the number of events. The default value is 1000 (effectively no chunking for most use cases).

**`--pipeline.ecs_compatibility MODE`**
:   Sets the process default value for  ECS compatibility mode. Can be an ECS version like `v1` or `v8`, or `disabled`. The default is `v8`. Pipelines defined before Logstash 8 operated without ECS in mind. To ensure a migrated pipeline continues to operate as it did in older releases of Logstash, opt-OUT of ECS for the individual pipeline by setting `pipeline.ecs_compatibility: disabled` in its `pipelines.yml` definition. Using the command-line flag will set the default for *all* pipelines, including new ones. See [ECS compatibility](/reference/ecs-ls.md#ecs-compatibility) for more info.

**`--pipeline.unsafe_shutdown`**
:   Force Logstash to exit during shutdown even if there are still inflight events in memory. By default, Logstash will refuse to quit until all received events have been pushed to the outputs. Enabling this option can lead to data loss during shutdown.

**`--path.data PATH`**
:   This should point to a writable directory. Logstash will use this directory whenever it needs to store data. Plugins will also have access to this path. The default is the `data` directory under Logstash home.

**`-p, --path.plugins PATH`**
:   A path of where to find custom plugins. This flag can be given multiple times to include multiple paths. Plugins are expected to be in a specific directory hierarchy: `PATH/logstash/TYPE/NAME.rb` where `TYPE` is `inputs`, `filters`, `outputs`, or `codecs`, and `NAME` is the name of the plugin.

**`-l, --path.logs PATH`**
:   Directory to write Logstash internal logs to.

**`--log.level LEVEL`**
:   Set the log level for Logstash. Possible values are:

    * `fatal`: log very severe error messages that will usually be followed by the application aborting
    * `error`: log errors
    * `warn`: log warnings
    * `info`: log verbose info (this is the default)
    * `debug`: log debugging info (for developers)
    * `trace`: log finer-grained messages beyond debugging info


**`--config.debug`**
:   Show the fully compiled configuration as a debug log message (you must also have `--log.level=debug` enabled).

    :::{warning}
    The log message will include any *password* options passed to plugin configs as plaintext, and may result in plaintext passwords appearing in your logs!
    :::

**`-i, --interactive SHELL`**
:   Drop to shell instead of running as normal. Valid shells are "irb" and "pry".

**`-V, --version`**
:   Emit the version of Logstash and its friends, then exit.

**`-t, --config.test_and_exit`**
:   Check configuration for valid syntax and then exit. Note that grok patterns are not checked for correctness with this flag. Logstash can read multiple config files from a directory. If you combine this flag with `--log.level=debug`, Logstash will log the combined config file, annotating each config block with the source file it came from.

**`-r, --config.reload.automatic`**
:   Monitor configuration changes and reload whenever the configuration is changed.

    :::{note}
    Use SIGHUP to manually reload the config. The default is false.
    :::

**`--config.reload.interval RELOAD_INTERVAL`**
:   How frequently to poll the configuration location for changes. The default value is "3s". Note that the unit qualifier (`s`) is required.

**`--api.enabled ENABLED`**
:   The HTTP API is enabled by default, but can be disabled by passing `false` to this option.

**`--api.http.host HTTP_HOST`**
:   Web API binding host. This option specifies the bind address for the metrics REST endpoint. The default is "127.0.0.1".

**`--api.http.port HTTP_PORT`**
:   Web API http port. This option specifies the bind port for the metrics REST endpoint. The default is 9600-9700. This setting accepts a range of the format 9600-9700. Logstash will pick up the first available port.

**`--log.format FORMAT`**
:   Specify if Logstash should write its own logs in JSON form (one event per line) or in plain text (using Ruby’s Object#inspect). The default is "plain".

**`--log.format.json.fix_duplicate_message_fields ENABLED`**
:   Avoid `message` field collision using JSON log format. Possible values are `true` (default) and `false`.

**`--path.settings SETTINGS_DIR`**
:   Set the directory containing the `logstash.yml` [settings file](/reference/logstash-settings-file.md) as well as the log4j logging configuration. This can also be set through the LS_SETTINGS_DIR environment variable. The default is the `config` directory under Logstash home.

**`--enable-local-plugin-development`**
:   This flag enables developers to update their local Gemfile without running into issues caused by a frozen lockfile. This flag can be helpful when you are developing/testing plugins locally.

::::{note}
This flag is for Logstash developers only. End users should not need it.
::::


**`-h, --help`**
:   Print help


