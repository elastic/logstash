---
navigation_title: "uuid"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-uuid.html
---

# Uuid filter plugin [plugins-filters-uuid]


* Plugin version: v3.0.5
* Released on: 2017-11-07
* [Changelog](https://github.com/logstash-plugins/logstash-filter-uuid/blob/v3.0.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-uuid-index.md).

## Getting help [_getting_help_169]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-uuid). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_168]

The uuid filter allows you to generate a [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) and add it as a field to each processed event.

This is useful if you need to generate a string that’s unique for every event, even if the same input is processed multiple times. If you want to generate strings that are identical each time a event with a given content is processed (i.e. a hash) you should use the [fingerprint filter](/reference/plugins-filters-fingerprint.md) instead.

The generated UUIDs follow the version 4 definition in [RFC 4122](https://tools.ietf.org/html/rfc4122)) and will be represented as a standard hexadecimal string format, e.g. "e08806fe-02af-406c-bbde-8a5ae4475e57".


## Uuid Filter Configuration Options [plugins-filters-uuid-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-uuid-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`overwrite`](#plugins-filters-uuid-overwrite) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-filters-uuid-target) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-filters-uuid-common-options) for a list of options supported by all filter plugins.

 

### `overwrite` [plugins-filters-uuid-overwrite]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If the value in the field currently (if any) should be overridden by the generated UUID. Defaults to `false` (i.e. if the field is present, with ANY value, it won’t be overridden)

Example:

```ruby
   filter {
      uuid {
        target    => "uuid"
        overwrite => true
      }
   }
```


### `target` [plugins-filters-uuid-target]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Select the name of the field where the generated UUID should be stored.

Example:

```ruby
    filter {
      uuid {
        target => "uuid"
      }
    }
```



## Common options [plugins-filters-uuid-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-uuid-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-uuid-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-uuid-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-uuid-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-uuid-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-uuid-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-uuid-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-uuid-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      uuid {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      uuid {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-uuid-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      uuid {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      uuid {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-uuid-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-uuid-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 uuid filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      uuid {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-uuid-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-uuid-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      uuid {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      uuid {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-uuid-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      uuid {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      uuid {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



