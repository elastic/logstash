---
navigation_title: "cef"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-cef.html
---

# Cef codec plugin [plugins-codecs-cef]


* Plugin version: v6.2.8
* Released on: 2024-10-22
* [Changelog](https://github.com/logstash-plugins/logstash-codec-cef/blob/v6.2.8/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-cef-index.md).

## Getting help [_getting_help_173]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-cef). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_172]

Implementation of a Logstash codec for the ArcSight Common Event Format (CEF). It is based on [Implementing ArcSight CEF Revision 25, September 2017](https://www.microfocus.com/documentation/arcsight/arcsight-smartconnectors/pdfdoc/common-event-format-v25/common-event-format-v25.pdf).

If this codec receives a payload from an input that is not a valid CEF message, then it produces an event with the payload as the *message* field and a *_cefparsefailure* tag.


## Compatibility with the Elastic Common Schema (ECS) [_compatibility_with_the_elastic_common_schema_ecs_3]

This plugin can be used to decode CEF events *into* the Elastic Common Schema, or to encode ECS-compatible events into CEF. It can also be used *without* ECS, encoding and decoding events using only CEF-defined field names and keys.

The ECS Compatibility mode for a specific plugin instance can be controlled by setting [`ecs_compatibility`](#plugins-codecs-cef-ecs_compatibility) when defining the codec:

```sh
    input {
      tcp {
        # ...
        codec => cef {
          ecs_compatibility => v1
        }
      }
    }
```

If left unspecified, the value of the `pipeline.ecs_compatibility` setting is used.

### Timestamps and ECS compatiblity [_timestamps_and_ecs_compatiblity]

When decoding in ECS Compatibility Mode, timestamp-type fields are parsed and normalized to specific points on the timeline.

Because the CEF format allows ambiguous timestamp formats, some reasonable assumptions are made:

* When the timestamp does not include a year, we assume it happened in the recent past (or *very* near future to accommodate out-of-sync clocks and timezone offsets).
* When the timestamp does not include UTC-offset information, we use the event’s timezone (`dtz` or `deviceTimeZone` field), or fall through to this plugin’s [`default_timezone`](#plugins-codecs-cef-default_timezone).
* Localized timestamps are parsed using the provided [`locale`](#plugins-codecs-cef-locale).


### Field mapping [plugins-codecs-cef-field-mapping]

The header fields from each CEF payload is expanded to the following fields, depending on whether ECS is enabled.

#### Header field mapping [plugins-codecs-cef-header-field]

| ECS Disabled | ECS Field |
| --- | --- |
| `cefVersion` | `[cef][version]` |
| `deviceVendor` | `[observer][vendor]` |
| `deviceProduct` | `[observer][product]` |
| `deviceVersion` | `[observer][version]` |
| `deviceEventClassId` | `[event][code]` |
| `name` | `[cef][name]` |
| `severity` | `[event][severity]` |

When decoding CEF payloads with `ecs_compatibility => disabled`, the abbreviated CEF Keys found in extensions are expanded, and CEF Field Names are inserted at the root level of the event.

When decoding in an ECS Compatibility mode, the ECS Fields are populated from the corresponding CEF Field Names *or* CEF Keys found in the payload’s extensions.

The following is a mapping between these fields.


#### Extension field mapping [plugins-codecs-cef-ext-field]

| CEF Field Name (optional CEF Key) | ECS Field |
| --- | --- |
| `agentAddress` (`agt`) | `[agent][ip]` |
| `agentDnsDomain` | `[cef][agent][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *higher* priority. |
| `agentHostName` (`ahost`) | `[agent][name]` |
| `agentId` (`aid`) | `[agent][id]` |
| `agentMacAddress` (`amac`) | `[agent][mac]` |
| `agentNtDomain` | `[cef][agent][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *lower* priority. |
| `agentReceiptTime` (`art`) | `[event][created]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `agentTimeZone` (`atz`) | `[cef][agent][timezone]` |
| `agentTranslatedAddress` | `[cef][agent][nat][ip]` |
| `agentTranslatedZoneExternalID` | `[cef][agent][translated_zone][external_id]` |
| `agentTranslatedZoneURI` | `[cef][agent][translated_zone][uri]` |
| `agentType` (`at`) | `[agent][type]` |
| `agentVersion` (`av`) | `[agent][version]` |
| `agentZoneExternalID` | `[cef][agent][zone][external_id]` |
| `agentZoneURI` | `[cef][agent][zone][uri]` |
| `applicationProtocol` (`app`) | `[network][protocol]` |
| `baseEventCount` (`cnt`) | `[cef][base_event_count]` |
| `bytesIn` (`in`) | `[source][bytes]` |
| `bytesOut` (`out`) | `[destination][bytes]` |
| `categoryDeviceType` (`catdt`) | `[cef][device_type]` |
| `customerExternalID` | `[organization][id]` |
| `customerURI` | `[organization][name]` |
| `destinationAddress` (`dst`) | `[destination][ip]` |
| `destinationDnsDomain` | `[destination][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *higher* priority. |
| `destinationGeoLatitude` (`dlat`) | `[destination][geo][location][lat]` |
| `destinationGeoLongitude` (`dlong`) | `[destination][geo][location][lon]` |
| `destinationHostName` (`dhost`) | `[destination][domain]` |
| `destinationMacAddress` (`dmac`) | `[destination][mac]` |
| `destinationNtDomain` (`dntdom`) | `[destination][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *lower* priority. |
| `destinationPort` (`dpt`) | `[destination][port]` |
| `destinationProcessId` (`dpid`) | `[destination][process][pid]` |
| `destinationProcessName` (`dproc`) | `[destination][process][name]` |
| `destinationServiceName` | `[destination][service][name]` |
| `destinationTranslatedAddress` | `[destination][nat][ip]` |
| `destinationTranslatedPort` | `[destination][nat][port]` |
| `destinationTranslatedZoneExternalID` | `[cef][destination][translated_zone][external_id]` |
| `destinationTranslatedZoneURI` | `[cef][destination][translated_zone][uri]` |
| `destinationUserId` (`duid`) | `[destination][user][id]` |
| `destinationUserName` (`duser`) | `[destination][user][name]` |
| `destinationUserPrivileges` (`dpriv`) | `[destination][user][group][name]` |
| `destinationZoneExternalID` | `[cef][destination][zone][external_id]` |
| `destinationZoneURI` | `[cef][destination][zone][uri]` |
| `deviceAction` (`act`) | `[event][action]` |
| `deviceAddress` (`dvc`) | `[observer][ip]`<br>                                                 When plugin configured with `device => observer` |
| `[host][ip]`<br>                                                 When plugin configured with `device => host` |
| `deviceCustomFloatingPoint1` (`cfp1`) | `[cef][device_custom_floating_point_1][value]` |
| `deviceCustomFloatingPoint1Label` (`cfp1Label`) | `[cef][device_custom_floating_point_1][label]` |
| `deviceCustomFloatingPoint2` (`cfp2`) | `[cef][device_custom_floating_point_2][value]` |
| `deviceCustomFloatingPoint2Label` (`cfp2Label`) | `[cef][device_custom_floating_point_2][label]` |
| `deviceCustomFloatingPoint3` (`cfp3`) | `[cef][device_custom_floating_point_3][value]` |
| `deviceCustomFloatingPoint3Label` (`cfp3Label`) | `[cef][device_custom_floating_point_3][label]` |
| `deviceCustomFloatingPoint4` (`cfp4`) | `[cef][device_custom_floating_point_4][value]` |
| `deviceCustomFloatingPoint4Label` (`cfp4Label`) | `[cef][device_custom_floating_point_4][label]` |
| `deviceCustomFloatingPoint5` (`cfp5`) | `[cef][device_custom_floating_point_5][value]` |
| `deviceCustomFloatingPoint5Label` (`cfp5Label`) | `[cef][device_custom_floating_point_5][label]` |
| `deviceCustomFloatingPoint6` (`cfp6`) | `[cef][device_custom_floating_point_6][value]` |
| `deviceCustomFloatingPoint6Label` (`cfp6Label`) | `[cef][device_custom_floating_point_6][label]` |
| `deviceCustomFloatingPoint7` (`cfp7`) | `[cef][device_custom_floating_point_7][value]` |
| `deviceCustomFloatingPoint7Label` (`cfp7Label`) | `[cef][device_custom_floating_point_7][label]` |
| `deviceCustomFloatingPoint8` (`cfp8`) | `[cef][device_custom_floating_point_8][value]` |
| `deviceCustomFloatingPoint8Label` (`cfp8Label`) | `[cef][device_custom_floating_point_8][label]` |
| `deviceCustomFloatingPoint9` (`cfp9`) | `[cef][device_custom_floating_point_9][value]` |
| `deviceCustomFloatingPoint9Label` (`cfp9Label`) | `[cef][device_custom_floating_point_9][label]` |
| `deviceCustomFloatingPoint10` (`cfp10`) | `[cef][device_custom_floating_point_10][value]` |
| `deviceCustomFloatingPoint10Label` (`cfp10Label`) | `[cef][device_custom_floating_point_10][label]` |
| `deviceCustomFloatingPoint11` (`cfp11`) | `[cef][device_custom_floating_point_11][value]` |
| `deviceCustomFloatingPoint11Label` (`cfp11Label`) | `[cef][device_custom_floating_point_11][label]` |
| `deviceCustomFloatingPoint12` (`cfp12`) | `[cef][device_custom_floating_point_12][value]` |
| `deviceCustomFloatingPoint12Label` (`cfp12Label`) | `[cef][device_custom_floating_point_12][label]` |
| `deviceCustomFloatingPoint13` (`cfp13`) | `[cef][device_custom_floating_point_13][value]` |
| `deviceCustomFloatingPoint13Label` (`cfp13Label`) | `[cef][device_custom_floating_point_13][label]` |
| `deviceCustomFloatingPoint14` (`cfp14`) | `[cef][device_custom_floating_point_14][value]` |
| `deviceCustomFloatingPoint14Label` (`cfp14Label`) | `[cef][device_custom_floating_point_14][label]` |
| `deviceCustomFloatingPoint15` (`cfp15`) | `[cef][device_custom_floating_point_15][value]` |
| `deviceCustomFloatingPoint15Label` (`cfp15Label`) | `[cef][device_custom_floating_point_15][label]` |
| `deviceCustomIPv6Address1` (`c6a1`) | `[cef][device_custom_ipv6_address_1][value]` |
| `deviceCustomIPv6Address1Label` (`c6a1Label`) | `[cef][device_custom_ipv6_address_1][label]` |
| `deviceCustomIPv6Address2` (`c6a2`) | `[cef][device_custom_ipv6_address_2][value]` |
| `deviceCustomIPv6Address2Label` (`c6a2Label`) | `[cef][device_custom_ipv6_address_2][label]` |
| `deviceCustomIPv6Address3` (`c6a3`) | `[cef][device_custom_ipv6_address_3][value]` |
| `deviceCustomIPv6Address3Label` (`c6a3Label`) | `[cef][device_custom_ipv6_address_3][label]` |
| `deviceCustomIPv6Address4` (`c6a4`) | `[cef][device_custom_ipv6_address_4][value]` |
| `deviceCustomIPv6Address4Label` (`c6a4Label`) | `[cef][device_custom_ipv6_address_4][label]` |
| `deviceCustomIPv6Address5` (`c6a5`) | `[cef][device_custom_ipv6_address_5][value]` |
| `deviceCustomIPv6Address5Label` (`c6a5Label`) | `[cef][device_custom_ipv6_address_5][label]` |
| `deviceCustomIPv6Address6` (`c6a6`) | `[cef][device_custom_ipv6_address_6][value]` |
| `deviceCustomIPv6Address6Label` (`c6a6Label`) | `[cef][device_custom_ipv6_address_6][label]` |
| `deviceCustomIPv6Address7` (`c6a7`) | `[cef][device_custom_ipv6_address_7][value]` |
| `deviceCustomIPv6Address7Label` (`c6a7Label`) | `[cef][device_custom_ipv6_address_7][label]` |
| `deviceCustomIPv6Address8` (`c6a8`) | `[cef][device_custom_ipv6_address_8][value]` |
| `deviceCustomIPv6Address8Label` (`c6a8Label`) | `[cef][device_custom_ipv6_address_8][label]` |
| `deviceCustomIPv6Address9` (`c6a9`) | `[cef][device_custom_ipv6_address_9][value]` |
| `deviceCustomIPv6Address9Label` (`c6a9Label`) | `[cef][device_custom_ipv6_address_9][label]` |
| `deviceCustomIPv6Address10` (`c6a10`) | `[cef][device_custom_ipv6_address_10][value]` |
| `deviceCustomIPv6Address10Label` (`c6a10Label`) | `[cef][device_custom_ipv6_address_10][label]` |
| `deviceCustomIPv6Address11` (`c6a11`) | `[cef][device_custom_ipv6_address_11][value]` |
| `deviceCustomIPv6Address11Label` (`c6a11Label`) | `[cef][device_custom_ipv6_address_11][label]` |
| `deviceCustomIPv6Address12` (`c6a12`) | `[cef][device_custom_ipv6_address_12][value]` |
| `deviceCustomIPv6Address12Label` (`c6a12Label`) | `[cef][device_custom_ipv6_address_12][label]` |
| `deviceCustomIPv6Address13` (`c6a13`) | `[cef][device_custom_ipv6_address_13][value]` |
| `deviceCustomIPv6Address13Label` (`c6a13Label`) | `[cef][device_custom_ipv6_address_13][label]` |
| `deviceCustomIPv6Address14` (`c6a14`) | `[cef][device_custom_ipv6_address_14][value]` |
| `deviceCustomIPv6Address14Label` (`c6a14Label`) | `[cef][device_custom_ipv6_address_14][label]` |
| `deviceCustomIPv6Address15` (`c6a15`) | `[cef][device_custom_ipv6_address_15][value]` |
| `deviceCustomIPv6Address15Label` (`c6a15Label`) | `[cef][device_custom_ipv6_address_15][label]` |
| `deviceCustomNumber1` (`cn1`) | `[cef][device_custom_number_1][value]` |
| `deviceCustomNumber1Label` (`cn1Label`) | `[cef][device_custom_number_1][label]` |
| `deviceCustomNumber2` (`cn2`) | `[cef][device_custom_number_2][value]` |
| `deviceCustomNumber2Label` (`cn2Label`) | `[cef][device_custom_number_2][label]` |
| `deviceCustomNumber3` (`cn3`) | `[cef][device_custom_number_3][value]` |
| `deviceCustomNumber3Label` (`cn3Label`) | `[cef][device_custom_number_3][label]` |
| `deviceCustomNumber4` (`cn4`) | `[cef][device_custom_number_4][value]` |
| `deviceCustomNumber4Label` (`cn4Label`) | `[cef][device_custom_number_4][label]` |
| `deviceCustomNumber5` (`cn5`) | `[cef][device_custom_number_5][value]` |
| `deviceCustomNumber5Label` (`cn5Label`) | `[cef][device_custom_number_5][label]` |
| `deviceCustomNumber6` (`cn6`) | `[cef][device_custom_number_6][value]` |
| `deviceCustomNumber6Label` (`cn6Label`) | `[cef][device_custom_number_6][label]` |
| `deviceCustomNumber7` (`cn7`) | `[cef][device_custom_number_7][value]` |
| `deviceCustomNumber7Label` (`cn7Label`) | `[cef][device_custom_number_7][label]` |
| `deviceCustomNumber8` (`cn8`) | `[cef][device_custom_number_8][value]` |
| `deviceCustomNumber8Label` (`cn8Label`) | `[cef][device_custom_number_8][label]` |
| `deviceCustomNumber9` (`cn9`) | `[cef][device_custom_number_9][value]` |
| `deviceCustomNumber9Label` (`cn9Label`) | `[cef][device_custom_number_9][label]` |
| `deviceCustomNumber10` (`cn10`) | `[cef][device_custom_number_10][value]` |
| `deviceCustomNumber10Label` (`cn10Label`) | `[cef][device_custom_number_10][label]` |
| `deviceCustomNumber11` (`cn11`) | `[cef][device_custom_number_11][value]` |
| `deviceCustomNumber11Label` (`cn11Label`) | `[cef][device_custom_number_11][label]` |
| `deviceCustomNumber12` (`cn12`) | `[cef][device_custom_number_12][value]` |
| `deviceCustomNumber12Label` (`cn12Label`) | `[cef][device_custom_number_12][label]` |
| `deviceCustomNumber13` (`cn13`) | `[cef][device_custom_number_13][value]` |
| `deviceCustomNumber13Label` (`cn13Label`) | `[cef][device_custom_number_13][label]` |
| `deviceCustomNumber14` (`cn14`) | `[cef][device_custom_number_14][value]` |
| `deviceCustomNumber14Label` (`cn14Label`) | `[cef][device_custom_number_14][label]` |
| `deviceCustomNumber15` (`cn15`) | `[cef][device_custom_number_15][value]` |
| `deviceCustomNumber15Label` (`cn15Label`) | `[cef][device_custom_number_15][label]` |
| `deviceCustomString1` (`cs1`) | `[cef][device_custom_string_1][value]` |
| `deviceCustomString1Label` (`cs1Label`) | `[cef][device_custom_string_1][label]` |
| `deviceCustomString2` (`cs2`) | `[cef][device_custom_string_2][value]` |
| `deviceCustomString2Label` (`cs2Label`) | `[cef][device_custom_string_2][label]` |
| `deviceCustomString3` (`cs3`) | `[cef][device_custom_string_3][value]` |
| `deviceCustomString3Label` (`cs3Label`) | `[cef][device_custom_string_3][label]` |
| `deviceCustomString4` (`cs4`) | `[cef][device_custom_string_4][value]` |
| `deviceCustomString4Label` (`cs4Label`) | `[cef][device_custom_string_4][label]` |
| `deviceCustomString5` (`cs5`) | `[cef][device_custom_string_5][value]` |
| `deviceCustomString5Label` (`cs5Label`) | `[cef][device_custom_string_5][label]` |
| `deviceCustomString6` (`cs6`) | `[cef][device_custom_string_6][value]` |
| `deviceCustomString6Label` (`cs6Label`) | `[cef][device_custom_string_6][label]` |
| `deviceCustomString7` (`cs7`) | `[cef][device_custom_string_7][value]` |
| `deviceCustomString7Label` (`cs7Label`) | `[cef][device_custom_string_7][label]` |
| `deviceCustomString8` (`cs8`) | `[cef][device_custom_string_8][value]` |
| `deviceCustomString8Label` (`cs8Label`) | `[cef][device_custom_string_8][label]` |
| `deviceCustomString9` (`cs9`) | `[cef][device_custom_string_9][value]` |
| `deviceCustomString9Label` (`cs9Label`) | `[cef][device_custom_string_9][label]` |
| `deviceCustomString10` (`cs10`) | `[cef][device_custom_string_10][value]` |
| `deviceCustomString10Label` (`cs10Label`) | `[cef][device_custom_string_10][label]` |
| `deviceCustomString11` (`cs11`) | `[cef][device_custom_string_11][value]` |
| `deviceCustomString11Label` (`cs11Label`) | `[cef][device_custom_string_11][label]` |
| `deviceCustomString12` (`cs12`) | `[cef][device_custom_string_12][value]` |
| `deviceCustomString12Label` (`cs12Label`) | `[cef][device_custom_string_12][label]` |
| `deviceCustomString13` (`cs13`) | `[cef][device_custom_string_13][value]` |
| `deviceCustomString13Label` (`cs13Label`) | `[cef][device_custom_string_13][label]` |
| `deviceCustomString14` (`cs14`) | `[cef][device_custom_string_14][value]` |
| `deviceCustomString14Label` (`cs14Label`) | `[cef][device_custom_string_14][label]` |
| `deviceCustomString15` (`cs15`) | `[cef][device_custom_string_15][value]` |
| `deviceCustomString15Label` (`cs15Label`) | `[cef][device_custom_string_15][label]` |
| `deviceDirection` | `[network][direction]` |
| `deviceDnsDomain` | `[observer][registered_domain]`<br>                                                 When plugin configured with `device => observer`. |
| `[host][registered_domain]`<br>                                                 When plugin configured with `device => host`. |
| `deviceEventCategory` (`cat`) | `[cef][category]` |
| `deviceExternalId` | `[observer][name]`<br>                                                 When plugin configured with `device => observer`. |
| `[host][id]`<br>                                                 When plugin configured with `device => host`. |
| `deviceFacility` | `[log][syslog][facility][code]` |
| `deviceHostName` (`dvchost`) | `[observer][hostname]`<br>                                                 When plugin configured with `device => observer`. |
| `[host][name]`<br>                                                 When plugin configured with `device => host`. |
| `deviceInboundInterface` | `[observer][ingress][interface][name]` |
| `deviceMacAddress` (`dvcmac`) | `[observer][mac]`<br>                                                 When plugin configured with `device => observer`. |
| `[host][mac]`<br>                                                 When plugin configured with `device => host`. |
| `deviceNtDomain` | `[cef][nt_domain]` |
| `deviceOutboundInterface` | `[observer][egress][interface][name]` |
| `devicePayloadId` | `[cef][payload_id]` |
| `deviceProcessId` (`dvcpid`) | `[process][pid]` |
| `deviceProcessName` | `[process][name]` |
| `deviceReceiptTime` (`rt`) | `@timestamp`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `deviceTimeZone` (`dtz`) | `[event][timezone]` |
| `deviceTranslatedAddress` | `[host][nat][ip]` |
| `deviceTranslatedZoneExternalID` | `[cef][translated_zone][external_id]` |
| `deviceTranslatedZoneURI` | `[cef][translated_zone][uri]` |
| `deviceVersion` | `[observer][version]` |
| `deviceZoneExternalID` | `[cef][zone][external_id]` |
| `deviceZoneURI` | `[cef][zone][uri]` |
| `endTime` (`end`) | `[event][end]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `eventId` | `[event][id]` |
| `eventOutcome` (`outcome`) | `[event][outcome]` |
| `externalId` | `[cef][external_id]` |
| `fileCreateTime` | `[file][created]` |
| `fileHash` | `[file][hash]` |
| `fileId` | `[file][inode]` |
| `fileModificationTime` | `[file][mtime]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `fileName` (`fname`) | `[file][name]` |
| `filePath` | `[file][path]` |
| `filePermission` | `[file][group]` |
| `fileSize` (`fsize`) | `[file][size]` |
| `fileType` | `[file][extension]` |
| `managerReceiptTime` (`mrt`) | `[event][ingested]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `message` (`msg`) | `[message]` |
| `oldFileCreateTime` | `[cef][old_file][created]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `oldFileHash` | `[cef][old_file][hash]` |
| `oldFileId` | `[cef][old_file][inode]` |
| `oldFileModificationTime` | `[cef][old_file][mtime]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `oldFileName` | `[cef][old_file][name]` |
| `oldFilePath` | `[cef][old_file][path]` |
| `oldFilePermission` | `[cef][old_file][group]` |
| `oldFileSize` | `[cef][old_file][size]` |
| `oldFileType` | `[cef][old_file][extension]` |
| `rawEvent` | `[event][original]` |
| `Reason` (`reason`) | `[event][reason]` |
| `requestClientApplication` | `[user_agent][original]` |
| `requestContext` | `[http][request][referrer]` |
| `requestCookies` | `[cef][request][cookies]` |
| `requestMethod` | `[http][request][method]` |
| `requestUrl` (`request`) | `[url][original]` |
| `sourceAddress` (`src`) | `[source][ip]` |
| `sourceDnsDomain` | `[source][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *higher* priority. |
| `sourceGeoLatitude` (`slat`) | `[source][geo][location][lat]` |
| `sourceGeoLongitude` (`slong`) | `[source][geo][location][lon]` |
| `sourceHostName` (`shost`) | `[source][domain]` |
| `sourceMacAddress` (`smac`) | `[source][mac]` |
| `sourceNtDomain` (`sntdom`) | `[source][registered_domain]`<br>                                                 Multiple possible CEF fields map to this ECS Field. When decoding, the last entry encountered wins. When encoding, this field has *lower* priority. |
| `sourcePort` (`spt`) | `[source][port]` |
| `sourceProcessId` (`spid`) | `[source][process][pid]` |
| `sourceProcessName` (`sproc`) | `[source][process][name]` |
| `sourceServiceName` | `[source][service][name]` |
| `sourceTranslatedAddress` | `[source][nat][ip]` |
| `sourceTranslatedPort` | `[source][nat][port]` |
| `sourceTranslatedZoneExternalID` | `[cef][source][translated_zone][external_id]` |
| `sourceTranslatedZoneURI` | `[cef][source][translated_zone][uri]` |
| `sourceUserId` (`suid`) | `[source][user][id]` |
| `sourceUserName` (`suser`) | `[source][user][name]` |
| `sourceUserPrivileges` (`spriv`) | `[source][user][group][name]` |
| `sourceZoneExternalID` | `[cef][source][zone][external_id]` |
| `sourceZoneURI` | `[cef][source][zone][uri]` |
| `startTime` (`start`) | `[event][start]`<br>                                                 This field contains a timestamp. In ECS Compatibility Mode, it is parsed to a specific point in time. |
| `transportProtocol` (`proto`) | `[network][transport]` |
| `type` | `[cef][type]` |




## Cef Codec Configuration Options [plugins-codecs-cef-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`default_timezone`](#plugins-codecs-cef-default_timezone) | [string](/reference/configuration-file-structure.md#string) | No |
| [`delimiter`](#plugins-codecs-cef-delimiter) | [string](/reference/configuration-file-structure.md#string) | No |
| [`device`](#plugins-codecs-cef-device) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ecs_compatibility`](#plugins-codecs-cef-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`fields`](#plugins-codecs-cef-fields) | [array](/reference/configuration-file-structure.md#array) | No |
| [`locale`](#plugins-codecs-cef-locale) | [string](/reference/configuration-file-structure.md#string) | No |
| [`name`](#plugins-codecs-cef-name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`product`](#plugins-codecs-cef-product) | [string](/reference/configuration-file-structure.md#string) | No |
| [`raw_data_field`](#plugins-codecs-cef-raw_data_field) | [string](/reference/configuration-file-structure.md#string) | No |
| [`reverse_mapping`](#plugins-codecs-cef-reverse_mapping) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`severity`](#plugins-codecs-cef-severity) | [string](/reference/configuration-file-structure.md#string) | No |
| [`signature`](#plugins-codecs-cef-signature) | [string](/reference/configuration-file-structure.md#string) | No |
| [`vendor`](#plugins-codecs-cef-vendor) | [string](/reference/configuration-file-structure.md#string) | No |
| [`version`](#plugins-codecs-cef-version) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `default_timezone` [plugins-codecs-cef-default_timezone]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * [Timezone names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (such as `Europe/Moscow`, `America/Argentina/Buenos_Aires`)
    * UTC Offsets (such as `-08:00`, `+03:00`)

* The default value is your system time zone
* This option has no effect when *encoding*.

When parsing timestamp fields in ECS mode and encountering timestamps that do not contain UTC-offset information, the `deviceTimeZone` (`dtz`) field from the CEF payload is used to interpret the given time. If the event does not include timezone information, this `default_timezone` is used instead.


### `delimiter` [plugins-codecs-cef-delimiter]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

If your input puts a delimiter between each CEF event, you’ll want to set this to be that delimiter.

::::{note}
Byte stream inputs such as TCP require delimiter to be specified. Otherwise input can be truncated or incorrectly split.
::::


**Example**

```ruby
    input {
      tcp {
        codec => cef { delimiter => "\r\n" }
        # ...
      }
    }
```

This setting allows the following character sequences to have special meaning:

* `\\r` (backslash "r") - means carriage return (ASCII 0x0D)
* `\\n` (backslash "n") - means newline (ASCII 0x0A)


### `device` [plugins-codecs-cef-device]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `observer`: indicates that device-specific fields represent the device used to *observe* the event.
    * `host`: indicates that device-specific fields represent the device on which the event *occurred*.

* The default value for this setting is `observer`.
* Option has no effect when [`ecs_compatibility => disabled`](#plugins-codecs-cef-ecs_compatibility).
* Option has no effect when *encoding*

Defines a set of device-specific CEF fields as either representing the device on which an event *occurred*, or merely the device from which the event was *observed*. This causes the relevant fields to be routed to either the `host` or the `observer` top-level groupings.

If the codec handles data from a variety of sources, the ECS recommendation is to use `observer`.


### `ecs_compatibility` [plugins-codecs-cef-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: uses CEF-defined field names in the event (e.g., `bytesIn`, `sourceAddress`)
    * `v1`: supports ECS-compatible event fields (e.g., `[source][bytes]`, `[source][ip]`)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).


### `fields` [plugins-codecs-cef-fields]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, a list of fields can be provided to be included in CEF extensions part as key/value pairs.


### `locale` [plugins-codecs-cef-locale]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * Abbreviated language_COUNTRY format (e.g., `en_GB`, `pt_BR`)
    * Valid [IETF BCP 47](https://tools.ietf.org/html/bcp47) language tag (e.g., `zh-cmn-Hans-CN`)

* The default value is your system locale
* Option has no effect when *encoding*

When parsing timestamp fields in ECS mode and encountering timestamps in a localized format, this `locale` is used to interpret locale-specific strings such as month abbreviations.


### `name` [plugins-codecs-cef-name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Logstash"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the name field in the CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.


### `product` [plugins-codecs-cef-product]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Logstash"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the device product field in CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.


### `raw_data_field` [plugins-codecs-cef-raw_data_field]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting

Store the raw data to the field, for example `[event][original]`. Existing target field will be overriden.


### `reverse_mapping` [plugins-codecs-cef-reverse_mapping]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`
* Option has no effect when *decoding*

Set to true to adhere to the specifications and encode using the CEF key name (short name) for the CEF field names.


### `severity` [plugins-codecs-cef-severity]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"6"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the severity field in CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.

Defined as field of type string to allow sprintf. The value will be validated to be an integer in the range from 0 to 10 (including). All invalid values will be mapped to the default of 6.


### `signature` [plugins-codecs-cef-signature]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Logstash"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the signature ID field in CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.


### `vendor` [plugins-codecs-cef-vendor]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"Elasticsearch"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the device vendor field in CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.


### `version` [plugins-codecs-cef-version]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"1.0"`
* Option has no effect when *decoding*

When this codec is used in an Output Plugin, this option can be used to specify the value of the device version field in CEF header. The new value can include `%{{foo}}` strings to help you build a new value from other parts of the event.
