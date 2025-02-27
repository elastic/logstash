---
navigation_title: "es_bulk"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-es_bulk.html
---

# Es_bulk codec plugin [plugins-codecs-es_bulk]


* Plugin version: v3.1.0
* Released on: 2021-08-19
* [Changelog](https://github.com/logstash-plugins/logstash-codec-es_bulk/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-es_bulk-index.md).

## Getting help [_getting_help_181]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-es_bulk). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_180]

This codec will decode the [Elasticsearch bulk format](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-bulk) into individual events, plus metadata into the `@metadata` field.

Encoding is not supported at this time as the Elasticsearch output submits Logstash events in bulk format.


## Codec settings in the `logstash-input-http` plugin [plugins-codecs-es_bulk-codec-settings]

The [input-http](/reference/plugins-inputs-http.md) plugin has two configuration options for codecs: `codec` and `additional_codecs`.

Values in `additional_codecs` are prioritized over those specified in the `codec` option. That is, the default `codec` is applied only if no codec for the request’s content-type is found in the `additional_codecs` setting.


## Event Metadata and the Elastic Common Schema (ECS) [plugins-codecs-es_bulk-ecs_metadata]

When ECS compatibility is disabled, the metadata is stored in the `[@metadata]` field. When ECS is enabled, the metadata is stored in the `[@metadata][codec][es_bulk]` field.


## ES Bulk Codec Configuration Options [plugins-codecs-es_bulk-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`ecs_compatibility`](#plugins-codecs-es_bulk-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target`](#plugins-codecs-es_bulk-target) | [string](/reference/configuration-file-structure.md#string) | No |

### `ecs_compatibility` [plugins-codecs-es_bulk-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: unstructured metadata added at @metadata
    * `v1`: uses `[@metadata][codec][es_bulk]` fields


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).


### `target` [plugins-codecs-es_bulk-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field for placing the values. If this setting is not set, the data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
input {
  kafka {
    codec => es_bulk {
        target => "[document]"
    }
  }
}
```



