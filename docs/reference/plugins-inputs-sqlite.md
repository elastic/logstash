---
navigation_title: "sqlite"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-sqlite.html
---

# Sqlite input plugin [plugins-inputs-sqlite]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-input-sqlite/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-sqlite-index.md).

## Installation [_installation_15]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-sqlite`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_52]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-sqlite). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_52]

Read rows from an sqlite database.

This is most useful in cases where you are logging directly to a table. Any tables being watched must have an `id` column that is monotonically increasing.

All tables are read by default except:

* ones matching `sqlite_%` - these are internal/adminstrative tables for sqlite
* `since_table` - this is used by this plugin to track state.

Example

```sql
    % sqlite /tmp/example.db
    sqlite> CREATE TABLE weblogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip STRING,
        request STRING,
        response INTEGER);
    sqlite> INSERT INTO weblogs (ip, request, response)
        VALUES ("1.2.3.4", "/index.html", 200);
```

Then with this logstash config:

```ruby
    input {
      sqlite {
        path => "/tmp/example.db"
        type => weblogs
      }
    }
    output {
      stdout {
        debug => true
      }
    }
```

Sample output:

```ruby
    {
      "@source"      => "sqlite://sadness/tmp/x.db",
      "@tags"        => [],
      "@fields"      => {
        "ip"       => "1.2.3.4",
        "request"  => "/index.html",
        "response" => 200
      },
      "@timestamp"   => "2013-05-29T06:16:30.850Z",
      "@source_host" => "sadness",
      "@source_path" => "/tmp/x.db",
      "@message"     => "",
      "@type"        => "foo"
    }
```


## Sqlite Input Configuration Options [plugins-inputs-sqlite-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-sqlite-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`batch`](#plugins-inputs-sqlite-batch) | [number](/reference/configuration-file-structure.md#number) | No |
| [`exclude_tables`](#plugins-inputs-sqlite-exclude_tables) | [array](/reference/configuration-file-structure.md#array) | No |
| [`path`](#plugins-inputs-sqlite-path) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-inputs-sqlite-common-options) for a list of options supported by all input plugins.

 

### `batch` [plugins-inputs-sqlite-batch]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

How many rows to fetch at a time from each `SELECT` call.


### `exclude_tables` [plugins-inputs-sqlite-exclude_tables]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Any tables to exclude by name. By default all tables are followed.


### `path` [plugins-inputs-sqlite-path]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The path to the sqlite database file.



## Common options [plugins-inputs-sqlite-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-sqlite-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-sqlite-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-sqlite-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-sqlite-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-sqlite-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-sqlite-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-sqlite-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-sqlite-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-sqlite-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-sqlite-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 sqlite inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  sqlite {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-sqlite-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-sqlite-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



