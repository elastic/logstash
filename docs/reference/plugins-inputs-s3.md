---
navigation_title: "s3"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-s3.html
---

# S3 input plugin [plugins-inputs-s3]


* A component of the [aws integration plugin](/reference/plugins-integrations-aws.md)
* Integration version: v7.1.8
* Released on: 2024-07-26
* [Changelog](https://github.com/logstash-plugins/logstash-integration-aws/blob/v7.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-s3-index.md).

## Getting help [_getting_help_47]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-aws). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_47]

Stream events from files from a S3 bucket.

::::{important}
The S3 input plugin only supports AWS S3. Other S3 compatible storage solutions are not supported.
::::


Each line from each file generates an event. Files ending in `.gz` are handled as gzip’ed files.

Files that are archived to AWS Glacier will be skipped.


## Event Metadata and the Elastic Common Schema (ECS) [plugins-inputs-s3-ecs_metadata]

This plugin adds cloudfront metadata to event. When ECS compatibility is disabled, the value is stored in the root level. When ECS is enabled, the value is stored in the `@metadata` where it can be used by other plugins in your pipeline.

Here’s how ECS compatibility mode affects output.

|  ECS disabled |  ECS v1 | Availability | Description |
| --- | --- | --- | --- |
|  cloudfront_fields |  [@metadata][s3][cloudfront][fields] | *available when the file is a CloudFront log* | *column names of log* |
|  cloudfront_version |  [@metadata][s3][cloudfront][version] | *available when the file is a CloudFront log* | *version of log* |


## S3 Input Configuration Options [plugins-inputs-s3-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-s3-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`access_key_id`](#plugins-inputs-s3-access_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`additional_settings`](#plugins-inputs-s3-additional_settings) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`aws_credentials_file`](#plugins-inputs-s3-aws_credentials_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`backup_add_prefix`](#plugins-inputs-s3-backup_add_prefix) | [string](/reference/configuration-file-structure.md#string) | No |
| [`backup_to_bucket`](#plugins-inputs-s3-backup_to_bucket) | [string](/reference/configuration-file-structure.md#string) | No |
| [`backup_to_dir`](#plugins-inputs-s3-backup_to_dir) | [string](/reference/configuration-file-structure.md#string) | No |
| [`bucket`](#plugins-inputs-s3-bucket) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`delete`](#plugins-inputs-s3-delete) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ecs_compatibility`](#plugins-inputs-s3-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`endpoint`](#plugins-inputs-s3-endpoint) | [string](/reference/configuration-file-structure.md#string) | No |
| [`exclude_pattern`](#plugins-inputs-s3-exclude_pattern) | [string](/reference/configuration-file-structure.md#string) | No |
| [`gzip_pattern`](#plugins-inputs-s3-gzip_pattern) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_object_properties`](#plugins-inputs-s3-include_object_properties) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`interval`](#plugins-inputs-s3-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`prefix`](#plugins-inputs-s3-prefix) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_uri`](#plugins-inputs-s3-proxy_uri) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-inputs-s3-region) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_arn`](#plugins-inputs-s3-role_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_session_name`](#plugins-inputs-s3-role_session_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`secret_access_key`](#plugins-inputs-s3-secret_access_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`session_token`](#plugins-inputs-s3-session_token) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sincedb_path`](#plugins-inputs-s3-sincedb_path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`temporary_directory`](#plugins-inputs-s3-temporary_directory) | [string](/reference/configuration-file-structure.md#string) | No |
| [`use_aws_bundled_ca`](#plugins-inputs-s3-use_aws_bundled_ca) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`watch_for_new_files`](#plugins-inputs-s3-watch_for_new_files) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-s3-common-options) for a list of options supported by all input plugins.

 

### `access_key_id` [plugins-inputs-s3-access_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order:

1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config
2. External credentials file specified by `aws_credentials_file`
3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`
5. IAM Instance Profile (available when running inside EC2)


### `additional_settings` [plugins-inputs-s3-additional_settings]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Key-value pairs of settings and corresponding values used to parametrize the connection to s3. See full list in [the AWS SDK documentation](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.md). Example:

```ruby
    input {
      s3 {
        access_key_id => "1234"
        secret_access_key => "secret"
        bucket => "logstash-test"
        additional_settings => {
          force_path_style => true
          follow_redirects => false
        }
      }
    }
```


### `aws_credentials_file` [plugins-inputs-s3-aws_credentials_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path to YAML file containing a hash of AWS credentials. This file will only be loaded if `access_key_id` and `secret_access_key` aren’t set. The contents of the file should look like this:

```ruby
    :access_key_id: "12345"
    :secret_access_key: "54321"
```


### `backup_add_prefix` [plugins-inputs-s3-backup_add_prefix]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

Append a prefix to the key (full path including file name in s3) after processing. If backing up to another (or the same) bucket, this effectively lets you choose a new *folder* to place the files in


### `backup_to_bucket` [plugins-inputs-s3-backup_to_bucket]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

Name of a S3 bucket to backup processed files to.


### `backup_to_dir` [plugins-inputs-s3-backup_to_dir]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

Path of a local directory to backup processed files to.


### `bucket` [plugins-inputs-s3-bucket]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the S3 bucket.


### `delete` [plugins-inputs-s3-delete]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Whether to delete processed files from the original bucket.


### `ecs_compatibility` [plugins-inputs-s3-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names
    * `v1`,`v8`: uses metadata fields that are compatible with Elastic Common Schema


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). See [Event Metadata and the Elastic Common Schema (ECS)](#plugins-inputs-s3-ecs_metadata) for detailed information.


### `endpoint` [plugins-inputs-s3-endpoint]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The endpoint to connect to. By default it is constructed using the value of `region`. This is useful when connecting to S3 compatible services, but beware that these aren’t guaranteed to work correctly with the AWS SDK.


### `exclude_pattern` [plugins-inputs-s3-exclude_pattern]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

Ruby style regexp of keys to exclude from the bucket.

Note that files matching the pattern are skipped *after* they have been listed. Consider using [`prefix`](#plugins-inputs-s3-prefix) instead where possible.

Example:

```ruby
"exclude_pattern" => "\/2020\/04\/"
```

This pattern excludes all logs containing "/2020/04/" in the path.


### `gzip_pattern` [plugins-inputs-s3-gzip_pattern]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"\.gz(ip)?$"`

Regular expression used to determine whether an input file is in gzip format.


### `include_object_properties` [plugins-inputs-s3-include_object_properties]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Whether or not to include the S3 object’s properties (last_modified, content_type, metadata) into each Event at `[@metadata][s3]`. Regardless of this setting, `[@metadata][s3][key]` will always be present.


### `interval` [plugins-inputs-s3-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

Interval to wait between to check the file list again after a run is finished. Value is in seconds.


### `prefix` [plugins-inputs-s3-prefix]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

If specified, the prefix of filenames in the bucket must match (not a regexp)


### `proxy_uri` [plugins-inputs-s3-proxy_uri]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URI to proxy server if required


### `region` [plugins-inputs-s3-region]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"us-east-1"`

The AWS Region


### `role_arn` [plugins-inputs-s3-role_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS IAM Role to assume, if any. This is used to generate temporary credentials, typically for cross-account access. See the [AssumeRole API documentation](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.md) for more information.


### `role_session_name` [plugins-inputs-s3-role_session_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

Session name to use when assuming an IAM role.


### `secret_access_key` [plugins-inputs-s3-secret_access_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Secret Access Key


### `session_token` [plugins-inputs-s3-session_token]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Session token for temporary credential


### `sincedb_path` [plugins-inputs-s3-sincedb_path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `nil`

Where to write the since database (keeps track of the date the last handled file was added to S3). The default will write sincedb files to in the directory *{path.data}/plugins/inputs/s3/*

If specified, this setting must be a filename path and not just a directory.


### `temporary_directory` [plugins-inputs-s3-temporary_directory]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"/tmp/logstash"`

Set the directory where logstash will store the tmp files before processing them.


### `use_aws_bundled_ca` [plugins-inputs-s3-use_aws_bundled_ca]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use bundled CA certificates that ship with AWS SDK to verify SSL peer certificates. For cases where the default certificates are unavailable, e.g. Windows, you can set this to `true`.


### `watch_for_new_files` [plugins-inputs-s3-watch_for_new_files]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether or not to watch for new files. Disabling this option causes the input to close itself after processing the files from a single listing.



## Common options [plugins-inputs-s3-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-s3-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-s3-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-s3-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-s3-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-s3-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-s3-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-s3-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-s3-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-s3-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-s3-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 s3 inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  s3 {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-s3-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-s3-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



