---
navigation_title: "sns"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-sns.html
---

# Sns output plugin [plugins-outputs-sns]


* A component of the [aws integration plugin](/reference/plugins-integrations-aws.md)
* Integration version: v7.1.8
* Released on: 2024-07-26
* [Changelog](https://github.com/logstash-plugins/logstash-integration-aws/blob/v7.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-sns-index.md).

## Getting help [_getting_help_109]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-aws). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_109]

SNS output.

Send events to Amazon’s Simple Notification Service, a hosted pub/sub framework.  It supports various subscription types, including email, HTTP/S, SMS, and SQS.

For further documentation about the service see:

```
http://docs.amazonwebservices.com/sns/latest/api/
```
This plugin looks for the following fields on events it receives:

* `sns` - If no ARN is found in the configuration file, this will be used as the ARN to publish.
* `sns_subject` - The subject line that should be used. Optional. The `%{{host}}` will be used if `sns_subject` is not present. The subject will be truncated to 100 characters. If `sns_subject` is set to a non-string value a JSON version of that value will be saved.
* `sns_message` - Optional string of message to be sent. If this is set to a non-string value it will be encoded with the specified `codec`. If this is not set the entire event will be encoded with the codec. with the @message truncated so that the length of the JSON fits in `32768` bytes.


## Upgrading to 2.0.0 [_upgrading_to_2_0_0]

This plugin used to have a `format` option for controlling the encoding of messages prior to being sent to SNS. This plugin now uses the logstash standard [codec](/reference/configuration-file-structure.md#codec) option for encoding instead. If you want the same *plain* format as the v0/1 codec (`format => "plain"`) use `codec => "s3_plain"`.


## Sns Output Configuration Options [plugins-outputs-sns-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-sns-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`access_key_id`](#plugins-outputs-sns-access_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`arn`](#plugins-outputs-sns-arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`aws_credentials_file`](#plugins-outputs-sns-aws_credentials_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_uri`](#plugins-outputs-sns-proxy_uri) | [string](/reference/configuration-file-structure.md#string) | No |
| [`publish_boot_message_arn`](#plugins-outputs-sns-publish_boot_message_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-outputs-sns-region) | [string](/reference/configuration-file-structure.md#string), one of `["us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-central-1", "eu-west-1", "eu-west-2", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "ap-northeast-2", "sa-east-1", "us-gov-west-1", "cn-north-1", "ap-south-1", "ca-central-1"]` | No |
| [`secret_access_key`](#plugins-outputs-sns-secret_access_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`session_token`](#plugins-outputs-sns-session_token) | [string](/reference/configuration-file-structure.md#string) | No |
| [`use_aws_bundled_ca`](#plugins-outputs-sns-use_aws_bundled_ca) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-outputs-sns-common-options) for a list of options supported by all output plugins.

 

### `access_key_id` [plugins-outputs-sns-access_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order:

1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config
2. External credentials file specified by `aws_credentials_file`
3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`
5. IAM Instance Profile (available when running inside EC2)


### `arn` [plugins-outputs-sns-arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Optional ARN to send messages to. If you do not set this you must include the `sns` field in your events to set the ARN on a per-message basis!


### `aws_credentials_file` [plugins-outputs-sns-aws_credentials_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path to YAML file containing a hash of AWS credentials. This file will only be loaded if `access_key_id` and `secret_access_key` aren’t set. The contents of the file should look like this:

```ruby
    :access_key_id: "12345"
    :secret_access_key: "54321"
```


### `proxy_uri` [plugins-outputs-sns-proxy_uri]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URI to proxy server if required


### `publish_boot_message_arn` [plugins-outputs-sns-publish_boot_message_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

When an ARN for an SNS topic is specified here, the message "Logstash successfully booted" will be sent to it when this plugin is registered.

Example: arn:aws:sns:us-east-1:770975001275:logstash-testing


### `region` [plugins-outputs-sns-region]

* Value can be any of: `us-east-1`, `us-east-2`, `us-west-1`, `us-west-2`, `eu-central-1`, `eu-west-1`, `eu-west-2`, `ap-southeast-1`, `ap-southeast-2`, `ap-northeast-1`, `ap-northeast-2`, `sa-east-1`, `us-gov-west-1`, `cn-north-1`, `ap-south-1`, `ca-central-1`
* Default value is `"us-east-1"`

The AWS Region


### `secret_access_key` [plugins-outputs-sns-secret_access_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Secret Access Key


### `session_token` [plugins-outputs-sns-session_token]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Session token for temporary credential


### `use_aws_bundled_ca` [plugins-outputs-sns-use_aws_bundled_ca]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use bundled CA certificates that ship with AWS SDK to verify SSL peer certificates. For cases where the default certificates are unavailable, e.g. Windows, you can set this to `true`.



## Common options [plugins-outputs-sns-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-sns-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-sns-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-sns-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-sns-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-sns-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-sns-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 sns outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  sns {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




