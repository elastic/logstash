---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/core-operations.html
---

# Performing Core Operations [core-operations]

The plugins described in this section are useful for core operations, such as mutating and dropping events.

[date filter](logstash-docs-md://lsr/plugins-filters-date.md)
:   Parses dates from fields to use as Logstash timestamps for events.

    The following config parses a field called `logdate` to set the Logstash timestamp:

    ```json
    filter {
      date {
        match => [ "logdate", "MMM dd yyyy HH:mm:ss" ]
      }
    }
    ```


[drop filter](logstash-docs-md://lsr/plugins-filters-drop.md)
:   Drops events. This filter is typically used in combination with conditionals.

    The following config drops `debug` level log messages:

    ```json
    filter {
      if [loglevel] == "debug" {
        drop { }
      }
    }
    ```


[fingerprint filter](logstash-docs-md://lsr/plugins-filters-fingerprint.md)
:   Fingerprints fields by applying a consistent hash.

    The following config fingerprints the `IP`, `@timestamp`, and `message` fields and adds the hash to a metadata field called `generated_id`:

    ```json
    filter {
      fingerprint {
        source => ["IP", "@timestamp", "message"]
        method => "SHA1"
        key => "0123"
        target => "[@metadata][generated_id]"
      }
    }
    ```


[mutate filter](logstash-docs-md://lsr/plugins-filters-mutate.md)
:   Performs general mutations on fields. You can rename, remove, replace, and modify fields in your events.

    The following config renames the `HOSTORIP` field to `client_ip`:

    ```json
    filter {
      mutate {
        rename => { "HOSTORIP" => "client_ip" }
      }
    }
    ```

    The following config strips leading and trailing whitespace from the specified fields:

    ```json
    filter {
      mutate {
        strip => ["field1", "field2"]
      }
    }
    ```


[ruby filter](logstash-docs-md://lsr/plugins-filters-ruby.md)
:   Executes Ruby code.

    The following config executes Ruby code that cancels 90% of the events:

    ```json
    filter {
      ruby {
        code => "event.cancel if rand <= 0.90"
      }
    }
    ```


