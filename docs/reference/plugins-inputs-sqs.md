---
navigation_title: "sqs"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-sqs.html
---

# Sqs input plugin [plugins-inputs-sqs]


* A component of the [aws integration plugin](/reference/plugins-integrations-aws.md)
* Integration version: v7.1.8
* Released on: 2024-07-26
* [Changelog](https://github.com/logstash-plugins/logstash-integration-aws/blob/v7.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-sqs-index.md).

## Getting help [_getting_help_53]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-aws). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_53]

Pull events from an Amazon Web Services Simple Queue Service (SQS) queue.

SQS is a simple, scalable queue system that is part of the Amazon Web Services suite of tools.

Although SQS is similar to other queuing systems like AMQP, it uses a custom API and requires that you have an AWS account. See [http://aws.amazon.com/sqs/](http://aws.amazon.com/sqs/) for more details on how SQS works, what the pricing schedule looks like and how to setup a queue.

To use this plugin, you **must**:

* Have an AWS account
* Setup an SQS queue
* Create an identity that has access to consume messages from the queue.

The "consumer" identity must have the following permissions on the queue:

* `sqs:ChangeMessageVisibility`
* `sqs:ChangeMessageVisibilityBatch`
* `sqs:DeleteMessage`
* `sqs:DeleteMessageBatch`
* `sqs:GetQueueAttributes`
* `sqs:GetQueueUrl`
* `sqs:ListQueues`
* `sqs:ReceiveMessage`

Typically, you should setup an IAM policy, create a user and apply the IAM policy to the user. A sample policy is as follows:

```json
    {
      "Statement": [
        {
          "Action": [
            "sqs:ChangeMessageVisibility",
            "sqs:ChangeMessageVisibilityBatch",
            "sqs:DeleteMessage",
            "sqs:DeleteMessageBatch",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ListQueues",
            "sqs:ReceiveMessage"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:sqs:us-east-1:123456789012:Logstash"
          ]
        }
      ]
    }
```

See [http://aws.amazon.com/iam/](http://aws.amazon.com/iam/) for more details on setting up AWS identities.


## Sqs Input Configuration Options [plugins-inputs-sqs-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-sqs-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`access_key_id`](#plugins-inputs-sqs-access_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`additional_settings`](#plugins-inputs-sqs-additional_settings) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`aws_credentials_file`](#plugins-inputs-sqs-aws_credentials_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`endpoint`](#plugins-inputs-sqs-endpoint) | [string](/reference/configuration-file-structure.md#string) | No |
| [`id_field`](#plugins-inputs-sqs-id_field) | [string](/reference/configuration-file-structure.md#string) | No |
| [`md5_field`](#plugins-inputs-sqs-md5_field) | [string](/reference/configuration-file-structure.md#string) | No |
| [`polling_frequency`](#plugins-inputs-sqs-polling_frequency) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy_uri`](#plugins-inputs-sqs-proxy_uri) | [string](/reference/configuration-file-structure.md#string) | No |
| [`queue`](#plugins-inputs-sqs-queue) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`queue_owner_aws_account_id`](#plugins-inputs-sqs-queue_owner_aws_account_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-inputs-sqs-region) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_arn`](#plugins-inputs-sqs-role_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_session_name`](#plugins-inputs-sqs-role_session_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`secret_access_key`](#plugins-inputs-sqs-secret_access_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sent_timestamp_field`](#plugins-inputs-sqs-sent_timestamp_field) | [string](/reference/configuration-file-structure.md#string) | No |
| [`session_token`](#plugins-inputs-sqs-session_token) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-sqs-threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_aws_bundled_ca`](#plugins-inputs-sqs-use_aws_bundled_ca) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-sqs-common-options) for a list of options supported by all input plugins.

 

### `access_key_id` [plugins-inputs-sqs-access_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order:

1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config
2. External credentials file specified by `aws_credentials_file`
3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`
5. IAM Instance Profile (available when running inside EC2)


### `additional_settings` [plugins-inputs-sqs-additional_settings]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Key-value pairs of settings and corresponding values used to parametrize the connection to SQS. See full list in [the AWS SDK documentation](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SQS/Client.md). Example:

```ruby
    input {
      sqs {
        access_key_id => "1234"
        secret_access_key => "secret"
        queue => "logstash-test-queue"
        additional_settings => {
          force_path_style => true
          follow_redirects => false
        }
      }
    }
```


### `aws_credentials_file` [plugins-inputs-sqs-aws_credentials_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path to YAML file containing a hash of AWS credentials. This file will only be loaded if `access_key_id` and `secret_access_key` aren’t set. The contents of the file should look like this:

```ruby
    :access_key_id: "12345"
    :secret_access_key: "54321"
```


### `endpoint` [plugins-inputs-sqs-endpoint]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The endpoint to connect to. By default it is constructed using the value of `region`. This is useful when connecting to S3 compatible services, but beware that these aren’t guaranteed to work correctly with the AWS SDK.


### `id_field` [plugins-inputs-sqs-id_field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Name of the event field in which to store the SQS message ID


### `md5_field` [plugins-inputs-sqs-md5_field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Name of the event field in which to store the SQS message MD5 checksum


### `polling_frequency` [plugins-inputs-sqs-polling_frequency]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `20`

Polling frequency, default is 20 seconds


### `proxy_uri` [plugins-inputs-sqs-proxy_uri]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URI to proxy server if required


### `queue` [plugins-inputs-sqs-queue]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Name of the SQS Queue name to pull messages from. Note that this is just the name of the queue, not the URL or ARN.


### `queue_owner_aws_account_id` [plugins-inputs-sqs-queue_owner_aws_account_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

ID of the AWS account owning the queue if you want to use a [cross-account queue](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-basic-examples-of-sqs-policies.md#grant-two-permissions-to-one-account) with embedded policy. Note that AWS SDK only support numerical account ID and not account aliases.


### `region` [plugins-inputs-sqs-region]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"us-east-1"`

The AWS Region


### `role_arn` [plugins-inputs-sqs-role_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS IAM Role to assume, if any. This is used to generate temporary credentials, typically for cross-account access. See the [AssumeRole API documentation](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.md) for more information.


### `role_session_name` [plugins-inputs-sqs-role_session_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

Session name to use when assuming an IAM role.


### `secret_access_key` [plugins-inputs-sqs-secret_access_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Secret Access Key


### `sent_timestamp_field` [plugins-inputs-sqs-sent_timestamp_field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Name of the event field in which to store the SQS message Sent Timestamp


### `session_token` [plugins-inputs-sqs-session_token]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Session token for temporary credential


### `threads` [plugins-inputs-sqs-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`


### `use_aws_bundled_ca` [plugins-inputs-sqs-use_aws_bundled_ca]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use bundled CA certificates that ship with AWS SDK to verify SSL peer certificates. For cases where the default certificates are unavailable, e.g. Windows, you can set this to `true`.



## Common options [plugins-inputs-sqs-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-sqs-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-sqs-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-sqs-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-sqs-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-sqs-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-sqs-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-sqs-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-sqs-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"json"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-sqs-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-sqs-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 sqs inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  sqs {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-sqs-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-sqs-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



