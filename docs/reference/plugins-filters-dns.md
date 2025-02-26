---
navigation_title: "dns"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-dns.html
---

# Dns filter plugin [plugins-filters-dns]


* Plugin version: v3.2.0
* Released on: 2023-01-26
* [Changelog](https://github.com/logstash-plugins/logstash-filter-dns/blob/v3.2.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-dns-index.md).

## Getting help [_getting_help_134]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-dns). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_133]

The DNS filter performs a lookup (either an A record/CNAME record lookup or a reverse lookup at the PTR record) on records specified under the `reverse` arrays or respectively under the `resolve` arrays.

The config should look like this:

```ruby
    filter {
      dns {
        reverse => [ "source_host", "field_with_address" ]
        resolve => [ "field_with_fqdn" ]
        action => "replace"
      }
    }
```

This filter, like all filters, only processes 1 event at a time, so the use of this plugin can significantly slow down your pipeline’s throughput if you have a high latency network. By way of example, if each DNS lookup takes 2 milliseconds, the maximum throughput you can achieve with a single filter worker is 500 events per second (1000 milliseconds / 2 milliseconds).


## Dns Filter Configuration Options [plugins-filters-dns-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-dns-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`action`](#plugins-filters-dns-action) | [string](/reference/configuration-file-structure.md#string), one of `["append", "replace"]` | No |
| [`failed_cache_size`](#plugins-filters-dns-failed_cache_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`failed_cache_ttl`](#plugins-filters-dns-failed_cache_ttl) | [number](/reference/configuration-file-structure.md#number) | No |
| [`hit_cache_size`](#plugins-filters-dns-hit_cache_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`hit_cache_ttl`](#plugins-filters-dns-hit_cache_ttl) | [number](/reference/configuration-file-structure.md#number) | No |
| [`hostsfile`](#plugins-filters-dns-hostsfile) | [array](/reference/configuration-file-structure.md#array) | No |
| [`max_retries`](#plugins-filters-dns-max_retries) | [number](/reference/configuration-file-structure.md#number) | No |
| [`nameserver`](#plugins-filters-dns-nameserver) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`resolve`](#plugins-filters-dns-resolve) | [array](/reference/configuration-file-structure.md#array) | No |
| [`reverse`](#plugins-filters-dns-reverse) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tag_on_timeout`](#plugins-filters-dns-tag_on_timeout) | [array](/reference/configuration-file-structure.md#array) | No |
| [`timeout`](#plugins-filters-dns-timeout) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-filters-dns-common-options) for a list of options supported by all filter plugins.

 

### `action` [plugins-filters-dns-action]

* Value can be any of: `append`, `replace`
* Default value is `"append"`

Determine what action to do: append or replace the values in the fields specified under `reverse` and `resolve`.


### `failed_cache_size` [plugins-filters-dns-failed_cache_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0` (cache disabled)

cache size for failed requests


### `failed_cache_ttl` [plugins-filters-dns-failed_cache_ttl]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

how long to cache failed requests (in seconds)


### `hit_cache_size` [plugins-filters-dns-hit_cache_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0` (cache disabled)

set the size of cache for successful requests


### `hit_cache_ttl` [plugins-filters-dns-hit_cache_ttl]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

how long to cache successful requests (in seconds)


### `hostsfile` [plugins-filters-dns-hostsfile]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Use custom hosts file(s). For example: `["/var/db/my_custom_hosts"]`


### `max_retries` [plugins-filters-dns-max_retries]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `2`

number of times to retry a failed resolve/reverse


### `nameserver` [plugins-filters-dns-nameserver]

* Value type is [hash](/reference/configuration-file-structure.md#hash), and is composed of:

    * a required `address` key, whose value is either a [string](/reference/configuration-file-structure.md#string) or an [array](/reference/configuration-file-structure.md#array), representing one or more nameserver ip addresses
    * an optional `search` key, whose value is either a [string](/reference/configuration-file-structure.md#string) or an [array](/reference/configuration-file-structure.md#array), representing between one and six search domains (e.g., with search domain `com`, a query for `example` will match DNS entries for `example.com`)
    * an optional `ndots` key, used in conjunction with `search`, whose value is a [number](/reference/configuration-file-structure.md#number), representing the minimum number of dots in a domain name being resolved that will *prevent* the search domains from being used (default `1`; this option is rarely needed)

* For backward-compatibility, values of [string](/reference/configuration-file-structure.md#string) and [array](/reference/configuration-file-structure.md#array) are also accepted, representing one or more nameserver ip addresses *without* search domains.
* There is no default value for this setting.

Use custom nameserver(s). For example:

```ruby
    filter {
      dns {
        nameserver => {
          address => ["8.8.8.8", "8.8.4.4"]
          search  => ["internal.net"]
        }
      }
    }
```

If `nameserver` is not specified then `/etc/resolv.conf` will be read to configure the resolver using the `nameserver`, `domain`, `search` and `ndots` directives in `/etc/resolv.conf`.


### `resolve` [plugins-filters-dns-resolve]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Forward resolve one or more fields.


### `reverse` [plugins-filters-dns-reverse]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Reverse resolve one or more fields.


### `timeout` [plugins-filters-dns-timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0.5`

`resolv` calls will be wrapped in a timeout instance


### `tag_on_timeout` [plugins-filters-dns-tag_on_timeout]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Defaults to `["_dnstimeout"]`.

Add tag(s) on DNS lookup time out.



## Common options [plugins-filters-dns-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-dns-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-dns-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-dns-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-dns-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-dns-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-dns-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-dns-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-dns-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      dns {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      dns {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-dns-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      dns {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      dns {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-dns-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-dns-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 dns filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      dns {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-dns-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-dns-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      dns {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      dns {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-dns-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      dns {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      dns {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



