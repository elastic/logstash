---
navigation_title: "protobuf"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-codecs-protobuf.html
---

# Protobuf codec plugin [plugins-codecs-protobuf]


* Plugin version: v1.3.0
* Released on: 2023-09-20
* [Changelog](https://github.com/logstash-plugins/logstash-codec-protobuf/blob/v1.3.0/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/codec-protobuf-index.md).

## Installation [_installation_71]

For plugins not bundled by default, it is easy to install by running `bin/logstash-plugin install logstash-codec-protobuf`. See [Working with plugins](/reference/working-with-plugins.md) for more details.


## Getting help [_getting_help_196]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-codec-protobuf). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_195]

This codec converts protobuf encoded messages into logstash events and vice versa. It supports the protobuf versions 2 and 3.

The plugin requires the protobuf definitions to be compiled to ruby files.<br> For protobuf 2 use the [ruby-protoc compiler](https://github.com/codekitchen/ruby-protocol-buffers).<br> For protobuf 3 use the [official google protobuf compiler](https://developers.google.com/protocol-buffers/docs/reference/ruby-generated).

The following shows a usage example (protobuf v2) for decoding events from a kafka stream:

```ruby
kafka
{
  topic_id => "..."
  key_deserializer_class => "org.apache.kafka.common.serialization.ByteArrayDeserializer"
  value_deserializer_class => "org.apache.kafka.common.serialization.ByteArrayDeserializer"
  codec => protobuf
  {
    class_name => "Animals::Mammals::Unicorn"
    class_file => '/path/to/pb_definitions/some_folder/Unicorn.pb.rb'
    protobuf_root_directory => "/path/to/pb_definitions/"
  }
}
```

Decoder usage example for protobuf v3:

```ruby
kafka
{
  topic_id => "..."
  key_deserializer_class => "org.apache.kafka.common.serialization.ByteArrayDeserializer"
  value_deserializer_class => "org.apache.kafka.common.serialization.ByteArrayDeserializer"
  codec => protobuf
  {
    class_name => "Animals.Mammals.Unicorn"
    class_file => '/path/to/pb_definitions/some_folder/Unicorn_pb.rb'
    protobuf_root_directory => "/path/to/pb_definitions/"
    protobuf_version => 3
  }
}
```

The codec can be used in input and output plugins.<br> When using the codec in the kafka input plugin please set the deserializer classes as shown above.<br> When using the codec in an output plugin:

* make sure to include all the desired fields in the protobuf definition, including timestamp. Remove fields that are not part of the protobuf definition from the event by using the mutate filter. Encoding will fail if the event has fields which are not in the protobuf definition.
* the `@` symbol is currently not supported in field names when loading the protobuf definitions for encoding. Make sure to call the timestamp field `timestamp` instead of `@timestamp` in the protobuf file. Logstash event fields will be stripped of the leading `@` before conversion.
* fields with a nil value will automatically be removed from the event. Empty fields will not be removed.
* it is recommended to set the config option `pb3_encoder_autoconvert_types` to true. Otherwise any type mismatch between your data and the protobuf definition will cause an event to be lost. The auto typeconversion does not alter your data. It just tries to convert obviously identical data into the expected datatype, such as converting integers to floats where floats are expected, or "true" / "false" strings into booleans where booleans are expected.
* When writing to Kafka: set the serializer class: `value_serializer => "org.apache.kafka.common.serialization.ByteArraySerializer"`

Encoder usage example (protobufg v3):

```ruby
kafka
  {
    codec => protobuf
    {
      class_name => "Animals.Mammals.Unicorn"
      class_file => '/path/to/pb_definitions/some_folder/Unicorn_pb.rb'
      protobuf_root_directory => "/path/to/pb_definitions/"
      protobuf_version => 3
    }
    value_serializer => "org.apache.kafka.common.serialization.ByteArraySerializer"
  }
}
```


## Protobuf Codec Configuration Options [plugins-codecs-protobuf-options]

| Setting | Input type | Required |
| --- | --- | --- |
| [`class_name`](#plugins-codecs-protobuf-class_name) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`class_file`](#plugins-codecs-protobuf-class_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`protobuf_root_directory`](#plugins-codecs-protobuf-protobuf_root_directory) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_path`](#plugins-codecs-protobuf-include_path) | [array](/reference/configuration-file-structure.md#array) | No |
| [`protobuf_version`](#plugins-codecs-protobuf-protobuf_version) | [number](/reference/configuration-file-structure.md#number) | Yes |
| [`stop_on_error`](#plugins-codecs-protobuf-stop_on_error) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`pb3_encoder_autoconvert_types`](#plugins-codecs-protobuf-pb3_encoder_autoconvert_types) | [boolean](/reference/configuration-file-structure.md#boolean) | No |

 

### `class_name` [plugins-codecs-protobuf-class_name]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Fully qualified name of the class to decode. Please note that the module delimiter is different depending on the protobuf version. For protobuf v2, use double colons:

```ruby
class_name => "Animals::Mammals::Unicorn"
```

For protobuf v3, use single dots:

```ruby
class_name => "Animals.Mammals.Unicorn"
```

For protobuf v3, you can copy the class name from the Descriptorpool registrations at the bottom of the generated protobuf ruby file. It contains lines like this:

```ruby
Animals.Mammals.Unicorn = Google::Protobuf::DescriptorPool.generated_pool.lookup("Animals.Mammals.Unicorn").msgclass
```

If your class references other definitions: you only have to add the name of the main class here.


### `class_file` [plugins-codecs-protobuf-class_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Absolute path to the directory that contains all compiled protobuf files. If the protobuf definitions are spread across multiple folders, this needs to point to the folder containing all those folders.


### `protobuf_root_directory` [plugins-codecs-protobuf-protobuf_root_directory]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Absolute path to the root directory that contains all referenced/used dependencies of the main class (`class_name`) or any of its dependencies. Must be used in combination with the `class_file` setting, and can not be used in combination with the legacy loading mechanism `include_path`.

Example:

```
 pb3
   ├── header
   │   └── header_pb.rb
   ├── messageA_pb.rb
```

In this case `messageA_pb.rb` has an embedded message from `header/header_pb.rb`. If `class_file` is set to `messageA_pb.rb`, and `class_name` to `MessageA`, `protobuf_root_directory` must be set to `/path/to/pb3`, which includes both definitions.


### `include_path` [plugins-codecs-protobuf-include_path]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Legacy protobuf definition loading mechanism for backwards compatibility: List of absolute pathes to files with protobuf definitions. When using more than one file, make sure to arrange the files in reverse order of dependency so that each class is loaded before it is refered to by another.

Example: a class *Unicorn* referencing another protobuf class *Wings*

```ruby
module Animal
  module Mammal
    class Unicorn
      set_fully_qualified_name "Animal.Mammal.Unicorn"
      optional ::Bodypart::Wings, :wings, 1
      optional :string, :name, 2
      ...
```

would be configured as

```ruby
include_path => ['/path/to/pb_definitions/wings.pb.rb','/path/to/pb_definitions/unicorn.pb.rb']
```

Please note that protobuf v2 files have the ending `.pb.rb` whereas files compiled for protobuf v3 end in `_pb.rb`.

Cannot be used together with `protobuf_root_directory` or `class_file`.


### `protobuf_version` [plugins-codecs-protobuf-protobuf_version]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is 2

Protocol buffers version. Valid settings are 2, 3.


### `stop_on_error` [plugins-codecs-protobuf-stop_on_error]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is false

Stop entire pipeline when encountering a non decodable message.


### `pb3_encoder_autoconvert_types` [plugins-codecs-protobuf-pb3_encoder_autoconvert_types]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is true

Convert data types to match the protobuf definition (if possible). The protobuf encoder library is very strict with regards to data types. Example: an event has an integer field but the protobuf definition expects a float. This would lead to an exception and the event would be lost.

This feature tries to convert the datatypes to the expectations of the protobuf definitions, without modifying the data whatsoever. Examples of conversions it might attempt:

`"true"
:   string ⇒ true :: boolean`

`17
:   int ⇒ 17.0 :: float`

`12345
:   number ⇒ "12345" :: string`

Available only for protobuf version 3.


### `pb3_set_oneof_metainfo` [plugins-codecs-protobuf-pb3_set_oneof_metainfo]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is false

Add meta information to `[@metadata][pb_oneof]` about which classes were chosen for [oneof](https://developers.google.com/protocol-buffers/docs/proto3#oneof) fields. A new field of name `[@metadata][pb_oneof][FOO]` will be added, where `FOO` is the name of the `oneof` field.

Example values: for the protobuf definition

```ruby
    oneof :horse_type do
      optional :unicorn, :message, 2, "UnicornType"
      optional :pegasus, :message, 3, "PegasusType"
    end
```

the field `[@metadata][pb_oneof][horse_type]` will be set to either `pegasus` or `unicorn`. Available only for protobuf version 3.



