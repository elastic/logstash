---
navigation_title: "webhdfs"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-webhdfs.html
---

# Webhdfs output plugin [plugins-outputs-webhdfs]


* Plugin version: v3.1.0
* Released on: 2023-10-03
* [Changelog](https://github.com/logstash-plugins/logstash-output-webhdfs/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/output-webhdfs-index.md).

## Getting help [_getting_help_119]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-webhdfs). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_119]

This plugin sends Logstash events into files in HDFS via the [webhdfs](https://hadoop.apache.org/docs/r1.0.4/webhdfs.html) REST API.


## Dependencies [_dependencies]

This plugin has no dependency on jars from hadoop, thus reducing configuration and compatibility problems. It uses the webhdfs gem from Kazuki Ohta and TAGOMORI Satoshi (@see: [https://github.com/kzk/webhdfs](https://github.com/kzk/webhdfs)). Optional dependencies are zlib and snappy gem if you use the compression functionality.


## Operational Notes [_operational_notes]

If you get an error like:

```
Max write retries reached. Exception: initialize: name or service not known {:level=>:error}
```
make sure that the hostname of your namenode is resolvable on the host running Logstash. When creating/appending to a file, webhdfs somtime sends a `307 TEMPORARY_REDIRECT` with the `HOSTNAME` of the machine its running on.


## Usage [_usage_5]

This is an example of Logstash config:

```ruby
input {
  ...
}
filter {
  ...
}
output {
  webhdfs {
    host => "127.0.0.1"                 # (required)
    port => 50070                       # (optional, default: 50070)
    path => "/user/logstash/dt=%{+YYYY-MM-dd}/logstash-%{+HH}.log"  # (required)
    user => "hue"                       # (required)
  }
}
```


## Webhdfs Output Configuration Options [plugins-outputs-webhdfs-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-webhdfs-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`compression`](#plugins-outputs-webhdfs-compression) | [string](/reference/configuration-file-structure.md#string), one of `["none", "snappy", "gzip"]` | No |
| [`flush_size`](#plugins-outputs-webhdfs-flush_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`host`](#plugins-outputs-webhdfs-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`idle_flush_time`](#plugins-outputs-webhdfs-idle_flush_time) | [number](/reference/configuration-file-structure.md#number) | No |
| [`kerberos_keytab`](#plugins-outputs-webhdfs-kerberos_keytab) | [string](/reference/configuration-file-structure.md#string) | No |
| [`open_timeout`](#plugins-outputs-webhdfs-open_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`path`](#plugins-outputs-webhdfs-path) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`port`](#plugins-outputs-webhdfs-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`read_timeout`](#plugins-outputs-webhdfs-read_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_interval`](#plugins-outputs-webhdfs-retry_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_known_errors`](#plugins-outputs-webhdfs-retry_known_errors) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`retry_times`](#plugins-outputs-webhdfs-retry_times) | [number](/reference/configuration-file-structure.md#number) | No |
| [`single_file_per_thread`](#plugins-outputs-webhdfs-single_file_per_thread) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`snappy_bufsize`](#plugins-outputs-webhdfs-snappy_bufsize) | [number](/reference/configuration-file-structure.md#number) | No |
| [`snappy_format`](#plugins-outputs-webhdfs-snappy_format) | [string](/reference/configuration-file-structure.md#string), one of `["stream", "file"]` | No |
| [`ssl_cert`](#plugins-outputs-webhdfs-ssl_cert) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ssl_key`](#plugins-outputs-webhdfs-ssl_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`standby_host`](#plugins-outputs-webhdfs-standby_host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`standby_port`](#plugins-outputs-webhdfs-standby_port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_httpfs`](#plugins-outputs-webhdfs-use_httpfs) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_kerberos_auth`](#plugins-outputs-webhdfs-use_kerberos_auth) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_ssl_auth`](#plugins-outputs-webhdfs-use_ssl_auth) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`user`](#plugins-outputs-webhdfs-user) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-outputs-webhdfs-common-options) for a list of options supported by all output plugins.

 

### `compression` [plugins-outputs-webhdfs-compression]

* Value can be any of: `none`, `snappy`, `gzip`
* Default value is `"none"`

Compress output. One of [*none*, *snappy*, *gzip*]


### `flush_size` [plugins-outputs-webhdfs-flush_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `500`

Sending data to webhdfs if event count is above, even if `store_interval_in_secs` is not reached.


### `host` [plugins-outputs-webhdfs-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The server name for webhdfs/httpfs connections.


### `idle_flush_time` [plugins-outputs-webhdfs-idle_flush_time]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Sending data to webhdfs in x seconds intervals.


### `kerberos_keytab` [plugins-outputs-webhdfs-kerberos_keytab]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Set kerberos keytab file. Note that the gssapi library needs to be available to use this.


### `open_timeout` [plugins-outputs-webhdfs-open_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `30`

WebHdfs open timeout, default 30s.


### `path` [plugins-outputs-webhdfs-path]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The path to the file to write to. Event fields can be used here, as well as date fields in the joda time format, e.g.: `/user/logstash/dt=%{+YYYY-MM-dd}/%{@source_host}-%{+HH}.log`


### `port` [plugins-outputs-webhdfs-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50070`

The server port for webhdfs/httpfs connections.


### `read_timeout` [plugins-outputs-webhdfs-read_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `30`

The WebHdfs read timeout, default 30s.


### `retry_interval` [plugins-outputs-webhdfs-retry_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0.5`

How long should we wait between retries.


### `retry_known_errors` [plugins-outputs-webhdfs-retry_known_errors]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Retry some known webhdfs errors. These may be caused by race conditions when appending to same file, etc.


### `retry_times` [plugins-outputs-webhdfs-retry_times]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

How many times should we retry. If retry_times is exceeded, an error will be logged and the event will be discarded.


### `single_file_per_thread` [plugins-outputs-webhdfs-single_file_per_thread]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Avoid appending to same file in multiple threads. This solves some problems with multiple logstash output threads and locked file leases in webhdfs. If this option is set to true, %{[@metadata][thread_id]} needs to be used in path config settting.


### `snappy_bufsize` [plugins-outputs-webhdfs-snappy_bufsize]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `32768`

Set snappy chunksize. Only neccessary for stream format. Defaults to 32k. Max is 65536 @see [http://code.google.com/p/snappy/source/browse/trunk/framing_format.txt](http://code.google.com/p/snappy/source/browse/trunk/framing_format.txt)


### `snappy_format` [plugins-outputs-webhdfs-snappy_format]

* Value can be any of: `stream`, `file`
* Default value is `"stream"`

Set snappy format. One of "stream", "file". Set to stream to be hive compatible.


### `ssl_cert` [plugins-outputs-webhdfs-ssl_cert]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Set ssl cert file.


### `ssl_key` [plugins-outputs-webhdfs-ssl_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Set ssl key file.


### `standby_host` [plugins-outputs-webhdfs-standby_host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `false`

Standby namenode for ha hdfs.


### `standby_port` [plugins-outputs-webhdfs-standby_port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50070`

Standby namenode port for ha hdfs.


### `use_httpfs` [plugins-outputs-webhdfs-use_httpfs]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use httpfs mode if set to true, else webhdfs.


### `use_kerberos_auth` [plugins-outputs-webhdfs-use_kerberos_auth]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Set kerberos authentication.


### `use_ssl_auth` [plugins-outputs-webhdfs-use_ssl_auth]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Set ssl authentication. Note that the openssl library needs to be available to use this.


### `user` [plugins-outputs-webhdfs-user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The Username for webhdfs.



## Common options [plugins-outputs-webhdfs-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-webhdfs-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-webhdfs-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-webhdfs-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-webhdfs-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"line"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-webhdfs-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-webhdfs-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 webhdfs outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  webhdfs {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




