---
navigation_title: "jdbc_streaming"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-jdbc_streaming.html
---

# Jdbc_streaming filter plugin [plugins-filters-jdbc_streaming]


* A component of the [jdbc integration plugin](/reference/plugins-integrations-jdbc.md)
* Integration version: v5.5.2
* Released on: 2024-12-23
* [Changelog](https://github.com/logstash-plugins/logstash-integration-jdbc/blob/v5.5.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-jdbc_streaming-index.md).

## Getting help [_getting_help_148]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-jdbc). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_147]

This filter executes a SQL query and stores the result set in the field specified as `target`. It will cache the results locally in an LRU cache with expiry.

For example, you can load a row based on an id in the event.

```ruby
filter {
  jdbc_streaming {
    jdbc_driver_library => "/path/to/mysql-connector-java-5.1.34-bin.jar"
    jdbc_driver_class => "com.mysql.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://localhost:3306/mydatabase"
    jdbc_user => "me"
    jdbc_password => "secret"
    statement => "select * from WORLD.COUNTRY WHERE Code = :code"
    parameters => { "code" => "country_code"}
    target => "country_details"
  }
}
```


## Prepared Statements [plugins-filters-jdbc_streaming-prepared_statements]

Using server side prepared statements can speed up execution times as the server optimises the query plan and execution.

::::{note}
Not all JDBC accessible technologies will support prepared statements.
::::


With the introduction of Prepared Statement support comes a different code execution path and some new settings. Most of the existing settings are still useful but there are several new settings for Prepared Statements to read up on.

Use the boolean setting `use_prepared_statements` to enable this execution mode.

Use the `prepared_statement_name` setting to specify a name for the Prepared Statement, this identifies the prepared statement locally and remotely and it should be unique in your config and on the database.

Use the `prepared_statement_bind_values` array setting to specify the bind values. Typically, these values are indirectly extracted from your event, i.e. the string in the array refers to a field name in your event. You can also use constant values like numbers or strings but ensure that any string constants (e.g. a locale constant of "en" or "de") is not also an event field name. It is a good idea to use the bracketed field reference syntax for fields and normal strings for constants, e.g. `prepared_statement_bind_values => ["[src_ip]", "tokyo"],`.

There are 3 possible parameter schemes. Interpolated, field references and constants. Use interpolation when you are prefixing, suffixing or concatenating field values to create a value that exists in your database, e.g. `%{{username}}@%{{domain}}` → `"alice@example.org"`, `%{{distance}}km` → "42km". Use field references for exact field values e.g. "[srcip]" → "192.168.1.2". Use constants when a database column holds values that slice or categorise a number of similar records e.g. language translations.

A boolean setting `prepared_statement_warn_on_constant_usage`, defaulting to true, controls whether you will see a WARN message logged that warns when constants could be missing the bracketed field reference syntax. If you have set your field references and constants correctly you should set `prepared_statement_warn_on_constant_usage` to false. This setting and code checks should be deprecated in a future major Logstash release.

The `statement` (or `statement_path`) setting still holds the SQL statement but to use bind variables you must use the `?` character as a placeholder in the exact order found in the `prepared_statement_bind_values` array. Some technologies may require connection string properties to be set, see MySQL example below.

Example:

```ruby
filter {
  jdbc_streaming {
    jdbc_driver_library => "/path/to/mysql-connector-java-5.1.34-bin.jar"
    jdbc_driver_class => "com.mysql.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://localhost:3306/mydatabase?cachePrepStmts=true&prepStmtCacheSize=250&prepStmtCacheSqlLimit=2048&useServerPrepStmts=true"
    jdbc_user => "me"
    jdbc_password => "secret"
    statement => "select * from WORLD.COUNTRY WHERE Code = ?"
    use_prepared_statements => true
    prepared_statement_name => "lookup_country_info"
    prepared_statement_bind_values => ["[country_code]"]
    target => "country_details"
  }
}
```


## Jdbc_streaming Filter Configuration Options [plugins-filters-jdbc_streaming-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-jdbc_streaming-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`cache_expiration`](#plugins-filters-jdbc_streaming-cache_expiration) | [number](/reference/configuration-file-structure.md#number) | No |
| [`cache_size`](#plugins-filters-jdbc_streaming-cache_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`default_hash`](#plugins-filters-jdbc_streaming-default_hash) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`jdbc_connection_string`](#plugins-filters-jdbc_streaming-jdbc_connection_string) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_driver_class`](#plugins-filters-jdbc_streaming-jdbc_driver_class) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_driver_library`](#plugins-filters-jdbc_streaming-jdbc_driver_library) | a valid filesystem path | No |
| [`jdbc_password`](#plugins-filters-jdbc_streaming-jdbc_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`jdbc_user`](#plugins-filters-jdbc_streaming-jdbc_user) | [string](/reference/configuration-file-structure.md#string) | No |
| [`jdbc_validate_connection`](#plugins-filters-jdbc_streaming-jdbc_validate_connection) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`jdbc_validation_timeout`](#plugins-filters-jdbc_streaming-jdbc_validation_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`parameters`](#plugins-filters-jdbc_streaming-parameters) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`prepared_statement_bind_values`](#plugins-filters-jdbc_streaming-prepared_statement_bind_values) | [array](/reference/configuration-file-structure.md#array) | No |
| [`prepared_statement_name`](#plugins-filters-jdbc_streaming-prepared_statement_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`prepared_statement_warn_on_constant_usage`](#plugins-filters-jdbc_streaming-prepared_statement_warn_on_constant_usage) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`sequel_opts`](#plugins-filters-jdbc_streaming-sequel_opts) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`statement`](#plugins-filters-jdbc_streaming-statement) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`tag_on_default_use`](#plugins-filters-jdbc_streaming-tag_on_default_use) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tag_on_failure`](#plugins-filters-jdbc_streaming-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |
| [`target`](#plugins-filters-jdbc_streaming-target) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`use_cache`](#plugins-filters-jdbc_streaming-use_cache) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_prepared_statements`](#plugins-filters-jdbc_streaming-use_prepared_statements) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-filters-jdbc_streaming-common-options) for a list of options supported by all filter plugins.

 

### `cache_expiration` [plugins-filters-jdbc_streaming-cache_expiration]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5.0`

The minimum number of seconds any entry should remain in the cache. Defaults to 5 seconds.

A numeric value. You can use decimals for example: `cache_expiration => 0.25`. If there are transient jdbc errors, the cache will store empty results for a given parameter set and bypass the jbdc lookup. This will merge the default_hash into the event until the cache entry expires. Then the jdbc lookup will be tried again for the same parameters. Conversely, while the cache contains valid results, any external problem that would cause jdbc errors will not be noticed for the cache_expiration period.


### `cache_size` [plugins-filters-jdbc_streaming-cache_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `500`

The maximum number of cache entries that will be stored. Defaults to 500 entries. The least recently used entry will be evicted.


### `default_hash` [plugins-filters-jdbc_streaming-default_hash]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Define a default object to use when lookup fails to return a matching row. Ensure that the key names of this object match the columns from the statement.


### `jdbc_connection_string` [plugins-filters-jdbc_streaming-jdbc_connection_string]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC connection string


### `jdbc_driver_class` [plugins-filters-jdbc_streaming-jdbc_driver_class]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC driver class to load, for example "oracle.jdbc.OracleDriver" or "org.apache.derby.jdbc.ClientDriver"


### `jdbc_driver_library` [plugins-filters-jdbc_streaming-jdbc_driver_library]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

JDBC driver library path to third party driver library.


### `jdbc_password` [plugins-filters-jdbc_streaming-jdbc_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

JDBC password


### `jdbc_user` [plugins-filters-jdbc_streaming-jdbc_user]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC user


### `jdbc_validate_connection` [plugins-filters-jdbc_streaming-jdbc_validate_connection]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Connection pool configuration. Validate connection before use.


### `jdbc_validation_timeout` [plugins-filters-jdbc_streaming-jdbc_validation_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3600`

Connection pool configuration. How often to validate a connection (in seconds).


### `parameters` [plugins-filters-jdbc_streaming-parameters]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Hash of query parameter, for example `{ "id" => "id_field" }`.


### `prepared_statement_bind_values` [plugins-filters-jdbc_streaming-prepared_statement_bind_values]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Array of bind values for the prepared statement. Use field references and constants. See the section on [prepared_statements](#plugins-filters-jdbc_streaming-prepared_statements) for more info.


### `prepared_statement_name` [plugins-filters-jdbc_streaming-prepared_statement_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

Name given to the prepared statement. It must be unique in your config and in the database. You need to supply this if `use_prepared_statements` is true.


### `prepared_statement_warn_on_constant_usage` [plugins-filters-jdbc_streaming-prepared_statement_warn_on_constant_usage]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

A flag that controls whether a warning is logged if, in `prepared_statement_bind_values`, a String constant is detected that might be intended as a field reference.


### `sequel_opts` [plugins-filters-jdbc_streaming-sequel_opts]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

General/Vendor-specific Sequel configuration options

An example of an optional connection pool configuration max_connections - The maximum number of connections the connection pool

examples of vendor-specific options can be found in this documentation page: [https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc](https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc)


### `statement` [plugins-filters-jdbc_streaming-statement]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Statement to execute. To use parameters, use named parameter syntax, for example "SELECT * FROM MYTABLE WHERE ID = :id".


### `tag_on_default_use` [plugins-filters-jdbc_streaming-tag_on_default_use]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_jdbcstreamingdefaultsused"]`

Append values to the `tags` field if no record was found and default values were used.


### `tag_on_failure` [plugins-filters-jdbc_streaming-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_jdbcstreamingfailure"]`

Append values to the `tags` field if sql error occurred.


### `target` [plugins-filters-jdbc_streaming-target]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field to store the extracted result(s). Field is overwritten if exists.


### `use_cache` [plugins-filters-jdbc_streaming-use_cache]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Enable or disable caching, boolean true or false. Defaults to true.


### `use_prepared_statements` [plugins-filters-jdbc_streaming-use_prepared_statements]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When set to `true`, enables prepare statement usage



## Common options [plugins-filters-jdbc_streaming-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-jdbc_streaming-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-jdbc_streaming-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-jdbc_streaming-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-jdbc_streaming-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-jdbc_streaming-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-jdbc_streaming-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-jdbc_streaming-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-jdbc_streaming-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      jdbc_streaming {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      jdbc_streaming {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-jdbc_streaming-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      jdbc_streaming {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      jdbc_streaming {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-jdbc_streaming-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-jdbc_streaming-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 jdbc_streaming filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      jdbc_streaming {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-jdbc_streaming-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-jdbc_streaming-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      jdbc_streaming {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      jdbc_streaming {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-jdbc_streaming-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      jdbc_streaming {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      jdbc_streaming {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



