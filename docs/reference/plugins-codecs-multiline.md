---
navigation_title: "multiline"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-multiline.html
---

# Multiline codec plugin [plugins-codecs-multiline]


* Plugin version: v3.1.2
* Released on: 2024-04-25
* [Changelog](https://github.com/logstash-plugins/logstash-codec-multiline/blob/v3.1.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/codec-multiline-index.md).

## Getting help [_getting_help_192]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-multiline). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_191]

The multiline codec will collapse multiline messages and merge them into a single event.

::::{important}
If you are using a Logstash input plugin that supports multiple hosts, such as the [beats input plugin](/reference/plugins-inputs-beats.md), you should not use the multiline codec to handle multiline events. Doing so may result in the mixing of streams and corrupted event data. In this situation, you need to handle multiline events before sending the event data to Logstash.
::::


The original goal of this codec was to allow joining of multiline messages from files into a single event. For example, joining Java exception and stacktrace messages into a single event.

The config looks like this:

```ruby
    input {
      stdin {
        codec => multiline {
          pattern => "pattern, a regexp"
          negate => "true" or "false"
          what => "previous" or "next"
        }
      }
    }
```

The `pattern` should match what you believe to be an indicator that the field is part of a multi-line event.

The `what` must be `previous` or `next` and indicates the relation to the multi-line event.

The `negate` can be `true` or `false` (defaults to `false`). If `true`, a message not matching the pattern will constitute a match of the multiline filter and the `what` will be applied. (vice-versa is also true)

For example, Java stack traces are multiline and usually have the message starting at the far-left, with each subsequent line indented. Do this:

```ruby
    input {
      stdin {
        codec => multiline {
          pattern => "^\s"
          what => "previous"
        }
      }
    }
```

This says that any line starting with whitespace belongs to the previous line.

Another example is to merge lines not starting with a date up to the previous line..

```ruby
    input {
      file {
        path => "/var/log/someapp.log"
        codec => multiline {
          # Grok pattern names are valid! :)
          pattern => "^%{TIMESTAMP_ISO8601} "
          negate => true
          what => "previous"
        }
      }
    }
```

This says that any line not starting with a timestamp should be merged with the previous line.

One more common example is C line continuations (backslash). Here’s how to do that:

```ruby
    input {
      stdin {
        codec => multiline {
          pattern => "\\$"
          what => "next"
        }
      }
    }
```

This says that any line ending with a backslash should be combined with the following line.


## Multiline codec configuration options [plugins-codecs-multiline-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`auto_flush_interval`](#plugins-codecs-multiline-auto_flush_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`charset`](#plugins-codecs-multiline-charset) | [string](/reference/configuration-file-structure.md#string), one of `["ASCII-8BIT", "UTF-8", "US-ASCII", "Big5", "Big5-HKSCS", "Big5-UAO", "CP949", "Emacs-Mule", "EUC-JP", "EUC-KR", "EUC-TW", "GB2312", "GB18030", "GBK", "ISO-8859-1", "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5", "ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-9", "ISO-8859-10", "ISO-8859-11", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "KOI8-R", "KOI8-U", "Shift_JIS", "UTF-16BE", "UTF-16LE", "UTF-32BE", "UTF-32LE", "Windows-31J", "Windows-1250", "Windows-1251", "Windows-1252", "IBM437", "IBM737", "IBM775", "CP850", "IBM852", "CP852", "IBM855", "CP855", "IBM857", "IBM860", "IBM861", "IBM862", "IBM863", "IBM864", "IBM865", "IBM866", "IBM869", "Windows-1258", "GB1988", "macCentEuro", "macCroatian", "macCyrillic", "macGreek", "macIceland", "macRoman", "macRomania", "macThai", "macTurkish", "macUkraine", "CP950", "CP951", "IBM037", "stateless-ISO-2022-JP", "eucJP-ms", "CP51932", "EUC-JIS-2004", "GB12345", "ISO-2022-JP", "ISO-2022-JP-2", "CP50220", "CP50221", "Windows-1256", "Windows-1253", "Windows-1255", "Windows-1254", "TIS-620", "Windows-874", "Windows-1257", "MacJapanese", "UTF-7", "UTF8-MAC", "UTF-16", "UTF-32", "UTF8-DoCoMo", "SJIS-DoCoMo", "UTF8-KDDI", "SJIS-KDDI", "ISO-2022-JP-KDDI", "stateless-ISO-2022-JP-KDDI", "UTF8-SoftBank", "SJIS-SoftBank", "BINARY", "CP437", "CP737", "CP775", "IBM850", "CP857", "CP860", "CP861", "CP862", "CP863", "CP864", "CP865", "CP866", "CP869", "CP1258", "Big5-HKSCS:2008", "ebcdic-cp-us", "eucJP", "euc-jp-ms", "EUC-JISX0213", "eucKR", "eucTW", "EUC-CN", "eucCN", "CP936", "ISO2022-JP", "ISO2022-JP2", "ISO8859-1", "ISO8859-2", "ISO8859-3", "ISO8859-4", "ISO8859-5", "ISO8859-6", "CP1256", "ISO8859-7", "CP1253", "ISO8859-8", "CP1255", "ISO8859-9", "CP1254", "ISO8859-10", "ISO8859-11", "CP874", "ISO8859-13", "CP1257", "ISO8859-14", "ISO8859-15", "ISO8859-16", "CP878", "MacJapan", "ASCII", "ANSI_X3.4-1968", "646", "CP65000", "CP65001", "UTF-8-MAC", "UTF-8-HFS", "UCS-2BE", "UCS-4BE", "UCS-4LE", "CP932", "csWindows31J", "SJIS", "PCK", "CP1250", "CP1251", "CP1252", "external", "locale"]` | No |
| [`ecs_compatibility`](#plugins-codecs-multiline-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`max_bytes`](#plugins-codecs-multiline-max_bytes) | [bytes](/reference/configuration-file-structure.md#bytes) | No |
| [`max_lines`](#plugins-codecs-multiline-max_lines) | [number](/reference/configuration-file-structure.md#number) | No |
| [`multiline_tag`](#plugins-codecs-multiline-multiline_tag) | [string](/reference/configuration-file-structure.md#string) | No |
| [`negate`](#plugins-codecs-multiline-negate) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`pattern`](#plugins-codecs-multiline-pattern) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`patterns_dir`](#plugins-codecs-multiline-patterns_dir) | [array](/reference/configuration-file-structure.md#array) | No |
| [`what`](#plugins-codecs-multiline-what) | [string](/reference/configuration-file-structure.md#string), one of `["previous", "next"]` | Yes |

 

### `auto_flush_interval` [plugins-codecs-multiline-auto_flush_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

The accumulation of multiple lines will be converted to an event when either a matching new line is seen or there has been no new data appended for this many seconds. No default.  If unset, no auto_flush. Units: seconds


### `charset` [plugins-codecs-multiline-charset]

* Value can be any of: `ASCII-8BIT`, `UTF-8`, `US-ASCII`, `Big5`, `Big5-HKSCS`, `Big5-UAO`, `CP949`, `Emacs-Mule`, `EUC-JP`, `EUC-KR`, `EUC-TW`, `GB2312`, `GB18030`, `GBK`, `ISO-8859-1`, `ISO-8859-2`, `ISO-8859-3`, `ISO-8859-4`, `ISO-8859-5`, `ISO-8859-6`, `ISO-8859-7`, `ISO-8859-8`, `ISO-8859-9`, `ISO-8859-10`, `ISO-8859-11`, `ISO-8859-13`, `ISO-8859-14`, `ISO-8859-15`, `ISO-8859-16`, `KOI8-R`, `KOI8-U`, `Shift_JIS`, `UTF-16BE`, `UTF-16LE`, `UTF-32BE`, `UTF-32LE`, `Windows-31J`, `Windows-1250`, `Windows-1251`, `Windows-1252`, `IBM437`, `IBM737`, `IBM775`, `CP850`, `IBM852`, `CP852`, `IBM855`, `CP855`, `IBM857`, `IBM860`, `IBM861`, `IBM862`, `IBM863`, `IBM864`, `IBM865`, `IBM866`, `IBM869`, `Windows-1258`, `GB1988`, `macCentEuro`, `macCroatian`, `macCyrillic`, `macGreek`, `macIceland`, `macRoman`, `macRomania`, `macThai`, `macTurkish`, `macUkraine`, `CP950`, `CP951`, `IBM037`, `stateless-ISO-2022-JP`, `eucJP-ms`, `CP51932`, `EUC-JIS-2004`, `GB12345`, `ISO-2022-JP`, `ISO-2022-JP-2`, `CP50220`, `CP50221`, `Windows-1256`, `Windows-1253`, `Windows-1255`, `Windows-1254`, `TIS-620`, `Windows-874`, `Windows-1257`, `MacJapanese`, `UTF-7`, `UTF8-MAC`, `UTF-16`, `UTF-32`, `UTF8-DoCoMo`, `SJIS-DoCoMo`, `UTF8-KDDI`, `SJIS-KDDI`, `ISO-2022-JP-KDDI`, `stateless-ISO-2022-JP-KDDI`, `UTF8-SoftBank`, `SJIS-SoftBank`, `BINARY`, `CP437`, `CP737`, `CP775`, `IBM850`, `CP857`, `CP860`, `CP861`, `CP862`, `CP863`, `CP864`, `CP865`, `CP866`, `CP869`, `CP1258`, `Big5-HKSCS:2008`, `ebcdic-cp-us`, `eucJP`, `euc-jp-ms`, `EUC-JISX0213`, `eucKR`, `eucTW`, `EUC-CN`, `eucCN`, `CP936`, `ISO2022-JP`, `ISO2022-JP2`, `ISO8859-1`, `ISO8859-2`, `ISO8859-3`, `ISO8859-4`, `ISO8859-5`, `ISO8859-6`, `CP1256`, `ISO8859-7`, `CP1253`, `ISO8859-8`, `CP1255`, `ISO8859-9`, `CP1254`, `ISO8859-10`, `ISO8859-11`, `CP874`, `ISO8859-13`, `CP1257`, `ISO8859-14`, `ISO8859-15`, `ISO8859-16`, `CP878`, `MacJapan`, `ASCII`, `ANSI_X3.4-1968`, `646`, `CP65000`, `CP65001`, `UTF-8-MAC`, `UTF-8-HFS`, `UCS-2BE`, `UCS-4BE`, `UCS-4LE`, `CP932`, `csWindows31J`, `SJIS`, `PCK`, `CP1250`, `CP1251`, `CP1252`, `external`, `locale`
* Default value is `"UTF-8"`

The character encoding used in this input. Examples include `UTF-8` and `cp1252`

This setting is useful if your log files are in `Latin-1` (aka `cp1252`) or in another character set other than `UTF-8`.

This only affects "plain" format logs since JSON is `UTF-8` already.


### `ecs_compatibility` [plugins-codecs-multiline-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: plugin only sets the `message` field
    * `v1`,`v8`: Elastic Common Schema compliant behavior (`[event][original]` is also added)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://docs/reference/index.md)).


### `max_bytes` [plugins-codecs-multiline-max_bytes]

* Value type is [bytes](/reference/configuration-file-structure.md#bytes)
* Default value is `"10 MiB"`

The accumulation of events can make logstash exit with an out of memory error if event boundaries are not correctly defined. This settings make sure to flush multiline events after reaching a number of bytes, it is used in combination max_lines.


### `max_lines` [plugins-codecs-multiline-max_lines]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `500`

The accumulation of events can make logstash exit with an out of memory error if event boundaries are not correctly defined. This settings make sure to flush multiline events after reaching a number of lines, it is used in combination max_bytes.


### `multiline_tag` [plugins-codecs-multiline-multiline_tag]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"multiline"`

Tag multiline events with a given tag. This tag will only be added to events that actually have multiple lines in them.


### `negate` [plugins-codecs-multiline-negate]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Negate the regexp pattern (*if not matched*).


### `pattern` [plugins-codecs-multiline-pattern]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The regular expression to match.


### `patterns_dir` [plugins-codecs-multiline-patterns_dir]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

Logstash ships by default with a bunch of patterns, so you don’t necessarily need to define this yourself unless you are adding additional patterns.

Pattern files are plain text with format:

```ruby
    NAME PATTERN
```

For example:

```ruby
    NUMBER \d+
```


### `what` [plugins-codecs-multiline-what]

* This is a required setting.
* Value can be any of: `previous`, `next`
* There is no default value for this setting.

If the pattern matched, does event belong to the next or previous event?



