---
navigation_title: "s3"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-s3.html
---

# S3 output plugin [plugins-outputs-s3]


* A component of the [aws integration plugin](/reference/plugins-integrations-aws.md)
* Integration version: v7.1.8
* Released on: 2024-07-26
* [Changelog](https://github.com/logstash-plugins/logstash-integration-aws/blob/v7.1.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-s3-index.md).

## Getting help [_getting_help_107]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-aws). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_107]

This plugin batches and uploads logstash events into Amazon Simple Storage Service (Amazon S3).

::::{important}
The S3 output plugin only supports AWS S3. Other S3 compatible storage solutions are not supported.
::::


S3 outputs create temporary files into the OS' temporary directory. You can specify where to save them using the `temporary_directory` option.

::::{important}
For configurations containing multiple s3 outputs with the restore option enabled, each output should define its own *temporary_directory*.
::::


### Requirements [_requirements]

* Amazon S3 Bucket and S3 Access Permissions (Typically access_key_id and secret_access_key)
* S3 PutObject permission


### S3 output file [_s3_output_file]

```txt
`ls.s3.312bc026-2f5d-49bc-ae9f-5940cf4ad9a6.2013-04-18T10.00.tag_hello.part0.txt`
```

|     |     |     |
| --- | --- | --- |
| ls.s3 | indicates logstash plugin s3 |  |
| 312bc026-2f5d-49bc-ae9f-5940cf4ad9a6 | a new, random uuid per file. |  |
| 2013-04-18T10.00 | represents the time whenever you specify time_file. |  |
| tag_hello | indicates the event’s tag. |  |
| part0 | If you indicate size_file, it will generate more parts if your file.size > size_file.When a file is full, it gets pushed to the bucket and then deleted from the temporary directory.If a file is empty, it is simply deleted.  Empty files will not be pushed. |  |


### Crash Recovery [_crash_recovery]

This plugin will recover and upload temporary log files after crash/abnormal termination when using `restore` set to true


### Usage [_usage_4]

This is an example of logstash config:

```ruby
output {
   s3{
     access_key_id => "crazy_key"             (optional)
     secret_access_key => "monkey_access_key" (optional)
     region => "eu-west-1"                    (optional, default = "us-east-1")
     bucket => "your_bucket"                  (required)
     size_file => 2048                        (optional) - Bytes
     time_file => 5                           (optional) - Minutes
     codec => "plain"                         (optional)
     canned_acl => "private"                  (optional. Options are "private", "public-read", "public-read-write", "authenticated-read", "aws-exec-read", "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write". Defaults to "private" )
   }
```



## S3 Output Configuration Options [plugins-outputs-s3-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-s3-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`access_key_id`](#plugins-outputs-s3-access_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`additional_settings`](#plugins-outputs-s3-additional_settings) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`aws_credentials_file`](#plugins-outputs-s3-aws_credentials_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`bucket`](#plugins-outputs-s3-bucket) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`canned_acl`](#plugins-outputs-s3-canned_acl) | [string](/reference/configuration-file-structure.md#string), one of `["private", "public-read", "public-read-write", "authenticated-read", "aws-exec-read", "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write"]` | No |
| [`encoding`](#plugins-outputs-s3-encoding) | [string](/reference/configuration-file-structure.md#string), one of `["none", "gzip"]` | No |
| [`endpoint`](#plugins-outputs-s3-endpoint) | [string](/reference/configuration-file-structure.md#string) | No |
| [`prefix`](#plugins-outputs-s3-prefix) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_uri`](#plugins-outputs-s3-proxy_uri) | [string](/reference/configuration-file-structure.md#string) | No |
| [`region`](#plugins-outputs-s3-region) | [string](/reference/configuration-file-structure.md#string) | No |
| [`restore`](#plugins-outputs-s3-restore) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`retry_count`](#plugins-outputs-s3-retry_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`retry_delay`](#plugins-outputs-s3-retry_delay) | [number](/reference/configuration-file-structure.md#number) | No |
| [`role_arn`](#plugins-outputs-s3-role_arn) | [string](/reference/configuration-file-structure.md#string) | No |
| [`role_session_name`](#plugins-outputs-s3-role_session_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`rotation_strategy`](#plugins-outputs-s3-rotation_strategy) | [string](/reference/configuration-file-structure.md#string), one of `["size_and_time", "size", "time"]` | No |
| [`secret_access_key`](#plugins-outputs-s3-secret_access_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`server_side_encryption`](#plugins-outputs-s3-server_side_encryption) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`server_side_encryption_algorithm`](#plugins-outputs-s3-server_side_encryption_algorithm) | [string](/reference/configuration-file-structure.md#string), one of `["AES256", "aws:kms"]` | No |
| [`session_token`](#plugins-outputs-s3-session_token) | [string](/reference/configuration-file-structure.md#string) | No |
| [`signature_version`](#plugins-outputs-s3-signature_version) | [string](/reference/configuration-file-structure.md#string), one of `["v2", "v4"]` | No |
| [`size_file`](#plugins-outputs-s3-size_file) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ssekms_key_id`](#plugins-outputs-s3-ssekms_key_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`storage_class`](#plugins-outputs-s3-storage_class) | [string](/reference/configuration-file-structure.md#string), one of `["STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW", "EXPRESS_ONEZONE"]` | No |
| [`temporary_directory`](#plugins-outputs-s3-temporary_directory) | [string](/reference/configuration-file-structure.md#string) | No |
| [`time_file`](#plugins-outputs-s3-time_file) | [number](/reference/configuration-file-structure.md#number) | No |
| [`upload_multipart_threshold`](#plugins-outputs-s3-upload_multipart_threshold) | [number](/reference/configuration-file-structure.md#number) | No |
| [`upload_queue_size`](#plugins-outputs-s3-upload_queue_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`upload_workers_count`](#plugins-outputs-s3-upload_workers_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_aws_bundled_ca`](#plugins-outputs-s3-use_aws_bundled_ca) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`validate_credentials_on_root_bucket`](#plugins-outputs-s3-validate_credentials_on_root_bucket) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-outputs-s3-common-options) for a list of options supported by all output plugins.

 

### `access_key_id` [plugins-outputs-s3-access_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order:

1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config
2. External credentials file specified by `aws_credentials_file`
3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`
5. IAM Instance Profile (available when running inside EC2)


### `additional_settings` [plugins-outputs-s3-additional_settings]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Key-value pairs of settings and corresponding values used to parametrize the connection to S3. See full list in [the AWS SDK documentation](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Client.md). Example:

```ruby
    output {
      s3 {
        access_key_id => "1234",
        secret_access_key => "secret",
        region => "eu-west-1",
        bucket => "logstash-test",
        additional_settings => {
          "force_path_style" => true,
          "follow_redirects" => false
        }
      }
    }
```


### `aws_credentials_file` [plugins-outputs-s3-aws_credentials_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path to YAML file containing a hash of AWS credentials. This file will only be loaded if `access_key_id` and `secret_access_key` aren’t set. The contents of the file should look like this:

```ruby
    :access_key_id: "12345"
    :secret_access_key: "54321"
```


### `bucket` [plugins-outputs-s3-bucket]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

S3 bucket


### `canned_acl` [plugins-outputs-s3-canned_acl]

* Value can be any of: `private`, `public-read`, `public-read-write`, `authenticated-read`, `aws-exec-read`, `bucket-owner-read`, `bucket-owner-full-control`, `log-delivery-write`
* Default value is `"private"`

The S3 canned ACL to use when putting the file. Defaults to "private".


### `encoding` [plugins-outputs-s3-encoding]

* Value can be any of: `none`, `gzip`
* Default value is `"none"`

Specify the content encoding. Supports ("gzip"). Defaults to "none"


### `endpoint` [plugins-outputs-s3-endpoint]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The endpoint to connect to. By default it is constructed using the value of `region`. This is useful when connecting to S3 compatible services, but beware that these aren’t guaranteed to work correctly with the AWS SDK. The endpoint should be an HTTP or HTTPS URL, e.g. [https://example.com](https://example.com)


### `prefix` [plugins-outputs-s3-prefix]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

Specify a prefix to the uploaded filename to simulate directories on S3. Prefix does not require leading slash. This option supports [Logstash interpolation](/reference/event-dependent-configuration.md#sprintf). For example, files can be prefixed with the event date using `prefix = "%{+YYYY}/%{+MM}/%{+dd}"`.

::::{important}
Take care when you are using interpolated strings in prefixes. This has the potential to create large numbers of unique prefixes, causing large numbers of in-progress uploads. This scenario may result in performance and stability issues, which can be further exacerbated when you use a rotation_strategy that delays uploads.
::::



### `proxy_uri` [plugins-outputs-s3-proxy_uri]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

URI to proxy server if required


### `region` [plugins-outputs-s3-region]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"us-east-1"`

The AWS Region


### `restore` [plugins-outputs-s3-restore]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Used to enable recovery after crash/abnormal termination. Temporary log files will be recovered and uploaded.


### `retry_count` [plugins-outputs-s3-retry_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `Infinity`

Allows to limit number of retries when S3 uploading fails.


### `retry_delay` [plugins-outputs-s3-retry_delay]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Delay (in seconds) to wait between consecutive retries on upload failures.


### `role_arn` [plugins-outputs-s3-role_arn]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS IAM Role to assume, if any. This is used to generate temporary credentials, typically for cross-account access. See the [AssumeRole API documentation](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.md) for more information.


### `role_session_name` [plugins-outputs-s3-role_session_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"logstash"`

Session name to use when assuming an IAM role.


### `rotation_strategy` [plugins-outputs-s3-rotation_strategy]

* Value can be any of: `size_and_time`, `size`, `time`
* Default value is `"size_and_time"`

Controls when to close the file and push it to S3.

If you set this value to `size`, it uses the value set in [`size_file`](#plugins-outputs-s3-size_file). If you set this value to `time`, it uses the value set in [`time_file`](#plugins-outputs-s3-time_file). If you set this value to `size_and_time`, it uses the values from [`size_file`](#plugins-outputs-s3-size_file) and [`time_file`](#plugins-outputs-s3-time_file), and splits the file when either one matches.

The default strategy checks both size and time. The first value to match triggers file rotation.


### `secret_access_key` [plugins-outputs-s3-secret_access_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Secret Access Key


### `server_side_encryption` [plugins-outputs-s3-server_side_encryption]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Specifies whether or not to use S3’s server side encryption. Defaults to no encryption.


### `server_side_encryption_algorithm` [plugins-outputs-s3-server_side_encryption_algorithm]

* Value can be any of: `AES256`, `aws:kms`
* Default value is `"AES256"`

Specifies what type of encryption to use when SSE is enabled.


### `session_token` [plugins-outputs-s3-session_token]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The AWS Session token for temporary credential


### `signature_version` [plugins-outputs-s3-signature_version]

* Value can be any of: `v2`, `v4`
* There is no default value for this setting.

The version of the S3 signature hash to use. Normally uses the internal client default, can be explicitly specified here


### `size_file` [plugins-outputs-s3-size_file]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5242880`

Set the file size in bytes. When the number of bytes exceeds the `size_file` value, a new file is created. If you use tags, Logstash generates a specific size file for every tag.


### `ssekms_key_id` [plugins-outputs-s3-ssekms_key_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The key to use when specified along with server_side_encryption ⇒ aws:kms. If server_side_encryption ⇒ aws:kms is set but this is not default KMS key is used. [http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.html](http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingKMSEncryption.md)


### `storage_class` [plugins-outputs-s3-storage_class]

* Value can be any of: `STANDARD`, `REDUCED_REDUNDANCY`, `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `DEEP_ARCHIVE`, `OUTPOSTS`, `GLACIER_IR`, `SNOW`, `EXPRESS_ONEZONE`
* Default value is `"STANDARD"`

Specifies what S3 storage class to use when uploading the file. More information about the different storage classes can be found: [http://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html](http://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.md) Defaults to STANDARD.


### `temporary_directory` [plugins-outputs-s3-temporary_directory]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"/tmp/logstash"`

Set the directory where logstash will store the tmp files before sending it to S3 default to the current OS temporary directory in linux /tmp/logstash


### `time_file` [plugins-outputs-s3-time_file]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `15`

Set the time, in MINUTES, to close the current sub_time_section of bucket. If [`rotation_strategy`](#plugins-outputs-s3-rotation_strategy) is set to `time` or `size_and_time`, then `time_file` cannot be set to 0. Otherwise, the plugin raises a configuration error.


### `upload_multipart_threshold` [plugins-outputs-s3-upload_multipart_threshold]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `15728640`

Files larger than this number are uploaded using the S3 multipart APIs


### `upload_queue_size` [plugins-outputs-s3-upload_queue_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `4`

Number of items we can keep in the local queue before uploading them


### `upload_workers_count` [plugins-outputs-s3-upload_workers_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `4`

Specify how many workers to use to upload the files to S3


### `use_aws_bundled_ca` [plugins-outputs-s3-use_aws_bundled_ca]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Use bundled CA certificates that ship with AWS SDK to verify SSL peer certificates. For cases where the default certificates are unavailable, e.g. Windows, you can set this to `true`.


### `validate_credentials_on_root_bucket` [plugins-outputs-s3-validate_credentials_on_root_bucket]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

The common use case is to define permissions on the root bucket and give Logstash full access to write logs. In some circumstances, you need more granular permissions on the subfolder. This allows you to disable the check at startup.



## Common options [plugins-outputs-s3-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-s3-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-s3-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-s3-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-s3-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"line"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-s3-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-s3-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 s3 outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  s3 {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




