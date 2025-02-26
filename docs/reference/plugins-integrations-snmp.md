---
navigation_title: "snmp"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-integrations-snmp.html
---

# SNMP Integration Plugin [plugins-integrations-snmp]


* Plugin version: v4.0.5
* Released on: 2025-01-06
* [Changelog](https://github.com/logstash-plugins/logstash-integration-snmp/blob/v4.0.5/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/integration-snmp-index.md).

## Getting help [_getting_help_7]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-snmp). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).

:::::{admonition} Announcing the new SNMP integration plugin
The new `logstash-integration-snmp` plugin is available and bundled with {{ls}} 8.15.0 (and later) by default. This plugin combines our classic `logstash-input-snmp` and `logstash-input-snmptrap` plugins into a single Ruby gem at v4.0.0 and later. Earlier versions of the stand-alone plugins that were bundled with {{ls}} by default will be replaced by the 4.0.0+ version contained in this new integration.

::::{important}
Before you upgrade to {{ls}} 8.15.0 that includes this new integration by default, be aware of [behavioral and mapping differences](#plugins-integrations-snmp-migration) between stand-alone plugins and the new versions included in `integration-snmp`. If you need to maintain current mappings for the `input-snmptrap` plugin, you have options to [preserve existing behavior](#plugins-integrations-snmp-input-snmptrap-compat).
::::


:::::



## Description [_description_8]

The SNMP integration plugin includes:

* [SNMP input plugin](/reference/plugins-inputs-snmp.md)
* [Snmptrap input plugin](/reference/plugins-inputs-snmptrap.md)

The new `logstash-integration-snmp` plugin combines the `logstash-input-snmp` and `logstash-input-snmptrap` plugins into one integrated plugin that encompasses the capabilities of both. This integrated plugin package provides better alignment in snmp processing, better resource management, easier package maintenance, and a smaller installation footprint.

In this section, we’ll cover:

* [Migrating to `logstash-integration-snmp` from individual plugins](#plugins-integrations-snmp-migration)
* [Importing MIBs](#plugins-integrations-snmp-import-mibs)


## Migrating to `logstash-integration-snmp` from individual plugins [plugins-integrations-snmp-migration]

You’ll retain and expand the functionality of existing stand-alone plugins, but in a more compact, integrated package. In this section, we’ll note mapping and behavioral changes, and explain how to preserve current behavior if needed.

### Migration notes: `logstash-input-snmp` [plugins-integrations-snmp-migration-input-snmp]

As a component of the new `logstash-integration-snmp` plugin, the `logstash-input-snmp` plugin offers the same capabilities as the stand-alone [logstash-input-snmp](https://github.com/logstash-plugins/logstash-input-snmp).

You might need to address some behavior changes depending on the use-case and how the ingested data is being handled through the pipeline.

#### Changes to mapping and error logging: `logstash-input-snmp` [plugins-integrations-snmp-input-snmp-mapping]

* **No such instance errors** are mapped as `error: no such instance currently exists at this OID string` instead of `noSuchInstance`.
* **No such object errors** are mapped as `error: no such object currently exists at this OID string` instead of `noSuchObject`.
* **End of MIB view errors** are mapped as `error: end of MIB view` instead of `endOfMibView`.
* An **unknown variable type** falls back to the `string` representation instead of logging an error as it did in with the stand-alone `logstash-input-snmp`. This change should not affect existing pipelines, unless they have custom error handlers that rely on specific error messages.



### Migration notes: `logstash-input-snmptrap` [plugins-integrations-snmp-migration-input-snmptrap]

As a component of the new `logstash-integration-snmp` plugin, the `logstash-input-snmptrap` plugin offers *almost the same capabilities* as the stand-alone [logstash-input-snmp](https://github.com/logstash-plugins/logstash-input-snmp) plugin.

You might need to address some behavior changes depending on your use case and how the ingested data is being handled through the pipeline.

#### Changes to mapping and error logging: `logstash-input-snmptrap` [plugins-integrations-snmp-input-snmptrap-mapping]

* The **PDU variable bindings** are mapped into the {{ls}} event using the defined data type. By default, the stand-alone `logstash-input-snmptrap` plugin converts all of the data to `string`, ignoring the original type. If this behavior is not what you want, you can use a filter to retain the original type.
* **SNMP `TimeTicks` variables** are mapped as `Long` timestamps instead of formatted date string (`%d days, %02d:%02d:%02d.%02d`).
* **`null` variables values** are mapped using the string `null` instead of `Null` (upper-case N).
* **No such instance errors** are mapped as `error: no such instance currently exists at this OID string` instead of `noSuchInstance`.
* **No such object errors** are mapped as `error: no such object currently exists at this OID string` instead of `noSuchObject`.
* **End of MIB view errors** are mapped as `error: end of MIB view` instead of `endOfMibView`.
* The previous generation (stand-alone) input-snmptrap plugin formatted the **`message` field** as a ruby-snmp `SNMP::SNMPv1_Trap` object representation.

    ```sh
    <SNMP::SNMPv1_Trap:0x6f1a7a4 @varbind_list=[#<SNMP::VarBind:0x2d7bcd8f @value="teststring", @name=[1.11.12.13.14.15]>], @timestamp=#<SNMP::TimeTicks:0x1af47e9d @value=55>, @generic_trap=6,  @enterprise=[1.2.3.4.5.6], @source_ip="127.0.0.1", @agent_addr=#<SNMP::IpAddress:0x29a4833e @value="test">, @specific_trap=99>
    ```

    The new integrated `input-snmptrap` plugin uses JSON to format **`message` field**.

    ```json
    {"error_index":0, "variable_bindings":{"1.3.6.1.6.3.1.1.4.1.0":"SNMPv2-MIB::coldStart", "1.3.6.1.2.1.1.3.0":0}, "error_status":0, "type":"TRAP", "error_status_text":"Success", "community":"public", "version":"2c", "request_id":1436216872}
    ```



#### Maintain maximum compatibility with previous implementation [plugins-integrations-snmp-input-snmptrap-compat]

If needed, you can configure the new `logstash-integration-snmp` plugin to maintain maximum compatibility with the previous (stand-alone) version of the [input-snmp](https://github.com/logstash-plugins/logstash-input-snmp) plugin.

```ruby
input {
   snmptrap {
    use_provided_mibs => false
    oid_mapping_format => 'ruby_snmp'
    oid_map_field_values => true
   }
}
```




## Importing MIBs [plugins-integrations-snmp-import-mibs]

The SNMP plugins already include the IETF MIBs (management information bases) and these do not need to be imported. To disable the bundled MIBs set the `use_provided_mibs` option to `false`.

Any other MIB will need to be manually imported to provide mapping of the numeric OIDs to MIB field names in the resulting event.

To import a MIB, the OSS [libsmi library](https://www.ibr.cs.tu-bs.de/projects/libsmi/) is required. libsmi is available and installable on most operating systems.

To import a MIB, you need to first convert the ASN.1 MIB file into a `.dic` file using the libsmi `smidump` command line utility.

**Example (using `RFC1213-MIB` file)**

```sh
$ smidump --level=1 -k -f python RFC1213-MIB > RFC1213-MIB.dic
```

Note that the resulting file as output by `smidump` must have the `.dic` extension.

### Preventing a `failed to locate MIB module` error [plugins-integrations-snmp-locate-mibs]

The `smidump` function looks for MIB dependencies in its pre-configured paths list. To avoid the `failed to locate MIB module` error, you may need to provide the MIBs locations in your particular environment.

The recommended ways to provide the additional path configuration are:

* an environment variable, or
* a config file to provide the additional path configuration.

See the "MODULE LOCATIONS" section of the [smi_config documentation](https://www.ibr.cs.tu-bs.de/projects/libsmi/smi_config.md#MODULE%20LOCATIONS) for more information.


### Option 1: Use an environment variable [plugins-integrations-snmp-env-var]

Set the `SMIPATH` env var with the path to your MIBs. Be sure to include a prepended colon (`:`) for the path.

```sh
$ SMIPATH=":/path/to/mibs/" smidump -k -f python CISCO-PROCESS-MIB.mib > CISCO-PROCESS-MIB_my.dic <1>
```

1. Notice the colon that precedes the path definition.



### Option 2: Provide a configuration file [plugins-integrations-snmp-mib-config]

The other approach is to create a configuration file with the `path` option. For example, you could create a file called `smi.conf`:

```sh
path :/path/to/mibs/
```

And use the config with smidump:

```sh
$ smidump -c smi.conf -k -f python CISCO-PROCESS-MIB.mib > CISCO-PROCESS-MIB_my.dic
```



