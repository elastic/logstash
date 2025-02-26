---
navigation_title: "redmine"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-outputs-redmine.html
---

# Redmine output plugin [plugins-outputs-redmine]


* Plugin version: v3.0.4
* Released on: 2018-04-06
* [Changelog](https://github.com/logstash-plugins/logstash-output-redmine/blob/v3.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/output-redmine-index.md).

## Installation [_installation_43]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-output-redmine`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_104]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-output-redmine). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_104]

The redmine output is used to create a ticket via the API redmine.

It send a POST request in a JSON format and use TOKEN authentication

 — Exemple of use — 

```ruby
 output {
   redmine {
     url => "http://redmineserver.tld"
     token => 'token'
     project_id => 200
     tracker_id => 1
     status_id => 3
     priority_id => 2
     subject => "Error ... detected"
   }
 }
```


## Redmine Output Configuration Options [plugins-outputs-redmine-options]

This plugin supports the following configuration options plus the [Common options](#plugins-outputs-redmine-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`assigned_to_id`](#plugins-outputs-redmine-assigned_to_id) | [number](/reference/configuration-file-structure.md#number) | No |
| [`categorie_id`](#plugins-outputs-redmine-categorie_id) | [number](/reference/configuration-file-structure.md#number) | No |
| [`description`](#plugins-outputs-redmine-description) | [string](/reference/configuration-file-structure.md#string) | No |
| [`fixed_version_id`](#plugins-outputs-redmine-fixed_version_id) | [number](/reference/configuration-file-structure.md#number) | No |
| [`parent_issue_id`](#plugins-outputs-redmine-parent_issue_id) | [number](/reference/configuration-file-structure.md#number) | No |
| [`priority_id`](#plugins-outputs-redmine-priority_id) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`project_id`](#plugins-outputs-redmine-project_id) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`ssl`](#plugins-outputs-redmine-ssl) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`status_id`](#plugins-outputs-redmine-status_id) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`subject`](#plugins-outputs-redmine-subject) | [string](/reference/configuration-file-structure.md#string) | No |
| [`token`](#plugins-outputs-redmine-token) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`tracker_id`](#plugins-outputs-redmine-tracker_id) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`url`](#plugins-outputs-redmine-url) | [string](/reference/configuration-file-structure.md#string) | Yes |

Also see [Common options](#plugins-outputs-redmine-common-options) for a list of options supported by all output plugins.

 

### `assigned_to_id` [plugins-outputs-redmine-assigned_to_id]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `nil`

redmine issue assigned_to not required for post_issue


### `categorie_id` [plugins-outputs-redmine-categorie_id]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `nil`

not required for post_issue


### `description` [plugins-outputs-redmine-description]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"%{{message}}"`

redmine issue description required


### `fixed_version_id` [plugins-outputs-redmine-fixed_version_id]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `nil`

redmine issue fixed_version_id


### `parent_issue_id` [plugins-outputs-redmine-parent_issue_id]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `nil`

redmine issue parent_issue_id not required for post_issue


### `priority_id` [plugins-outputs-redmine-priority_id]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

redmine issue priority_id required


### `project_id` [plugins-outputs-redmine-project_id]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

redmine issue projet_id required


### `ssl` [plugins-outputs-redmine-ssl]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`


### `status_id` [plugins-outputs-redmine-status_id]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

redmine issue status_id required


### `subject` [plugins-outputs-redmine-subject]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `%{{host}}`

redmine issue subject required


### `token` [plugins-outputs-redmine-token]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

redmine token user used for authentication


### `tracker_id` [plugins-outputs-redmine-tracker_id]

* This is a required setting.
* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

redmine issue tracker_id required


### `url` [plugins-outputs-redmine-url]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

host of redmine app value format : *http://urlofredmine.tld* - Not add */issues* at end



## Common options [plugins-outputs-redmine-common-options]

These configuration options are supported by all output plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`codec`](#plugins-outputs-redmine-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-outputs-redmine-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-outputs-redmine-id) | [string](/reference/configuration-file-structure.md#string) | No |

### `codec` [plugins-outputs-redmine-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-outputs-redmine-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-outputs-redmine-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type. For example, if you have 2 redmine outputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
output {
  redmine {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::




