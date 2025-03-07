---
navigation_title: "clone"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-clone.html
---

# Clone filter plugin [plugins-filters-clone]


* Plugin version: v4.2.0
* Released on: 2021-11-10
* [Changelog](https://github.com/logstash-plugins/logstash-filter-clone/blob/v4.2.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-clone-index.md).

## Getting help [_getting_help_129]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-clone). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_128]

The clone filter is for duplicating events. A clone will be created for each type in the clone list. The original event is left unchanged and a `type` field is added to the clone. Created events are inserted into the pipeline as normal events and will be processed by the remaining pipeline configuration starting from the filter that generated them (i.e. this plugin).


## Event Metadata and the Elastic Common Schema (ECS) [_event_metadata_and_the_elastic_common_schema_ecs]

This plugin adds a tag to a cloned event. By default, the tag is stored in the `type` field. When ECS is enabled, the tag is stored in the `tags` array field.

Here’s how ECS compatibility mode affects output.

|  ECS disabled |  ECS `v1`, `v8` | Availability | Description |
| --- | --- | --- | --- |
|  type |  tags | *Always* | *a tag of cloned event* |


## Clone Filter Configuration Options [plugins-filters-clone-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-clone-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`clones`](#plugins-filters-clone-clones) | [array](/reference/configuration-file-structure.md#array) | Yes |
| [`ecs_compatibility`](#plugins-filters-clone-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-clone-common-options) for a list of options supported by all filter plugins.

 

### `clones` [plugins-filters-clone-clones]

* This is a required setting.
* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.
* a new clone will be created with a `type` of the given value in this list when ECS is disabled
* a new clone will be created with a `tags` of the given value in this list when ECS is enabled

Note: setting an empty array will not create any clones. A warning message is logged.


### `ecs_compatibility` [plugins-filters-clone-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names
    * `v1`, `v8`: uses fields that are compatible with Elastic Common Schema

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the behavior of the [`clones`](#plugins-filters-clone-clones)

Example:

```ruby
    filter {
      clone {
        clones => ["sun", "moon"]
      }
    }
```

ECS disabled

```text
{
      "@version" => "1",
      "sequence" => 0,
       "message" => "Hello World!",
    "@timestamp" => 2021-03-24T11:20:36.226Z,
          "host" => "example.com"
}
{
      "@version" => "1",
      "sequence" => 0,
       "message" => "Hello World!",
    "@timestamp" => 2021-03-24T11:20:36.226Z,
          "type" => "sun",
          "host" => "example.com"
}
{
      "@version" => "1",
      "sequence" => 0,
       "message" => "Hello World!",
    "@timestamp" => 2021-03-24T11:20:36.226Z,
          "type" => "moon",
          "host" => "example.com"
}
```

ECS enabled

```text
{
      "sequence" => 0,
    "@timestamp" => 2021-03-23T20:25:10.042Z,
       "message" => "Hello World!",
      "@version" => "1",
          "host" => "example.com"
}
{
          "tags" => [
        [0] "sun"
    ],
      "sequence" => 0,
    "@timestamp" => 2021-03-23T20:25:10.042Z,
       "message" => "Hello World!",
      "@version" => "1",
          "host" => "example.com"
}
{
          "tags" => [
        [0] "moon"
    ],
      "sequence" => 0,
    "@timestamp" => 2021-03-23T20:25:10.042Z,
       "message" => "Hello World!",
      "@version" => "1",
          "host" => "example.com"
}
```



## Common options [plugins-filters-clone-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-clone-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-clone-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-clone-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-clone-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-clone-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-clone-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-clone-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-clone-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      clone {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      clone {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-clone-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      clone {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      clone {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-clone-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-clone-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 clone filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      clone {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-clone-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-clone-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      clone {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      clone {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-clone-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      clone {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      clone {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



