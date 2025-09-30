---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/logstash-settings-file.html
---

# logstash.yml [logstash-settings-file]

You can set options in the Logstash settings file, `logstash.yml`, to control Logstash execution. For example, you can specify pipeline settings, the location of configuration files, logging options, and other settings. Most of the settings in the `logstash.yml` file are also available as [command-line flags](/reference/running-logstash-command-line.md#command-line-flags) when you run Logstash. Any flags that you set at the command line override the corresponding settings in the `logstash.yml` file.

The `logstash.yml` file is written in [YAML](http://yaml.org/). Its location varies by platform (see [Logstash Directory Layout](/reference/dir-layout.md)). You can specify settings in hierarchical form or use flat keys. For example, to use hierarchical form to set the pipeline batch size and batch delay, you specify:

```yaml
pipeline:
  batch:
    size: 125
    delay: 50
```

To express the same values as flat keys, you specify:

```yaml
pipeline.batch.size: 125
pipeline.batch.delay: 50
```

The `logstash.yml` file also supports bash-style interpolation of environment variables and keystore secrets in setting values.

```yaml
pipeline:
  batch:
    size: ${BATCH_SIZE}
    delay: ${BATCH_DELAY:50}
node:
  name: "node_${LS_NODE_NAME}"
path:
   queue: "/tmp/${QUEUE_DIR:queue}"
```

Note that the `${VAR_NAME:default_value}` notation is supported, setting a default batch delay of `50` and a default `path.queue` of `/tmp/queue` in the above example.

The `logstash.yml` file includes these settings.

| Setting | Description | Default value |
| --- | --- | --- |
| `node.name` | A descriptive name for the node. | Machine’s hostname |
| `path.data` | The directory that Logstash and its plugins use for any persistent needs. | `LOGSTASH_HOME/data` |
| `pipeline.id` | The ID of the pipeline. | `main` |
| `pipeline.workers` | The number of workers that will, in parallel, execute the filter and outputstages of the pipeline. This setting uses the[`java.lang.Runtime.getRuntime.availableProcessors`](https://docs.oracle.com/javase/7/docs/api/java/lang/Runtime.md#availableProcessors())value as a default if not overridden by `pipeline.workers` in `pipelines.yml` or`pipeline.workers` from `logstash.yml`.  If you have modified this setting andsee that events are backing up, or that the CPU is not saturated, considerincreasing this number to better utilize machine processing power. | Number of the host’s CPU cores |
| `pipeline.batch.size` | The maximum number of events an individual worker thread will collect from inputs  before attempting to execute its filters and outputs.  Larger batch sizes are generally more efficient, but come at the cost of increased memory  overhead. You may need to increase JVM heap space in the `jvm.options` config file.  See [Logstash Configuration Files](/reference/config-setting-files.md) for more info. | `125` |
| `pipeline.batch.delay` | When creating pipeline event batches, how long in milliseconds to wait for  each event before dispatching an undersized batch to pipeline workers. | `50` |
| `pipeline.batch.metrics.sampling_mode` {applies_to}`stack: preview 9.2.0`| Controls frequency of collection of batch size metrics. These metrics measure the actual number of events and byte size of batches processed through a pipeline. This can be helpful to tune `pipeline.batch.size` to reflect the actual batch sizes processed. <br><br>Note: This feature is in **technical preview** and may change in the future.<br><br>Current options are:<br><br>* `disabled`: disabling the collection.<br>* `minimal`:  calculate based on a subset of batches.(default)<br>* `full`: calculate based on every processed batch.<br> | `minimal` |
| `pipeline.unsafe_shutdown` | When set to `true`, forces Logstash to exit during shutdown even if there are still inflight events  in memory. By default, Logstash will refuse to quit until all received events  have been pushed to the outputs. Enabling this option can lead to data loss during shutdown. | `false` |
| `pipeline.plugin_classloaders` | (Beta) Load Java plugins in independent classloaders to isolate their dependencies. | `false` |
| `pipeline.ordered` | Set the pipeline event ordering. Valid options are:<br><br>* `auto`. Automatically enables ordering if the `pipeline.workers` setting is `1`, and disables otherwise.<br>* `true`. Enforces ordering on the pipeline and prevents Logstash from starting if there are multiple workers.<br>* `false`. Disables the processing required to preserve order. Ordering will not be guaranteed, but you save the processing cost of preserving order.<br> | `auto` |
| `pipeline.ecs_compatibility` | Sets the pipeline’s default value for `ecs_compatibility`, a setting that is available to plugins that implement an ECS compatibility mode for use with the Elastic Common Schema. Possible values are:<br><br>* `disabled`<br>* `v1`<br>* `v8`<br><br>This option allows the [early opt-in (or preemptive opt-out) of ECS compatibility](/reference/ecs-ls.md) modes in plugins, which is scheduled to be on-by-default in a future major release of {{ls}}.<br><br>Values other than `disabled` are currently considered BETA, and may produce unintended consequences when upgrading {{ls}}.<br> | `disabled` |
| `path.config` | The path to the Logstash config for the main pipeline. If you specify a directory or wildcard,  config files are read from the directory in alphabetical order. | Platform-specific. See [Logstash Directory Layout](/reference/dir-layout.md). |
| `config.string` | A string that contains the pipeline configuration to use for the main pipeline. Use the same syntax as  the config file. | *N/A* |
| `config.test_and_exit` | When set to `true`, checks that the configuration is valid and then exits. Note that grok patterns are not checked for  correctness with this setting. Logstash can read multiple config files from a directory. If you combine this  setting with `log.level: debug`, Logstash will log the combined config file, annotating  each config block with the source file it came from. | `false` |
| `config.reload.automatic` | When set to `true`, periodically checks if the configuration has changed and reloads the configuration whenever it is changed.  This can also be triggered manually through the SIGHUP signal. | `false` |
| `config.reload.interval` | How often in seconds Logstash checks the config files for changes. Note that the unit qualifier (`s`) is required. | `3s` |
| `config.debug` | When set to `true`, shows the fully compiled configuration as a debug log message. You must also set `log.level: debug`.  WARNING: The log message will include any *password* options passed to plugin configs as plaintext, and may result  in plaintext passwords appearing in your logs! | `false` |
| `config.support_escapes` | When set to `true`, quoted strings will process the following escape sequences: `\n` becomes a literal newline (ASCII 10). `\r` becomes a literal carriage return (ASCII 13). `\t` becomes a literal tab (ASCII 9). `\\` becomes a literal backslash `\`. `\"` becomes a literal double quotation mark. `\'` becomes a literal quotation mark. | `false` |
| `config.field_reference.escape_style` | Provides a way to reference fields that contain [field reference special characters](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html#formal-grammar-escape-sequences) `[` and `]`.<br><br>Note: This feature is in **technical preview** and may change in the future.<br><br>Current options are:<br><br>* `percent`: URI-style `%`+`HH` hexadecimal encoding of UTF-8 bytes (`[` → `%5B`; `]` → `%5D`)<br>* `ampersand`: HTML-style `&#`+`DD`+`;` encoding of decimal Unicode code-points (`[` → `&#91;`; `]` → `&#93;`)<br>* `none`: field names containing special characters *cannot* be referenced.<br> | `none` |
| `queue.type` | The internal queuing model to use for event buffering. Specify `memory` for legacy in-memory based queuing, or `persisted` for disk-based ACKed queueing ([persistent queues](/reference/persistent-queues.md)). | `memory` |
| `path.queue` | The directory path where the data files will be stored when persistent queues are enabled (`queue.type: persisted`). | `path.data/queue` |
| `queue.page_capacity` | The size of the page data files used when persistent queues are enabled (`queue.type: persisted`). The queue data consists of append-only data files separated into pages. | 64mb |
| `queue.max_events` | The maximum number of unread events in the queue when persistent queues are enabled (`queue.type: persisted`). | 0 (unlimited) |
| `queue.max_bytes` | The total capacity of the queue (`queue.type: persisted`) in number of bytes. Make sure the capacity of your disk drive is greater than the value you specify here. If both `queue.max_events` and `queue.max_bytes` are specified, Logstash uses whichever criteria is reached first. | 1024mb (1g) |
| `queue.checkpoint.acks` | The maximum number of ACKed events before forcing a checkpoint when persistent queues are enabled (`queue.type: persisted`). Specify `queue.checkpoint.acks: 0` to set this value to unlimited. | 1024 |
| `queue.checkpoint.writes` | The maximum number of written events before forcing a checkpoint when persistent queues are enabled (`queue.type: persisted`). Specify `queue.checkpoint.writes: 0` to set this value to unlimited. | 1024 |
| `queue.checkpoint.retry` | When enabled, Logstash will retry four times per attempted checkpoint write for any checkpoint writes that fail. Any subsequent errors are not retried. This is a workaround for failed checkpoint writes that have been seen only on Windows platform, filesystems with non-standard behavior such as SANs and is not recommended except in those specific circumstances. (`queue.type: persisted`) | `true` |
| `queue.drain` | When enabled, Logstash waits until the persistent queue (`queue.type: persisted`) is drained before shutting down. | `false` |
| `dead_letter_queue.enable` | Flag to instruct Logstash to enable the DLQ feature supported by plugins. | `false` |
| `dead_letter_queue.max_bytes` | The maximum size of each dead letter queue. Entries will be dropped if they  would increase the size of the dead letter queue beyond this setting. | `1024mb` |
| `dead_letter_queue.storage_policy` | Defines the action to take when the dead_letter_queue.max_bytes setting is reached: `drop_newer` stops accepting new values that would push the file size over the limit, and `drop_older` removes the oldest events to make space for new ones. | `drop_newer` |
| `path.dead_letter_queue` | The directory path where the data files will be stored for the dead-letter queue. | `path.data/dead_letter_queue` |
| `api.enabled` | The HTTP API is enabled by default. It can be disabled, but features that rely on it will not work as intended. | `true` |
| `api.environment` | The API returns the provided string as a part of its response. Setting your environment may help to disambiguate between similarly-named nodes in production vs test environments. | `production` |
| `api.http.host` | The bind address for the HTTP API endpoint.  By default, the {{ls}} HTTP API binds only to the local loopback interface.  When configured securely (`api.ssl.enabled: true` and `api.auth.type: basic`), the HTTP API binds to *all* available interfaces. | `"127.0.0.1"` |
| `api.http.port` | The bind port for the HTTP API endpoint. | `9600-9700` |
| `api.ssl.enabled` | Set to `true` to enable SSL on the HTTP API.  Doing so requires both `api.ssl.keystore.path` and `api.ssl.keystore.password` to be set. | `false` |
| `api.ssl.keystore.path` | The path to a valid JKS or PKCS12 keystore for use in securing the {{ls}} API.  The keystore must be password-protected, and must contain a single certificate chain and a private key.  This setting is ignored unless `api.ssl.enabled` is set to `true`. | *N/A* |
| `api.ssl.keystore.password` | The password to the keystore provided with `api.ssl.keystore.path`.  This setting is ignored unless `api.ssl.enabled` is set to `true`. | *N/A* |
| `api.ssl.supported_protocols` | List of allowed SSL/TLS versions to use when establishing a secure connection. The availability of protocols depends on the JVM version. Certain protocols are disabled by default and need to be enabled manually by changing `jdk.tls.disabledAlgorithms` in the **$JDK_HOME/conf/security/java.security** configuration file. Possible values are:<br><br>* `TLSv1`<br>* `TLSv1.1`<br>* `TLSv1.2`<br>* `TLSv1.3`<br> | *N/A* |
| `api.auth.type` | Set to `basic` to require HTTP Basic auth on the API using the credentials supplied with `api.auth.basic.username` and `api.auth.basic.password`. | `none` |
| `api.auth.basic.username` | The username to require for HTTP Basic auth  Ignored unless `api.auth.type` is set to `basic`. | *N/A* |
| `api.auth.basic.password` | The password to require for HTTP Basic auth. Ignored unless `api.auth.type` is set to `basic`. It should meet default password policy which requires non-empty minimum 8 char string that includes a digit, upper case letter and lower case letter. The default password policy can be customized by following options:<br><br>* Set `api.auth.basic.password_policy.include.digit` `REQUIRED` (default) to accept only passwords that include at least one digit or `OPTIONAL` to exclude from requirement.<br>* Set `api.auth.basic.password_policy.include.upper` `REQUIRED` (default) to accept only passwords that include at least one upper case letter or `OPTIONAL` to exclude from requirement.<br>* Set `api.auth.basic.password_policy.include.lower` `REQUIRED` (default) to accept only passwords that include at least one lower case letter or `OPTIONAL` to exclude from requirement.<br>* Set `api.auth.basic.password_policy.include.symbol` `REQUIRED` to accept only passwords that include at least one special character or `OPTIONAL` (default) to exclude from requirement.<br>* Set `api.auth.basic.password_policy.length.minimum` to a value from 9 to 1024 if you want to require more than the 8 character default setting for passwords.<br> | *N/A* |
| `api.auth.basic.password_policy.mode` | Raises either `WARN` or `ERROR` message when password requirements are not met.Ignored unless `api.auth.type` is set to `basic`. | `WARN` |
| `log.level` | The log level. Valid options are:<br><br>* `fatal`<br>* `error`<br>* `warn`<br>* `info`<br>* `debug`<br>* `trace`<br> | `info` |
| `log.format` | The log format. Set to `json` to log in JSON format, or `plain` to use `Object#.inspect`. | `plain` |
| `log.format.json.fix_duplicate_message_fields` | When the log format is `json` avoid collision of field names in log lines. | `true` |
| `path.logs` | The directory where Logstash will write its log to. | `LOGSTASH_HOME/logs` |
| `pipeline.separate_logs` | This a boolean setting to enable separation of logs per pipeline in different log files. If enabled Logstash will create a different log file for each pipeline,using the pipeline.id as name of the file. The destination directory is taken from the `path.log`s setting. When there are many pipelines configured in Logstash,separating each log lines per pipeline could be helpful in case you need to troubleshoot what’s happening in a single pipeline, without interference of the other ones. | `false` |
| `path.plugins` | Where to find custom plugins. You can specify this setting multiple times to include  multiple paths. Plugins are expected to be in a specific directory hierarchy:  `PATH/logstash/TYPE/NAME.rb` where `TYPE` is `inputs`, `filters`, `outputs`, or `codecs`,  and `NAME` is the name of the plugin. | Platform-specific. See [Logstash Directory Layout](/reference/dir-layout.md). |
| `allow_superuser` | Setting to `true` to allow or `false` to block running Logstash as a superuser. | `false` |
| `pipeline.buffer.type` | Determine where to allocate memory buffers, for plugins that leverage them.Defaults to `heap` but can be switched to `direct` to instruct Logstash to prefer allocation of buffers in direct memory. | `heap` Check out [Buffer Allocation types](/reference/jvm-settings.md#off-heap-buffers-allocation) for more info. |

