---
navigation_title: "dissect"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-dissect.html
---

# Dissect filter plugin [plugins-filters-dissect]


* Plugin version: v1.2.5
* Released on: 2022-02-14
* [Changelog](https://github.com/logstash-plugins/logstash-filter-dissect/blob/v1.2.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-dissect-index.md).

## Getting help [_getting_help_133]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-dissect). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_132]

The Dissect filter plugin tokenizes incoming strings using defined patterns. It extracts unstructured event data into fields using delimiters. This process is called tokenization.

Unlike a regular split operation where one delimiter is applied to the whole string, the Dissect operation applies a set of delimiters to a string value.

::::{note}
All keys must be found and extracted for tokenization to be successful. If one or more keys cannot be found, an error occurs and the original event is not modified.
::::


### Dissect or Grok? Or both? [_dissect_or_grok_or_both]

Dissect differs from Grok in that it does not use regular expressions and is faster. Dissect works well when data is reliably repeated. Grok is a better choice when the structure of your text varies from line to line.

You can use both Dissect and Grok for a hybrid use case when a section of the line is reliably repeated, but the entire line is not. The Dissect filter can deconstruct the section of the line that is repeated. The Grok filter can process the remaining field values with more regex predictability.


### Terminology [_terminology]

**dissect pattern** - the set of fields and delimiters describing the textual format. Also known as a dissection. The dissection is described using a set of `%{}` sections: `%{{a}} - %{{b}} - %{{c}}`

**field** - the text from `%{` to `}` inclusive.

**delimiter** - the text between `}` and the next `%{` characters. Any set of characters other than `%{`, `'not }'`, or `}` is a delimiter.

**key** - the text between the `%{` and `}`, exclusive of the `?`, `+`, `&` prefixes and the ordinal suffix.

Examples:

`%{?aaa}` - the key is `aaa`

`%{+bbb/3}` - the key is `bbb`

`%{&ccc}` - the key is `ccc`

::::{note}
Using the `.` (dot) as `key` will generate fields with `.` in the field name. If you want to get nested fields, use the brackets notation such as `%{[fieldname][subfieldname]}`.
::::



### Sample configuration [_sample_configuration_2]

The config might look like this:

```ruby
  filter {
    dissect {
      mapping => {
        "message" => "%{ts} %{+ts} %{+ts} %{src} %{} %{prog}[%{pid}]: %{msg}"
      }
    }
  }
```

When a string is dissected from left to right, text is captured up to the first delimiter. The captured text is stored in the first field. This is repeated for each field/# delimiter pair until the last delimiter is reached. Then **the remaining text is stored in the last field**.



## Notations [_notations]

[Normal field notation](#plugins-filters-dissect-normal)

[Skip field notation](#plugins-filters-dissect-skip)

[Append field notation](#plugins-filters-dissect-append)

[Indirect field notation](#plugins-filters-dissect-indirect)

### Notes and usage guidelines [_notes_and_usage_guidelines]

* For append or indirect fields, the key can refer to a field that already exists in the event before dissection.
* Use a Skip field if you do not want the indirection key/value stored.

    Example:

    `%{?a}: %{&a}` applied to text `google: 77.98` will build a key/value of `google => 77.98`.

* Append and indirect cannot be combined.

    Examples:

    `%{+&something}` will add a value to the `&something` key (probably not the intended outcome).

    `%{&+something}` will add a value to the `+something` key (again probably unintended).



### Normal field notation [plugins-filters-dissect-normal]

The found value is added to the Event using the key. A normal field has no prefix or suffix.

Example:

`%{{some_field}}`


### Skip field notation [plugins-filters-dissect-skip]

The found value is stored internally, but is not added to the Event. The key, if supplied, is prefixed with a `?`.

Examples:

`%{}` is an empty skip field.

`%{?foo}` is a named skip field.


### Append field notation [plugins-filters-dissect-append]

If the value is the first field seen, it is stored. Subsequent fields are appended to another value.

The key is prefixed with a `+`. The final value is stored in the Event using the key.

::::{note}
The delimiter found before the field is appended with the value. If no delimiter is found before the field, a single space character is used.
::::


Examples:

`%{+some_field}` is an append field.

`%{+some_field/2}` is an append field with an order modifier.

**Order modifiers**

An order modifier, `/digits`, allows one to reorder the append sequence.

Example:

For text `1 2 3 go`, this `%{+a/2} %{+a/1} %{+a/4} %{+a/3}` will build a key/value of `a => 2 1 go 3`.

**Append fields** without an order modifier will append in declared order.

Example:

For text `1 2 3 go`, this `%{{a}} %{{b}} %{+a}` will build two key/values of `a => 1 3 go, b => 2`


### Indirect field notation [plugins-filters-dissect-indirect]

The found value is added to the Event using the found value of another field as the key. The key is prefixed with a `&`.

Examples:

`%{&some_field}` is an indirect field where the key is indirectly sourced from the value of `some_field`.

For text `error: some_error, some_description`, this notation `error: %{?err}, %{&err}` will build a key/value of `some_error => some_description`.



## Multiple Consecutive Delimiter Handling [_multiple_consecutive_delimiter_handling]

::::{important}
Multiple found delimiter handling has changed starting with version 1.1.1 of this plugin. Now multiple consecutive delimiters are seen as missing fields by default and not padding. If you are already using Dissect and your source text has fields padded with extra delimiters, you will need to change your config. Please read the section below.
::::


### Empty data between delimiters [_empty_data_between_delimiters]

Given this text as the sample used to create a dissection:

```ruby
John Smith,Big Oaks,Wood Lane,Hambledown,Canterbury,CB34RY
```

The created dissection, with 6 fields, is:

```ruby
%{name},%{addr1},%{addr2},%{addr3},%{city},%{zip}
```

When a line like this is processed:

```ruby
Jane Doe,4321 Fifth Avenue,,,New York,87432
```

Dissect will create an event with empty fields for `addr2 and addr3` like so:

```ruby
{
  "name": "Jane Doe",
  "addr1": "4321 Fifth Avenue",
  "addr2": "",
  "addr3": "",
  "city": "New York"
  "zip": "87432"
}
```


### Delimiters used as padding to visually align fields [_delimiters_used_as_padding_to_visually_align_fields]

**Padding to the right hand side**

Given these texts as the samples used to create a dissection:

```ruby
00000043 ViewReceive     machine-321
f3000a3b Calc            machine-123
```

The dissection, with 3 fields, is:

```ruby
%{id} %{function->} %{server}
```

Note, above, the second field has a `->` suffix which tells Dissect to ignore padding to its right.<br> Dissect will create these events:

```ruby
{
  "id": "00000043",
  "function": "ViewReceive",
  "server": "machine-123"
}
{
  "id": "f3000a3b",
  "function": "Calc",
  "server": "machine-321"
}
```

::::{important}
Always add the `->` suffix to the field on the left of the padding.
::::


**Padding to the left hand side (to the human eye)**

Given these texts as the samples used to create a dissection:

```ruby
00000043     ViewReceive machine-321
f3000a3b            Calc machine-123
```

The dissection, with 3 fields, is now:

```ruby
%{id->} %{function} %{server}
```

Here the `->` suffix moves to the `id` field because Dissect sees the padding as being to the right of the `id` field.<br>



## Conditional processing [_conditional_processing]

You probably want to use this filter inside an `if` block. This ensures that the event contains a field value with a suitable structure for the dissection.

Example:

```ruby
filter {
  if [type] == "syslog" or "syslog" in [tags] {
    dissect {
      mapping => {
        "message" => "%{ts} %{+ts} %{+ts} %{src} %{} %{prog}[%{pid}]: %{msg}"
      }
    }
  }
}
```


## Dissect Filter Configuration Options [plugins-filters-dissect-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-dissect-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`convert_datatype`](#plugins-filters-dissect-convert_datatype) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`mapping`](#plugins-filters-dissect-mapping) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`tag_on_failure`](#plugins-filters-dissect-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-filters-dissect-common-options) for a list of options supported by all filter plugins.

 

### `convert_datatype` [plugins-filters-dissect-convert_datatype]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

With this setting `int` and `float` datatype conversions can be specified. These will be done after all `mapping` dissections have taken place. Feel free to use this setting on its own without a `mapping` section.

**Example**

```ruby
filter {
  dissect {
    convert_datatype => {
      "cpu" => "float"
      "code" => "int"
    }
  }
}
```


### `mapping` [plugins-filters-dissect-mapping]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

A hash of dissections of `field => value`<br>

::::{important}
Don’t use an escaped newline `\n` in the value. It will be interpreted as two characters `\` + `n`. Instead use actual line breaks in the config. Also use single quotes to define the value if it contains double quotes.
::::


A later dissection can be done on values from a previous dissection or they can be independent.

**Example**

```ruby
filter {
  dissect {
    mapping => {
      # using an actual line break
      "message" => '"%{field1}" "%{field2}"
 "%{description}"'
      "description" => "%{field3} %{field4} %{field5}"
    }
  }
}
```

This is useful if you want to keep the field `description` but also dissect it further.


### `tag_on_failure` [plugins-filters-dissect-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_dissectfailure"]`

Append values to the `tags` field when dissection fails



## Common options [plugins-filters-dissect-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-dissect-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-dissect-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-dissect-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-dissect-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-dissect-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-dissect-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-dissect-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-dissect-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      dissect {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      dissect {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-dissect-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      dissect {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      dissect {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-dissect-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-dissect-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 dissect filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      dissect {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-dissect-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-dissect-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      dissect {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      dissect {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-dissect-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      dissect {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      dissect {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.
