---
navigation_title: "translate"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-translate.html
---

# Translate filter plugin [plugins-filters-translate]


* Plugin version: v3.4.2
* Released on: 2023-06-14
* [Changelog](https://github.com/logstash-plugins/logstash-filter-translate/blob/v3.4.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-translate-index.md).

## Getting help [_getting_help_165]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-translate). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_164]

A general search and replace tool that uses a configured hash and/or a file to determine replacement values. Currently supported are YAML, JSON, and CSV files. Each dictionary item is a key value pair.

You can specify dictionary entries in one of two ways:

* The `dictionary` configuration item can contain a hash representing the mapping.
* An external file (readable by logstash) may be specified in the `dictionary_path` configuration item.

These two methods may not be used in conjunction; it will produce an error.

Operationally, for each event, the value from the `source` setting is tested against the dictionary and if it matches exactly (or matches a regex when `regex` configuration item has been enabled), the matched value is put in the `target` field, but on no match the `fallback` setting string is used instead.

Example:

```ruby
    filter {
      translate {
        source => "[http][response][status_code]"
        target => "[http_status_description]"
        dictionary => {
          "100" => "Continue"
          "101" => "Switching Protocols"
          "200" => "OK"
          "500" => "Server Error"
        }
        fallback => "I'm a teapot"
      }
    }
```

Occasionally, people find that they have a field with a variable sized array of values or objects that need some enrichment. The `iterate_on` setting helps in these cases.

Alternatively, for simple string search and replacements for just a few values you might consider using the gsub function of the mutate filter.

It is possible to provide multi-valued dictionary values. When using a YAML or JSON dictionary, you can have the value as a hash (map) or an array datatype. When using a CSV dictionary, multiple values in the translation must be extracted with another filter e.g. Dissect or KV.<br> Note that the `fallback` is a string so on no match the fallback setting needs to formatted so that a filter can extract the multiple values to the correct fields.

File based dictionaries are loaded in a separate thread using a scheduler. If you set a `refresh_interval` of 300 seconds (5 minutes) or less then the modified time of the file is checked before reloading. Very large dictionaries are supported, internally tested at 100 000 key/values, and we minimise the impact on throughput by having the refresh in the scheduler thread. Any ongoing modification of the dictionary file should be done using a copy/edit/rename or create/rename mechanism to avoid the refresh code from processing half-baked dictionary content.


## Compatibility with the Elastic Common Schema (ECS) [plugins-filters-translate-ecs_metadata]

The plugin acts as an in-place translator if `source` and `target` are the same and does not produce any new event fields. This is the default behavior in [ECS compatibility mode](#plugins-filters-translate-ecs_compatibility).


## Translate Filter Configuration Options [plugins-filters-translate-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-translate-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`destination`](#plugins-filters-translate-destination) | [string](/reference/configuration-file-structure.md#string) | No |
| [`dictionary`](#plugins-filters-translate-dictionary) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`dictionary_path`](#plugins-filters-translate-dictionary_path) | a valid filesystem path | No |
| [`ecs_compatibility`](#plugins-filters-translate-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`exact`](#plugins-filters-translate-exact) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`fallback`](#plugins-filters-translate-fallback) | [string](/reference/configuration-file-structure.md#string) | No |
| [`field`](#plugins-filters-translate-field) | [string](/reference/configuration-file-structure.md#string) | No |
| [`iterate_on`](#plugins-filters-translate-iterate_on) | [string](/reference/configuration-file-structure.md#string) | No |
| [`override`](#plugins-filters-translate-override) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`refresh_interval`](#plugins-filters-translate-refresh_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`regex`](#plugins-filters-translate-regex) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`source`](#plugins-filters-translate-source) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`refresh_behaviour`](#plugins-filters-translate-refresh_behaviour) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target`](#plugins-filters-translate-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`yaml_dictionary_code_point_limit`](#plugins-filters-translate-yaml_dictionary_code_point_limit) | [number](/reference/configuration-file-structure.md#number) | No |

Also see [Common options](#plugins-filters-translate-common-options) for a list of options supported by all filter plugins.

 

### `destination` [plugins-filters-translate-destination]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Deprecated alias for [`target`](#plugins-filters-translate-target) setting.

::::{admonition} Deprecated in 3.3.0.
:class: warning

Use [`target`](#plugins-filters-translate-target) instead. In 4.0 this setting will be removed.
::::



### `dictionary` [plugins-filters-translate-dictionary]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

The dictionary to use for translation, when specified in the logstash filter configuration item (i.e. do not use the `dictionary_path` file).

Example:

```ruby
    filter {
      translate {
        dictionary => {
          "100"         => "Continue"
          "101"         => "Switching Protocols"
          "merci"       => "thank you"
          "old version" => "new version"
        }
      }
    }
```

::::{note}
It is an error to specify both `dictionary` and `dictionary_path`.
::::



### `dictionary_path` [plugins-filters-translate-dictionary_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The full path of the external dictionary file. The format of the table should be a standard YAML, JSON, or CSV.

Specify any integer-based keys in quotes. The value taken from the event’s `source` setting is converted to a string. The lookup dictionary keys must also be strings, and the quotes make the integer-based keys function as a string. For example, the YAML file should look something like this:

```ruby
    "100": Continue
    "101": Switching Protocols
    merci: gracias
    old version: new version
```

::::{note}
It is an error to specify both `dictionary` and `dictionary_path`.
::::


The currently supported formats are YAML, JSON, and CSV. Format selection is based on the file extension: `json` for JSON, `yaml` or `yml` for YAML, and `csv` for CSV. The CSV format expects exactly two columns, with the first serving as the original text (lookup key), and the second column as the translation.


### `ecs_compatibility` [plugins-filters-translate-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: disabled ECS-compatibility
    * `v1`, `v8`: compatibility with the specified major version of the Elastic Common Schema

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the *default* value of [`target`](#plugins-filters-translate-target).


### `exact` [plugins-filters-translate-exact]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

When `exact => true`, the translate filter will populate the destination field with the exact contents of the dictionary value. When `exact => false`, the filter will populate the destination field with the result of any existing destination field’s data, with the translated value substituted in-place.

For example, consider this simple translation.yml, configured to check the `data` field:

```ruby
    foo: bar
```

If logstash receives an event with the `data` field set to `foo`, and `exact => true`, the destination field will be populated with the string `bar`. If `exact => false`, and logstash receives the same event, the destination field will be also set to `bar`. However, if logstash receives an event with the `data` field set to `foofing`, the destination field will be set to `barfing`.

Set both `exact => true` AND `regex => `true` if you would like to match using dictionary keys as regular expressions. A large dictionary could be expensive to match in this case.


### `fallback` [plugins-filters-translate-fallback]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

In case no translation occurs in the event (no matches), this will add a default translation string, which will always populate `field`, if the match failed.

For example, if we have configured `fallback => "no match"`, using this dictionary:

```ruby
    foo: bar
```

Then, if logstash received an event with the field `foo` set to `bar`, the destination field would be set to `bar`. However, if logstash received an event with `foo` set to `nope`, then the destination field would still be populated, but with the value of `no match`. This configuration can be dynamic and include parts of the event using the `%{{field}}` syntax.


### `field` [plugins-filters-translate-field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Deprecated alias for [`source`](#plugins-filters-translate-source) setting.

::::{admonition} Deprecated in 3.3.0.
:class: warning

Use [`source`](#plugins-filters-translate-source) instead. In 4.0 this setting will be removed.
::::



### `iterate_on` [plugins-filters-translate-iterate_on]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

When the value that you need to perform enrichment on is a variable sized array then specify the field name in this setting. This setting introduces two modes, 1) when the value is an array of strings and 2) when the value is an array of objects (as in JSON object).<br> In the first mode, you should have the same field name in both `source` and `iterate_on`, the result will be an array added to the field specified in the `target` setting. This array will have the looked up value (or the `fallback` value or nil) in same ordinal position as each sought value.<br> In the second mode, specify the field that has the array of objects in `iterate_on` then specify the field in each object that provides the sought value with `source` and the field to write the looked up value (or the `fallback` value) to with `target`.

For a dictionary of:

```text
  100,Yuki
  101,Rupert
  102,Ahmed
  103,Kwame
```

Example of Mode 1

```ruby
    filter {
      translate {
        iterate_on => "[collaborator_ids]"
        source     => "[collaborator_ids]"
        target     => "[collaborator_names]"
        fallback => "Unknown"
      }
    }
```

Before

```json
  {
    "collaborator_ids": [100,103,110,102]
  }
```

After

```json
  {
    "collaborator_ids": [100,103,110,102],
    "collabrator_names": ["Yuki","Kwame","Unknown","Ahmed"]
  }
```

Example of Mode 2

```ruby
    filter {
      translate {
        iterate_on => "[collaborators]"
        source     => "[id]"
        target     => "[name]"
        fallback   => "Unknown"
      }
    }
```

Before

```json
  {
    "collaborators": [
      {
        "id": 100
      },
      {
        "id": 103
      },
      {
        "id": 110
      },
      {
        "id": 101
      }
    ]
  }
```

After

```json
  {
    "collaborators": [
      {
        "id": 100,
        "name": "Yuki"
      },
      {
        "id": 103,
        "name": "Kwame"
      },
      {
        "id": 110,
        "name": "Unknown"
      },
      {
        "id": 101,
        "name": "Rupert"
      }
    ]
  }
```


### `override` [plugins-filters-translate-override]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value depends on whether in-place translation is being used

If the destination (or target) field already exists, this configuration option controls whether the filter skips translation (default behavior) or overwrites the target field value with the new translation value.

In case of in-place translation, where `target` is the same as `source` (such as when [`ecs_compatibility`](#plugins-filters-translate-ecs_compatibility) is enabled), overwriting is allowed.


### `refresh_interval` [plugins-filters-translate-refresh_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300`

When using a dictionary file, this setting will indicate how frequently (in seconds) logstash will check the dictionary file for updates.<br> A value of zero or less will disable refresh.


### `regex` [plugins-filters-translate-regex]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

To treat dictionary keys as regular expressions, set `regex => true`.

Be sure to escape dictionary key strings for use with regex. Resources on regex formatting are available online.


### `refresh_behaviour` [plugins-filters-translate-refresh_behaviour]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `merge`

When using a dictionary file, this setting indicates how the update will be executed. Setting this to `merge` causes the new dictionary to be merged into the old one. This means same entry will be updated but entries that existed before but not in the new dictionary will remain after the merge; `replace` causes the whole dictionary to be replaced with a new one (deleting all entries of the old one on update).


### `source` [plugins-filters-translate-source]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the logstash event field containing the value to be compared for a match by the translate filter (e.g. `message`, `host`, `response_code`).

If this field is an array, only the first value will be used.


### `target` [plugins-filters-translate-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-filters-translate-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: `"translation"`
    * ECS Compatibility enabled: defaults to the same value as `source`


The target field you wish to populate with the translated code. If you set this value to the same value as `source` field, the plugin does a substitution, and the filter will succeed. This will clobber the old value of the source field!


### `yaml_dictionary_code_point_limit` [plugins-filters-translate-yaml_dictionary_code_point_limit]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is 134217728 (128MB for 1 byte code points)

The max amount of code points in the YAML file in `dictionary_path`. Please be aware that byte limit depends on the encoding. This setting is effective for YAML file only. YAML over the limit throws exception.



## Common options [plugins-filters-translate-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-translate-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-translate-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-translate-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-translate-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-translate-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-translate-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-translate-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-translate-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      translate {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      translate {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-translate-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      translate {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      translate {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-translate-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-translate-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 translate filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      translate {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-translate-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-translate-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      translate {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      translate {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-translate-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      translate {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      translate {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



