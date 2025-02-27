---
navigation_title: "date"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html
---

# Date filter plugin [plugins-filters-date]


* Plugin version: v3.1.15
* Released on: 2022-06-29
* [Changelog](https://github.com/logstash-plugins/logstash-filter-date/blob/v3.1.15/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://docs/reference/filter-date-index.md).

## Getting help [_getting_help_131]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-filter-date). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_130]

The date filter is used for parsing dates from fields, and then using that date or timestamp as the logstash timestamp for the event.

For example, syslog events usually have timestamps like this:

```ruby
    "Apr 17 09:32:01"
```

You would use the date format `MMM dd HH:mm:ss` to parse this.

The date filter is especially important for sorting events and for backfilling old data. If you don’t get the date correct in your event, then searching for them later will likely sort out of order.

In the absence of this filter, logstash will choose a timestamp based on the first time it sees the event (at input time), if the timestamp is not already set in the event. For example, with file input, the timestamp is set to the time of each read.


## Date Filter Configuration Options [plugins-filters-date-options]

This plugin supports the following configuration options plus the [Common options](#plugins-filters-date-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`locale`](#plugins-filters-date-locale) | [string](/reference/configuration-file-structure.md#string) | No |
| [`match`](#plugins-filters-date-match) | [array](/reference/configuration-file-structure.md#array) | No |
| [`tag_on_failure`](#plugins-filters-date-tag_on_failure) | [array](/reference/configuration-file-structure.md#array) | No |
| [`target`](#plugins-filters-date-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`timezone`](#plugins-filters-date-timezone) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-filters-date-common-options) for a list of options supported by all filter plugins.

 

### `locale` [plugins-filters-date-locale]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Specify a locale to be used for date parsing using either IETF-BCP47 or POSIX language tag. Simple examples are `en`,`en-US` for BCP47 or `en_US` for POSIX.

The locale is mostly necessary to be set for parsing month names (pattern with `MMM`) and weekday names (pattern with `EEE`).

If not specified, the platform default will be used but for non-english platform default an english parser will also be used as a fallback mechanism.


### `match` [plugins-filters-date-match]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

An array with field name first, and format patterns following, `[ field, formats... ]`

If your time field has multiple possible formats, you can do this:

```ruby
    match => [ "logdate", "MMM dd yyyy HH:mm:ss",
              "MMM  d yyyy HH:mm:ss", "ISO8601" ]
```

The above will match a syslog (rfc3164) or `iso8601` timestamp.

There are a few special exceptions. The following format literals exist to help you save time and ensure correctness of date parsing.

* `ISO8601` - should parse any valid ISO8601 timestamp, such as `2011-04-19T03:44:01.103Z`
* `UNIX` - will parse **float or int** value expressing unix time in seconds since epoch like 1326149001.132 as well as 1326149001
* `UNIX_MS` - will parse **int** value expressing unix time in milliseconds since epoch like 1366125117000
* `TAI64N` - will parse tai64n time values

For example, if you have a field `logdate`, with a value that looks like `Aug 13 2010 00:03:44`, you would use this configuration:

```ruby
    filter {
      date {
        match => [ "logdate", "MMM dd yyyy HH:mm:ss" ]
      }
    }
```

If your field is nested in your structure, you can use the nested syntax `[foo][bar]` to match its value. For more information, please refer to [Field references](/reference/event-dependent-configuration.md#logstash-config-field-references)

**More details on the syntax**

The syntax used for parsing date and time text uses letters to indicate the kind of time value (month, minute, etc), and a repetition of letters to indicate the form of that value (2-digit month, full month name, etc).

Here’s what you can use to parse dates and times:

y
:   year

    yyyy
    :   full year number. Example: `2015`.

    yy
    :   two-digit year. Example: `15` for the year 2015.


M
:   month of the year

    M
    :   minimal-digit month. Example: `1` for January and `12` for December.

    MM
    :   two-digit month. zero-padded if needed. Example: `01` for January  and `12` for December

    MMM
    :   abbreviated month text. Example: `Jan` for January. Note: The language used depends on your locale. See the `locale` setting for how to change the language.

    MMMM
    :   full month text, Example: `January`. Note: The language used depends on your locale.


d
:   day of the month

    d
    :   minimal-digit day. Example: `1` for the 1st of the month.

    dd
    :   two-digit day, zero-padded if needed. Example: `01` for the 1st of the month.


H
:   hour of the day (24-hour clock)

    H
    :   minimal-digit hour. Example: `0` for midnight.

    HH
    :   two-digit hour, zero-padded if needed. Example: `00` for midnight.


m
:   minutes of the hour (60 minutes per hour)

    m
    :   minimal-digit minutes. Example: `0`.

    mm
    :   two-digit minutes, zero-padded if needed. Example: `00`.


s
:   seconds of the minute (60 seconds per minute)

    s
    :   minimal-digit seconds. Example: `0`.

    ss
    :   two-digit seconds, zero-padded if needed. Example: `00`.


S
:   fraction of a second **Maximum precision is milliseconds (`SSS`). Beyond that, zeroes are appended.**

    S
    :   tenths of a second. Example:  `0` for a subsecond value `012`

    SS
    :   hundredths of a second. Example:  `01` for a subsecond value `01`

    SSS
    :   thousandths of a second. Example:  `012` for a subsecond value `012`


Z
:   time zone offset or identity

    Z
    :   Timezone offset structured as HHmm (hour and minutes offset from Zulu/UTC). Example: `-0700`.

    ZZ
    :   Timezone offset structured as HH:mm (colon in between hour and minute offsets). Example: `-07:00`.

    ZZZ
    :   Timezone identity. Example: `America/Los_Angeles`. Note: Valid IDs are listed on the [Joda.org available time zones page](http://joda-time.sourceforge.net/timezones.md).


z
:   time zone names. **Time zone names (*z*) cannot be parsed.**

w
:   week of the year

    w
    :   minimal-digit week. Example: `1`.

    ww
    :   two-digit week, zero-padded if needed. Example: `01`.


D
:   day of the year

e
:   day of the week (number)

E
:   day of the week (text)

    E, EE, EEE
    :   Abbreviated day of the week. Example:  `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`. Note: The actual language of this will depend on your locale.

    EEEE
    :   The full text day of the week. Example: `Monday`, `Tuesday`, …​ Note: The actual language of this will depend on your locale.


For non-formatting syntax, you’ll need to put single-quote characters around the value. For example, if you were parsing ISO8601 time, "2015-01-01T01:12:23" that little "T" isn’t a valid time format, and you want to say "literally, a T", your format would be this: "yyyy-MM-dd’T’HH:mm:ss"

Other less common date units, such as era (G), century (C), am/pm (a), and # more, can be learned about on the [joda-time documentation](http://www.joda.org/joda-time/key_format.md).


### `tag_on_failure` [plugins-filters-date-tag_on_failure]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `["_dateparsefailure"]`

Append values to the `tags` field when there has been no successful match


### `target` [plugins-filters-date-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"@timestamp"`

Store the matching timestamp into the given target field.  If not provided, default to updating the `@timestamp` field of the event.


### `timezone` [plugins-filters-date-timezone]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Specify a time zone canonical ID to be used for date parsing. The valid IDs are listed on the [Joda.org available time zones page](http://joda-time.sourceforge.net/timezones.md). This is useful in case the time zone cannot be extracted from the value, and is not the platform default. If this is not specified the platform default will be used. Canonical ID is good as it takes care of daylight saving time for you For example, `America/Los_Angeles` or `Europe/Paris` are valid IDs. This field can be dynamic and include parts of the event using the `%{{field}}` syntax



## Common options [plugins-filters-date-common-options]

These configuration options are supported by all filter plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-filters-date-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`add_tag`](#plugins-filters-date-add_tag) | [array](/reference/configuration-file-structure.md#array) | No |
| [`enable_metric`](#plugins-filters-date-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-filters-date-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`periodic_flush`](#plugins-filters-date-periodic_flush) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`remove_field`](#plugins-filters-date-remove_field) | [array](/reference/configuration-file-structure.md#array) | No |
| [`remove_tag`](#plugins-filters-date-remove_tag) | [array](/reference/configuration-file-structure.md#array) | No |

### `add_field` [plugins-filters-date-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

If this filter is successful, add any arbitrary fields to this event. Field names can be dynamic and include parts of the event using the `%{{field}}`.

Example:

```json
    filter {
      date {
        add_field => { "foo_%{somefield}" => "Hello world, from %{host}" }
      }
    }
```

```json
    # You can also add multiple fields at once:
    filter {
      date {
        add_field => {
          "foo_%{somefield}" => "Hello world, from %{host}"
          "new_field" => "new_static_value"
        }
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add field `foo_hello` if it is present, with the value above and the `%{{host}}` piece replaced with that value from the event. The second example would also add a hardcoded field.


### `add_tag` [plugins-filters-date-add_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, add arbitrary tags to the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      date {
        add_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also add multiple tags at once:
    filter {
      date {
        add_tag => [ "foo_%{somefield}", "taggedy_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would add a tag `foo_hello` (and the second example would of course add a `taggedy_tag` tag).


### `enable_metric` [plugins-filters-date-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance. By default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-filters-date-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 date filters. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
    filter {
      date {
        id => "ABC"
      }
    }
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `periodic_flush` [plugins-filters-date-periodic_flush]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Call the filter flush method at regular interval. Optional.


### `remove_field` [plugins-filters-date-remove_field]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary fields from this event. Fields names can be dynamic and include parts of the event using the `%{{field}}` Example:

```json
    filter {
      date {
        remove_field => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple fields at once:
    filter {
      date {
        remove_field => [ "foo_%{somefield}", "my_extraneous_field" ]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the field with name `foo_hello` if it is present. The second example would remove an additional, non-dynamic field.


### `remove_tag` [plugins-filters-date-remove_tag]

* Value type is [array](/reference/configuration-file-structure.md#array)
* Default value is `[]`

If this filter is successful, remove arbitrary tags from the event. Tags can be dynamic and include parts of the event using the `%{{field}}` syntax.

Example:

```json
    filter {
      date {
        remove_tag => [ "foo_%{somefield}" ]
      }
    }
```

```json
    # You can also remove multiple tags at once:
    filter {
      date {
        remove_tag => [ "foo_%{somefield}", "sad_unwanted_tag"]
      }
    }
```

If the event has field `"somefield" == "hello"` this filter, on success, would remove the tag `foo_hello` if it is present. The second example would remove a sad, unwanted tag as well.
