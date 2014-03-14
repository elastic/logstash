---
title: Configuration Language - Logstash
layout: content_right
---
# Logstash Config Language

The Logstash config language aims to be simple.

There are 3 main sections: inputs, filters, outputs. Each section has
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

For a given event, are applied in the order of appearance in the
configuration file.

## Comments

Comments are the same as in ruby, perl, and python. Starts with a '#' character. Example:

    # this is a comment

    input { # comments can appear at the end of a line, too
      # ...
    }

## Plugins

The input, filter and output sections all let you configure plugins. Plugin
configuration consists of the plugin name followed by a block of settings for
that plugin. For example, how about two file inputs:

    input {
      file {
        path => "/var/log/messages"
        type => "syslog"
      }

      file {
        path => "/var/log/apache/access.log"
        type => "apache"
      }
    }

The above configures two file separate inputs. Both set two
configuration settings each: 'path' and 'type'. Each plugin has different
settings for configuring it; seek the documentation for your plugin to
learn what settings are available and what they mean. For example, the
[file input][fileinput] documentation will explain the meanings of the
path and type settings.

[fileinput]: inputs/file

## Value Types

The documentation for a plugin may enforce a configuration field having a
certain type.  Examples include boolean, string, array, number, hash,
etc.

### <a name="boolean"></a>Boolean

A boolean must be either `true` or `false`. Note the lack of quotes around `true` and `false`.

Examples:

    debug => true

### <a name="string"></a>String

A string must be a single value.

Example:

    name => "Hello world"

Single, unquoted words are valid as strings, too, but you should use quotes.

### <a name="number"></a>Number

Numbers must be valid numerics (floating point or integer are OK).

Example:

    port => 33

### <a name="array"></a>Array

An array can be a single string value or multiple. If you specify the same
field multiple times, it appends to the array.

Examples:

    path => [ "/var/log/messages", "/var/log/*.log" ]
    path => "/data/mysql/mysql.log"

The above makes 'path' a 3-element array including all 3 strings.

### <a name="hash"></a>Hash

A hash is basically the same syntax as Ruby hashes. 
The key and value are simply pairs, such as:

    match => { "field1" => "value1", "field2" => "value2", ... }

## <a name="fieldreferences"></a>Field References

All events have properties. For example, an apache access log would have things
like status code (200, 404), request path ("/", "index.html"), HTTP verb (GET, POST),
client IP address, etc. Logstash calls these properties "fields." 

In many cases, it is useful to be able to refer to a field by name. To do this,
you can use the Logstash field reference syntax.

By way of example, let us suppose we have this event:

    {
      "agent": "Mozilla/5.0 (compatible; MSIE 9.0)",
      "ip": "192.168.24.44",
      "request": "/index.html"
      "response": {
        "status": 200,
        "bytes": 52353
      },
      "ua": {
        "os": "Windows 7"
      }
    }

- the syntax to access fields is `[fieldname]`.
- if you are only referring to a **top-level field**, you can omit the `[]` and
simply say `fieldname`.
- in the case of **nested fields**, like the "os" field above, you need
the full path to that field: `[ua][os]`.

## <a name="sprintf"></a>sprintf format

This syntax is also used in what Logstash calls 'sprintf format'. This format
allows you to refer to field values from within other strings. For example, the
statsd output has an 'increment' setting, to allow you to keep a count of
apache logs by status code:

    output {
      statsd {
        increment => "apache.%{[response][status]}"
      }
    }

You can also do time formatting in this sprintf format. Instead of specifying a field name, use the `+FORMAT` syntax where `FORMAT` is a [time format](http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html). 

For example, if you want to use the file output to write to logs based on the
hour and the 'type' field:

    output {
      file {
        path => "/var/log/%{type}.%{+yyyy.MM.dd.HH}"
      }
    }

## <a name="conditionals"></a>Conditionals

Sometimes you only want a filter or output to process an event under
certain conditions. For that, you'll want to use a conditional!

Conditionals in Logstash look and act the same way they do in programming
languages. You have `if`, `else if` and `else` statements. Conditionals may be
nested if you need that.

The syntax is follows:

    if EXPRESSION {
      ...
    } else if EXPRESSION {
      ...
    } else {
      ...
    }

What's an expression? Comparison tests, boolean logic, etc!

The following comparison operators  are supported:

* equality, etc: ==,  !=,  <,  >,  <=,  >= 
* regexp: =~, !~ 
* inclusion: in, not in

The following boolean operators are supported:

* and, or, nand, xor

The following unary operators are supported:

* !

Expressions may contain expressions. Expressions may be negated with `!`.
Expressions may be grouped with parentheses `(...)`. Expressions can be long
and complex.

For example, if we want to remove the field `secret` if the field
`action` has a value of `login`:

    filter {
      if [action] == "login" {
        mutate { remove => "secret" }
      }
    }

The above uses the field reference syntax to get the value of the
`action` field. It is compared against the text `login` and, if equal,
allows the mutate filter to delete the field named `secret`.

How about a more complex example?

* alert nagios of any apache events with status 5xx
* record any 4xx status to elasticsearch
* record all status code hits via statsd

How about telling nagios of any http event that has a status code of 5xx?

    output {
      if [type] == "apache" {
        if [status] =~ /^5\d\d/ {
          nagios { ...  }
        } else if [status] =~ /^4\d\d/ {
          elasticsearch { ... }
        }

        statsd { increment => "apache.%{status}" }
      }
    }

You can also do multiple expressions in a single condition:

    output {
      # Send production errors to pagerduty
      if [loglevel] == "ERROR" and [deployment] == "production" {
        pagerduty {
          ...
        }
      }
    }

Here are some examples for testing with the in conditional:

    filter {
      if [foo] in [foobar] {
        mutate { add_tag => "field in field" }
      }
      if [foo] in "foo" {
        mutate { add_tag => "field in string" }
      }
      if "hello" in [greeting] {
        mutate { add_tag => "string in field" }
      }
      if [foo] in ["hello", "world", "foo"] {
        mutate { add_tag => "field in list" }
      }
      if [missing] in [alsomissing] {
        mutate { add_tag => "shouldnotexist" }
      }
      if !("foo" in ["hello", "world"]) {
        mutate { add_tag => "shouldexist" }
      }
    }

Or, to test if grok was successful:

    output {
      if "_grokparsefailure" not in [tags] {
        elasticsearch { ... }
      }
    }

## Further Reading

For more information, see [the plugin docs index](index)
