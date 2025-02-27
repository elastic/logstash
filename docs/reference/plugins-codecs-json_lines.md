---
navigation_title: "json_lines"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-json_lines.html
---

# Json_lines codec plugin [plugins-codecs-json_lines]


* Plugin version: v3.2.2
* Released on: 2024-09-06
* [Changelog](https://github.com/logstash-plugins/logstash-codec-json_lines/blob/v3.2.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-json_lines-index.md).

## Getting help [_getting_help_189]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-json_lines). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_188]

This codec will decode streamed JSON that is newline delimited. Encoding will emit a single JSON string ending in a `@delimiter` NOTE: Do not use this codec if your source input is line-oriented JSON, for example, redis or file inputs. Rather, use the json codec. More info: This codec is expecting to receive a stream (string) of newline terminated lines. The file input will produce a line string without a newline. Therefore this codec cannot work with line oriented inputs.


## Json_lines Codec Configuration Options [plugins-codecs-json_lines-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`charset`](#plugins-codecs-json_lines-charset) | [string](/reference/configuration-file-structure.md#string), one of `["ASCII-8BIT", "UTF-8", "US-ASCII", "Big5", "Big5-HKSCS", "Big5-UAO", "CP949", "Emacs-Mule", "EUC-JP", "EUC-KR", "EUC-TW", "GB2312", "GB18030", "GBK", "ISO-8859-1", "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-9", "ISO-8859-10", "ISO-8859-11", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "KOI8-R", "KOI8-U", "Shift_JIS", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE", "Windows-31J", "Windows-1250", "Windows-1251", "Windows-1252", "IBM437", "IBM737", "IBM775", "CP850", "IBM852", "CP852", "IBM855", "CP855", "IBM857", "IBM860", "IBM861", "IBM862", "IBM863", "IBM864", "IBM865", "IBM866", "IBM869", "Windows-1258", "GB1988", "macCentEuro", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macThai", "macTurkish", "macUkraine", "CP950", "CP951", "IBM037", "stateless-ISO-2022-JP", "eucJP-ms", "CP51932", "EUC-JIS-2004", "GB12345", "ISO-2022-JP", "ISO-2022-JP-2", "CP50220", "CP50221", "Windows-1256", "Windows-1253", "Windows-1255", "Windows-1254", "TIS-620", "Windows-874", "Windows-1257", "MacJapanese", "UTF-7", "UTF8-MAC", "UTF-16", "UTF-32", "UTF8-DoCoMo", "SJIS-DoCoMo", "UTF8-KDDI", "SJIS-KDDI", "ISO-2022-JP-KDDI", "stateless-ISO-2022-JP-KDDI", "UTF8-SoftBank", "SJIS-SoftBank", "BINARY", "CP437", "CP737", "CP775", "IBM850", "CP857", "CP860", "CP861", "CP862", "CP863", "CP864", "CP865", "CP866", "CP869", "CP1258", "Big5-HKSCS:2008", "ebcdic-cp-us", "eucJP", "euc-jp-ms", "EUC-JISX0213", "eucKR", "eucTW", "EUC-CN", "eucCN", "CP936", "ISO2022-JP", "ISO2022-JP2", "ISO8859-1", "ISO8859-2", "ISO8859-3", "ISO8859-4", "ISO8859-5", "ISO8859-6", "CP1256", "ISO8859-7", "CP1253", "ISO8859-8", "CP1255", "ISO8859-9", "CP1254", "ISO8859-10", "ISO8859-11", "CP874", "ISO8859-13", "CP1257", "ISO8859-14", "ISO8859-15", "ISO8859-16", "CP878", "MacJapan", "ASCII", "ANSI_X3.4-1968", "646", "CP65000", "CP65001", "UTF-8-MAC", "UTF-8-HFS", "UCS-2BE", "UCS-4BE", "UCS-4LE", "CP932", "csWindows31J", "SJIS", "PCK", "CP1250", "CP1251", "CP1252", "external", "locale"]` | No |
| [`decode_size_limit_bytes`](#plugins-codecs-json_lines-decode_size_limit_bytes) | [string](/reference/configuration-file-structure.md#string) | No |
| [`delimiter`](#plugins-codecs-json_lines-delimiter) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ecs_compatibility`](#plugins-codecs-json_lines-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`target`](#plugins-codecs-json_lines-target) | [string](/reference/configuration-file-structure.md#string) | No |

 

### `charset` [plugins-codecs-json_lines-charset]

* Value can be any of: `ASCII-8BIT`, `UTF-8`, `US-ASCII`, `Big5`, `Big5-HKSCS`, `Big5-UAO`, `CP949`, `Emacs-Mule`, `EUC-JP`, `EUC-KR`, `EUC-TW`, `GB2312`, `GB18030`, `GBK`, `ISO-8859-1`, `ISO-8859-2`, `ISO-8859-3`, `ISO-8859-4`, `ISO-8859-5`, `ISO-8859-6`, `ISO-8859-7`, `ISO-8859-8`, `ISO-8859-9`, `ISO-8859-10`, `ISO-8859-11`, `ISO-8859-13`, `ISO-8859-14`, `ISO-8859-15`, `ISO-8859-16`, `KOI8-R`, `KOI8-U`, `Shift_JIS`, `UTF-16BE`, `UTF-16LE`, `UTF-32BE`, `UTF-32LE`, `Windows-31J`, `Windows-1250`, `Windows-1251`, `Windows-1252`, `IBM437`, `IBM737`, `IBM775`, `CP850`, `IBM852`, `CP852`, `IBM855`, `CP855`, `IBM857`, `IBM860`, `IBM861`, `IBM862`, `IBM863`, `IBM864`, `IBM865`, `IBM866`, `IBM869`, `Windows-1258`, `GB1988`, `macCentEuro`, `macCroatian`, `macCyrillic`, `macGreek`, `macIceland`, `macRoman`, `macRomania`, `macThai`, `macTurkish`, `macUkraine`, `CP950`, `CP951`, `IBM037`, `stateless-ISO-2022-JP`, `eucJP-ms`, `CP51932`, `EUC-JIS-2004`, `GB12345`, `ISO-2022-JP`, `ISO-2022-JP-2`, `CP50220`, `CP50221`, `Windows-1256`, `Windows-1253`, `Windows-1255`, `Windows-1254`, `TIS-620`, `Windows-874`, `Windows-1257`, `MacJapanese`, `UTF-7`, `UTF8-MAC`, `UTF-16`, `UTF-32`, `UTF8-DoCoMo`, `SJIS-DoCoMo`, `UTF8-KDDI`, `SJIS-KDDI`, `ISO-2022-JP-KDDI`, `stateless-ISO-2022-JP-KDDI`, `UTF8-SoftBank`, `SJIS-SoftBank`, `BINARY`, `CP437`, `CP737`, `CP775`, `IBM850`, `CP857`, `CP860`, `CP861`, `CP862`, `CP863`, `CP864`, `CP865`, `CP866`, `CP869`, `CP1258`, `Big5-HKSCS:2008`, `ebcdic-cp-us`, `eucJP`, `euc-jp-ms`, `EUC-JISX0213`, `eucKR`, `eucTW`, `EUC-CN`, `eucCN`, `CP936`, `ISO2022-JP`, `ISO2022-JP2`, `ISO8859-1`, `ISO8859-2`, `ISO8859-3`, `ISO8859-4`, `ISO8859-5`, `ISO8859-6`, `CP1256`, `ISO8859-7`, `CP1253`, `ISO8859-8`, `CP1255`, `ISO8859-9`, `CP1254`, `ISO8859-10`, `ISO8859-11`, `CP874`, `ISO8859-13`, `CP1257`, `ISO8859-14`, `ISO8859-15`, `ISO8859-16`, `CP878`, `MacJapan`, `ASCII`, `ANSI_X3.4-1968`, `646`, `CP65000`, `CP65001`, `UTF-8-MAC`, `UTF-8-HFS`, `UCS-2BE`, `UCS-4BE`, `UCS-4LE`, `CP932`, `csWindows31J`, `SJIS`, `PCK`, `CP1250`, `CP1251`, `CP1252`, `external`, `locale`
* Default value is `"UTF-8"`

The character encoding used in this codec. Examples include `UTF-8` and `CP1252`

JSON requires valid `UTF-8` strings, but in some cases, software that emits JSON does so in another encoding (nxlog, for example). In weird cases like this, you can set the charset setting to the actual encoding of the text and logstash will convert it for you.

For nxlog users, you’ll want to set this to `CP1252`


### `decode_size_limit_bytes` [plugins-codecs-json_lines-decode_size_limit_bytes]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is 512 MB

Maximum number of bytes for a single line before stop processing.


### `delimiter` [plugins-codecs-json_lines-delimiter]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"\n"`

Change the delimiter that separates lines


### `ecs_compatibility` [plugins-codecs-json_lines-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names
    * `v1`, `v8`: Elastic Common Schema compliant behavior (warns when `target` isn’t set)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).


### `target` [plugins-codecs-json_lines-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Define the target field for placing the parsed data. If this setting is not set, the JSON data will be stored at the root (top level) of the event.

For example, if you want data to be put under the `document` field:

```ruby
    input {
      http {
        codec => json_lines {
          target => "[document]"
        }
      }
    }
```



