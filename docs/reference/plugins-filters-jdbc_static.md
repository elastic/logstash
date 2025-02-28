---
navigation_title: "jdbc_static"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-jdbc_static.html
---

# Jdbc_static filter plugin [plugins-filters-jdbc_static]


* A component of the [jdbc integration plugin](/reference/plugins-integrations-jdbc.md)
* Integration version: v5.5.2
* Released on: 2024-12-23
* [Changelog](https://github.com/logstash-plugins/logstash-integration-jdbc/blob/v5.5.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/filter-jdbc_static-index.md).

## Getting help [_getting_help_147]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-jdbc). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_146]

This filter enriches events with data pre-loaded from a remote database.

This filter is best suited for enriching events with reference data that is static or does not change very often, such as environments, users, and products.

This filter works by fetching data from a remote database, caching it in a local, in-memory [Apache Derby](https://db.apache.org/derby/manuals/#docs_10.14) database, and using lookups to enrich events with data cached in the local database. You can set up the filter to load the remote data once (for static data), or you can schedule remote loading to run periodically (for data that needs to be refreshed).

To define the filter, you specify three main sections: local_db_objects, loaders, and lookups.

**local_db_objects**
:   Define the columns, types, and indexes used to build the local database structure. The column names and types should match the external database. Define as many of these objects as needed to build the local database structure.

**loaders**
:   Query the external database to fetch the dataset that will be cached locally. Define as many loaders as needed to fetch the remote data. Each loader should fill a table defined by `local_db_objects`. Make sure the column names and datatypes in the loader SQL statement match the columns defined under `local_db_objects`. Each loader has an independent remote database connection.

**lookups**
:   Perform lookup queries on the local database to enrich the events. Define as many lookups as needed to enrich the event from all lookup tables in one pass. Ideally the SQL statement should only return one row. Any rows are converted to Hash objects and are stored in a target field that is an Array.

    The following example config fetches data from a remote database, caches it in a local database, and uses lookups to enrich events with data cached in the local database.

    ```json
    filter {
      jdbc_static {
        loaders => [ <1>
          {
            id => "remote-servers"
            query => "select ip, descr from ref.local_ips order by ip"
            local_table => "servers"
          },
          {
            id => "remote-users"
            query => "select firstname, lastname, userid from ref.local_users order by userid"
            local_table => "users"
          }
        ]
        local_db_objects => [ <2>
          {
            name => "servers"
            index_columns => ["ip"]
            columns => [
              ["ip", "varchar(15)"],
              ["descr", "varchar(255)"]
            ]
          },
          {
            name => "users"
            index_columns => ["userid"]
            columns => [
              ["firstname", "varchar(255)"],
              ["lastname", "varchar(255)"],
              ["userid", "int"]
            ]
          }
        ]
        local_lookups => [ <3>
          {
            id => "local-servers"
            query => "SELECT descr as description FROM servers WHERE ip = :ip"
            parameters => {ip => "[from_ip]"}
            target => "server"
          },
          {
            id => "local-users"
            query => "SELECT firstname, lastname FROM users WHERE userid = ? AND country = ?"
            prepared_parameters => ["[loggedin_userid]", "[user_nation]"] <4>
            target => "user" <5>
            default_hash => { <6>
              firstname => nil
              lastname => nil
            }
          }
        ]
        # using add_field here to add & rename values to the event root
        add_field => { server_name => "%{[server][0][description]}" } <7>
        add_field => { user_firstname => "%{[user][0][firstname]}" }
        add_field => { user_lastname => "%{[user][0][lastname]}" }
        remove_field => ["server", "user"]
        staging_directory => "/tmp/logstash/jdbc_static/import_data"
        loader_schedule => "* */2 * * *" <8>
        jdbc_user => "logstash"
        jdbc_password => "example"
        jdbc_driver_class => "org.postgresql.Driver"
        jdbc_driver_library => "/tmp/logstash/vendor/postgresql-42.1.4.jar"
        jdbc_connection_string => "jdbc:postgresql://remotedb:5432/ls_test_2"
      }
    }

    output {
      if "_jdbcstaticdefaultsused" in [tags] {
        # Print all the not found users
        stdout { }
      }
    }
    ```

    1. Queries an external database to fetch the dataset that will be cached locally.
    2. Defines the columns, types, and indexes used to build the local database structure. The column names and types should match the external database. The order of table definitions is significant and should match that of the loader queries. See [Loader column and local_db_object order dependency](#plugins-filters-jdbc_static-object_order).
    3. Performs lookup queries on the local database to enrich the events.
    4. Local lookup queries can also use prepared statements where the parameters follow the positional ordering.
    5. Specifies the event field that will store the looked-up data. If the lookup returns multiple columns, the data is stored as a JSON object within the field.
    6. When the user is not found in the database, an event is created using data from the [`local_lookups`](#plugins-filters-jdbc_static-local_lookups) `default hash` setting, and the event is tagged with the list set in [`tag_on_default_use`](#plugins-filters-jdbc_static-tag_on_default_use).
    7. Takes data from the JSON object and stores it in top-level event fields for easier analysis in Kibana.
    8. Runs loaders every 2 hours.


Here’s a full example:

```json
input {
  generator {
    lines => [
      '{"from_ip": "10.2.3.20", "app": "foobar", "amount": 32.95}',
      '{"from_ip": "10.2.3.30", "app": "barfoo", "amount": 82.95}',
      '{"from_ip": "10.2.3.40", "app": "bazfoo", "amount": 22.95}'
    ]
    count => 200
  }
}

filter {
  json {
    source => "message"
  }

  jdbc_static {
    loaders => [
      {
        id => "servers"
        query => "select ip, descr from ref.local_ips order by ip"
        local_table => "servers"
      }
    ]
    local_db_objects => [
      {
        name => "servers"
        index_columns => ["ip"]
        columns => [
          ["ip", "varchar(15)"],
          ["descr", "varchar(255)"]
        ]
      }
    ]
    local_lookups => [
      {
        query => "select descr as description from servers WHERE ip = :ip"
        parameters => {ip => "[from_ip]"}
        target => "server"
      }
    ]
    staging_directory => "/tmp/logstash/jdbc_static/import_data"
    loader_schedule => "*/30 * * * *"
    jdbc_user => "logstash"
    jdbc_password => "logstash??"
    jdbc_driver_class => "org.postgresql.Driver"
    jdbc_driver_library => "/Users/guy/tmp/logstash-6.0.0/vendor/postgresql-42.1.4.jar"
    jdbc_connection_string => "jdbc:postgresql://localhost:5432/ls_test_2"
  }
}

output {
  stdout {
    codec => rubydebug {metadata => true}
  }
}
```

Assuming the loader fetches the following data from a Postgres database:

```shell
select * from ref.local_ips order by ip;
    ip     |         descr
-----------+-----------------------
 10.2.3.10 | Authentication Server
 10.2.3.20 | Payments Server
 10.2.3.30 | Events Server
 10.2.3.40 | Payroll Server
 10.2.3.50 | Uploads Server
```

The events are enriched with a description of the server based on the value of the IP:

```shell
{
           "app" => "bazfoo",
      "sequence" => 0,
        "server" => [
        [0] {
            "description" => "Payroll Server"
        }
    ],
        "amount" => 22.95,
    "@timestamp" => 2017-11-30T18:08:15.694Z,
      "@version" => "1",
          "host" => "Elastics-MacBook-Pro.local",
       "message" => "{\"from_ip\": \"10.2.3.40\", \"app\": \"bazfoo\", \"amount\": 22.95}",
       "from_ip" => "10.2.3.40"
}
```


## Using this plugin with multiple pipelines [_using_this_plugin_with_multiple_pipelines]

::::{important}
Logstash uses a single, in-memory Apache Derby instance as the lookup database engine for the entire JVM. Because each plugin instance uses a unique database inside the shared Derby engine, there should be no conflicts with plugins attempting to create and populate the same tables. This is true regardless of whether the plugins are defined in a single pipeline, or multiple pipelines. However, after setting up the filter, you should watch the lookup results and view the logs to verify correct operation.

::::



## Loader column and local_db_object order dependency [plugins-filters-jdbc_static-object_order]

::::{important}
For loader performance reasons, the loading mechanism uses a CSV style file with an inbuilt Derby file import procedure to add the remote data to the local db. The retrieved columns are written to the CSV file as is and the file import procedure expects a 1 to 1 correspondence to the order of the columns specified in the local_db_object settings. Please ensure that this order is in place.

::::



## Compatibility with the Elastic Common Schema (ECS) [plugins-filters-jdbc_static-ecs]

This plugin is compatible with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). It behaves the same regardless of ECS compatibility, except giving a warning when ECS is enabled and `target` isn’t set.

::::{tip}
Set the `target` option to avoid potential schema conflicts.
::::



## Jdbc_static filter configuration options [plugins-filters-jdbc_static-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-jdbc_static-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`jdbc_connection_string`](#plugins-filters-jdbc_static-jdbc_connection_string) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_driver_class`](#plugins-filters-jdbc_static-jdbc_driver_class) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`jdbc_driver_library`](#plugins-filters-jdbc_static-jdbc_driver_library) | a valid filesystem path | No |
| [`jdbc_password`](#plugins-filters-jdbc_static-jdbc_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`jdbc_user`](#plugins-filters-jdbc_static-jdbc_user) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tag_on_failure`](#plugins-filters-jdbc_static-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tag_on_default_use`](#plugins-filters-jdbc_static-tag_on_default_use) | [array](/reference/configuration-file-structure.md#array) | No |
| [`staging_directory`](#plugins-filters-jdbc_static-staging_directory) | [string](/reference/configuration-file-structure.md#string) | No |
| [`loader_schedule`](#plugins-filters-jdbc_static-loader_schedule) | [string](/reference/configuration-file-structure.md#string) | No |
| [`loaders`](#plugins-filters-jdbc_static-loaders) | [array](/reference/configuration-file-structure.md#array) | No |
| [`local_db_objects`](#plugins-filters-jdbc_static-local_db_objects) | [array](/reference/configuration-file-structure.md#array) | No |
| [`local_lookups`](#plugins-filters-jdbc_static-local_lookups) | [array](/reference/configuration-file-structure.md#array) | No |

Also see [Common options](#plugins-filters-jdbc_static-common-options) for a list of options supported by all filter plugins.

 

### `jdbc_connection_string` [plugins-filters-jdbc_static-jdbc_connection_string]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC connection string.


### `jdbc_driver_class` [plugins-filters-jdbc_static-jdbc_driver_class]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC driver class to load, for example, "org.apache.derby.jdbc.ClientDriver".

::::{note}
According to [Issue 43](https://github.com/logstash-plugins/logstash-input-jdbc/issues/43), if you are using the Oracle JDBC driver (ojdbc6.jar), the correct `jdbc_driver_class` is `"Java::oracle.jdbc.driver.OracleDriver"`.
::::



### `jdbc_driver_library` [plugins-filters-jdbc_static-jdbc_driver_library]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC driver library path to third-party driver library. Use comma separated paths in one string if you need multiple libraries.

If the driver class is not provided, the plugin looks for it in the Logstash Java classpath.


### `jdbc_password` [plugins-filters-jdbc_static-jdbc_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

JDBC password.


### `jdbc_user` [plugins-filters-jdbc_static-jdbc_user]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JDBC user.


### `tag_on_default_use` [plugins-filters-jdbc_static-tag_on_default_use]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_jdbcstaticdefaultsused"]`

Append values to the `tags` field if no record was found and default values were used.


### `tag_on_failure` [plugins-filters-jdbc_static-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_jdbcstaticfailure"]`

Append values to the `tags` field if a SQL error occurred.


### `staging_directory` [plugins-filters-jdbc_static-staging_directory]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is derived from the Ruby temp directory + plugin_name + "import_data"
* e.g. `"/tmp/logstash/jdbc_static/import_data"`

The directory used stage the data for bulk loading, there should be sufficient disk space to handle the data you wish to use to enrich events. Previous versions of this plugin did not handle loading datasets of more than several thousand rows well due to an open bug in Apache Derby. This setting introduces an alternative way of loading large recordsets. As each row is received it is spooled to file and then that file is imported using a system *import table* system call.

Append values to the `tags` field if a SQL error occurred.


### `loader_schedule` [plugins-filters-jdbc_static-loader_schedule]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

You can schedule remote loading to run periodically according to a specific schedule. This scheduling syntax is powered by [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler). The syntax is cron-like with some extensions specific to Rufus (for example, timezone support). For more about this syntax, see [parsing cronlines and time strings](https://github.com/jmettraux/rufus-scheduler#parsing-cronlines-and-time-strings).

Examples:

|     |     |
| --- | --- |
| `*/30 * * * *` | will execute on the 0th and 30th minute of every hour every day. |
| `* 5 * 1-3 *` | will execute every minute of 5am every day of January through March. |
| `0 * * * *` | will execute on the 0th minute of every hour every day. |
| `0 6 * * * America/Chicago` | will execute at 6:00am (UTC/GMT -5) every day. |

Debugging using the Logstash interactive shell:

```shell
bin/logstash -i irb
irb(main):001:0> require 'rufus-scheduler'
=> true
irb(main):002:0> Rufus::Scheduler.parse('*/10 * * * *')
=> #<Rufus::Scheduler::CronLine:0x230f8709 @timezone=nil, @weekdays=nil, @days=nil, @seconds=[0], @minutes=[0, 10, 20, 30, 40, 50], @hours=nil, @months=nil, @monthdays=nil, @original="*/10 * * * *">
irb(main):003:0> exit
```

The object returned by the above call, an instance of `Rufus::Scheduler::CronLine` shows the seconds, minutes etc. of execution.


### `loaders` [plugins-filters-jdbc_static-loaders]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

The array should contain one or more Hashes. Each Hash is validated according to the table below.

| Setting | Input type | Required |
| --- | --- | --- |
| id | string | No |
| local_table | string | Yes |
| query | string | Yes |
| max_rows | number | No |
| jdbc_connection_string | string | No |
| jdbc_driver_class | string | No |
| jdbc_driver_library | a valid filesystem path | No |
| jdbc_password | password | No |
| jdbc_user | string | No |

**Loader Field Descriptions:**

id
:   An optional identifier. This is used to identify the loader that is generating error messages and log lines.

local_table
:   The destination table in the local lookup database that the loader will fill.

query
:   The SQL statement that is executed to fetch the remote records. Use SQL aliases and casts to ensure that the record’s columns and datatype match the table structure in the local database as defined in the `local_db_objects`.

max_rows
:   The default for this setting is 1 million. Because the lookup database is in-memory, it will take up JVM heap space. If the query returns many millions of rows, you should increase the JVM memory given to Logstash or limit the number of rows returned, perhaps to those most frequently found in the event data.

jdbc_connection_string
:   If not set in a loader, this setting defaults to the plugin-level `jdbc_connection_string` setting.

jdbc_driver_class
:   If not set in a loader, this setting defaults to the plugin-level `jdbc_driver_class` setting.

jdbc_driver_library
:   If not set in a loader, this setting defaults to the plugin-level `jdbc_driver_library` setting.

jdbc_password
:   If not set in a loader, this setting defaults to the plugin-level `jdbc_password` setting.

jdbc_user
:   If not set in a loader, this setting defaults to the plugin-level `jdbc_user` setting.


### `local_db_objects` [plugins-filters-jdbc_static-local_db_objects]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

The array should contain one or more Hashes. Each Hash represents a table schema for the local lookups database. Each Hash is validated according to the table below.

| Setting | Input type | Required |
| --- | --- | --- |
| name | string | Yes |
| columns | array | Yes |
| index_columns | number | No |
| preserve_existing | boolean | No |

**Local_db_objects Field Descriptions:**

name
:   The name of the table to be created in the database.

columns
:   An array of column specifications. Each column specification is an array of exactly two elements, for example `["ip", "varchar(15)"]`. The first element is the column name string. The second element is a string that is an [Apache Derby SQL type](https://db.apache.org/derby/docs/10.14/ref/crefsqlj31068.md). The string content is checked when the local lookup tables are built, not when the settings are validated. Therefore, any misspelled SQL type strings result in errors.

index_columns
:   An array of strings. Each string must be defined in the `columns` setting. The index name will be generated internally. Unique or sorted indexes are not supported.

preserve_existing
:   This setting, when `true`, checks whether the table already exists in the local lookup database. If you have multiple pipelines running in the same instance of Logstash, and more than one pipeline is using this plugin, then you must read the important multiple pipeline notice at the top of the page.


### `local_lookups` [plugins-filters-jdbc_static-local_lookups]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

The array should contain one or more Hashes. Each Hash represents a lookup enrichment. Each Hash is validated according to the table below.

| Setting | Input type | Required |
| --- | --- | --- |
| id | string | No |
| query | string | Yes |
| parameters | hash | Yes |
| target | string | No |
| default_hash | hash | No |
| tag_on_failure | string | No |
| tag_on_default_use | string | No |

**Local_lookups Field Descriptions:**

id
:   An optional identifier. This is used to identify the lookup that is generating error messages and log lines. If you omit this setting then a default id is used instead.

query
:   A SQL SELECT statement that is executed to achieve the lookup. To use parameters, use named parameter syntax, for example `"SELECT * FROM MYTABLE WHERE ID = :id"`. Alternatively, the `?` sign can be used as a prepared statement parameter, in which case the `prepared_parameters` array is used to populate the values

parameters
:   A key/value Hash or dictionary. The key (LHS) is the text that is substituted for in the SQL statement `SELECT * FROM sensors WHERE reference = :p1`. The value (RHS) is the field name in your event. The plugin reads the value from this key out of the event and substitutes that value into the statement, for example, `parameters => { "p1" => "ref" }`. Quoting is automatic - you do not need to put quotes in the statement. Only use the field interpolation syntax on the RHS if you need to add a prefix/suffix or join two event field values together to build the substitution value. For example, imagine an IOT message that has an id and a location, and you have a table of sensors that have a column of `id-loc_id`. In this case your parameter hash would look like this: `parameters => { "p1" => "%{[id]}-%{[loc_id]}" }`.

prepared_parameters
:   An Array, where the position is related to the position of the `?` in the query syntax. The values of array follow the same semantic of `parameters`. If `prepared_parameters` is valorized the filter is forced to use JDBC’s prepared statement to query the local database. Prepared statements provides two benefits: one on the performance side, because avoid the DBMS to parse and compile the SQL expression for every call; the other benefit is on the security side, using prepared statements avoid SQL-injection attacks based on query string concatenation.

target
:   An optional name for the field that will receive the looked-up data. If you omit this setting then the `id` setting (or the default id) is used. The looked-up data, an array of results converted to Hashes, is never added to the root of the event. If you want to do this, you should use the `add_field` setting. This means that you are in full control of how the fields/values are put in the root of the event, for example, `add_field => { user_firstname => "%{[user][0][firstname]}" }` - where `[user]` is the target field, `[0]` is the first result in the array, and `[firstname]` is the key in the result hash.

default_hash
:   An optional hash that will be put in the target field array when the lookup returns no results. Use this setting if you need to ensure that later references in other parts of the config actually refer to something.

tag_on_failure
:   An optional string that overrides the plugin-level setting. This is useful when defining multiple lookups.

tag_on_default_use
:   An optional string that overrides the plugin-level setting. This is useful when defining multiple lookups.



## Common options [plugins-filters-jdbc_static-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-jdbc_static-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-jdbc_static-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-jdbc_static-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-jdbc_static-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-jdbc_static-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-jdbc_static-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-jdbc_static-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-jdbc_static-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      jdbc_static {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      jdbc_static {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-jdbc_static-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      jdbc_static {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      jdbc_static {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-jdbc_static-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-jdbc_static-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 jdbc_static filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      jdbc_static {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-jdbc_static-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-jdbc_static-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      jdbc_static {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      jdbc_static {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-jdbc_static-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      jdbc_static {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      jdbc_static {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.



