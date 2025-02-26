---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/field-extraction.html
---

# Extracting Fields and Wrangling Data [field-extraction]

The plugins described in this section are useful for extracting fields and parsing unstructured data into fields.

[dissect filter](/reference/plugins-filters-dissect.md)
:   Extracts unstructured event data into fields by using delimiters. The dissect filter does not use regular expressions and is very fast. However, if the structure of the data varies from line to line, the grok filter is more suitable.

    For example, let’s say you have a log that contains the following message:

    ```json
    Apr 26 12:20:02 localhost systemd[1]: Starting system activity accounting tool...
    ```

    The following config dissects the message:

    ```json
    filter {
      dissect {
        mapping => { "message" => "%{ts} %{+ts} %{+ts} %{src} %{prog}[%{pid}]: %{msg}" }
      }
    }
    ```

    After the dissect filter is applied, the event will be dissected into the following fields:

    ```json
    {
      "msg"        => "Starting system activity accounting tool...",
      "@timestamp" => 2017-04-26T19:33:39.257Z,
      "src"        => "localhost",
      "@version"   => "1",
      "host"       => "localhost.localdomain",
      "pid"        => "1",
      "message"    => "Apr 26 12:20:02 localhost systemd[1]: Starting system activity accounting tool...",
      "type"       => "stdin",
      "prog"       => "systemd",
      "ts"         => "Apr 26 12:20:02"
    }
    ```


[kv filter](/reference/plugins-filters-kv.md)
:   Parses key-value pairs.

    For example, let’s say you have a log message that contains the following key-value pairs:

    ```json
    ip=1.2.3.4 error=REFUSED
    ```

    The following config parses the key-value pairs into fields:

    ```json
    filter {
      kv { }
    }
    ```

    After the filter is applied, the event in the example will have these fields:

    * `ip: 1.2.3.4`
    * `error: REFUSED`


[grok filter](/reference/plugins-filters-grok.md)
:   Parses unstructured event data into fields. This tool is perfect for syslog logs, Apache and other webserver logs, MySQL logs, and in general, any log format that is generally written for humans and not computer consumption. Grok works by combining text patterns into something that matches your logs.

    For example, let’s say you have an HTTP request log that contains the following message:

    ```json
    55.3.244.1 GET /index.html 15824 0.043
    ```

    The following config parses the message into fields:

    ```json
    filter {
      grok {
        match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
      }
    }
    ```

    After the filter is applied, the event in the example will have these fields:

    * `client: 55.3.244.1`
    * `method: GET`
    * `request: /index.html`
    * `bytes: 15824`
    * `duration: 0.043`


::::{tip}
If you need help building grok patterns, try the [Grok Debugger](docs-content://explore-analyze/query-filter/tools/grok-debugger.md). The Grok Debugger is an {{xpack}} feature under the Basic License and is therefore **free to use**.
::::


