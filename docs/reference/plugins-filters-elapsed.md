---
navigation_title: "elapsed"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-elapsed.html
---

# Elapsed filter plugin [plugins-filters-elapsed]


* Plugin version: v4.1.0
* Released on: 2018-07-31
* [Changelog](https://github.com/logstash-plugins/logstash-filter-elapsed/blob/v4.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-elapsed-index.md).

## Installation [_installation_58]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-filter-elapsed`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_136]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-elapsed). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_135]

The elapsed filter tracks a pair of start/end events and uses their timestamps to calculate the elapsed time between them.

The filter has been developed to track the execution time of processes and other long tasks.

The configuration looks like this:

```ruby
    filter {
      elapsed {
        start_tag => "start event tag"
        end_tag => "end event tag"
        unique_id_field => "id field name"
        timeout => seconds
        new_event_on_match => true/false
      }
    }
```

The events managed by this filter must have some particular properties. The event describing the start of the task (the "start event") must contain a tag equal to `start_tag`. On the other side, the event describing the end of the task (the "end event") must contain a tag equal to `end_tag`. Both these two kinds of event need to own an ID field which identify uniquely that particular task. The name of this field is stored in `unique_id_field`.

You can use a Grok filter to prepare the events for the elapsed filter. An example of configuration can be:

```ruby
    filter {
      grok {
        match => { "message" => "%{TIMESTAMP_ISO8601} START id: (?<task_id>.*)" }
        add_tag => [ "taskStarted" ]
      }
```

```
grok {
  match => { "message" => "%{{TIMESTAMP_ISO8601}} END id: (?<task_id>.*)" }
  add_tag => [ "taskTerminated" ]
}
```
```
  elapsed {
    start_tag => "taskStarted"
    end_tag => "taskTerminated"
    unique_id_field => "task_id"
  }
}
```
The elapsed filter collects all the "start events". If two, or more, "start events" have the same ID, only the first one is recorded, the others are discarded.

When an "end event" matching a previously collected "start event" is received, there is a match. The configuration property `new_event_on_match` tells where to insert the elapsed information: they can be added to the "end event" or a new "match event" can be created. Both events store the following information:

* the tags `elapsed` and `elapsed_match`
* the field `elapsed_time` with the difference, in seconds, between the two events timestamps
* an ID filed with the task ID
* the field `elapsed_timestamp_start` with the timestamp of the start event

If the "end event" does not arrive before "timeout" seconds, the "start event" is discarded and an "expired event" is generated. This event contains:

* the tags `elapsed` and `elapsed_expired_error`
* a field called `elapsed_time` with the age, in seconds, of the "start event"
* an ID filed with the task ID
* the field `elapsed_timestamp_start` with the timestamp of the "start event"


## Elapsed Filter Configuration Options [plugins-filters-elapsed-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-elapsed-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`end_tag`](#plugins-filters-elapsed-end_tag) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`new_event_on_match`](#plugins-filters-elapsed-new_event_on_match) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`start_tag`](#plugins-filters-elapsed-start_tag) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`timeout`](#plugins-filters-elapsed-timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`unique_id_field`](#plugins-filters-elapsed-unique_id_field) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`keep_start_event`](#plugins-filters-elapsed-keep_start_event) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-elapsed-common-options) for a list of options supported by all filter plugins.

 

### `end_tag` [plugins-filters-elapsed-end_tag]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the tag identifying the "end event"


### `new_event_on_match` [plugins-filters-elapsed-new_event_on_match]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

This property manage what to do when an "end event" matches a "start event". If it’s set to `false` (default value), the elapsed information are added to the "end event"; if it’s set to `true` a new "match event" is created.


### `start_tag` [plugins-filters-elapsed-start_tag]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the tag identifying the "start event"


### `timeout` [plugins-filters-elapsed-timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1800`

The amount of seconds after an "end event" can be considered lost. The corresponding "start event" is discarded and an "expired event" is generated. The default value is 30 minutes (1800 seconds).


### `unique_id_field` [plugins-filters-elapsed-unique_id_field]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the field containing the task ID. This value must uniquely identify the task in the system, otherwise it’s impossible to match the couple of events.


### `keep_start_event` [plugins-filters-elapsed-keep_start_event]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `first`

This property manages what to do when several events matched as a start one were received before the end event for the specified ID. There are two supported values: `first` or `last`. If it’s set to `first` (default value), the first event matched as a start will be used; if it’s set to `last`, the last one will be used.



## Common options [plugins-filters-elapsed-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-elapsed-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-elapsed-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-elapsed-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-elapsed-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-elapsed-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-elapsed-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-elapsed-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-elapsed-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      elapsed {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      elapsed {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-elapsed-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elapsed {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      elapsed {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-elapsed-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-elapsed-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 elapsed filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      elapsed {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-elapsed-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-elapsed-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      elapsed {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      elapsed {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-elapsed-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      elapsed {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      elapsed {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



