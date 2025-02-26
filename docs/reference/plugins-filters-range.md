---
navigation_title: "range"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-range.html
---

# Range filter plugin [plugins-filters-range]


* Plugin version: v3.0.3
* Released on: 2017-11-07
* [Changelog](https://github.com/logstash-plugins/logstash-filter-range/blob/v3.0.3/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-range-index.md).

## Installation [_installation_64]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-filter-range`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_157]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-range). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_156]

This filter is used to check that certain fields are within expected size/length ranges. Supported types are numbers and strings. Numbers are checked to be within numeric value range. Strings are checked to be within string length range. More than one range can be specified for same fieldname, actions will be applied incrementally. When field value is within a specified range an action will be taken. Supported actions are drop event, add tag, or add field with specified value.

Example use cases are for histogram-like tagging of events or for finding anomaly values in fields or too big events that should be dropped.


## Range Filter Configuration Options [plugins-filters-range-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-range-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`negate`](#plugins-filters-range-negate) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ranges`](#plugins-filters-range-ranges) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-filters-range-common-options) for a list of options supported by all filter plugins.

 

### `negate` [plugins-filters-range-negate]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Negate the range match logic, events should be outsize of the specified range to match.


### `ranges` [plugins-filters-range-ranges]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

An array of field, min, max, action tuples. Example:

```ruby
    filter {
      range {
        ranges => [ "message", 0, 10, "tag:short",
                    "message", 11, 100, "tag:medium",
                    "message", 101, 1000, "tag:long",
                    "message", 1001, 1e1000, "drop",
                    "duration", 0, 100, "field:latency:fast",
                    "duration", 101, 200, "field:latency:normal",
                    "duration", 201, 1000, "field:latency:slow",
                    "duration", 1001, 1e1000, "field:latency:outlier",
                    "requests", 0, 10, "tag:too_few_%{host}_requests" ]
      }
    }
```

Supported actions are drop tag or field with specified value. Added tag names and field names and field values can have `%{{dynamic}}` values.



## Common options [plugins-filters-range-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-range-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-range-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-range-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-range-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-range-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-range-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-range-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-range-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      range {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      range {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-range-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      range {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      range {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-range-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-range-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 range filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      range {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-range-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-range-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      range {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      range {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-range-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      range {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      range {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



