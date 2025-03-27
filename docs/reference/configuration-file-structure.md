---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/configuration-file-structure.html
---

# Structure of a pipeline [configuration-file-structure]

A {{ls}} pipeline config file has a separate section for each type of plugin you want to add to the event processing pipeline. For example:

```js
# This is a comment. You should use comments to describe
# parts of your configuration.
input {
  ...
}

filter {
  ...
}

output {
  ...
}
```

Each section contains configuration options for one or more plugins. If you specify multiple filters, they are applied in the order they appear in the configuration file. If you specify multiple outputs, events are sent to each destination sequentially, in the order they appear in the configuration file.

::::{tip}
When you are ready to deploy a pipeline beyond your local machine, add the pipeline config file to [`logstash.yml`](/reference/logstash-settings-file.md) using the `pipeline.id` setting. When you are ready to deploy [multiple pipelines](/reference/multiple-pipelines.md), set up and configure your pipelines in the `pipelines.yml` file.
::::



## Plugin configuration [plugin_configuration]

A plugin configuration consists of the plugin name followed by a block of settings for that plugin. For example, this input section configures two file inputs:

```js
input {
  http {
    port => 3333
    tags => gateway
  }
  http {
    port => 4444
    tags => billing
  }
}
```

In this example, two settings are configured for each of the file inputs: *port* and *tags*.

The settings you can configure vary according to the plugin type. For information about each plugin, see [Input Plugins](logstash-docs-md://lsr/input-plugins.md), [Output Plugins](logstash-docs-md://lsr/output-plugins.md), [Filter Plugins](logstash-docs-md://lsr/filter-plugins.md), and [Codec Plugins](logstash-docs-md://lsr/codec-plugins.md).


## Value types [plugin-value-types]

A plugin can require that the value for a setting be a certain type, such as boolean, list, or hash. The following value types are supported.

## Array [array]

This type is now mostly deprecated in favor of using a standard type like `string` with the plugin defining the `:list => true` property for better type checking. It is still needed to handle lists of hashes or mixed types where type checking is not desired.

Example:

```js
  users => [ {id => 1, name => bob}, {id => 2, name => jane} ]
```


### Lists [list]

Not a type in and of itself, but a property types can have. This makes it possible to type check multiple values. Plugin authors can enable list checking by specifying `:list => true` when declaring an argument.

Example:

```js
  path => [ "/var/log/messages", "/var/log/*.log" ]
  uris => [ "http://elastic.co", "http://example.net" ]
```

This example configures `path`, which is a `string` to be a list that contains an element for each of the three strings. It also will configure the `uris` parameter to be a list of URIs, failing if any of the URIs provided are not valid.


### Boolean [boolean]

A boolean must be either `true` or `false`. Note that the `true` and `false` keywords are not enclosed in quotes.

Example:

```js
  ssl_enable => true
```


### Bytes [bytes]

A bytes field is a string field that represents a valid unit of bytes. It is a convenient way to declare specific sizes in your plugin options. Both SI (k M G T P E Z Y) and Binary (Ki Mi Gi Ti Pi Ei Zi Yi) units are supported. Binary units are in base-1024 and SI units are in base-1000. This field is case-insensitive and accepts space between the value and the unit. If no unit is specified, the integer string represents the number of bytes.

Examples:

```js
  my_bytes => "1113"   # 1113 bytes
  my_bytes => "10MiB"  # 10485760 bytes
  my_bytes => "100kib" # 102400 bytes
  my_bytes => "180 mb" # 180000000 bytes
```


### Codec [codec]

A codec is the name of Logstash codec used to represent the data. Codecs can be used in both inputs and outputs.

Input codecs provide a convenient way to decode your data before it enters the input. Output codecs provide a convenient way to encode your data before it leaves the output. Using an input or output codec eliminates the need for a separate filter in your Logstash pipeline.

A list of available codecs can be found at the [Codec Plugins](logstash-docs-md://lsr/codec-plugins.md) page.

Example:

```js
  codec => "json"
```


### Hash [hash]

A hash is a collection of key value pairs specified in the format `"field1" => "value1"`. Note that multiple key value entries are separated by spaces rather than commas.

Example:

```js
match => {
  "field1" => "value1"
  "field2" => "value2"
  ...
}
# or as a single line. No commas between entries:
match => { "field1" => "value1" "field2" => "value2" }
```


### Number [number]

Numbers must be valid numeric values (floating point or integer).

Example:

```js
  port => 33
```


### Password [password]

A password is a string with a single value that is not logged or printed.

Example:

```js
  my_password => "password"
```


### URI [uri]

A URI can be anything from a full URL like *http://elastic.co/* to a simple identifier like *foobar*. If the URI contains a password such as *http://user:pass@example.net* the password portion of the URI will not be logged or printed.

Example:

```js
  my_uri => "http://foo:bar@example.net"
```


### Path [path]

A path is a string that represents a valid operating system path.

Example:

```js
  my_path => "/tmp/logstash"
```


### String [string]

A string must be a single character sequence. Note that string values are enclosed in quotes, either double or single.

### Escape sequences [_escape_sequences]

By default, escape sequences are not enabled. If you wish to use escape sequences in quoted strings, you will need to set `config.support_escapes: true` in your `logstash.yml`. When `true`, quoted strings (double and single) will have this transformation:

|     |     |
| --- | --- |
| Text | Result |
| \r | carriage return (ASCII 13) |
| \n | new line (ASCII 10) |
| \t | tab (ASCII 9) |
| \\ | backslash (ASCII 92) |
| \" | double quote (ASCII 34) |
| \' | single quote (ASCII 39) |

Example:

```js
  name => "Hello world"
  name => 'It\'s a beautiful day'
```


### Field reference [field-reference]

A Field Reference is a special [String](#string) value representing the path to a field in an event, such as `@timestamp` or `[@timestamp]` to reference a top-level field, or `[client][ip]` to access a nested field. The [*Field References Deep Dive*](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html) provides detailed information about the structure of Field References. When provided as a configuration option, Field References need to be quoted and special characters must be escaped following the same rules as [String](#string).


## Comments [comments]

Comments are the same as in perl, ruby, and python. A comment starts with a *#* character, and does not need to be at the beginning of a line. For example:

```js
# this is a comment

input { # comments can appear at the end of a line, too
  # ...
}
```

::::{note}
Comments containing environment variable `${var}` references in `config.string` are still evaluated. Remove the `$` sign to avoid pipeline loading failures.
::::




