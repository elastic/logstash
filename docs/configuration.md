---
title: Configuration Language - logstash
layout: content_right
---
# LogStash Config Language

The logstash config language aims to be simple.

There's 3 main sections: inputs, filters, outputs. Each section has
configurations for each plugin available in that section.

Example:

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

## Filters and Ordering

For a given event, are applied in the order of appearance in the config file.

## Comments

Comments are as in ruby, perl, and python. Starts with a '#' character. Example:

    # this is a comment

## Value Types

The documentation for a plugin may say that a config field has a certain type.
Examples include boolean, string, array, number, hash, etc.

### <a name="boolean"></a>Boolean

A boolean must be either true or false.

Examples:

    debug => true

### <a name="string"></a>String

A string must be a single value.

Example:

    name => "Hello world"

Single, unquoted words are valid as strings, too, but you should use quotes.

### <a name="number"></a>Number

Numbers must be valid numerics (floating point or integer are OK)

Example:

    port => 33

### <a name="array"></a>Array

An 'array' can be a single string value or multiple. If you specify the same
field multiple times, it appends to the array.

Examples:

    path => [ "/var/log/messages", "/var/log/*.log" ]
    path => "/data/mysql/mysql.log"

The above makes 'path' a 3-element array including all 3 strings.

### <a name="hash"></a>Hash

A 'hash' is basically the same syntax as Ruby hashes. 
The 'key' and 'value' are simply pairs, such as:

    match => { "field1" => "value1", "field2" => "value2", ... }

## Further reading

For more information, see [the plugin docs index](index)
