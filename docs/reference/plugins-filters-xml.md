---
navigation_title: "xml"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html
---

# Xml filter plugin [plugins-filters-xml]


* Plugin version: v4.2.1
* Released on: 2024-10-29
* [Changelog](https://github.com/logstash-plugins/logstash-filter-xml/blob/v4.2.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-xml-index.md).

## Getting help [_getting_help_171]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-xml). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_170]

XML filter. Takes a field that contains XML and expands it into an actual datastructure.


## Xml Filter Configuration Options [plugins-filters-xml-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-xml-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`force_array`](#plugins-filters-xml-force_array) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`force_content`](#plugins-filters-xml-force_content) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`namespaces`](#plugins-filters-xml-namespaces) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`parse_options`](#plugins-filters-xml-parse_options) | [string](/reference/configuration-file-structure.md#string) | No |
| [`remove_namespaces`](#plugins-filters-xml-remove_namespaces) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`source`](#plugins-filters-xml-source) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`store_xml`](#plugins-filters-xml-store_xml) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`suppress_empty`](#plugins-filters-xml-suppress_empty) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-filters-xml-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`xpath`](#plugins-filters-xml-xpath) | [hash](/reference/configuration-file-structure.md#hash) | No |

Also see [Common options](#plugins-filters-xml-common-options) for a list of options supported by all filter plugins.

 

### `force_array` [plugins-filters-xml-force_array]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

By default the filter will force single elements to be arrays. Setting this to false will prevent storing single elements in arrays.


### `force_content` [plugins-filters-xml-force_content]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

By default the filter will expand attributes differently from content inside of tags. This option allows you to force text content and attributes to always parse to a hash value.


### `namespaces` [plugins-filters-xml-namespaces]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

By default only namespaces declarations on the root element are considered. This allows to configure all namespace declarations to parse the XML document.

Example:

```ruby
filter {
  xml {
    namespaces => {
      "xsl" => "http://www.w3.org/1999/XSL/Transform"
      "xhtml" => "http://www.w3.org/1999/xhtml"
    }
  }
}
```


### `parse_options` [plugins-filters-xml-parse_options]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Setting XML parse options allows for more control of the parsing process. By default the parser is not strict and thus accepts some invalid content. Currently supported options are:

* `strict` - forces the parser to fail early instead of accumulating errors when content is not valid xml.

Control characters such as ASCII 0x0 are not allowed and *always* result in non-valid XML.

When XML content is not valid, it will be tagged as `_xmlparsefailure`.

XML specs:

* XML 1.0 Spec: [https://www.w3.org/TR/2008/REC-xml-20081126/#charsets](https://www.w3.org/TR/2008/REC-xml-20081126/#charsets)
* XML 1.1 Spec: [https://www.w3.org/TR/xml11/#charsets](https://www.w3.org/TR/xml11/#charsets)


### `remove_namespaces` [plugins-filters-xml-remove_namespaces]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Remove all namespaces from all nodes in the document. Of course, if the document had nodes with the same names but different namespaces, they will now be ambiguous.


### `source` [plugins-filters-xml-source]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Config for xml to hash is:

```ruby
    source => source_field
```

For example, if you have the whole XML document in your `message` field:

```ruby
    filter {
      xml {
        source => "message"
      }
    }
```

The above would parse the XML from the `message` field.


### `store_xml` [plugins-filters-xml-store_xml]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

By default the filter will store the whole parsed XML in the destination field as described above. Setting this to false will prevent that.


### `suppress_empty` [plugins-filters-xml-suppress_empty]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

By default, output nothing if the element is empty. If set to `false`, empty element will result in an empty hash object.


### `target` [plugins-filters-xml-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define target for placing the data

For example if you want the data to be put in the `doc` field:

```ruby
    filter {
      xml {
        target => "doc"
      }
    }
```

XML in the value of the source field will be expanded into a datastructure in the `target` field. Note: if the `target` field already exists, it will be overridden. Required if `store_xml` is true (which is the default).


### `xpath` [plugins-filters-xml-xpath]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

xpath will additionally select string values (non-strings will be converted to strings with Ruby’s `to_s` function) from parsed XML (using each source field defined using the method above) and place those values in the destination fields. Configuration:

```ruby
xpath => [ "xpath-syntax", "destination-field" ]
```

Values returned by XPath parsing from `xpath-syntax` will be put in the destination field. Multiple values returned will be pushed onto the destination field as an array. As such, multiple matches across multiple source fields will produce duplicate entries in the field.

#### Additional XPath resources [plugins-filters-xml-xpath_resources]

For more information on XPath, see [https://www.w3schools.com/xml/xml_xpath.asp](https://www.w3schools.com/xml/xml_xpath.asp).

The [XPath functions](https://www.w3schools.com/xml/xsl_functions.asp) are particularly powerful.




## Common options [plugins-filters-xml-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-xml-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-xml-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-xml-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-xml-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-xml-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-xml-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-xml-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-xml-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      xml {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      xml {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-xml-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      xml {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      xml {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-xml-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-xml-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 xml filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      xml {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-xml-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-xml-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      xml {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      xml {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-xml-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      xml {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      xml {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



