---
navigation_title: "google_pubsub"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-google_pubsub.html
---

# Google Cloud Pub/Sub Output Plugin [plugins-outputs-google_pubsub]


* Plugin version: v1.2.0
* Released on: 2023-08-22
* [Changelog](https://github.com/logstash-plugins/logstash-output-google_pubsub/blob/v1.2.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-google_pubsub-index.md).

## Installation [_installation_31]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-google_pubsub`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_82]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-google_pubsub). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_82]

A Logstash plugin to upload log events to [Google Cloud Pubsub](https://cloud.google.com/pubsub/). Events are batched and uploaded in the background for the sake of efficiency. Message payloads are serialized JSON representations of the events.

Example use-cases:

* Stream events to Dataproc via Pub/Sub for real-time analysis.
* Forward events from an on-prem datacenter to the Logstash in the cloud.
* Use Pub/Sub as an scalable buffer to even out event flow between processing steps.

Note: While this project is partially maintained by Google, this is not an official Google product.


## Environment Configuration [_environment_configuration_2]

To use this plugin, you must create a [service account](https://developers.google.com/storage/docs/authentication#service_accounts) and grant it the publish permission on a topic. You MAY also use the [Application Default Credentials](https://cloud.google.com/docs/authentication/production) assigned to a compute instance.

The Pub/Sub topic *must* exist before you run the plugin.


## Example Configurations [_example_configurations]

### Basic [_basic_2]

A basic configuration which only includes a project, topic, and JSON key file:

```ruby
output {
  google_pubsub {
    # Required attributes
    project_id => "my_project"
    topic => "my_topic"

    # Optional if you're using app default credentials
    json_key_file => "service_account_key.json"
  }
}
```


### High Volume [_high_volume]

If you find that uploads are going too slowly, you can increase the message batching:

```ruby
output {
  google_pubsub {
    project_id => "my_project"
    topic => "my_topic"
    json_key_file => "service_account_key.json"

    # Options for configuring the upload
    message_count_threshold => 1000
    delay_threshold_secs => 10
    request_byte_threshold => 5000000
  }
}
```


### Attributes [_attributes]

You can attach additional attributes to each request. For example, you could attach a datacenter label to a log message to help with debugging:

```ruby
output {
  google_pubsub {
    project_id => "my_project"
    topic => "my_topic"
    json_key_file => "service_account_key.json"


    attributes => {"origin" => "pacific-datacenter"}
  }
}
```


### Different Codecs [_different_codecs]

You can use codecs with this plugin to change the body of the events:

```ruby
output {
  google_pubsub {
    project_id => "my_project"
    topic => "my_topic"
    json_key_file => "service_account_key.json"


    codec => plain {format => "%{[time]}: %{[message]}"}
  }
}
```



## Additional Resources [_additional_resources_3]

* [Cloud Pub/Sub Homepage](https://cloud.google.com/pubsub/)
* [Cloud Pub/Sub Pricing](https://cloud.google.com/pubsub/pricing/)
* [IAM Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
* [Application Default Credentials](https://cloud.google.com/docs/authentication/production)


## Google Cloud Pub/Sub Output Configuration Options [plugins-outputs-google_pubsub-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-google_pubsub-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`project_id`](#plugins-outputs-google_pubsub-project_id) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`topic`](#plugins-outputs-google_pubsub-topic) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`json_key_file`](#plugins-outputs-google_pubsub-json_key_file) | [path](/reference/configuration-file-structure.md#path) | No |
| [`delay_threshold_secs`](#plugins-outputs-google_pubsub-delay_threshold_secs) | [number](/reference/configuration-file-structure.md#number) | No |
| [`message_count_threshold`](#plugins-outputs-google_pubsub-message_count_threshold) | [number](/reference/configuration-file-structure.md#number) | No |
| [`request_byte_threshold`](#plugins-outputs-google_pubsub-request_byte_threshold) | [bytes](/reference/configuration-file-structure.md#bytes) | No |
| [`attributes`](#plugins-outputs-google_pubsub-attributes) | [hash](/reference/configuration-file-structure.md#hash) | No |

Also see [Common options](#plugins-outputs-google_pubsub-common-options) for a list of options supported by all input plugins.

### `project_id` [plugins-outputs-google_pubsub-project_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Google Cloud Project ID (name, not number).


### `topic` [plugins-outputs-google_pubsub-topic]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Google Cloud Pub/Sub Topic. You must create the topic manually before running this plugin.


### `json_key_file` [plugins-outputs-google_pubsub-json_key_file]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The path to the key to authenticate your user to the bucket. This service user *must* have the `pubsub.topics.publish` permission so it can publish to the topic.

If Logstash is running within Google Compute Engine and no `json_key_file` is defined, the plugin will use GCE’s Application Default Credentials. Outside of GCE, you must to specify a Service Account JSON key file.


### `delay_threshold_secs` [plugins-outputs-google_pubsub-delay_threshold_secs]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default is: `5`

Send the batch once this delay has passed, from the time the first message is queued. Must be greater than 0.


### `message_count_threshold` [plugins-outputs-google_pubsub-message_count_threshold]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default is: `100`

Once this many messages are queued, send all the messages in a single call, even if the delay threshold hasn’t elapsed yet. Must be < 1000. A value of 0 will cause messages to instantly be sent but will reduce total throughput due to overhead.


### `request_byte_threshold` [plugins-outputs-google_pubsub-request_byte_threshold]

* Value type is [bytes](/reference/configuration-file-structure.md#bytes)
* Default is: `1000000`

Once the number of bytes in the batched request reaches this threshold, send all of the messages in a single call, even if neither the delay or message count thresholds have been exceeded yet. This includes full message payload size, including any attributes set.


### `attributes` [plugins-outputs-google_pubsub-attributes]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default is: `{}`

Attributes to add to the message in key: value formats. Keys and values MUST be strings.



## Common options [plugins-outputs-google_pubsub-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-google_pubsub-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-google_pubsub-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-google_pubsub-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-google_pubsub-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"json"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-google_pubsub-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-google_pubsub-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 google_pubsub outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  google_pubsub {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




