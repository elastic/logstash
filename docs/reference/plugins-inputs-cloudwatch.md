---
navigation_title: "cloudwatch"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-cloudwatch.html
---

# Cloudwatch input plugin [plugins-inputs-cloudwatch]


* A component of the [aws integration plugin](/reference/plugins-integrations-aws.md)
* Integration version: v7.1.8
* Released on: 2024-07-26
* [Changelog](https://github.com/logstash-plugins/logstash-integration-aws/blob/v7.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-cloudwatch-index.md).

## Getting help [_getting_help_10]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-aws). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_11]

Pull events from the Amazon Web Services CloudWatch API.

To use this plugin, you **must** have an AWS account, and the following policy

Typically, you should setup an IAM policy, create a user and apply the IAM policy to the user. A sample policy for EC2 metrics is as follows:

```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Stmt1444715676000",
                "Effect": "Allow",
                "Action": [
                    "cloudwatch:GetMetricStatistics",
                    "cloudwatch:ListMetrics"
                ],
                "Resource": "*"
            },
            {
                "Sid": "Stmt1444716576170",
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeInstances"
                ],
                "Resource": "*"
            }
        ]
    }
```

See [http://aws.amazon.com/iam/](http://aws.amazon.com/iam/) for more details on setting up AWS identities.

### Configuration examples [_configuration_examples]

```ruby
    input {
      cloudwatch {
        namespace => "AWS/EC2"
        metrics => [ "CPUUtilization" ]
        filters => { "tag:Group" => "API-Production" }
        region => "us-east-1"
      }
    }
```

```ruby
    input {
      cloudwatch {
        namespace => "AWS/EBS"
        metrics => ["VolumeQueueLength"]
        filters => { "tag:Monitoring" => "Yes" }
        region => "us-east-1"
      }
    }
```

```ruby
    input {
      cloudwatch {
        namespace => "AWS/RDS"
        metrics => ["CPUUtilization", "CPUCreditUsage"]
        filters => { "EngineName" => "mysql" } # Only supports EngineName, DatabaseClass and DBInstanceIdentifier
        region => "us-east-1"
      }
    }
```

```ruby
    input {
      cloudwatch {
        namespace => "sqlserver_test2"
        metrics => [ "Memory Available Bytes"]
        filters =>  {
            InstanceId => "i-xxxxxxxxxxx"
            objectname => "Memory"
        }
        combined => true
        interval => 600
        period => 300
      }
    }
```



## Cloudwatch Input Configuration Options [plugins-inputs-cloudwatch-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-cloudwatch-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`access_key_id`](#plugins-inputs-cloudwatch-access_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`aws_credentials_file`](#plugins-inputs-cloudwatch-aws_credentials_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`combined`](#plugins-inputs-cloudwatch-combined) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`endpoint`](#plugins-inputs-cloudwatch-endpoint) | [string](/reference/configuration-file-structure.md#string) | No |
| [`filters`](#plugins-inputs-cloudwatch-filters) | [array](/reference/configuration-file-structure.md#array) | See [note](#plugins-inputs-cloudwatch-filters) |
| [`interval`](#plugins-inputs-cloudwatch-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`metrics`](#plugins-inputs-cloudwatch-metrics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`namespace`](#plugins-inputs-cloudwatch-namespace) | [string](/reference/configuration-file-structure.md#string) | No |
| [`period`](#plugins-inputs-cloudwatch-period) | [number](/reference/configuration-file-structure.md#number) | No |
| [`proxy_uri`](#plugins-inputs-cloudwatch-proxy_uri) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-inputs-cloudwatch-region) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_arn`](#plugins-inputs-cloudwatch-role_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_session_name`](#plugins-inputs-cloudwatch-role_session_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`secret_access_key`](#plugins-inputs-cloudwatch-secret_access_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`session_token`](#plugins-inputs-cloudwatch-session_token) | [string](/reference/configuration-file-structure.md#string) | No |
| [`statistics`](#plugins-inputs-cloudwatch-statistics) | [array](/reference/configuration-file-structure.md#array) | No |
| [`use_aws_bundled_ca`](#plugins-inputs-cloudwatch-use_aws_bundled_ca) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_ssl`](#plugins-inputs-cloudwatch-use_ssl) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-cloudwatch-common-options) for a list of options supported by all input plugins.

 

### `access_key_id` [plugins-inputs-cloudwatch-access_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order:

1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config
2. External credentials file specified by `aws_credentials_file`
3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`
5. IAM Instance Profile (available when running inside EC2)


### `aws_credentials_file` [plugins-inputs-cloudwatch-aws_credentials_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path to YAML file containing a hash of AWS credentials. This file will only be loaded if `access_key_id` and `secret_access_key` aren’t set. The contents of the file should look like this:

```ruby
    :access_key_id: "12345"
    :secret_access_key: "54321"
```


### `combined` [plugins-inputs-cloudwatch-combined]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use this for namespaces that need to combine the dimensions like S3 and SNS.


### `endpoint` [plugins-inputs-cloudwatch-endpoint]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The endpoint to connect to. By default it is constructed using the value of `region`. This is useful when connecting to S3 compatible services, but beware that these aren’t guaranteed to work correctly with the AWS SDK.


### `filters` [plugins-inputs-cloudwatch-filters]

* This setting can be required or optional. See note below.
* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

::::{note}
This setting is optional when the namespace is `AWS/EC2`. Otherwise this is a required field.
::::


Specify the filters to apply when fetching resources. Follow the AWS convention:

* Instances: { *instance-id* ⇒ *i-12344321* }
* Tags: { "tag:Environment" ⇒ "Production" }
* Volumes: { *attachment.status* ⇒ *attached* }

Each namespace uniquely support certain dimensions. Please consult the documentation to ensure you’re using valid filters.


### `interval` [plugins-inputs-cloudwatch-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `900`

Set how frequently CloudWatch should be queried

The default, `900`, means check every 15 minutes. Setting this value too low (generally less than 300) results in no metrics being returned from CloudWatch.


### `metrics` [plugins-inputs-cloudwatch-metrics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["CPUUtilization", "DiskReadOps", "DiskWriteOps", "NetworkIn", "NetworkOut"]`

Specify the metrics to fetch for the namespace. The defaults are AWS/EC2 specific. See [http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/aws-namespaces.html](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/aws-namespaces.md) for the available metrics for other namespaces.


### `namespace` [plugins-inputs-cloudwatch-namespace]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"AWS/EC2"`

If undefined, LogStash will complain, even if codec is unused. The service namespace of the metrics to fetch.

The default is for the EC2 service. See [http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/aws-namespaces.html](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/aws-namespaces.md) for valid values.


### `period` [plugins-inputs-cloudwatch-period]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300`

Set the granularity of the returned datapoints.

Must be at least 60 seconds and in multiples of 60.


### `proxy_uri` [plugins-inputs-cloudwatch-proxy_uri]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URI to proxy server if required


### `region` [plugins-inputs-cloudwatch-region]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"us-east-1"`

The AWS Region


### `role_arn` [plugins-inputs-cloudwatch-role_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS IAM Role to assume, if any. This is used to generate temporary credentials, typically for cross-account access. See the [AssumeRole API documentation](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.md) for more information.


### `role_session_name` [plugins-inputs-cloudwatch-role_session_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

Session name to use when assuming an IAM role.


### `secret_access_key` [plugins-inputs-cloudwatch-secret_access_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Secret Access Key


### `session_token` [plugins-inputs-cloudwatch-session_token]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Session token for temporary credential


### `statistics` [plugins-inputs-cloudwatch-statistics]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["SampleCount", "Average", "Minimum", "Maximum", "Sum"]`

Specify the statistics to fetch for each namespace


### `use_aws_bundled_ca` [plugins-inputs-cloudwatch-use_aws_bundled_ca]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use bundled CA certificates that ship with AWS SDK to verify SSL peer certificates. For cases where the default certificates are unavailable, e.g. Windows, you can set this to `true`.


### `use_ssl` [plugins-inputs-cloudwatch-use_ssl]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Make sure we require the V1 classes when including this module. require *aws-sdk* will load v2 classes. Should we require (true) or disable (false) using SSL for communicating with the AWS API The AWS SDK for Ruby defaults to SSL so we preserve that



## Common options [plugins-inputs-cloudwatch-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-cloudwatch-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-cloudwatch-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-cloudwatch-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-cloudwatch-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-cloudwatch-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-cloudwatch-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-cloudwatch-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-cloudwatch-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-cloudwatch-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-cloudwatch-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 cloudwatch inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  cloudwatch {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-cloudwatch-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-cloudwatch-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



