---
navigation_title: "imap"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-imap.html
---

# Imap input plugin [plugins-inputs-imap]


* Plugin version: v3.2.1
* Released on: 2023-10-03
* [Changelog](https://github.com/logstash-plugins/logstash-input-imap/blob/v3.2.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-imap-index.md).

## Getting help [_getting_help_28]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-imap). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_28]

Read mails from IMAP server

Periodically scan an IMAP folder (`INBOX` by default) and move any read messages to the trash.


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-imap-ecs]

The plugin includes sensible defaults that change based on [ECS compatibility mode](#plugins-inputs-imap-ecs_compatibility). When ECS compatibility is disabled, mail headers and attachments are targeted at the root level. When targeting an ECS version, headers and attachments target `@metadata` sub-fields unless configured otherwise in order to avoid conflict with ECS fields. See [`headers_target`](#plugins-inputs-imap-headers_target), and [`attachments_target`](#plugins-inputs-imap-attachments_target).


## Imap Input Configuration Options [plugins-inputs-imap-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-imap-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`attachments_target`](#plugins-inputs-imap-attachments_target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`check_interval`](#plugins-inputs-imap-check_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`content_type`](#plugins-inputs-imap-content_type) | [string](/reference/configuration-file-structure.md#string) | No |
| [`delete`](#plugins-inputs-imap-delete) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ecs_compatibility`](#plugins-inputs-imap-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`expunge`](#plugins-inputs-imap-expunge) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`fetch_count`](#plugins-inputs-imap-fetch_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`folder`](#plugins-inputs-imap-folder) | [string](/reference/configuration-file-structure.md#string) | No |
| [`headers_target`](#plugins-inputs-imap-headers_target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-inputs-imap-host) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`lowercase_headers`](#plugins-inputs-imap-lowercase_headers) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`password`](#plugins-inputs-imap-password) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`port`](#plugins-inputs-imap-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`save_attachments`](#plugins-inputs-imap-save_attachments) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`secure`](#plugins-inputs-imap-secure) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`sincedb_path`](#plugins-inputs-imap-sincedb_path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`strip_attachments`](#plugins-inputs-imap-strip_attachments) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`uid_tracking`](#plugins-inputs-imap-uid_tracking) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`user`](#plugins-inputs-imap-user) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`verify_cert`](#plugins-inputs-imap-verify_cert) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-imap-common-options) for a list of options supported by all input plugins.

 

### `attachments_target` [plugins-inputs-imap-attachments_target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-inputs-imap-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: `"[attachments]"`
    * ECS Compatibility enabled: `"[@metadata][input][imap][attachments]"


The name of the field under which mail attachments information will be added, if [`save_attachments`](#plugins-inputs-imap-save_attachments) is set.


### `check_interval` [plugins-inputs-imap-check_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300`


### `content_type` [plugins-inputs-imap-content_type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"text/plain"`

For multipart messages, use the first part that has this content-type as the event message.


### `delete` [plugins-inputs-imap-delete]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`


### `ecs_compatibility` [plugins-inputs-imap-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (for example, `From` header field is added to the event)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, the `From` header is added as metadata)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the *default* value of [`headers_target`](#plugins-inputs-imap-headers_target) and [`attachments_target`](#plugins-inputs-imap-attachments_target).


### `expunge` [plugins-inputs-imap-expunge]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`


### `fetch_count` [plugins-inputs-imap-fetch_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `50`


### `folder` [plugins-inputs-imap-folder]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"INBOX"`


### `headers_target` [plugins-inputs-imap-headers_target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-inputs-imap-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: no default value (for example, the subject header is stored under the `"subject"` name)
    * ECS Compatibility enabled: `"[@metadata][input][imap][headers]"`


The name of the field under which mail headers will be added.

Setting `headers_target => ''` skips headers processing and no header is added to the event. Except the date header, if present, which is always used as the event’s `@timestamp`.


### `host` [plugins-inputs-imap-host]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.


### `lowercase_headers` [plugins-inputs-imap-lowercase_headers]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`


### `password` [plugins-inputs-imap-password]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.


### `port` [plugins-inputs-imap-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.


### `save_attachments` [plugins-inputs-imap-save_attachments]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When set to true the content of attachments will be included in the `attachments.data` field.


### `secure` [plugins-inputs-imap-secure]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`


### `sincedb_path` [plugins-inputs-imap-sincedb_path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path of the sincedb database file (keeps track of the UID of the last processed mail) that will be written to disk. The default will write sincedb file to `<path.data>/plugins/inputs/imap` directory. NOTE: it must be a file path and not a directory path.


### `strip_attachments` [plugins-inputs-imap-strip_attachments]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`


### `uid_tracking` [plugins-inputs-imap-uid_tracking]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When the IMAP input plugin connects to the mailbox for the first time and the UID of the last processed mail is not yet known, the unread mails are first downloaded and the UID of the last processed mail is saved. From this point on, if `uid_tracking` is set to `true`, all new mail will be downloaded regardless of whether they are marked as read or unread. This allows users or other services to use the mailbox simultaneously with the IMAP input plugin. UID of the last processed mail is always saved regardles of the `uid_tracking` value, so you can switch its value as needed. In transition from the previous IMAP input plugin version, first process at least one mail with `uid_tracking` set to `false` to save the UID of the last processed mail and then switch `uid_tracking` to `true`.


### `user` [plugins-inputs-imap-user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.


### `verify_cert` [plugins-inputs-imap-verify_cert]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`



## Common options [plugins-inputs-imap-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-imap-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-imap-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-imap-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-imap-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-imap-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-imap-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-imap-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-imap-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-imap-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-imap-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 imap inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  imap {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-imap-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-imap-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



