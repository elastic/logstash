---
title: Configuration Language - logstash
layout: content_right
---
# LogStash Config Language

The logstash config language aims to be simple.

There's 3 main sections: inputs, filters, outputs. Each section has
configurations for each plugin available in that section.

Example:

    input {
      ...
    }

    filter {
      ...
    }

    output {
      ...
    }

## Filters

For a given event, are applied in the order of appearance in the config file.

## Types

The documentation for a plugin may say that a config field has a certain type.
Examples include boolean, string, array, number, hash, etc.

### Boolean

A boolean must be either true or false.

Examples:

    debug => true

### String

A string must be a single value.

Example:

    name => "Hello world"

### Number

Numbers must be valid numerics (floating point or integer are OK)

Example:

    port => 33

### Array

An 'array' can be a single string value or multiple. If you specify the same
field multiple times, it appends to the array.

Examples:

    path => [ "/var/log/messages", "/var/log/*.log" ]
    path => "/data/mysql/mysql.log"

The above makes 'path' a 3-element array including all 3 strings.

### Hash

A 'hash' is currently represented using the same syntax as an array (see above).
The 'key' and 'value' are simply pairs, such as:

    match => [ "field1", "pattern1", "field2", "pattern2" ]

The above would internally be represented as this hash: `{ "field1" =>
"pattern1", "field2" => "pattern2" }`

Why this syntax? Well frankly it was easier than adding additional grammar to
the config language. Logstash may support ruby- or json-like hash syntax in the
future, but not otday.

## Further reading

For more information, see [the plugin docs index](index)
