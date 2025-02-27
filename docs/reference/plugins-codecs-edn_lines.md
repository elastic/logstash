---
navigation_title: "edn_lines"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-edn_lines.html
---

# Edn_lines codec plugin [plugins-codecs-edn_lines]


* Plugin version: v3.1.0
* Released on: 2021-08-04
* [Changelog](https://github.com/logstash-plugins/logstash-codec-edn_lines/blob/v3.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-edn_lines-index.md).

## Getting help [_getting_help_180]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-edn_lines). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_179]

Reads and produces newline-delimited EDN format data.


## Edn_lines Codec configuration options [plugins-codecs-edn_lines-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`target`](#plugins-codecs-edn_lines-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `target` [plugins-codecs-edn_lines-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.
* The option is only relevant while decoding.

Define the target field for placing the decoded fields. If this setting is not set, data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
    input {
      tcp {
        port => 4242
        codec => edn_lines {
          target => "[document]"
        }
      }
    }
```



