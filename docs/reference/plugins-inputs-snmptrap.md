---
navigation_title: "snmptrap"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-snmptrap.html
---

# SNMP trap input plugin [plugins-inputs-snmptrap]


* A component of the [snmp integration plugin](/reference/plugins-integrations-snmp.md)
* Integration version: v4.0.5
* Released on: 2025-01-06
* [Changelog](https://github.com/logstash-plugins/logstash-integration-snmp/blob/v4.0.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/input-snmptrap-index.md).

## Getting help [_getting_help_51]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-snmp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).

::::{admonition} Migrating to `logstash-integration-snmp` from stand-alone `input-snmptrap`
The `logstash-input-snmptrap` plugin is now a component of the `logstash-integration-snmp` plugin which is bundled with {{ls}} 8.15.0 by default. This integrated plugin package provides better alignment in snmp processing, better resource management, easier package maintenance, and a smaller installation footprint.

Before you upgrade to {{ls}} 8.15.0, be aware of [behavioral and mapping differences](/reference/plugins-integrations-snmp.md#plugins-integrations-snmp-migration) between current stand-alone plugins and the new versions included in `integration-snmp`. If you need to maintain current mappings for the `input-snmptrap` plugin, you have options to [preserve existing behavior](/reference/plugins-integrations-snmp.md#plugins-integrations-snmp-input-snmptrap-compat).

::::



## Description [_description_51]

The `logstash-input-snmptrap` plugin reads SNMP trap messages as events.

Resulting `message` field resembles:

```json
{"agent_addr":"192.168.1.40", "generic_trap":6, "specific_trap":15511, "enterprise":"1.3.6.1.2.1.1.1", "variable_bindings":{"1.3.6.1.2.1.1.2.0":"test one", "1.3.6.1.2.1.1.1.0":"test two"}, "type":"V1TRAP", "community":"public", "version":1, "timestamp":1500}
```


## Event Metadata and the Elastic Common Schema (ECS) [plugins-inputs-snmptrap-ecs]

Because SNMP data has specific field names based on OIDs, we recommend setting a [`target`](#plugins-inputs-snmptrap-target). The source host field changes based on [`ecs_compatibility`](#plugins-inputs-snmptrap-ecs_compatibility).

|     |     |     |     |
| --- | --- | --- | --- |
| ECS disabled | ECS v1, v8 | *Availability* | *Description* |
| [host] | [host][ip] | *Always* | *IP address of the host e.g. "192.168.1.11"* |

This plugin also adds the trap PDU metadata to each event. The value is stored in the `@metadata` where it can be used by other plugins in the pipeline.

|     |     |     |
| --- | --- | --- |
| ECS disabled, v1, v8 | *Availability* | *Description* |
| [@metadata][input][snmptrap][pdu][agent_addr] | *`SNMPv1`* | *Network address of the object generating the trap* |
| [@metadata][input][snmptrap][pdu][community] | *`SNMPv1` `SNMPv2c`* | *SNMP community* |
| [@metadata][input][snmptrap][pdu][enterprise] | *`SNMPv1`* | *Type of object generating the trap* |
| [@metadata][input][snmptrap][pdu][error_index] | *`SNMPv2c` `SNMPv3`* | *Provides additional information by identifyingwhich variable binding in the list caused the error* |
| [@metadata][input][snmptrap][pdu][error_status] | *`SNMPv2c` `SNMPv3`* | *Error status code* |
| [@metadata][input][snmptrap][pdu][error_status_text] | *`SNMPv2c` `SNMPv3`* | *Error status code description* |
| [@metadata][input][snmptrap][pdu][generic_trap] | *`SNMPv1`* | *Generic trap type* |
| [@metadata][input][snmptrap][pdu][request_id] | *`SNMPv2c` `SNMPv3`* | *Request ID* |
| [@metadata][input][snmptrap][pdu][specific_trap] | *`SNMPv1`* | *Specific code, presented even if the generic_trap is not enterprise specific* |
| [@metadata][input][snmptrap][pdu][timestamp] | *`SNMPv1`* | *Time elapsed between the last (re)initialization of the network entity and the generation of the trap* |
| [@metadata][input][snmptrap][pdu][type] | *Always* | *PDU type* |
| [@metadata][input][snmptrap][pdu][variable_bindings] | *Always* | *SNMP variable bindings values* |
| [@metadata][input][snmptrap][pdu][version] | *Always* | *SNMP version* |


## Importing MIBs [plugins-inputs-snmptrap-import-mibs]

This plugin already includes the IETF MIBs (management information bases), and you do not need to import them. If you need additional MIBs, you need to import them. Check out [Importing MIBs](/reference/plugins-integrations-snmp.md#plugins-integrations-snmp-import-mibs) for info.


## SNMP Trap Input Configuration Options [plugins-inputs-snmptrap-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-snmptrap-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`community`](#plugins-inputs-snmptrap-community) | [array](/reference/configuration-file-structure.md#array) | No |
| [`ecs_compatibility`](#plugins-inputs-snmptrap-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`host`](#plugins-inputs-snmptrap-host) | [string](/reference/configuration-file-structure.md#string) | No |
| [`mib_paths`](#plugins-inputs-snmptrap-mib_paths) | [path](/reference/configuration-file-structure.md#path) | No |
| [`oid_mapping_format`](#plugins-inputs-snmptrap-oid_mapping_format) | [string](/reference/configuration-file-structure.md#string), one of `["default", "ruby_snmp", "dotted_string"]` | No |
| [`oid_map_field_values`](#plugins-inputs-snmptrap-oid_map_field_values) | [boolean](/reference/configuration-file-structure.md#boolean) | Yes |
| [`oid_path_length`](#plugins-inputs-snmptrap-oid_path_length) | [number](/reference/configuration-file-structure.md#number) | No |
| [`oid_root_skip`](#plugins-inputs-snmptrap-oid_root_skip) | [number](/reference/configuration-file-structure.md#number) | No |
| [`port`](#plugins-inputs-snmptrap-port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`supported_transports`](#plugins-inputs-snmptrap-supported_transports) | [string](/reference/configuration-file-structure.md#string) | No |
| [`supported_versions`](#plugins-inputs-snmptrap-supported_versions) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target`](#plugins-inputs-snmptrap-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-snmptrap-threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_provided_mibs`](#plugins-inputs-snmptrap-use_provided_mibs) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`yamlmibdir`](#plugins-inputs-snmptrap-yamlmibdir) | [string](/reference/configuration-file-structure.md#string) | *Deprecated* |


## SNMPv3 Authentication Options [_snmpv3_authentication_options_3]

This plugin supports the following SNMPv3 authentication options.

| Setting | Input type | Required |
| --- | --- | --- |
| [`auth_pass`](#plugins-inputs-snmptrap-auth_pass) | [password](/reference/configuration-file-structure.md#password) | No |
| [`auth_protocol`](#plugins-inputs-snmptrap-auth_protocol) | [string](/reference/configuration-file-structure.md#string), one of `["md5", "sha", "sha2", "hmac128sha224", "hmac192sha256", "hmac256sha384", "hmac384sha512"]` | No |
| [`priv_pass`](#plugins-inputs-snmptrap-priv_pass) | [password](/reference/configuration-file-structure.md#password) | No |
| [`priv_protocol`](#plugins-inputs-snmptrap-priv_protocol) | [string](/reference/configuration-file-structure.md#string), one of `["des", "3des", "aes", "aes128", "aes192", "aes256"]` | No |
| [`security_level`](#plugins-inputs-snmptrap-security_level) | [string](/reference/configuration-file-structure.md#string), one of `["noAuthNoPriv", "authNoPriv", "authPriv"]` | No |
| [`security_name`](#plugins-inputs-snmptrap-security_name) | [string](/reference/configuration-file-structure.md#string) | No |


## SNMP Trap Input Configuration Options [_snmp_trap_input_configuration_options]

Also see [Common options](#plugins-inputs-snmptrap-common-options) for a list of options supported by all input plugins.

### `community` [plugins-inputs-snmptrap-community]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["public"]`

The SNMPv1 and SNMPv2c communities to listen for. To allow any community, set this config value to empty `community => []`.

Examples

**Listen for `public` and `guest` communities**

```ruby
input {
  snmptrap {
    community => ["public", "guest"]
  }
}
```

**Listen for all communities**

```ruby
input {
  snmptrap {
    community => []
  }
}
```


### `ecs_compatibility` [plugins-inputs-snmptrap-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (fields might be set at the root of the event)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, the `host` field)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).


### `host` [plugins-inputs-snmptrap-host]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"0.0.0.0"`

The address to listen on.


### `mib_paths` [plugins-inputs-snmptrap-mib_paths]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting

The `mib_paths` option specifies the location of one or more imported MIB files. The value can be either a dir path containing the imported MIB (`.dic`, `.yaml`) files or a file path to a single MIB file.


### `oid_mapping_format` [plugins-inputs-snmptrap-oid_mapping_format]

* Value can be any of: `default`, `ruby_snmp`, `dotted_string`
* Default value is `"default"`

Defines the mapping textual representation of an OID in the Logstash event: * `default` translates every identifier, using the MIBs resolved names, separated by dots. Example: `1.3.6.1.2.1.1.2.0` is mapped as `iso.org.dod.internet.mgmt.mib-2.system.sysObjectID.0` * `ruby_snmp` produces field names prefixed by the MIBs module name, followed by the latest resolved identifier name and unknowns values. Example: `1.3.6.1.2.1.1.2.0` is mapped as `SNMPv2-MIB::sysObjectID.0`. * `dotted_string` maps fields using the standard dotted string representation, Example: `1.3.6.1.2.1.1.2.0` is mapped as  `1.3.6.1.2.1.1.2.0`


### `oid_map_field_values` [plugins-inputs-snmptrap-oid_map_field_values]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Defines if the Logstash event fields values, which types are `OID`, are mapped using the configured OID textual representation set on the [`oid_mapping_format`](#plugins-inputs-snmptrap-oid_mapping_format) option.


### `oid_root_skip` [plugins-inputs-snmptrap-oid_root_skip]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The `oid_root_skip` option specifies the number of OID root digits to ignore in the event field name. For example, in a numeric OID like "1.3.6.1.2.1.1.1.0" the first 5 digits could be ignored by setting `oid_root_skip => 5` which would result in a field name "1.1.1.0". Similarly when a MIB is used an OID such "1.3.6.1.2.mib-2.system.sysDescr.0" would become "mib-2.system.sysDescr.0"

* You can use this setting or [`oid_path_length`](#plugins-inputs-snmptrap-oid_path_length), but not both at the same time.
* Use this setting only if [`oid_mapping_format`](#plugins-inputs-snmptrap-oid_mapping_format) is set to `default`.


### `oid_path_length` [plugins-inputs-snmptrap-oid_path_length]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `0`

The `oid_path_length` option specifies the number of OID root digits to retain in the event field name. For example, in a numeric OID like "1.3.6.1.2.1.1.1.0" the last 2 digits could be retained by setting `oid_path_length => 2` which would result in a field name "1.0". Similarly when a MIB is used an OID such "1.3.6.1.2.mib-2.system.sysDescr.0" would become "sysDescr.0"

* You can use this setting or [`oid_root_skip`](#plugins-inputs-snmptrap-oid_root_skip), but not both at the same time.
* Use this setting only if [`oid_mapping_format`](#plugins-inputs-snmptrap-oid_mapping_format) is set to `default`.


### `port` [plugins-inputs-snmptrap-port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1062`

The port to listen on. Remember that ports less than 1024 (privileged ports) may require root to use. hence the default of 1062.


### `supported_transports` [plugins-inputs-snmptrap-supported_transports]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `tcp`, `udp`
* Default value is `["udp"]`

The supported transport protocols to listen on.

SNMP was originally designed for use with UDP as transport protocol and is the official recommendation. TCP is an optional transport mapping and can be enabled if needed. For more details on SNMP over TCP, please refer to the [RFC-3430](https://datatracker.ietf.org/doc/html/rfc3430).


### `supported_versions` [plugins-inputs-snmptrap-supported_versions]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Allowed values are: `1`, `2c`, `3`
* Default value is `["1", "2c"]`

The supported SNMP protocol versions to listen on. SNMP messages for versions that are either unsupported and/or disabled are automatically discarded.


### `target` [plugins-inputs-snmptrap-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The name of the field under which SNMP payloads are assigned. If not specified data will be stored in the root of the event.

Setting a target is recommended when [`ecs_compatibility`](#plugins-inputs-snmptrap-ecs_compatibility) is enabled.


### `threads` [plugins-inputs-snmptrap-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is 75% of the number of CPU cores

The number of threads to use for processing the received SNMP trap messages.


### `use_provided_mibs` [plugins-inputs-snmptrap-use_provided_mibs]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

This plugin provides all IETF MIBs (management information bases), publicly available in the [libsmi](https://www.ibr.cs.tu-bs.de/projects/libsmi) version `0.5.0`. When enabled, it automatically loads the bundled MIBs and provides mapping of the numeric OIDs to MIB field names in the resulting event.


### `yamlmibdir` [plugins-inputs-snmptrap-yamlmibdir]

::::{admonition} Deprecated in 4.0.0.
:class: warning

Replaced by [`mib_paths`](#plugins-inputs-snmptrap-mib_paths)
::::


* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

directory of YAML MIB maps  (same format ruby-snmp uses)



## SNMPv3 Authentication Options [_snmpv3_authentication_options_4]

A **single user** can be configured. Multiple snmptrap input declarations will be needed if multiple SNMPv3 users are required. These options are required only if you are using SNMPv3.

### `auth_pass` [plugins-inputs-snmptrap-auth_pass]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting

The `auth_pass` option specifies the SNMPv3 authentication passphrase or password.


### `auth_protocol` [plugins-inputs-snmptrap-auth_protocol]

The `auth_protocol` option specifies the SNMPv3 authentication protocol or type

* Value can be any of: `md5`, `sha`, `sha2`, `hmac128sha224`, `hmac192sha256`, `hmac256sha384`, `hmac384sha512`
* Note that `sha2` and `hmac192sha256` are equivalent
* There is no default value for this setting


### `priv_pass` [plugins-inputs-snmptrap-priv_pass]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting

The `priv_pass` option specifies the SNMPv3 encryption password.


### `priv_protocol` [plugins-inputs-snmptrap-priv_protocol]

* Value can be any of: `des`, `3des`, `aes`, `aes128`, `aes192`, `aes256`
* Note that `aes` and `aes128` are equivalent
* There is no default value for this setting

The `priv_protocol` option specifies the SNMPv3 privacy/encryption protocol.


### `security_level` [plugins-inputs-snmptrap-security_level]

* Value can be any of: `noAuthNoPriv`, `authNoPriv`, `authPriv`
* There is no default value for this setting

The `security_level` option specifies the SNMPv3 security level between Authentication, No Privacy; Authentication, Privacy; or no Authentication, no Privacy.


### `security_name` [plugins-inputs-snmptrap-security_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

The `security_name` option specifies the SNMPv3 security name or user name.



## Configuration examples [_configuration_examples_2]

**Specifying SNMPv3 traps settings**

```ruby
input {
  snmptrap {
    supported_versions => ['3']
    security_name => "mySecurityName"
    auth_protocol => "sha"
    auth_pass => "ShaPassword"
    priv_protocol => "aes"
    priv_pass => "AesPasword"
    security_level => "authPriv"
  }
}
```


## Common options [plugins-inputs-snmptrap-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-snmptrap-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-snmptrap-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-snmptrap-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-snmptrap-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-snmptrap-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-snmptrap-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-snmptrap-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-snmptrap-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-snmptrap-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-snmptrap-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 snmptrap inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  snmptrap {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-snmptrap-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-snmptrap-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.
