---
navigation_title: "fluent"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-fluent.html
---

# Fluent codec plugin [plugins-codecs-fluent]


* Plugin version: v3.4.3
* Released on: 2024-06-25
* [Changelog](https://github.com/logstash-plugins/logstash-codec-fluent/blob/v3.4.3/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-fluent-index.md).

## Getting help [_getting_help_182]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-fluent). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_181]

This codec handles fluentd’s msgpack schema.

For example, you can receive logs from `fluent-logger-ruby` with:

```ruby
    input {
      tcp {
        codec => fluent
        port => 4000
      }
    }
```

And from your ruby code in your own application:

```ruby
    logger = Fluent::Logger::FluentLogger.new(nil, :host => "example.log", :port => 4000)
    logger.post("some_tag", { "your" => "data", "here" => "yay!" })
```

::::{note}
Fluent uses second-precision for events, so you will not see sub-second precision on events processed by this codec.
::::



## Fluent Codec configuration options [plugins-codecs-fluent-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`nanosecond_precision`](#plugins-codecs-fluent-nanosecond_precision) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-codecs-fluent-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `nanosecond_precision` [plugins-codecs-fluent-nanosecond_precision]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Enables sub-second level precision while encoding events.


### `target` [plugins-codecs-fluent-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field for placing the decoded values. If this setting is not set, data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `logs` field:

```ruby
    input {
      tcp {
        codec => fluent {
          target => "[logs]"
        }
        port => 4000
      }
    }
```



