---
navigation_title: "cidr"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-cidr.html
---

# Cidr filter plugin [plugins-filters-cidr]


* Plugin version: v3.1.3
* Released on: 2019-09-18
* [Changelog](https://github.com/logstash-plugins/logstash-filter-cidr/blob/v3.1.3/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-cidr-index.md).

## Getting help [_getting_help_127]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-cidr). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_126]

The CIDR filter is for checking IP addresses in events against a list of network blocks that might contain it. Multiple addresses can be checked against multiple networks, any match succeeds. Upon success additional tags and/or fields can be added to the event.


## Cidr Filter Configuration Options [plugins-filters-cidr-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-cidr-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`address`](#plugins-filters-cidr-address) | [array](/reference/configuration-file-structure.md#array) | No |
| [`network`](#plugins-filters-cidr-network) | [array](/reference/configuration-file-structure.md#array) | No |
| [`network_path`](#plugins-filters-cidr-network_path) | a valid filesystem path | No |
| [`refresh_interval`](#plugins-filters-cidr-refresh_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`separator`](#plugins-filters-cidr-separator) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-cidr-common-options) for a list of options supported by all filter plugins.

 

### `address` [plugins-filters-cidr-address]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

The IP address(es) to check with. Example:

```ruby
    filter {
      cidr {
        add_tag => [ "testnet" ]
        address => [ "%{src_ip}", "%{dst_ip}" ]
        network => [ "192.0.2.0/24" ]
      }
    }
```


### `network` [plugins-filters-cidr-network]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

The IP network(s) to check against. Example:

```ruby
    filter {
      cidr {
        add_tag => [ "linklocal" ]
        address => [ "%{clientip}" ]
        network => [ "169.254.0.0/16", "fe80::/64" ]
      }
    }
```


### `network_path` [plugins-filters-cidr-network_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The full path of the external file containing the networks the filter should check with. Networks are separated by a separator character defined in `separator`.

```ruby
    192.168.1.0/24
    192.167.0.0/16
NOTE: It is an error to specify both `network` and `network_path`.
```


### `refresh_interval` [plugins-filters-cidr-refresh_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `600`

When using an external file, this setting will indicate how frequently (in seconds) Logstash will check the file for updates.


### `separator` [plugins-filters-cidr-separator]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `\n`

Separator character used for parsing networks from the external file specified by `network_path`. Defaults to newline `\n` character.



## Common options [plugins-filters-cidr-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-cidr-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-cidr-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-cidr-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-cidr-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-cidr-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-cidr-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-cidr-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-cidr-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      cidr {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      cidr {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-cidr-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      cidr {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      cidr {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-cidr-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-cidr-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 cidr filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      cidr {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-cidr-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-cidr-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      cidr {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      cidr {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-cidr-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      cidr {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      cidr {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



