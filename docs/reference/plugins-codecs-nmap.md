---
navigation_title: "nmap"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-nmap.html
---

# Nmap codec plugin [plugins-codecs-nmap]


* Plugin version: v0.0.22
* Released on: 2022-11-16
* [Changelog](https://github.com/logstash-plugins/logstash-codec-nmap/blob/v0.0.22/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-nmap-index.md).

## Installation [_installation_70]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-codec-nmap`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_194]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-nmap). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_193]

This codec is used to parse [nmap](https://nmap.org/) output data which is serialized in XML format. Nmap ("Network Mapper") is a free and open source utility for network discovery and security auditing. For more information on nmap, see [https://nmap.org/](https://nmap.org/).

This codec can only be used for decoding data.

Event types are listed below

`nmap_scan_metadata`: An object containing top level information about the scan, including how many hosts were up, and how many were down. Useful for the case where you need to check if a DNS based hostname does not resolve, where both those numbers will be zero. `nmap_host`: One event is created per host. The full data covering an individual host, including open ports and traceroute information as a nested structure. `nmap_port`: One event is created per host/port. This duplicates data already in `nmap_host`: This was put in for the case where you want to model ports as separate documents in Elasticsearch (which Kibana prefers). `nmap_traceroute_link`: One of these is output per traceroute *connection*, with a `from` and a `to` object describing each hop. Note that traceroute hop data is not always correct due to the fact that each tracing ICMP packet may take a different route. Also very useful for Kibana visualizations.


## Nmap Codec Configuration Options [plugins-codecs-nmap-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`emit_hosts`](#plugins-codecs-nmap-emit_hosts) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`emit_ports`](#plugins-codecs-nmap-emit_ports) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`emit_scan_metadata`](#plugins-codecs-nmap-emit_scan_metadata) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`emit_traceroute_links`](#plugins-codecs-nmap-emit_traceroute_links) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

 

### `emit_hosts` [plugins-codecs-nmap-emit_hosts]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Emit all host data as a nested document (including ports + traceroutes) with the type *nmap_fullscan*


### `emit_ports` [plugins-codecs-nmap-emit_ports]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Emit each port as a separate document with type *nmap_port*


### `emit_scan_metadata` [plugins-codecs-nmap-emit_scan_metadata]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Emit scan metadata


### `emit_traceroute_links` [plugins-codecs-nmap-emit_traceroute_links]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Emit each hop_tuple of the traceroute with type *nmap_traceroute_link*



