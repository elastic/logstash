---
navigation_title: "jdbc"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-jdbc.html
---

# Jdbc input plugin [plugins-inputs-jdbc]


* A component of the [jdbc integration plugin](/reference/plugins-integrations-jdbc.md)
* Integration version: v5.5.2
* Released on: 2024-12-23
* [Changelog](https://github.com/logstash-plugins/logstash-integration-jdbc/blob/v5.5.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-jdbc-index.md).

## Getting help [_getting_help_32]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-jdbc). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_32]

This plugin was created as a way to ingest data in any database with a JDBC interface into Logstash. You can periodically schedule ingestion using a cron syntax (see `schedule` setting) or run the query one time to load data into Logstash. Each row in the resultset becomes a single event. Columns in the resultset are converted into fields in the event.


## Drivers [_drivers]

This plugin does not come packaged with JDBC driver libraries. The desired jdbc driver library must be explicitly passed in to the plugin using the `jdbc_driver_library` configuration option.

See the [`jdbc_driver_library`](#plugins-inputs-jdbc-jdbc_driver_library) and [`jdbc_driver_class`](#plugins-inputs-jdbc-jdbc_driver_class) options for more info.


## Scheduling [_scheduling_2]

Input from this plugin can be scheduled to run periodically according to a specific schedule. This scheduling syntax is powered by [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler). The syntax is cron-like with some extensions specific to Rufus (e.g. timezone support ).

Examples:

|     |     |
| --- | --- |
| `* 5 * 1-3 *` | will execute every minute of 5am every day of January through March. |
| `0 * * * *` | will execute on the 0th minute of every hour every day. |
| `0 6 * * * America/Chicago` | will execute at 6:00am (UTC/GMT -5) every day. |

Further documentation describing this syntax can be found [here](https://github.com/jmettraux/rufus-scheduler#parsing-cronlines-and-time-strings).


## State [_state]

The plugin will persist the `sql_last_value` parameter in the form of a metadata file stored in the configured `last_run_metadata_path`. Upon query execution, this file will be updated with the current value of `sql_last_value`. Next time the pipeline starts up, this value will be updated by reading from the file. If `clean_run` is set to true, this value will be ignored and `sql_last_value` will be set to Jan 1, 1970, or 0 if `use_column_value` is true, as if no query has ever been executed.


## Dealing With Large Result-sets [_dealing_with_large_result_sets]

Many JDBC drivers use the `fetch_size` parameter to limit how many results are pre-fetched at a time from the cursor into the client’s cache before retrieving more results from the result-set. This is configured in this plugin using the `jdbc_fetch_size` configuration option. No fetch size is set by default in this plugin, so the specific driver’s default size will be used.


## Usage: [_usage]

Here is an example of setting up the plugin to fetch data from a MySQL database. First, we place the appropriate JDBC driver library in our current path (this can be placed anywhere on your filesystem). In this example, we connect to the *mydb* database using the user: *mysql* and wish to input all rows in the *songs* table that match a specific artist. The following examples demonstrates a possible Logstash configuration for this. The `schedule` option in this example will instruct the plugin to execute this input statement on the minute, every minute.

```ruby
input {
  jdbc {
    jdbc_driver_library => "mysql-connector-java-5.1.36-bin.jar"
    jdbc_driver_class => "com.mysql.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://localhost:3306/mydb"
    jdbc_user => "mysql"
    parameters => { "favorite_artist" => "Beethoven" }
    schedule => "* * * * *"
    statement => "SELECT * from songs where artist = :favorite_artist"
  }
}
```


## Configuring SQL statement [_configuring_sql_statement]

A sql statement is required for this input. This can be passed-in via a statement option in the form of a string, or read from a file (`statement_filepath`). File option is typically used when the SQL statement is large or cumbersome to supply in the config. The file option only supports one SQL statement. The plugin will only accept one of the options. It cannot read a statement from a file as well as from the `statement` configuration parameter.


## Configuring multiple SQL statements [_configuring_multiple_sql_statements]

Configuring multiple SQL statements is useful when there is a need to query and ingest data from different database tables or views. It is possible to define separate Logstash configuration files for each statement or to define multiple statements in a single configuration file. When using multiple statements in a single Logstash configuration file, each statement has to be defined as a separate jdbc input (including jdbc driver, connection string and other required parameters).

Please note that if any of the statements use the `sql_last_value` parameter (e.g. for ingesting only data changed since last run), each input should define its own `last_run_metadata_path` parameter. Failure to do so will result in undesired behaviour, as all inputs will store their state to the same (default) metadata file, effectively overwriting each other’s `sql_last_value`.


## Predefined Parameters [_predefined_parameters]

Some parameters are built-in and can be used from within your queries. Here is the list:

|     |     |
| --- | --- |
| sql_last_value | The value used to calculate which rows to query. Before any query is run,this is set to Thursday, 1 January 1970, or 0 if `use_column_value` is true and`tracking_column` is set. It is updated accordingly after subsequent queries are run. |
| offset, size | Values used with manual paging mode to explicitly implement the paging.Supported only if [`jdbc_paging_enabled`](#plugins-inputs-jdbc-jdbc_paging_enabled) is enabled and[`jdbc_paging_mode`](#plugins-inputs-jdbc-jdbc_paging_mode) has the `explicit` value. |

Example:

```ruby
input {
  jdbc {
    statement => "SELECT id, mycolumn1, mycolumn2 FROM my_table WHERE id > :sql_last_value"
    use_column_value => true
    tracking_column => "id"
    # ... other configuration bits
  }
}
```


## Prepared Statements [_prepared_statements]

Using server side prepared statements can speed up execution times as the server optimises the query plan and execution.

::::{note}
Not all JDBC accessible technologies will support prepared statements.
::::


With the introduction of Prepared Statement support comes a different code execution path and some new settings. Most of the existing settings are still useful but there are several new settings for Prepared Statements to read up on. Use the boolean setting `use_prepared_statements` to enable this execution mode. Use the `prepared_statement_name` setting to specify a name for the Prepared Statement, this identifies the prepared statement locally and remotely and it should be unique in your config and on the database. Use the `prepared_statement_bind_values` array setting to specify the bind values, use the exact string `:sql_last_value` (multiple times if necessary) for the predefined parameter mentioned before. The `statement` (or `statement_path`) setting still holds the SQL statement but to use bind variables you must use the `?` character as a placeholder in the exact order found in the `prepared_statement_bind_values` array.

::::{note}
Building count queries around a prepared statement is not supported at this time. Because jdbc paging uses count queries when `jdbc_paging_mode` has value `auto`，jdbc paging is not supported with prepared statements at this time either. Therefore, `jdbc_paging_enabled`, `jdbc_page_size` settings are ignored when using prepared statements.
::::


Example:

```ruby
input {
  jdbc {
    statement => "SELECT * FROM mgd.seq_sequence WHERE _sequence_key > ? AND _sequence_key < ? + ? ORDER BY _sequence_key ASC"
    prepared_statement_bind_values => [":sql_last_value", ":sql_last_value", 4]
    prepared_statement_name => "foobar"
    use_prepared_statements => true
    use_column_value => true
    tracking_column_type => "numeric"
    tracking_column => "_sequence_key"
    last_run_metadata_path => "/elastic/tmp/testing/confs/test-jdbc-int-sql_last_value.yml"
    # ... other configuration bits
  }
}
```


## Database-specific considerations [_database_specific_considerations]

The JDBC input plugin leverages the [sequel](https://github.com/jeremyevans/sequel) library to query databases through their JDBC drivers. The implementation of drivers will vary, however, potentially leading to unexpected behavior.

### Unable to reuse connections [_unable_to_reuse_connections]

Some databases - such as Sybase or SQL Anywhere - may have issues with stale connections, timing out between scheduled runs and never reconnecting.

To ensure connections are valid before queries are executed, enable [`jdbc_validate_connection`](#plugins-inputs-jdbc-jdbc_validate_connection) and set [`jdbc_validation_timeout`](#plugins-inputs-jdbc-jdbc_validation_timeout) to a shorter interval than the [`schedule`](#plugins-inputs-jdbc-schedule).

```ruby
input {
  jdbc {
    schedule => "* * * * *"       # run every minute
    jdbc_validate_connection => true
    jdbc_validation_timeout => 50 # 50 seconds
  }
}
```



## Jdbc Input Configuration Options [plugins-inputs-jdbc-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-jdbc-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`clean_run`](#plugins-inputs-jdbc-clean_run) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`columns_charset`](#plugins-inputs-jdbc-columns_charset) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`connection_retry_attempts`](#plugins-inputs-jdbc-connection_retry_attempts) | [number](/reference/configuration-file-structure.md#number) | No |
| [`connection_retry_attempts_wait_time`](#plugins-inputs-jdbc-connection_retry_attempts_wait_time) | [number](/reference/configuration-file-structure.md#number) | No |
| [`jdbc_connection_string`](#plugins-inputs-jdbc-jdbc_connection_string) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_default_timezone`](#plugins-inputs-jdbc-jdbc_default_timezone) | [string](/reference/configuration-file-structure.md#string) | No |
| [`jdbc_driver_class`](#plugins-inputs-jdbc-jdbc_driver_class) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_driver_library`](#plugins-inputs-jdbc-jdbc_driver_library) | [string](/reference/configuration-file-structure.md#string) | No |
| [`jdbc_fetch_size`](#plugins-inputs-jdbc-jdbc_fetch_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`jdbc_page_size`](#plugins-inputs-jdbc-jdbc_page_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`jdbc_paging_enabled`](#plugins-inputs-jdbc-jdbc_paging_enabled) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`jdbc_paging_mode`](#plugins-inputs-jdbc-jdbc_paging_mode) | [string](/reference/configuration-file-structure.md#string), one of `["auto", "explicit"]` | No |
| [`jdbc_password`](#plugins-inputs-jdbc-jdbc_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`jdbc_password_filepath`](#plugins-inputs-jdbc-jdbc_password_filepath) | a valid filesystem path | No |
| [`jdbc_pool_timeout`](#plugins-inputs-jdbc-jdbc_pool_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`jdbc_user`](#plugins-inputs-jdbc-jdbc_user) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_validate_connection`](#plugins-inputs-jdbc-jdbc_validate_connection) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`jdbc_validation_timeout`](#plugins-inputs-jdbc-jdbc_validation_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`last_run_metadata_path`](#plugins-inputs-jdbc-last_run_metadata_path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`lowercase_column_names`](#plugins-inputs-jdbc-lowercase_column_names) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`parameters`](#plugins-inputs-jdbc-parameters) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`plugin_timezone`](#plugins-inputs-jdbc-plugin_timezone) | [string](/reference/configuration-file-structure.md#string), one of `["local", "utc"]` | No |
| [`prepared_statement_bind_values`](#plugins-inputs-jdbc-prepared_statement_bind_values) | [array](/reference/configuration-file-structure.md#array) | No |
| [`prepared_statement_name`](#plugins-inputs-jdbc-prepared_statement_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`record_last_run`](#plugins-inputs-jdbc-record_last_run) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`schedule`](#plugins-inputs-jdbc-schedule) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sequel_opts`](#plugins-inputs-jdbc-sequel_opts) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`sql_log_level`](#plugins-inputs-jdbc-sql_log_level) | [string](/reference/configuration-file-structure.md#string), one of `["fatal", "error", "warn", "info", "debug"]` | No |
| [`statement`](#plugins-inputs-jdbc-statement) | [string](/reference/configuration-file-structure.md#string) | No |
| [`statement_filepath`](#plugins-inputs-jdbc-statement_filepath) | a valid filesystem path | No |
| [`statement_retry_attempts`](#plugins-inputs-jdbc-statement_retry_attempts) | [number](/reference/configuration-file-structure.md#number) | No |
| [`statement_retry_attempts_wait_time`](#plugins-inputs-jdbc-statement_retry_attempts_wait_time) | [number](/reference/configuration-file-structure.md#number) | No |
| [`target`](#plugins-inputs-jdbc-target) | [field reference](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html) | No |
| [`tracking_column`](#plugins-inputs-jdbc-tracking_column) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tracking_column_type`](#plugins-inputs-jdbc-tracking_column_type) | [string](/reference/configuration-file-structure.md#string), one of `["numeric", "timestamp"]` | No |
| [`use_column_value`](#plugins-inputs-jdbc-use_column_value) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_prepared_statements`](#plugins-inputs-jdbc-use_prepared_statements) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

Also see [Common options](#plugins-inputs-jdbc-common-options) for a list of options supported by all input plugins.

 

### `clean_run` [plugins-inputs-jdbc-clean_run]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Whether the previous run state should be preserved


### `columns_charset` [plugins-inputs-jdbc-columns_charset]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

The character encoding for specific columns. This option will override the `:charset` option for the specified columns.

Example:

```ruby
input {
  jdbc {
    ...
    columns_charset => { "column0" => "ISO-8859-1" }
    ...
  }
}
```

this will only convert column0 that has ISO-8859-1 as an original encoding.


### `connection_retry_attempts` [plugins-inputs-jdbc-connection_retry_attempts]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Maximum number of times to try connecting to database


### `connection_retry_attempts_wait_time` [plugins-inputs-jdbc-connection_retry_attempts_wait_time]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0.5`

Number of seconds to sleep between connection attempts


### `jdbc_connection_string` [plugins-inputs-jdbc-jdbc_connection_string]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC connection string


### `jdbc_default_timezone` [plugins-inputs-jdbc-jdbc_default_timezone]

* Value type is [string](/reference/configuration-file-structure.md#string)

    * Value should be a canonical timezone or offset, such as `Europe/Paris` or `Etc/GMT+3`
    * Value *may* include square-bracketed extensions, such as `America/Denver[dst_enabled_on_overlap:true]`

* There is no default value for this setting.

#### Timezone conversion [plugins-inputs-jdbc-jdbc_timezone_conv]

Logstash and Elasticsearch expect timestamps to be expressed in UTC terms. If your database has recorded timestamps that are relative to another timezone, the database timezone if you will, then set this setting to be the timezone that the database is using. However, as SQL does not allow for timezone data in timestamp fields we can’t figure this out on a record by record basis.  This plugin will automatically convert your SQL timestamp fields to Logstash timestamps, in relative UTC time in ISO8601 format.

Using this setting will manually assign a specified timezone offset, instead of using the timezone setting of the local machine.  You must use a canonical timezone, `America/Denver`, for example.



### Ambiguous timestamps [plugins-inputs-jdbc-jdbc_ambiguous_timestamps]

While it is common to store local times in SQL’s timestamp column type, many timezones change their offset during the course of a calendar year and therefore cannot be used with SQL’s timestamp type to represent an ordered, continuous timeline. For example in the `America/Chicago` zone when daylight saving time (DST) ends in the autumn, the clock rolls from `01:59:59` back to `01:00:00`, making any timestamp in the 2-hour period between `01:00:00CDT` and `02:00:00CST` on that day ambiguous.

When encountering an ambiguous timestamp caused by a DST transition, the query will fail unless the timezone specified here includes a square-bracketed instruction for how to handle overlapping periods (such as: `America/Chicago[dst_enabled_on_overlap:true]` or `Australia/Melbourne[dst_enabled_on_overlap:false]`).


### `plugin_timezone` [plugins-inputs-jdbc-plugin_timezone]

* Value can be any of: `utc`, `local`
* Default value is `"utc"`

If you want this plugin to offset timestamps to a timezone other than UTC, you can set this setting to `local` and the plugin will use the OS timezone for offset adjustments.

Note: when specifying `plugin_timezone` and/or `jdbc_default_timezone`, offset adjustments are made in two places, if `sql_last_value` is a timestamp and it is used as a parameter in the statement then offset adjustment is done from the plugin timezone into the data timezone and while records are processed, timestamps are offset adjusted from the database timezone to the plugin timezone. If your database timezone is UTC then you do not need to set either of these settings.


### `jdbc_driver_class` [plugins-inputs-jdbc-jdbc_driver_class]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC driver class to load, for example, "org.apache.derby.jdbc.ClientDriver"

::::{note}
Per [https://github.com/logstash-plugins/logstash-input-jdbc/issues/43](https://github.com/logstash-plugins/logstash-input-jdbc/issues/43), prepending `Java::` to the driver class may be required if it appears that the driver is not being loaded correctly despite relevant jar(s) being provided by either via the `jdbc_driver_library` setting or being placed in the Logstash  Java classpath. This is known to be the case for the Oracle JDBC driver (ojdbc6.jar), where the correct `jdbc_driver_class` is `"Java::oracle.jdbc.driver.OracleDriver"`, and may also be the case for other JDBC drivers.
::::



### `jdbc_driver_library` [plugins-inputs-jdbc-jdbc_driver_library]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC driver library path to third party driver library. In case of multiple libraries being required you can pass them separated by a comma.

::::{note}
If not provided, Plugin will look for the driver class in the Logstash Java classpath. Additionally, if the library does not appear to be being loaded correctly via this setting, placing the relevant jar(s) in the Logstash Java classpath rather than via this setting may help. Please also make sure the path is readable by the Logstash process (e.g. `logstash` user when running as a service).
::::



### `jdbc_fetch_size` [plugins-inputs-jdbc-jdbc_fetch_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

JDBC fetch size. if not provided, respective driver’s default will be used


### `jdbc_page_size` [plugins-inputs-jdbc-jdbc_page_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `100000`

JDBC page size


### `jdbc_paging_enabled` [plugins-inputs-jdbc-jdbc_paging_enabled]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

JDBC enable paging

This will cause a sql statement to be broken up into multiple queries. Each query will use limits and offsets to collectively retrieve the full result-set. The limit size is set with `jdbc_page_size`.

Be aware that ordering is not guaranteed between queries.


### `jdbc_paging_mode` [plugins-inputs-jdbc-jdbc_paging_mode]

* Value can be any of: `auto`, `explicit`
* Default value is `"auto"`

Whether to use `explicit` or `auto` mode during the JDBC paging

If `auto`, your statement will be automatically surrounded by a count query and subsequent multiple paged queries (with `LIMIT` statement, etc.).

If `explicit`, multiple queries (without a count query ahead) will be performed with your statement, until no more rows are retrieved. You have to write your own paging conditions in your statement configuration. The `offset` and `size` parameters can be used in your statement (`size` equal to `jdbc_page_size`, and `offset` incremented by `size` for each query). When the number of rows returned by the query is not equal to `size`, SQL paging will be ended. Example:

```ruby
input {
  jdbc {
    statement => "SELECT id, mycolumn1, mycolumn2 FROM my_table WHERE id > :sql_last_value LIMIT :size OFFSET :offset",
    jdbc_paging_enabled => true,
    jdbc_paging_mode => "explicit",
    jdbc_page_size => 100000
  }
}
```

```ruby
input {
  jdbc {
    statement => "CALL fetch_my_data(:sql_last_value, :offset, :size)",
    jdbc_paging_enabled => true,
    jdbc_paging_mode => "explicit",
    jdbc_page_size => 100000
  }
}
```

This mode can be considered in the following situations:

1. Performance issues encountered in default paging mode.
2. Your SQL statement is complex, so simply surrounding it with paging statements is not what you want.
3. Your statement is a stored procedure, and the actual paging statement is inside it.


### `jdbc_password` [plugins-inputs-jdbc-jdbc_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

JDBC password


### `jdbc_password_filepath` [plugins-inputs-jdbc-jdbc_password_filepath]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

JDBC password filename


### `jdbc_pool_timeout` [plugins-inputs-jdbc-jdbc_pool_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `5`

Connection pool configuration. The amount of seconds to wait to acquire a connection before raising a PoolTimeoutError (default 5)


### `jdbc_user` [plugins-inputs-jdbc-jdbc_user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC user


### `jdbc_validate_connection` [plugins-inputs-jdbc-jdbc_validate_connection]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Connection pool configuration. Validate connection before use.


### `jdbc_validation_timeout` [plugins-inputs-jdbc-jdbc_validation_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3600`

Connection pool configuration. How often to validate a connection (in seconds)


### `last_run_metadata_path` [plugins-inputs-jdbc-last_run_metadata_path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"<path.data>/plugins/inputs/jdbc/logstash_jdbc_last_run"`

Path to file with last run time

In versions prior to 5.2.6 the metadata file was written to `$HOME/.logstash_jdbc_last_run`. If during a Logstash upgrade the file is found in "$HOME" it will be moved to the default location under "path.data". If the path is defined by the user then no automatic move is performed.


### `lowercase_column_names` [plugins-inputs-jdbc-lowercase_column_names]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether to force the lowercasing of identifier fields


### `parameters` [plugins-inputs-jdbc-parameters]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Hash of query parameter, for example `{ "target_id" => "321" }`


### `prepared_statement_bind_values` [plugins-inputs-jdbc-prepared_statement_bind_values]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Array of bind values for the prepared statement. `:sql_last_value` is a reserved predefined string


### `prepared_statement_name` [plugins-inputs-jdbc-prepared_statement_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `""`

Name given to the prepared statement. It must be unique in your config and in the database


### `record_last_run` [plugins-inputs-jdbc-record_last_run]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Whether to save state or not in [`last_run_metadata_path`](#plugins-inputs-jdbc-last_run_metadata_path)


### `schedule` [plugins-inputs-jdbc-schedule]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Schedule of when to periodically run statement, in Cron format for example: "* * * * *" (execute query every minute, on the minute)

There is no schedule by default. If no schedule is given, then the statement is run exactly once.


### `sequel_opts` [plugins-inputs-jdbc-sequel_opts]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

General/Vendor-specific Sequel configuration options.

An example of an optional connection pool configuration max_connections - The maximum number of connections the connection pool

examples of vendor-specific options can be found in this documentation page: [https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc](https://github.com/jeremyevans/sequel/blob/master/doc/opening_databases.rdoc)


### `sql_log_level` [plugins-inputs-jdbc-sql_log_level]

* Value can be any of: `fatal`, `error`, `warn`, `info`, `debug`
* Default value is `"info"`

Log level at which to log SQL queries, the accepted values are the common ones fatal, error, warn, info and debug. The default value is info.


### `statement` [plugins-inputs-jdbc-statement]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

If undefined, Logstash will complain, even if codec is unused. Statement to execute

To use parameters, use named parameter syntax. For example:

```ruby
"SELECT * FROM MYTABLE WHERE id = :target_id"
```

here, ":target_id" is a named parameter. You can configure named parameters with the `parameters` setting.


### `statement_filepath` [plugins-inputs-jdbc-statement_filepath]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

Path of file containing statement to execute


### `statement_retry_attempts` [plugins-inputs-jdbc-statement_retry_attempts]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

Maximum number of times to try executing a statement.


### `statement_retry_attempts_wait_time` [plugins-inputs-jdbc-statement_retry_attempts_wait_time]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0.5`

Number of seconds to sleep between statement execution attempts.


### `target` [plugins-inputs-jdbc-target]

* Value type is [field reference](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html)
* There is no default value for this setting.

Without a `target`, events are created from each row column at the root level. When the `target` is set to a field reference, the column of each row is placed in the target field instead.

This option can be useful to avoid populating unknown fields when a downstream schema such as ECS is enforced.


### `tracking_column` [plugins-inputs-jdbc-tracking_column]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The column whose value is to be tracked if `use_column_value` is set to `true`


### `tracking_column_type` [plugins-inputs-jdbc-tracking_column_type]

* Value can be any of: `numeric`, `timestamp`
* Default value is `"numeric"`

Type of tracking column. Currently only "numeric" and "timestamp"


### `use_column_value` [plugins-inputs-jdbc-use_column_value]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When set to `true`, uses the defined [`tracking_column`](#plugins-inputs-jdbc-tracking_column) value as the `:sql_last_value`. When set to `false`, `:sql_last_value` reflects the last time the query was executed.


### `use_prepared_statements` [plugins-inputs-jdbc-use_prepared_statements]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When set to `true`, enables prepare statement usage



## Common options [plugins-inputs-jdbc-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-jdbc-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-jdbc-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-jdbc-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-jdbc-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-jdbc-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-jdbc-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-jdbc-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-jdbc-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-jdbc-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-jdbc-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 jdbc inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  jdbc {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-jdbc-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-jdbc-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



