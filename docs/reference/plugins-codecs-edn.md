---
navigation_title: "edn"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-edn.html
---

# Edn codec plugin [plugins-codecs-edn]


* Plugin version: v3.1.0
* Released on: 2021-08-04
* [Changelog](https://github.com/logstash-plugins/logstash-codec-edn/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-edn-index.md).

## Getting help [_getting_help_179]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-edn). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_178]

Reads and produces EDN format data.


## Edn Codec configuration options [plugins-codecs-edn-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`target`](#plugins-codecs-edn-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `target` [plugins-codecs-edn-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* The option is only relevant while decoding.

Define the target field for placing the decoded fields. If this setting is not set, data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
    input {
      tcp {
        port => 4242
        codec => edn {
          target => "[document]"
        }
      }
    }
```



