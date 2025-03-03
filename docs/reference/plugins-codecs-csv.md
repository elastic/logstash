---
navigation_title: "csv"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-csv.html
---

# Csv codec plugin [plugins-codecs-csv]


* Plugin version: v1.1.0
* Released on: 2021-07-28
* [Changelog](https://github.com/logstash-plugins/logstash-codec-csv/blob/v1.1.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-csv-index.md).

## Installation [_installation_68]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-codec-csv`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_177]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-csv). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_176]

The csv codec takes CSV data, parses it and passes it along.


## Compatibility with the Elastic Common Schema (ECS) [plugins-codecs-csv-ecs]

The plugin behaves the same regardless of ECS compatibility, except giving a warning when ECS is enabled and `target` isn’t set.

::::{tip}
Set the `target` option to avoid potential schema conflicts.
::::



## Csv Codec configuration options [plugins-codecs-csv-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`autodetect_column_names`](#plugins-codecs-csv-autodetect_column_names) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`autogenerate_column_names`](#plugins-codecs-csv-autogenerate_column_names) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`charset`](#plugins-codecs-csv-charset) | [string](/reference/configuration-file-structure.md#string), one of `["ASCII-8BIT", "UTF-8", "US-ASCII", "Big5", "Big5-HKSCS", "Big5-UAO", "CP949", "Emacs-Mule", "EUC-JP", "EUC-KR", "EUC-TW", "GB2312", "GB18030", "GBK", "ISO-8859-1", "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-9", "ISO-8859-10", "ISO-8859-11", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "KOI8-R", "KOI8-U", "Shift_JIS", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE", "Windows-31J", "Windows-1250", "Windows-1251", "Windows-1252", "IBM437", "IBM737", "IBM775", "CP850", "IBM852", "CP852", "IBM855", "CP855", "IBM857", "IBM860", "IBM861", "IBM862", "IBM863", "IBM864", "IBM865", "IBM866", "IBM869", "Windows-1258", "GB1988", "macCentEuro", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macThai", "macTurkish", "macUkraine", "CP950", "CP951", "IBM037", "stateless-ISO-2022-JP", "eucJP-ms", "CP51932", "EUC-JIS-2004", "GB12345", "ISO-2022-JP", "ISO-2022-JP-2", "CP50220", "CP50221", "Windows-1256", "Windows-1253", "Windows-1255", "Windows-1254", "TIS-620", "Windows-874", "Windows-1257", "MacJapanese", "UTF-7", "UTF8-MAC", "UTF-16", "UTF-32", "UTF8-DoCoMo", "SJIS-DoCoMo", "UTF8-KDDI", "SJIS-KDDI", "ISO-2022-JP-KDDI", "stateless-ISO-2022-JP-KDDI", "UTF8-SoftBank", "SJIS-SoftBank", "BINARY", "CP437", "CP737", "CP775", "IBM850", "CP857", "CP860", "CP861", "CP862", "CP863", "CP864", "CP865", "CP866", "CP869", "CP1258", "Big5-HKSCS:2008", "ebcdic-cp-us", "eucJP", "euc-jp-ms", "EUC-JISX0213", "eucKR", "eucTW", "EUC-CN", "eucCN", "CP936", "ISO2022-JP", "ISO2022-JP2", "ISO8859-1", "ISO8859-2", "ISO8859-3", "ISO8859-4", "ISO8859-5", "ISO8859-6", "CP1256", "ISO8859-7", "CP1253", "ISO8859-8", "CP1255", "ISO8859-9", "CP1254", "ISO8859-10", "ISO8859-11", "CP874", "ISO8859-13", "CP1257", "ISO8859-14", "ISO8859-15", "ISO8859-16", "CP878", "MacJapan", "ASCII", "ANSI_X3.4-1968", "646", "CP65000", "CP65001", "UTF-8-MAC", "UTF-8-HFS", "UCS-2BE", "UCS-4BE", "UCS-4LE", "CP932", "csWindows31J", "SJIS", "PCK", "CP1250", "CP1251", "CP1252", "external", "locale"]` | No |
| [`columns`](#plugins-codecs-csv-columns) | [array](/reference/configuration-file-structure.md#array) | No |
| [`convert`](#plugins-codecs-csv-convert) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`ecs_compatibility`](#plugins-codecs-csv-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_headers`](#plugins-codecs-csv-include_headers) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`quote_char`](#plugins-codecs-csv-quote_char) | [string](/reference/configuration-file-structure.md#string) | No |
| [`separator`](#plugins-codecs-csv-separator) | [string](/reference/configuration-file-structure.md#string) | No |
| [`skip_empty_columns`](#plugins-codecs-csv-skip_empty_columns) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-codecs-csv-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `autodetect_column_names` [plugins-codecs-csv-autodetect_column_names]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Define whether column names should be auto-detected from the header column or not. Defaults to false.


### `autogenerate_column_names` [plugins-codecs-csv-autogenerate_column_names]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Define whether column names should be autogenerated or not. Defaults to true. If set to false, columns not having a header specified will not be parsed.


### `charset` [plugins-codecs-csv-charset]

* Value can be any of: `ASCII-8BIT`, `UTF-8`, `US-ASCII`, `Big5`, `Big5-HKSCS`, `Big5-UAO`, `CP949`, `Emacs-Mule`, `EUC-JP`, `EUC-KR`, `EUC-TW`, `GB2312`, `GB18030`, `GBK`, `ISO-8859-1`, `ISO-8859-2`, `ISO-8859-3`, `ISO-8859-4`, `ISO-8859-5`, `ISO-8859-6`, `ISO-8859-7`, `ISO-8859-8`, `ISO-8859-9`, `ISO-8859-10`, `ISO-8859-11`, `ISO-8859-13`, `ISO-8859-14`, `ISO-8859-15`, `ISO-8859-16`, `KOI8-R`, `KOI8-U`, `Shift_JIS`, `UTF-16BE`, `UTF-16LE`, `UTF-32BE`, `UTF-32LE`, `Windows-31J`, `Windows-1250`, `Windows-1251`, `Windows-1252`, `IBM437`, `IBM737`, `IBM775`, `CP850`, `IBM852`, `CP852`, `IBM855`, `CP855`, `IBM857`, `IBM860`, `IBM861`, `IBM862`, `IBM863`, `IBM864`, `IBM865`, `IBM866`, `IBM869`, `Windows-1258`, `GB1988`, `macCentEuro`, `macCroatian`, `macCyrillic`, `macGreek`, `macIceland`, `macRoman`, `macRomania`, `macThai`, `macTurkish`, `macUkraine`, `CP950`, `CP951`, `IBM037`, `stateless-ISO-2022-JP`, `eucJP-ms`, `CP51932`, `EUC-JIS-2004`, `GB12345`, `ISO-2022-JP`, `ISO-2022-JP-2`, `CP50220`, `CP50221`, `Windows-1256`, `Windows-1253`, `Windows-1255`, `Windows-1254`, `TIS-620`, `Windows-874`, `Windows-1257`, `MacJapanese`, `UTF-7`, `UTF8-MAC`, `UTF-16`, `UTF-32`, `UTF8-DoCoMo`, `SJIS-DoCoMo`, `UTF8-KDDI`, `SJIS-KDDI`, `ISO-2022-JP-KDDI`, `stateless-ISO-2022-JP-KDDI`, `UTF8-SoftBank`, `SJIS-SoftBank`, `BINARY`, `CP437`, `CP737`, `CP775`, `IBM850`, `CP857`, `CP860`, `CP861`, `CP862`, `CP863`, `CP864`, `CP865`, `CP866`, `CP869`, `CP1258`, `Big5-HKSCS:2008`, `ebcdic-cp-us`, `eucJP`, `euc-jp-ms`, `EUC-JISX0213`, `eucKR`, `eucTW`, `EUC-CN`, `eucCN`, `CP936`, `ISO2022-JP`, `ISO2022-JP2`, `ISO8859-1`, `ISO8859-2`, `ISO8859-3`, `ISO8859-4`, `ISO8859-5`, `ISO8859-6`, `CP1256`, `ISO8859-7`, `CP1253`, `ISO8859-8`, `CP1255`, `ISO8859-9`, `CP1254`, `ISO8859-10`, `ISO8859-11`, `CP874`, `ISO8859-13`, `CP1257`, `ISO8859-14`, `ISO8859-15`, `ISO8859-16`, `CP878`, `MacJapan`, `ASCII`, `ANSI_X3.4-1968`, `646`, `CP65000`, `CP65001`, `UTF-8-MAC`, `UTF-8-HFS`, `UCS-2BE`, `UCS-4BE`, `UCS-4LE`, `CP932`, `csWindows31J`, `SJIS`, `PCK`, `CP1250`, `CP1251`, `CP1252`, `external`, `locale`
* Default value is `"UTF-8"`

List of valid conversion types used for the convert option The character encoding used in this codec. Examples include "UTF-8" and "CP1252".


### `columns` [plugins-codecs-csv-columns]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

**When decoding:** Define a list of column names (in the order they appear in the CSV, as if it were a header line). If `columns` is not configured, or there are not enough columns specified, the default column names are "column1", "column2", etc.

**When encoding:** List of fields names to include in the encoded CSV, in the order listed.


### `convert` [plugins-codecs-csv-convert]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Define a set of datatype conversions to be applied to columns. Possible conversions are: `integer`, `float`, `date`, `date_time`, `boolean`

**Example**

```ruby
    filter {
      csv {
        convert => { "column1" => "integer", "column2" => "boolean" }
      }
    }
```


### `ecs_compatibility` [plugins-codecs-csv-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: CSV data added at root level
    * `v1`,`v8`: Elastic Common Schema compliant behavior (`[event][original]` is also added)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).


### `include_headers` [plugins-codecs-csv-include_headers]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When **encoding** in an output plugin, include headers in the encoded CSV once per codec lifecyle (not for every event). Default ⇒ false


### `quote_char` [plugins-codecs-csv-quote_char]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"\""`

Define the character used to quote CSV fields. If this is not specified the default is a double quote `"`. Optional.


### `separator` [plugins-codecs-csv-separator]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `","`

Define the column separator value. If this is not specified, the default is a comma `,`. Optional.


### `skip_empty_columns` [plugins-codecs-csv-skip_empty_columns]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Define whether empty columns should be skipped. Defaults to false. If set to true, columns containing no value will not be included.


### `target` [plugins-codecs-csv-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field for placing the row values. If this setting is not set, the CSV data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
    input {
      file {
        codec => csv {
          autodetect_column_names => true
          target => "[document]"
        }
      }
    }
```
