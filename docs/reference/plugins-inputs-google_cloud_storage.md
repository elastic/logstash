---
navigation_title: "google_cloud_storage"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-google_cloud_storage.html
---

# Google Cloud Storage Input Plugin [plugins-inputs-google_cloud_storage]


* Plugin version: v0.15.0
* Released on: 2023-08-22
* [Changelog](https://github.com/logstash-plugins/logstash-input-google_cloud_storage/blob/v0.15.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-google_cloud_storage-index.md).

## Installation [_installation_2]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-input-google_cloud_storage`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_22]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-google_cloud_storage). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [plugins-inputs-google_cloud_storage-description]

Extracts events from files in a Google Cloud Storage bucket.

Example use-cases:

* Read [Stackdriver logs](https://cloud.google.com/stackdriver/) from a Cloud Storage bucket into Elastic.
* Read gzipped logs from cold-storage into Elastic.
* Restore data from an Elastic dump.
* Extract data from Cloud Storage, transform it with Logstash and load it into BigQuery.

Note: While this project is partially maintained by Google, this is not an official Google product.

::::{admonition} Installation Note
:class: note

Attempting to install this plugin may result in an error:

```bash
Bundler::VersionConflict: Bundler could not find compatible versions for gem "mimemagic":
  In Gemfile:
    logstash-input-google_cloud_storage (= 0.11.0) was resolved to 0.11.0, which depends on
      mimemagic (>= 0.3.7)

Could not find gem 'mimemagic (>= 0.3.7)', which is required by gem 'logstash-input-google_cloud_storage (= 0.11.0)', in any of the sources or in gems cached in vendor/cache
```

If this error occurs, you can fix it by manually installing the "mimemagic" dependency directly into the Logstash’s internal Ruby Gems cache, which is present at `vendor/bundle/jruby/<ruby_version>/gems/`. This could be done using the bundled Ruby gem’s instance inside the Logstash’s installation `bin/` folder.

To manually install the "mimemagic" gem into Logstash use:

```bash
bin/ruby -S gem install mimemagic -v '>= 0.3.7'
```

The mimemagic gem also requires the `shared-mime-info` package to be present, it can be installed using `apt-get install shared-mime-info` on Debian/Ubuntu or `yum install shared-mime-info` on Red Hat/RockyOS distributions.

Then install the plugin as usual with:

```bash
bin/logstash-plugin install logstash-input-google_cloud_storage
```

::::



## Metadata Attributes [plugins-inputs-google_cloud_storage-metadata-attributes]

The plugin exposes several metadata attributes about the object being read. You can access these later in the pipeline to augment the data or perform conditional logic.

| Key | Type | Description |
| --- | --- | --- |
| `[@metadata][gcs][bucket]` | `string` | The name of the bucket the file was read from. |
| `[@metadata][gcs][name]` | `string` | The name of the object. |
| `[@metadata][gcs][metadata]` | `object` | A map of metadata on the object. |
| `[@metadata][gcs][md5]` | `string` | MD5 hash of the data. Encoded using base64. |
| `[@metadata][gcs][crc32c]` | `string` | CRC32c checksum, as described in RFC 4960. Encoded using base64 in big-endian byte order. |
| `[@metadata][gcs][generation]` | `long` | The content generation of the object. Used for object versioning |
| `[@metadata][gcs][line]` | `long` | The position of the event in the file. 1 indexed. |
| `[@metadata][gcs][line_id]` | `string` | A deterministic, unique ID describing this line. This lets you do idempotent inserts into Elasticsearch. |

More information about object metadata can be found in the [official documentation](https://cloud.google.com/storage/docs/json_api/v1/objects).


## Example Configurations [plugins-inputs-google_cloud_storage-example-configurations]

### Basic [_basic]

Basic configuration to read JSON logs every minute from `my-logs-bucket`. For example, [Stackdriver logs](https://cloud.google.com/stackdriver/).

```ruby
input {
  google_cloud_storage {
    interval => 60
    bucket_id => "my-logs-bucket"
    json_key_file => "/home/user/key.json"
    file_matches => ".*json"
    codec => "json_lines"
  }
}
output { stdout { codec => rubydebug } }
```


### Idempotent Inserts into Elasticsearch [_idempotent_inserts_into_elasticsearch]

If your pipeline might insert the same file multiple times you can use the `line_id` metadata key as a deterministic id.

The ID has the format: `gs://<bucket_id>/<object_id>:<line_num>@<generation>`. `line_num` represents the nth event deserialized from the file starting at 1. `generation` is a unique id Cloud Storage generates for the object. When an object is overwritten it gets a new generation.

```ruby
input {
  google_cloud_storage {
    bucket_id => "batch-jobs-output"
  }
}

output {
  elasticsearch {
    document_id => "%{[@metadata][gcs][line_id]}"
  }
}
```


### From Cloud Storage to BigQuery [_from_cloud_storage_to_bigquery]

Extract data from Cloud Storage, transform it with Logstash and load it into BigQuery.

```ruby
input {
  google_cloud_storage {
    interval => 60
    bucket_id => "batch-jobs-output"
    file_matches => "purchases.*.csv"
    json_key_file => "/home/user/key.json"
    codec => "plain"
  }
}

filter {
  csv {
    columns => ["transaction", "sku", "price"]
    convert => {
      "transaction" => "integer"
      "price" => "float"
    }
  }
}

output {
  google_bigquery {
    project_id => "my-project"
    dataset => "logs"
    csv_schema => "transaction:INTEGER,sku:INTEGER,price:FLOAT"
    json_key_file => "/path/to/key.json"
    error_directory => "/tmp/bigquery-errors"
    ignore_unknown_values => true
  }
}
```



## Additional Resources [plugins-inputs-google_cloud_storage-additional-resources]

* [Cloud Storage Homepage](https://cloud.google.com/storage/)
* [Cloud Storage Pricing](https://cloud.google.com/storage/pricing-summary/)
* [IAM Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
* [Application Default Credentials](https://cloud.google.com/docs/authentication/production)


## Google Cloud Storage Input Configuration Options [plugins-inputs-google_cloud_storage-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-google_cloud_storage-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`bucket_id`](#plugins-inputs-google_cloud_storage-bucket_id) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`json_key_file`](#plugins-inputs-google_cloud_storage-json_key_file) | [path](/reference/configuration-file-structure.md#path) | No |
| [`interval`](#plugins-inputs-google_cloud_storage-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`file_matches`](#plugins-inputs-google_cloud_storage-file_matches) | [string](/reference/configuration-file-structure.md#string) | No |
| [`file_exclude`](#plugins-inputs-google_cloud_storage-file_exclude) | [string](/reference/configuration-file-structure.md#string) | No |
| [`metadata_key`](#plugins-inputs-google_cloud_storage-metadata_key) | [string](/reference/configuration-file-structure.md#string) | No |
| [`processed_db_path`](#plugins-inputs-google_cloud_storage-processed_db_path) | [path](/reference/configuration-file-structure.md#path) | No |
| [`delete`](#plugins-inputs-google_cloud_storage-delete) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`unpack_gzip`](#plugins-inputs-google_cloud_storage-unpack_gzip) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-google_cloud_storage-common-options) for a list of options supported by all input plugins.

### `bucket_id` [plugins-inputs-google_cloud_storage-bucket_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The bucket containing your log files.


### `json_key_file` [plugins-inputs-google_cloud_storage-json_key_file]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

The path to the key to authenticate your user to the bucket. This service user *should* have the `storage.objects.update` permission so it can create metadata on the object preventing it from being scanned multiple times.

If no key is provided the plugin will try to use the [default application credentials](https://cloud.google.com/java/docs/reference/google-auth-library/latest/com.google.auth.oauth2.GoogleCredentials#com_google_auth_oauth2_GoogleCredentials_getApplicationDefault__), and if they don’t exist, it falls back to unauthenticated mode.


### `interval` [plugins-inputs-google_cloud_storage-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default is: `60`

The number of seconds between looking for new files in your bucket.


### `file_matches` [plugins-inputs-google_cloud_storage-file_matches]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default is: `.*\.log(\.gz)?`

A regex pattern to filter files. Only files with names matching this will be considered. All files match by default.


### `file_exclude` [plugins-inputs-google_cloud_storage-file_exclude]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default is: `^$`

Any files matching this regex are excluded from processing. No files are excluded by default.


### `metadata_key` [plugins-inputs-google_cloud_storage-metadata_key]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default is: `x-goog-meta-ls-gcs-input`

This key will be set on the objects after they’ve been processed by the plugin. That way you can stop the plugin and not upload files again or prevent them from being uploaded by setting the field manually.

::::{note}
the key is a flag, if a file was partially processed before Logstash exited some events will be resent.
::::



### `processed_db_path` [plugins-inputs-google_cloud_storage-processed_db_path]

* Value type is [path](/reference/configuration-file-structure.md#path)
* Default is: `LOGSTASH_DATA/plugins/inputs/google_cloud_storage/db`.

If set, the plugin will store the list of processed files locally. This allows you to create a service account for the plugin that does not have write permissions. However, the data will not be shared across multiple running instances of Logstash.


### `delete` [plugins-inputs-google_cloud_storage-delete]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default is: `false`

Should the log file be deleted after its contents have been updated?


### `unpack_gzip` [plugins-inputs-google_cloud_storage-unpack_gzip]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default is: `true`

If set to `true`, files ending in `.gz` are decompressed before they’re parsed by the codec. The file will be skipped if it has the suffix, but can’t be opened as a gzip, e.g. if it has a bad magic number.



## Common options [plugins-inputs-google_cloud_storage-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-google_cloud_storage-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-google_cloud_storage-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-google_cloud_storage-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-google_cloud_storage-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-google_cloud_storage-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-google_cloud_storage-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-google_cloud_storage-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-google_cloud_storage-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-google_cloud_storage-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-google_cloud_storage-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 google_cloud_storage inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  google_cloud_storage {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-google_cloud_storage-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-google_cloud_storage-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



