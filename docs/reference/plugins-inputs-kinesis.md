---
navigation_title: "kinesis"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kinesis.html
---

# Kinesis input plugin [plugins-inputs-kinesis]


* Plugin version: v2.3.0
* Released on: 2023-08-28
* [Changelog](https://github.com/logstash-plugins/logstash-input-kinesis/blob/v2.3.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-kinesis-index.md).

## Installation [_installation_6]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-kinesis`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_36]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-kinesis). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_36]

You can use this plugin to receive events through [AWS Kinesis](http://docs.aws.amazon.com/kinesis/latest/dev/introduction.md). This plugin uses the [Java Kinesis Client Library](http://docs.aws.amazon.com/kinesis/latest/dev/kinesis-record-processor-implementation-app-java.md). The documentation at [https://github.com/awslabs/amazon-kinesis-client](https://github.com/awslabs/amazon-kinesis-client) will be useful.

AWS credentials can be specified either through environment variables, or an IAM instance role. The library uses a DynamoDB table for worker coordination, so you’ll need to grant access to that as well as to the Kinesis stream. The DynamoDB table has the same name as the `application_name` configuration option, which defaults to "logstash".

The library can optionally also send worker statistics to CloudWatch.


## Usage [plugins-inputs-kinesis-usage]

```ruby
input {
  kinesis {
    kinesis_stream_name => "my-logging-stream"
    codec => json { }
  }
}
```


## Using with CloudWatch Logs [plugins-inputs-kinesis-cloudwatch]

If you want to read a CloudWatch Logs subscription stream, you’ll also need to install and configure the [CloudWatch Logs Codec](https://github.com/threadwaste/logstash-codec-cloudwatch_logs).


## Authentication [plugins-inputs-kinesis-authentication]

This plugin uses the default AWS SDK auth chain, [DefaultAWSCredentialsProviderChain](https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/DefaultAWSCredentialsProviderChain.md), to determine which credentials the client will use, unless `profile` is set, in which case [ProfileCredentialsProvider](http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/profile/ProfileCredentialsProvider.md) is used.

The default chain reads the credentials in this order:

* `AWS_ACCESS_KEY_ID` / `AWS_SECRET_KEY` environment variables
* `~/.aws/credentials` credentials file
* EC2 instance profile

The credentials need access to the following services:

* AWS Kinesis
* AWS DynamoDB. The client library stores information for worker coordination in DynamoDB (offsets and active worker per partition)
* AWS CloudWatch. If the metrics are enabled the credentials need CloudWatch update permissions granted.

See the [AWS documentation](https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/auth/DefaultAWSCredentialsProviderChain.md) for more information on the default chain.


## Kinesis Input Configuration Options [plugins-inputs-kinesis-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-kinesis-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`application_name`](#plugins-inputs-kinesis-application_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`checkpoint_interval_seconds`](#plugins-inputs-kinesis-checkpoint_interval_seconds) | [number](/reference/configuration-file-structure.md#number) | No |
| [`http_proxy`](#plugins-inputs-kinesis-http_proxy) | [password](/reference/configuration-file-structure.md#password) | No |
| [`initial_position_in_stream`](#plugins-inputs-kinesis-initial_position_in_stream) | [string](/reference/configuration-file-structure.md#string) | No |
| [`kinesis_stream_name`](#plugins-inputs-kinesis-kinesis_stream_name) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`metrics`](#plugins-inputs-kinesis-metrics) | [string](/reference/configuration-file-structure.md#string), one of `[nil, "cloudwatch"]` | No |
| [`non_proxy_hosts`](#plugins-inputs-kinesis-non_proxy_hosts) | [string](/reference/configuration-file-structure.md#string) | No |
| [`profile`](#plugins-inputs-kinesis-profile) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-inputs-kinesis-region) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_arn`](#plugins-inputs-kinesis-role_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_session_name`](#plugins-inputs-kinesis-role_session_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`additional_settings`](#plugins-inputs-kinesis-additional_settings) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-kinesis-common-options) for a list of options supported by all input plugins.

 

### `application_name` [plugins-inputs-kinesis-application_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

The application name used for the dynamodb coordination table. Must be unique for this kinesis stream.


### `checkpoint_interval_seconds` [plugins-inputs-kinesis-checkpoint_interval_seconds]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

How many seconds between worker checkpoints to dynamodb.


### `http_proxy` [plugins-inputs-kinesis-http_proxy]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Proxy support for Kinesis, DynamoDB, and CloudWatch (if enabled).


### `initial_position_in_stream` [plugins-inputs-kinesis-initial_position_in_stream]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"TRIM_HORIZON"`

The value for initialPositionInStream. Accepts "TRIM_HORIZON" or "LATEST".


### `kinesis_stream_name` [plugins-inputs-kinesis-kinesis_stream_name]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The kinesis stream name.


### `metrics` [plugins-inputs-kinesis-metrics]

* Value can be any of: ``, `cloudwatch`
* Default value is `nil`

Worker metric tracking. By default this is disabled, set it to "cloudwatch" to enable the cloudwatch integration in the Kinesis Client Library.


### `non_proxy_hosts` [plugins-inputs-kinesis-non_proxy_hosts]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Hosts that should be excluded from proxying, separated by the "|" (pipe) character.


### `profile` [plugins-inputs-kinesis-profile]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS profile name for authentication. This ensures that the `~/.aws/credentials` AWS auth provider is used. By default this is empty and the default chain will be used.


### `region` [plugins-inputs-kinesis-region]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"us-east-1"`

The AWS region for Kinesis, DynamoDB, and CloudWatch (if enabled)


### `role_arn` [plugins-inputs-kinesis-role_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS role to assume. This can be used, for example, to access a Kinesis stream in a different AWS account. This role will be assumed after the default credentials or profile credentials are created. By default this is empty and a role will not be assumed.


### `role_session_name` [plugins-inputs-kinesis-role_session_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `logstash`

Session name to use when assuming an IAM role. This is recorded in CloudTrail logs for example.


### `additional_settings` [plugins-inputs-kinesis-additional_settings]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The KCL provides several configuration options which can be set in [KinesisClientLibConfiguration](https://github.com/awslabs/amazon-kinesis-client/blob/master/amazon-kinesis-client-multilang/src/main/java/software/amazon/kinesis/coordinator/KinesisClientLibConfiguration.java). These options are configured via various function calls that all begin with `with`. Some of these functions take complex types, which are not supported. However, you may invoke any one of the `withX()` functions that take a primitive by providing key-value pairs in `snake_case`.

Example:

To set the dynamodb read and write capacity values, use these functions: `withInitialLeaseTableReadCapacity` and `withInitialLeaseTableWriteCapacity`.

```text
additional_settings => {"initial_lease_table_read_capacity" => 25 "initial_lease_table_write_capacity" => 100}
```



## Common options [plugins-inputs-kinesis-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-kinesis-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-kinesis-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-kinesis-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-kinesis-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-kinesis-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-kinesis-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-kinesis-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-kinesis-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-kinesis-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-kinesis-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 kinesis inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  kinesis {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-kinesis-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-kinesis-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



