---
navigation_title: "snmp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-snmp.html
---

# SNMP input plugin [plugins-inputs-snmp]


* A component of the [snmp integration plugin](/reference/plugins-integrations-snmp.md)
* Integration version: v4.0.5
* Released on: 2025-01-06
* [Changelog](https://github.com/logstash-plugins/logstash-integration-snmp/blob/v4.0.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-snmp-index.md).

## Getting help [_getting_help_50]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-snmp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).

::::{admonition} Migrating to `logstash-integration-snmp` from stand-alone `input-snmp`
The `logstash-input-snmp` plugin is now a component of the `logstash-integration-snmp` plugin which is bundled with {{ls}} 8.15.0 by default. This integrated plugin package provides better alignment in snmp processing, better resource management, easier package maintenance, and a smaller installation footprint.

Before you upgrade to {{ls}} 8.15.0, be aware of [behavioral and mapping differences](/reference/plugins-integrations-snmp.md#plugins-integrations-snmp-migration) between current stand-alone plugins and the new versions included in `integration-snmp`.

::::



## Description [_description_50]

The SNMP input polls network devices using Simple Network Management Protocol (SNMP) to gather information related to the current state of the devices operation.

The SNMP input plugin supports SNMP v1, v2c, and v3 over UDP and TCP transport protocols.


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-snmp-ecs]

Because SNMP data has specific field names based on OIDs, we recommend setting a [`target`](#plugins-inputs-snmp-target). Metadata fields follow a specific naming convention when [ECS compatibility mode](#plugins-inputs-snmp-ecs_compatibility) is enabled.

|     |     |     |     |
| --- | --- | --- | --- |
| ECS disabled | ECS v1, v8 | *Description* | *[@metadata][host_protocol]* |
| [@metadata][input][snmp][host][protocol] | The protocol used to retrieve data e.g. "udp" | *[@metadata][host_address]* | *[@metadata][input][snmp][host][address]* |
| The host IP e.g. "192.168.1.1" | [@metadata][host_port] | *[@metadata][input][snmp][host][port]* | *The host’s port e.g. "161"* |
| [@metadata][host_community] | [@metadata][input][snmp][host][community] | *The configured community e.g. "public"* | *[host]* |


## Importing MIBs [plugins-inputs-snmp-import-mibs]

This plugin already includes the IETF MIBs (management information bases), and you do not need to import them. If you need additional MIBs, you need to import them. Check out [Importing MIBs](/reference/plugins-integrations-snmp.md#plugins-integrations-snmp-import-mibs) for info.


## SNMP Input Configuration Options [plugins-inputs-snmp-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-snmp-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`ecs_compatibility`](#plugins-inputs-snmp-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`get`](#plugins-inputs-snmp-get) | [array](/reference/configuration-file-structure.md#array) | No |
| [`hosts`](#plugins-inputs-snmp-hosts) | [array](/reference/configuration-file-structure.md#array) | No |
| [`interval`](#plugins-inputs-snmp-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`local_engine_id`](#plugins-inputs-snmp-local_engine_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`mib_paths`](#plugins-inputs-snmp-mib_paths) | [path](/reference/configuration-file-structure.md#path) | No |
| [`oid_mapping_format`](#plugins-inputs-snmp-oid_mapping_format) | [string](/reference/configuration-file-structure.md#string), one of `["default", "ruby_snmp", "dotted_string"]` | No |
| [`oid_map_field_values`](#plugins-inputs-snmp-oid_map_field_values) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`oid_path_length`](#plugins-inputs-snmp-oid_path_length) | [number](/reference/configuration-file-structure.md#number) | No |
| [`oid_root_skip`](#plugins-inputs-snmp-oid_root_skip) | [number](/reference/configuration-file-structure.md#number) | No |
| [`poll_hosts_timeout`](#plugins-inputs-snmp-poll_hosts_timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`walk`](#plugins-inputs-snmp-walk) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tables`](#plugins-inputs-snmp-tables) | [array](/reference/configuration-file-structure.md#array) | No |
| [`target`](#plugins-inputs-snmp-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-snmp-threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_provided_mibs`](#plugins-inputs-snmp-use_provided_mibs) | [boolean](/reference/configuration-file-structure.md#boolean) | No |


## SNMPv3 Authentication Options [_snmpv3_authentication_options]

This plugin supports the following SNMPv3 authentication options.

| Setting | Input type | Required |
| --- | --- | --- |
| [`auth_pass`](#plugins-inputs-snmp-auth_pass) | [password](/reference/configuration-file-structure.md#password) | No |
| [`auth_protocol`](#plugins-inputs-snmp-auth_protocol) | [string](/reference/configuration-file-structure.md#string), one of `["md5", "sha", "sha2", "hmac128sha224", "hmac192sha256", "hmac256sha384", "hmac384sha512"]` | No |
| [`priv_pass`](#plugins-inputs-snmp-priv_pass) | [password](/reference/configuration-file-structure.md#password) | No |
| [`priv_protocol`](#plugins-inputs-snmp-priv_protocol) | [string](/reference/configuration-file-structure.md#string), one of `["des", "3des", "aes", "aes128", "aes192", "aes256"]` | No |
| [`security_level`](#plugins-inputs-snmp-security_level) | [string](/reference/configuration-file-structure.md#string), one of `["noAuthNoPriv", "authNoPriv", "authPriv"]` | No |
| [`security_name`](#plugins-inputs-snmp-security_name) | [string](/reference/configuration-file-structure.md#string) | No |


## SNMP Input Configuration Options [_snmp_input_configuration_options]

Also see [Common options](#plugins-inputs-snmp-common-options) for a list of options supported by all input plugins.

### `ecs_compatibility` [plugins-inputs-snmp-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (fields might be set at the root of the event)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, the `host` field)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).


### `get` [plugins-inputs-snmp-get]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting

Use the `get` option to query for scalar values for the given OID(s). One or more OID(s) are specified as an array of strings of OID(s).

Example

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0", "1.3.6.1.2.1.1.5.0"]
    hosts => [{host => "udp:127.0.0.1/161" community => "public"}]
  }
}
```


### `hosts` [plugins-inputs-snmp-hosts]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting

The `hosts` option specifies the list of hosts to query the configured `get` and `walk` options.

Each host definition is a hash and must define the `host` key and value. `host` must use the format `{tcp|udp}:{ip address}/{{port}}`, for example `host => "udp:127.0.0.1/161"`

Each host definition can optionally include the following keys and values:

* `community` the community string, default is `public`.
* `version` `1`, `2c` or `3`, default is `2c`.
* `retries` is the number of retries in case of failure, default is `2`.
* `timeout` is the timeout in milliseconds with a default value of `1000`.

**Specifying all hosts options**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    hosts => [{host => "udp:127.0.0.1/161" community => "public" version => "2c"  retries => 2  timeout => 1000}]
  }
}
```

**Specifying multiple hosts**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    hosts => [{host => "udp:127.0.0.1/161" community => "public"}, {host => "udp:192.168.0.1/161" community => "private"}]
  }
}
```

**Specifying IPv6 hosts**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    hosts => [{host => "udp:[::1]/161" community => "public"}, {host => "udp:[2001:db8::2:1]/161" community => "private"}]
  }
}
```


### `interval` [plugins-inputs-snmp-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `30`

The `interval` option specifies the polling interval in seconds. If polling all configured hosts takes longer than this interval, a warning will be emitted to the logs.


### `local_engine_id` [plugins-inputs-snmp-local_engine_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The SNMPv3 local engine ID. Its length must be greater or equal than 5 and less or equal than 32. If not provided, a default ID is generated based on the local IP address and additional four random bytes.


### `mib_paths` [plugins-inputs-snmp-mib_paths]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting

The `mib_paths` option specifies the location of one or more imported MIB files. The value can be either a dir path containing the imported MIB (`.dic`, `.yaml`) files, or a file path to a single MIB file.

This plugin includes the IETF MIBs. If you require other MIBs, you need to import them. See [Importing MIBs](#plugins-inputs-snmp-import-mibs).


### `oid_mapping_format` [plugins-inputs-snmp-oid_mapping_format]

* Value can be any of: `default`, `ruby_snmp`, `dotted_string`
* Default value is `"default"`

Defines the mapping textual representation of an OID in the Logstash event:

* `default` translates every identifier, using the MIBs resolved names, separated by dots. Example: `1.3.6.1.2.1.1.2.0` is mapped as `iso.org.dod.internet.mgmt.mib-2.system.sysObjectID.0`
* `ruby_snmp` produces field names prefixed by the MIBs module name, followed by the latest resolved identifier name and unknowns values. Example: `1.3.6.1.2.1.1.2.0` is mapped as `SNMPv2-MIB::sysObjectID.0`.
* `dotted_string` maps fields using the standard dotted string representation, Example: `1.3.6.1.2.1.1.2.0` is mapped as  `1.3.6.1.2.1.1.2.0`


### `oid_map_field_values` [plugins-inputs-snmp-oid_map_field_values]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Defines if the Logstash event fields values, which types are `OID`, are mapped using the configured OID textual representation set on the [`oid_mapping_format`](#plugins-inputs-snmp-oid_mapping_format) option.


### `oid_root_skip` [plugins-inputs-snmp-oid_root_skip]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The `oid_root_skip` option specifies the number of OID root digits to ignore in the event field name. For example, in a numeric OID like "1.3.6.1.2.1.1.1.0" the first 5 digits could be ignored by setting `oid_root_skip => 5` which would result in a field name "1.1.1.0". Similarly when a MIB is used an OID such "1.3.6.1.2.mib-2.system.sysDescr.0" would become "mib-2.system.sysDescr.0"

* You can use this setting or [`oid_path_length`](#plugins-inputs-snmp-oid_path_length), but not both at the same time.
* Use this setting only if [`oid_mapping_format`](#plugins-inputs-snmp-oid_mapping_format) is set to `default`.


### `oid_path_length` [plugins-inputs-snmp-oid_path_length]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The `oid_path_length` option specifies the number of OID root digits to retain in the event field name. For example, in a numeric OID like "1.3.6.1.2.1.1.1.0" the last 2 digits could be retained by setting `oid_path_length => 2` which would result in a field name "1.0". Similarly when a MIB is used an OID such "1.3.6.1.2.mib-2.system.sysDescr.0" would become "sysDescr.0"

* You can use this setting or [`oid_root_skip`](#plugins-inputs-snmp-oid_root_skip), but not both at the same time.
* This setting can be used only if [`oid_mapping_format`](#plugins-inputs-snmp-oid_mapping_format) is set to `default`.


### `poll_hosts_timeout` [plugins-inputs-snmp-poll_hosts_timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting

Specifies the maximum amount of time in milliseconds the polling client will wait for all [`hosts`](#plugins-inputs-snmp-hosts) responses. If all responses are not received before the timeout elapses, the client will fail and some hosts might not get polled during the current cycle.

By default, it uses the highest value between `1 hour`, the maximum [`hosts`](#plugins-inputs-snmp-hosts) configured `timeout`, and the [`interval`](#plugins-inputs-snmp-interval) value.


### `walk` [plugins-inputs-snmp-walk]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting

Use the `walk` option to retrieve the subtree of information for the given OID(s). One or more OID(s) are specified as an array of strings of OID(s).

Queries the subtree of information starting at the given OID(s).

Example

```ruby
  snmp {
    walk => ["1.3.6.1.2.1.1"]
    hosts => [{host => "udp:127.0.0.1/161" community => "public"}]
  }
}
```


### `tables` [plugins-inputs-snmp-tables]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting
* Results are returned under a field using the table name

The `tables` option is used to query for tabular values for the given column OID(s).

Each table definition is a hash and must define the name key and value and the columns to return.

**Specifying a single table**

```ruby
input {
  snmp {
    hosts => [{host => "udp:127.0.0.1/161" community => "public" version => "2c"  retries => 2  timeout => 1000}]
    tables => [ {"name" => "interfaces" "columns" => ["1.3.6.1.2.1.2.2.1.1", "1.3.6.1.2.1.2.2.1.2", "1.3.6.1.2.1.2.2.1.5"]} ]
  }
}
```

**Specifying multiple tables**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    tables => [ {"name" => "interfaces" "columns" => ["1.3.6.1.2.1.2.2.1.1", "1.3.6.1.2.1.2.2.1.2", "1.3.6.1.2.1.2.2.1.5"]}, {"name" => "ltmPoolStatTable" "columns" => ["1.3.6.1.4.1.3375.2.2.5.2.3.1.1", "1.3.6.1.4.1.3375.2.2.5.2.3.1.6"]} ]
  }
}
```


### `target` [plugins-inputs-snmp-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The name of the field under which SNMP payloads are assigned. If not specified data will be stored in the root of the event.

Setting a target is recommended when [`ecs_compatibility`](#plugins-inputs-snmp-ecs_compatibility) is enabled.


### `threads` [plugins-inputs-snmp-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is the number of CPU cores

The number of threads to use for executing the hosts SNMP requests.


### `use_provided_mibs` [plugins-inputs-snmp-use_provided_mibs]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

This plugin provides all IETF MIBs (management information bases), publicly available in the [libsmi](https://www.ibr.cs.tu-bs.de/projects/libsmi) version `0.5.0`. When enabled, it automatically loads the bundled MIBs and provides mapping of the numeric OIDs to MIB field names in the resulting event.



## SNMPv3 Authentication Options [_snmpv3_authentication_options_2]

A **single user** can be configured and will be used for all defined SNMPv3 hosts. Multiple snmp input declarations will be needed if multiple SNMPv3 users are required. These options are required only if you are using SNMPv3.

### `auth_pass` [plugins-inputs-snmp-auth_pass]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting

The `auth_pass` option specifies the SNMPv3 authentication passphrase or password.


### `auth_protocol` [plugins-inputs-snmp-auth_protocol]

The `auth_protocol` option specifies the SNMPv3 authentication protocol or type

* Value can be any of: `md5`, `sha`, `sha2`, `hmac128sha224`, `hmac192sha256`, `hmac256sha384`, `hmac384sha512`
* Note that `sha2` and `hmac192sha256` are equivalent
* There is no default value for this setting


### `priv_pass` [plugins-inputs-snmp-priv_pass]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting

The `priv_pass` option specifies the SNMPv3 encryption password.


### `priv_protocol` [plugins-inputs-snmp-priv_protocol]

* Value can be any of: `des`, `3des`, `aes`, `aes128`, `aes192`, `aes256`
* Note that `aes` and `aes128` are equivalent
* There is no default value for this setting

The `priv_protocol` option specifies the SNMPv3 privacy/encryption protocol.


### `security_level` [plugins-inputs-snmp-security_level]

* Value can be any of: `noAuthNoPriv`, `authNoPriv`, `authPriv`
* There is no default value for this setting

The `security_level` option specifies the SNMPv3 security level between Authentication, No Privacy; Authentication, Privacy; or no Authentication, no Privacy.


### `security_name` [plugins-inputs-snmp-security_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The `security_name` option specifies the SNMPv3 security name or user name.



## Configuration examples [plugins-inputs-snmp-examples]

**Specifying SNMPv3 settings**

```ruby
input {
  snmp {
    hosts => [{host => "udp:127.0.0.1/161" version => "3"}]
    get => ["1.3.6.1.2.1.1.1.0"]
    security_name => "mySecurityName"
    auth_protocol => "sha"
    auth_pass => "ShaPassword"
    priv_protocol => "aes"
    priv_pass => "AesPasword"
    security_level => "authPriv"
  }
}
```

**Using both `get` and `walk` in the same poll cycle for each host(s)**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0", "1.3.6.1.2.1.1.3.0", "1.3.6.1.2.1.1.5.0"]
    walk => ["1.3.6.1.2.1.1"]
    hosts => [{host => "udp:127.0.0.1/161" community => "public"}]
  }
}
```

**Specifying all global options**

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    hosts => [{host => "udp:127.0.0.1/161"}]

    mib_paths => ["path/to/converted/mibfile.dic"]
    oid_root_skip => 0
    interval => 30
  }
}
```


## Polled host information [_polled_host_information]

All the polled host information is stored in the event `@metadata`:

* `[@metadata][host_protocol]` : `udp` or `tcp`
* `[@metadata][host_address]` : host address for example `127.0.0.1`
* `[@metadata][host_port]` : host port (for example `161`)
* `[@metadata][host_community]` : community string for example `public`

By default, a `host` field is added to the event with the `[@metadata][host_address]` value.

```ruby
config :add_field, :validate => :hash, :default => { "host" => "%{[@metadata][host_address]}" }
```

You can customize the format and content of the `host` field by specifying an alternate `add_field`.

Example

```ruby
input {
  snmp {
    get => ["1.3.6.1.2.1.1.1.0"]
    hosts => [{host => "udp:127.0.0.1/161"}]

    add_field => {host => "%{[@metadata][host_protocol]}:%{[@metadata][host_address]}/%{[@metadata][host_port]},%{[@metadata][host_community]}"}
  }
}
```


## Common options [plugins-inputs-snmp-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-snmp-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`enable_metric`](#plugins-inputs-snmp-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-snmp-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-snmp-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-snmp-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-snmp-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `enable_metric` [plugins-inputs-snmp-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-snmp-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 snmp inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  snmp {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-snmp-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-snmp-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
