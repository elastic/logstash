---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/lookup-enrichment.html
---

# Enriching Data with Lookups [lookup-enrichment]

These plugins can help you enrich data with additional info, such as GeoIP and user agent info:

* [dns filter](#dns-def)
* [elasticsearch filter](#es-def)
* [geoip filter](#geoip-def)
* [http filter](#http-def)
* [jdbc_static filter](#jdbc-static-def)
* [jdbc_streaming filter](#jdbc-stream-def)
* [memcached filter](#memcached-def)
* [translate filter](#translate-def)
* [useragent filter](#useragent-def)


## Lookup plugins [lookup-plugins]

$$$dns-def$$$dns filter
:   The [dns filter plugin](logstash-docs-md://lsr/plugins-filters-dns.md) performs a standard or reverse DNS lookup.

    The following config performs a reverse lookup on the address in the `source_host` field and replaces it with the domain name:

    ```json
    filter {
      dns {
        reverse => [ "source_host" ]
        action => "replace"
      }
    }
    ```


$$$es-def$$$elasticsearch filter
:   The [elasticsearch filter](logstash-docs-md://lsr/plugins-filters-elasticsearch.md) copies fields from previous log events in Elasticsearch to current events.

    The following config shows a complete example of how this filter might be used.  Whenever Logstash receives an "end" event, it uses this Elasticsearch filter to find the matching "start" event based on some operation identifier. Then it copies the `@timestamp` field from the "start" event into a new field on the "end" event.  Finally, using a combination of the date filter and the ruby filter, the code in the example calculates the time duration in hours between the two events.

    ```json
          if [type] == "end" {
             elasticsearch {
                hosts => ["es-server"]
                query => "type:start AND operation:%{[opid]}"
                fields => { "@timestamp" => "started" }
             }
             date {
                match => ["[started]", "ISO8601"]
                target => "[started]"
             }
             ruby {
                code => 'event.set("duration_hrs", (event.get("@timestamp") - event.get("started")) / 3600) rescue nil'
            }
          }
    ```


$$$geoip-def$$$geoip filter
:   The [geoip filter](logstash-docs-md://lsr/plugins-filters-geoip.md) adds geographical information about the location of IP addresses. For example:

    ```json
    filter {
      geoip {
        source => "clientip"
        target => "[source]"
      }
    }
    ```

    After the geoip filter is applied, the event will be enriched with geoip fields. For example:

    ```json 
    "source" => {
      "geo" => {
        "country_name" => "France",
        "country_iso_code" => "FR",
        "continent_code" => "EU",
        "location" => {
          "lon" => 2.3387,
          "lat" => 48.8582
        },
        "timezone" => "Europe/Paris"
      },
      "ip" => "82.67.74.30"
    }
    ```


$$$http-def$$$http filter
:   The [http filter](logstash-docs-md://lsr/plugins-filters-http.md) integrates with external web services/REST APIs, and enables lookup enrichment against any HTTP service or endpoint. This plugin is well suited for many enrichment use cases, such as social APIs, sentiment APIs, security feed APIs, and business service APIs.

$$$jdbc-static-def$$$jdbc_static filter
:   The [jdbc_static filter](logstash-docs-md://lsr/plugins-filters-jdbc_static.md) enriches events with data pre-loaded from a remote database.

    The following example fetches data from a remote database, caches it in a local database, and uses lookups to enrich events with data cached in the local database.

    ```json
    filter {
      jdbc_static {
        loaders => [ <1>
          {
            id => "remote-servers"
            query => "select ip, descr from ref.local_ips order by ip"
            local_table => "servers"
          },
          {
            id => "remote-users"
            query => "select firstname, lastname, userid from ref.local_users order by userid"
            local_table => "users"
          }
        ]
        local_db_objects => [ <2>
          {
            name => "servers"
            index_columns => ["ip"]
            columns => [
              ["ip", "varchar(15)"],
              ["descr", "varchar(255)"]
            ]
          },
          {
            name => "users"
            index_columns => ["userid"]
            columns => [
              ["firstname", "varchar(255)"],
              ["lastname", "varchar(255)"],
              ["userid", "int"]
            ]
          }
        ]
        local_lookups => [ <3>
          {
            id => "local-servers"
            query => "select descr as description from servers WHERE ip = :ip"
            parameters => {ip => "[from_ip]"}
            target => "server"
          },
          {
            id => "local-users"
            query => "select firstname, lastname from users WHERE userid = :id"
            parameters => {id => "[loggedin_userid]"}
            target => "user" <4>
          }
        ]
        # using add_field here to add & rename values to the event root
        add_field => { server_name => "%{[server][0][description]}" }
        add_field => { user_firstname => "%{[user][0][firstname]}" } <5>
        add_field => { user_lastname => "%{[user][0][lastname]}" }
        remove_field => ["server", "user"]
        jdbc_user => "logstash"
        jdbc_password => "example"
        jdbc_driver_class => "org.postgresql.Driver"
        jdbc_driver_library => "/tmp/logstash/vendor/postgresql-42.1.4.jar"
        jdbc_connection_string => "jdbc:postgresql://remotedb:5432/ls_test_2"
      }
    }
    ```

    1. Queries an external database to fetch the dataset that will be cached locally.
    2. Defines the columns, types, and indexes used to build the local database structure. The column names and types should match the external database.
    3. Performs lookup queries on the local database to enrich the events.
    4. Specifies the event field that will store the looked-up data. If the lookup returns multiple columns, the data is stored as a JSON object within the field.
    5. Takes data from the JSON object and stores it in top-level event fields for easier analysis in Kibana.


$$$jdbc-stream-def$$$jdbc_streaming filter
:   The [jdbc_streaming filter](logstash-docs-md://lsr/plugins-filters-jdbc_streaming.md) enriches events with database data.

    The following example executes a SQL query and stores the result set in a field called `country_details`:

    ```json
    filter {
      jdbc_streaming {
        jdbc_driver_library => "/path/to/mysql-connector-java-5.1.34-bin.jar"
        jdbc_driver_class => "com.mysql.jdbc.Driver"
        jdbc_connection_string => "jdbc:mysql://localhost:3306/mydatabase"
        jdbc_user => "me"
        jdbc_password => "secret"
        statement => "select * from WORLD.COUNTRY WHERE Code = :code"
        parameters => { "code" => "country_code"}
        target => "country_details"
      }
    }
    ```


$$$memcached-def$$$memcached filter
:   The [memcached filter](logstash-docs-md://lsr/plugins-filters-memcached.md) enables key/value lookup enrichment against a Memcached object caching system. It supports both read (GET) and write (SET) operations. It is a notable addition for security analytics use cases.

$$$translate-def$$$translate filter
:   The [translate filter](logstash-docs-md://lsr/plugins-filters-translate.md) replaces field contents based on replacement values specified in a hash or file. Currently supports these file types: YAML, JSON, and CSV.

    The following example takes the value of the `response_code` field, translates it to a description based on the values specified in the dictionary, and then removes the `response_code` field from the event:

    ```json
    filter {
      translate {
        field => "response_code"
        destination => "http_response"
        dictionary => {
          "200" => "OK"
          "403" => "Forbidden"
          "404" => "Not Found"
          "408" => "Request Timeout"
        }
        remove_field => "response_code"
      }
    }
    ```


$$$useragent-def$$$useragent filter
:   The [useragent filter](logstash-docs-md://lsr/plugins-filters-useragent.md) parses user agent strings into fields.

    The following example takes the user agent string in the `agent` field, parses it into user agent fields, and adds the user agent fields to a new field called `user_agent`. It also removes the original `agent` field:

    ```json
    filter {
      useragent {
        source => "agent"
        target => "user_agent"
        remove_field => "agent"
      }
    }
    ```

    After the filter is applied, the event will be enriched with user agent fields. For example:

    ```json
            "user_agent": {
              "os": "Mac OS X 10.12",
              "major": "50",
              "minor": "0",
              "os_minor": "12",
              "os_major": "10",
              "name": "Firefox",
              "os_name": "Mac OS X",
              "device": "Other"
            }
    ```


