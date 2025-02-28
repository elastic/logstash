---
navigation_title: "alter"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-alter.html
---

# Alter filter plugin [plugins-filters-alter]


* Plugin version: v3.0.3
* Released on: 2017-11-07
* [Changelog](https://github.com/logstash-plugins/logstash-filter-alter/blob/v3.0.3/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-alter-index.md).

## Installation [_installation_55]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-filter-alter`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_125]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-alter). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_124]

The alter filter allows you to do general alterations to fields that are not included in the normal mutate filter.

::::{note}
The functionality provided by this plugin is likely to be merged into the *mutate* filter in future versions.
::::



## Alter Filter Configuration Options [plugins-filters-alter-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-alter-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`coalesce`](#plugins-filters-alter-coalesce) | [array](/reference/configuration-file-structure.md#array) | No |
| [`condrewrite`](#plugins-filters-alter-condrewrite) | [array](/reference/configuration-file-structure.md#array) | No |
| [`condrewriteother`](#plugins-filters-alter-condrewriteother) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-filters-alter-common-options) for a list of options supported by all filter plugins.

 

### `coalesce` [plugins-filters-alter-coalesce]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Sets the value of field_name to the first nonnull expression among its arguments.

Example:

```ruby
    filter {
      alter {
        coalesce => [
             "field_name", "value1", "value2", "value3", ...
        ]
      }
    }
```


### `condrewrite` [plugins-filters-alter-condrewrite]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Change the content of the field to the specified value if the actual content is equal to the expected one.

Example:

```ruby
    filter {
      alter {
        condrewrite => [
             "field_name", "expected_value", "new_value",
             "field_name2", "expected_value2", "new_value2",
             ....
           ]
      }
    }
```


### `condrewriteother` [plugins-filters-alter-condrewriteother]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Change the content of the field to the specified value if the content of another field is equal to the expected one.

Example:

```ruby
    filter {
      alter {
        condrewriteother => [
             "field_name", "expected_value", "field_name_to_change", "value",
             "field_name2", "expected_value2", "field_name_to_change2", "value2",
             ....
        ]
      }
    }
```



## Common options [plugins-filters-alter-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-alter-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-alter-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-alter-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-alter-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-alter-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-alter-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-alter-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-alter-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      alter {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      alter {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-alter-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      alter {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      alter {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-alter-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-alter-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 alter filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      alter {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-alter-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-alter-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      alter {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      alter {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-alter-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      alter {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      alter {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



