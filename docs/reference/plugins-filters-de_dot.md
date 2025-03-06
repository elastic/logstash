---
navigation_title: "de_dot"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-de_dot.html
---

# De_dot filter plugin [plugins-filters-de_dot]


* Plugin version: v1.1.0
* Released on: 2024-05-27
* [Changelog](https://github.com/logstash-plugins/logstash-filter-de_dot/blob/v1.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-de_dot-index.md).

## Getting help [_getting_help_132]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-de_dot). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_131]

This filter *appears* to rename fields by replacing `.` characters with a different separator.  In reality, it’s a somewhat expensive filter that has to copy the source field contents to a new destination field (whose name no longer contains dots), and then remove the corresponding source field.

It should only be used if no other options are available.


## De_dot Filter Configuration Options [plugins-filters-de_dot-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-de_dot-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`fields`](#plugins-filters-de_dot-fields) | [array](/reference/configuration-file-structure.md#array) | No |
| [`nested`](#plugins-filters-de_dot-nested) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`recursive`](#plugins-filters-de_dot-recursive) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`separator`](#plugins-filters-de_dot-separator) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-de_dot-common-options) for a list of options supported by all filter plugins.

 

### `fields` [plugins-filters-de_dot-fields]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The `fields` array should contain a list of known fields to act on. If undefined, all top-level fields will be checked.  Sub-fields must be manually specified in the array.  For example: `["field.suffix","[foo][bar.suffix]"]` will result in "field_suffix" and nested or sub field ["foo"]["bar_suffix"]

::::{warning}
This is an expensive operation.
::::



### `nested` [plugins-filters-de_dot-nested]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If `nested` is *true*, then create sub-fields instead of replacing dots with a different separator.


### `recursive` [plugins-filters-de_dot-recursive]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If `recursive` is *true*, then recursively check sub-fields. It is recommended you only use this when setting specific fields, as this is an expensive operation.


### `separator` [plugins-filters-de_dot-separator]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"_"`

Replace dots with this value.



## Common options [plugins-filters-de_dot-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-de_dot-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-de_dot-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-de_dot-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-de_dot-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-de_dot-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-de_dot-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-de_dot-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-de_dot-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      de_dot {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      de_dot {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-de_dot-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      de_dot {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      de_dot {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-de_dot-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-de_dot-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 de_dot filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      de_dot {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-de_dot-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-de_dot-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      de_dot {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      de_dot {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-de_dot-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      de_dot {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      de_dot {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



