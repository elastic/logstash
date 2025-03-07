---
navigation_title: "avro"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-avro.html
---

# Avro codec plugin [plugins-codecs-avro]


* Plugin version: v3.4.1
* Released on: 2023-10-16
* [Changelog](https://github.com/logstash-plugins/logstash-codec-avro/blob/v3.4.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-avro-index.md).

## Getting help [_getting_help_172]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-avro). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_171]

Read serialized Avro records as Logstash events

This plugin is used to serialize Logstash events as Avro datums, as well as deserializing Avro datums into Logstash events.


## Event Metadata and the Elastic Common Schema (ECS) [plugins-codecs-avro-ecs_metadata]

The plugin behaves the same regardless of ECS compatibility, except adding the original message to `[event][original]`.


## Encoding [_encoding]

This codec is for serializing individual Logstash events as Avro datums that are Avro binary blobs. It does not encode Logstash events into an Avro file.


## Decoding [_decoding]

This codec is for deserializing individual Avro records. It is not for reading Avro files. Avro files have a unique format that must be handled upon input.

::::{admonition} Partial deserialization
:class: note

Avro format is known to support partial deserialization of arbitrary fields, providing a schema containing a subset of the schema which was used to serialize the data. This codec **doesn’t support partial deserialization of arbitrary fields**. Partial deserialization *might* work only when providing a schema which contains the first `N` fields of the schema used to serialize the data (and in the same order).

::::



## Usage [_usage_6]

Example usage with Kafka input.

```ruby
input {
  kafka {
    codec => avro {
        schema_uri => "/tmp/schema.avsc"
    }
  }
}
filter {
  ...
}
output {
  ...
}
```


## Avro Codec Configuration Options [plugins-codecs-avro-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`ecs_compatibility`](#plugins-codecs-avro-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`encoding`](#plugins-codecs-avro-encoding) | [string](/reference/configuration-file-structure.md#string), one of `["binary", "base64"]` | No |
| [`schema_uri`](#plugins-codecs-avro-schema_uri) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`tag_on_failure`](#plugins-codecs-avro-tag_on_failure) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-codecs-avro-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `ecs_compatibility` [plugins-codecs-avro-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: Avro data added at root level
    * `v1`,`v8`: Elastic Common Schema compliant behavior (`[event][original]` is also added)


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).


### `encoding` [plugins-codecs-avro-encoding]

* Value can be any of: `binary`, `base64`
* Default value is `base64`

Set encoding for Avro’s payload. Use `base64` (default) to indicate that this codec sends or expects to receive base64-encoded bytes.

Set this option to `binary` to indicate that this codec sends or expects to receive binary Avro data.


### `schema_uri` [plugins-codecs-avro-schema_uri]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

schema path to fetch the schema from. This can be a *http* or *file* scheme URI example:

* http - `http://example.com/schema.avsc`
* file - `/path/to/schema.avsc`


### `tag_on_failure` [plugins-codecs-avro-tag_on_failure]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

tag events with `_avroparsefailure` when decode fails


### `target` [plugins-codecs-avro-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* This is only relevant when decode data into an event

Define the target field for placing the values. If this setting is not set, the Avro data will be stored at the root (top level) of the event.

**Example**

```ruby
input {
  kafka {
    codec => avro {
        schema_uri => "/tmp/schema.avsc"
        target => "[document]"
    }
  }
}
```



