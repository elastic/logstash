---
navigation_title: "mutate"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html
---

# Mutate filter plugin [plugins-filters-mutate]


* Plugin version: v3.5.8
* Released on: 2023-11-22
* [Changelog](https://github.com/logstash-plugins/logstash-filter-mutate/blob/v3.5.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-mutate-index.md).

## Getting help [_getting_help_155]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-mutate). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_154]

The mutate filter allows you to perform general mutations on fields. You can rename, replace, and modify fields in your events.

### Processing order [plugins-filters-mutate-proc_order]

Mutations in a config file are executed in this order:

* coerce
* rename
* update
* replace
* convert
* gsub
* uppercase
* capitalize
* lowercase
* strip
* split
* join
* merge
* copy

::::{important}
Each mutation must be in its own code block if the sequence of operations needs to be preserved.
::::


Example:

```ruby
filter {
    mutate {
        split => { "hostname" => "." }
        add_field => { "shortHostname" => "%{[hostname][0]}" }
    }

    mutate {
        rename => {"shortHostname" => "hostname"}
    }
}
```



## Mutate Filter Configuration Options [plugins-filters-mutate-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-mutate-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`convert`](#plugins-filters-mutate-convert) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`copy`](#plugins-filters-mutate-copy) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`gsub`](#plugins-filters-mutate-gsub) | [array](/reference/configuration-file-structure.md#array) | No |
| [`join`](#plugins-filters-mutate-join) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`lowercase`](#plugins-filters-mutate-lowercase) | [array](/reference/configuration-file-structure.md#array) | No |
| [`merge`](#plugins-filters-mutate-merge) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`coerce`](#plugins-filters-mutate-coerce) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`rename`](#plugins-filters-mutate-rename) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`replace`](#plugins-filters-mutate-replace) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`split`](#plugins-filters-mutate-split) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`strip`](#plugins-filters-mutate-strip) | [array](/reference/configuration-file-structure.md#array) | No |
| [`update`](#plugins-filters-mutate-update) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`uppercase`](#plugins-filters-mutate-uppercase) | [array](/reference/configuration-file-structure.md#array) | No |
| [`capitalize`](#plugins-filters-mutate-capitalize) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tag_on_failure`](#plugins-filters-mutate-tag_on_failure) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-mutate-common-options) for a list of options supported by all filter plugins.

 

### `convert` [plugins-filters-mutate-convert]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Convert a field’s value to a different type, like turning a string to an integer. If the field value is an array, all members will be converted. If the field is a hash no action will be taken.

::::{admonition} Conversion insights
:class: note

The values are converted using Ruby semantics. Be aware that using `float` and `float_eu` converts the value to a double-precision 64-bit IEEE 754 floating point decimal number. In order to maintain precision due to the conversion, you should use a `double` in the Elasticsearch mappings.

::::


Valid conversion targets, and their expected behaviour with different inputs are:

* `integer`:

    * strings are parsed; comma-separators are supported (e.g., the string `"1,000"` produces an integer with value of one thousand); when strings have decimal parts, they are *truncated*.
    * floats and decimals are *truncated* (e.g., `3.99` becomes `3`, `-2.7` becomes `-2`)
    * boolean true and boolean false are converted to `1` and `0` respectively

* `integer_eu`:

    * same as `integer`, except string values support dot-separators and comma-decimals (e.g., `"1.000"` produces an integer with value of one thousand)

* `float`:

    * integers are converted to floats
    * strings are parsed; comma-separators and dot-decimals are supported (e.g., `"1,000.5"` produces a float with value of one thousand and one half)
    * boolean true and boolean false are converted to `1.0` and `0.0` respectively

* `float_eu`:

    * same as `float`, except string values support dot-separators and comma-decimals (e.g., `"1.000,5"` produces a float with value of one thousand and one half)

* `string`:

    * all values are stringified and encoded with UTF-8

* `boolean`:

    * integer 0 is converted to boolean `false`
    * integer 1 is converted to boolean `true`
    * float 0.0 is converted to boolean `false`
    * float 1.0 is converted to boolean `true`
    * strings `"true"`, `"t"`, `"yes"`, `"y"`, `"1"`and `"1.0"` are converted to boolean `true`
    * strings `"false"`, `"f"`, `"no"`, `"n"`, `"0"` and `"0.0"` are converted to boolean `false`
    * empty strings are converted to boolean `false`
    * all other values pass straight through without conversion and log a warning message
    * for arrays each value gets processed separately using rules above


This plugin can convert multiple fields in the same document, see the example below.

Example:

```ruby
    filter {
      mutate {
        convert => {
          "fieldname" => "integer"
          "booleanfield" => "boolean"
        }
      }
    }
```


### `copy` [plugins-filters-mutate-copy]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Copy an existing field to another field. Existing target field will be overriden.

Example:

```ruby
    filter {
      mutate {
         copy => { "source_field" => "dest_field" }
      }
    }
```


### `gsub` [plugins-filters-mutate-gsub]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Match a regular expression against a field value and replace all matches with a replacement string. Only fields that are strings or arrays of strings are supported. For other kinds of fields no action will be taken.

This configuration takes an array consisting of 3 elements per field/substitution.

Be aware of escaping any backslash in the config file.

Example:

```ruby
    filter {
      mutate {
        gsub => [
          # replace all forward slashes with underscore
          "fieldname", "/", "_",
          # replace backslashes, question marks, hashes, and minuses
          # with a dot "."
          "fieldname2", "[\\?#-]", "."
        ]
      }
    }
```


### `join` [plugins-filters-mutate-join]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Join an array with a separator character or string. Does nothing on non-array fields.

Example:

```ruby
   filter {
     mutate {
       join => { "fieldname" => "," }
     }
   }
```


### `lowercase` [plugins-filters-mutate-lowercase]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Convert a string to its lowercase equivalent.

Example:

```ruby
    filter {
      mutate {
        lowercase => [ "fieldname" ]
      }
    }
```


### `merge` [plugins-filters-mutate-merge]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Merge two fields of arrays or hashes. String fields will be automatically be converted into an array, so:

::::{admonition}
```
`array` + `string` will work
`string` + `string` will result in an 2 entry array in `dest_field`
`array` and `hash` will not work
```
::::


Example:

```ruby
    filter {
      mutate {
         merge => { "dest_field" => "added_field" }
      }
    }
```


### `coerce` [plugins-filters-mutate-coerce]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Set the default value of a field that exists but is null

Example:

```ruby
    filter {
      mutate {
        # Sets the default value of the 'field1' field to 'default_value'
        coerce => { "field1" => "default_value" }
      }
    }
```


### `rename` [plugins-filters-mutate-rename]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Rename one or more fields.

If the destination field already exists, its value is replaced.

If one of the source fields doesn’t exist, no action is performed for that field. (This is not considered an error; the `tag_on_failure` tag is not applied.)

When renaming multiple fields, the order of operations is not guaranteed.

Example:

```ruby
    filter {
      mutate {
        # Renames the 'HOSTORIP' field to 'client_ip'
        rename => { "HOSTORIP" => "client_ip" }
      }
    }
```


### `replace` [plugins-filters-mutate-replace]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Replace the value of a field with a new value, or add the field if it doesn’t already exist. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.

Example:

```ruby
    filter {
      mutate {
        replace => { "message" => "%{source_host}: My new message" }
      }
    }
```


### `split` [plugins-filters-mutate-split]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Split a field to an array using a separator character or string. Only works on string fields.

Example:

```ruby
    filter {
      mutate {
         split => { "fieldname" => "," }
      }
    }
```


### `strip` [plugins-filters-mutate-strip]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Strip whitespace from field. NOTE: this only works on leading and trailing whitespace.

Example:

```ruby
    filter {
      mutate {
         strip => ["field1", "field2"]
      }
    }
```


### `update` [plugins-filters-mutate-update]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Update an existing field with a new value. If the field does not exist, then no action will be taken.

Example:

```ruby
    filter {
      mutate {
        update => { "sample" => "My new message" }
      }
    }
```


### `uppercase` [plugins-filters-mutate-uppercase]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Convert a string to its uppercase equivalent.

Example:

```ruby
    filter {
      mutate {
        uppercase => [ "fieldname" ]
      }
    }
```


### `capitalize` [plugins-filters-mutate-capitalize]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Convert a string to its capitalized equivalent.

Example:

```ruby
    filter {
      mutate {
        capitalize => [ "fieldname" ]
      }
    }
```


### `tag_on_failure` [plugins-filters-mutate-tag_on_failure]

* Value type is [string](/reference/configuration-file-structure.md#string)
* The default value for this setting is `_mutate_error`

If a failure occurs during the application of this mutate filter, the rest of the operations are aborted and the provided tag is added to the event.



## Common options [plugins-filters-mutate-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-mutate-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-mutate-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-mutate-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-mutate-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-mutate-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-mutate-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-mutate-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-mutate-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      mutate {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      mutate {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-mutate-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      mutate {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      mutate {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-mutate-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-mutate-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 mutate filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      mutate {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-mutate-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-mutate-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      mutate {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      mutate {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-mutate-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      mutate {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      mutate {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



