---
navigation_title: "msgpack"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-msgpack.html
---

# Msgpack codec plugin [plugins-codecs-msgpack]


* Plugin version: v3.1.0
* Released on: 2021-08-09
* [Changelog](https://github.com/logstash-plugins/logstash-codec-msgpack/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-msgpack-index.md).

## Getting help [_getting_help_191]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-msgpack). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_190]

This codec reads and produces MessagePack encoded content.


## Msgpack Codec configuration options [plugins-codecs-msgpack-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`format`](#plugins-codecs-msgpack-format) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target`](#plugins-codecs-msgpack-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `format` [plugins-codecs-msgpack-format]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.


### `target` [plugins-codecs-msgpack-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field for placing the decoded values. If this setting is not set, data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
    input {
      tcp {
        port => 4242
        codec => msgpack {
          target => "[document]"
        }
      }
    }
```



