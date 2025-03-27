---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/data-deserialization.html
---

# Deserializing Data [data-deserialization]

The plugins described in this section are useful for deserializing data into Logstash events.

[avro codec](logstash-docs-md://lsr/plugins-codecs-avro.md)
:   Reads serialized Avro records as Logstash events. This plugin deserializes individual Avro records. It is not for reading Avro files. Avro files have a unique format that must be handled upon input.

    The following config deserializes input from Kafka:

    ```json
    input {
      kafka {
        codec => {
          avro => {
            schema_uri => "/tmp/schema.avsc"
          }
        }
      }
    }
    ...
    ```


[csv filter](logstash-docs-md://lsr/plugins-filters-csv.md)
:   Parses comma-separated value data into individual fields. By default, the filter autogenerates field names (column1, column2, and so on), or you can specify a list of names. You can also change the column separator.

    The following config parses CSV data into the field names specified in the `columns` field:

    ```json
    filter {
      csv {
        separator => ","
        columns => [ "Transaction Number", "Date", "Description", "Amount Debit", "Amount Credit", "Balance" ]
      }
    }
    ```


[fluent codec](logstash-docs-md://lsr/plugins-codecs-fluent.md)
:   Reads the Fluentd `msgpack` schema.

    The following config decodes logs received from `fluent-logger-ruby`:

    ```json
    input {
      tcp {
        codec => fluent
        port => 4000
      }
    }
    ```


[json codec](logstash-docs-md://lsr/plugins-codecs-json.md)
:   Decodes (via inputs) and encodes (via outputs) JSON formatted content, creating one event per element in a JSON array.

    The following config decodes the JSON formatted content in a file:

    ```json
    input {
      file {
        path => "/path/to/myfile.json"
        codec =>"json"
    }
    ```


[protobuf codec](logstash-docs-md://lsr/plugins-codecs-protobuf.md)
:   Reads protobuf encoded messages and converts them to Logstash events. Requires the protobuf definitions to be compiled as Ruby files. You can compile them by using the [ruby-protoc compiler](https://github.com/codekitchen/ruby-protocol-buffers).

    The following config decodes events from a Kafka stream:

    ```json
    input
      kafka {
        zk_connect => "127.0.0.1"
        topic_id => "your_topic_goes_here"
        codec => protobuf {
          class_name => "Animal::Unicorn"
          include_path => ['/path/to/protobuf/definitions/UnicornProtobuf.pb.rb']
        }
      }
    }
    ```


[xml filter](logstash-docs-md://lsr/plugins-filters-xml.md)
:   Parses XML into fields.

    The following config parses the whole XML document stored in the `message` field:

    ```json
    filter {
      xml {
        source => "message"
      }
    }
    ```


