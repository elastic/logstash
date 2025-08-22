---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html
  - https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html
---

# Accessing event data and fields [event-dependent-configuration]

A Logstash pipeline usually has three stages: inputs → filters → outputs. Inputs generate events, filters modify them, and outputs ship them elsewhere.

All events have properties.
For example, an Apache access log has properties like status code (200, 404), request path ("/", "index.html"), HTTP verb (GET, POST), client IP address, and so forth.
Logstash calls these properties "fields."

Event and data field types:
- [Field references](#logstash-config-field-references)
- [Sprintf format](#sprintf)
- [Conditionals](#conditionals)


::::{important}
Some configuration options in Logstash require the existence of fields in order to function. Because inputs generate events, there are no fields to evaluate within the input block—they do not exist yet!

[Field references](#logstash-config-field-references), [sprintf format](#sprintf), and [conditionals](#conditionals) do not work in input blocks.
These configuration options depend on events and fields, and therefore, work only within filter and output blocks.
::::



## Field references [logstash-config-field-references]

When you need to refer to a field by name, you can use the Logstash [field reference syntax](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html).

The basic syntax to access a field is `[fieldname]`.
If you are referring to a **top-level field**, you can omit the `[]` and use `fieldname`. To refer to a **nested field**, specify the full path to that field: `[top-level field][nested field]`.

For example, this event has five top-level fields (agent, ip, request, response, ua) and three nested fields (status, bytes, os).

```
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
```

To reference the `os` field, specify `[ua][os]`. 
To reference a top-level field such as `request`, specify the field name.


### Why use field references? [field-reference-deep-dive]

You might find situations in which you need to refer to a field or collection of fields by name. 
You can accomplish this goal using the Logstash field reference syntax.

The syntax to access a field specifies the entire path to the field, with each fragment wrapped in square brackets.
When a field name contains square brackets, the brackets must be properly [ escaped](#formal-grammar-escape-sequences).

Field references can be expressed literally within [conditional statements](#conditionals) in your pipeline configurations,
as string arguments to your pipeline plugins, or within sprintf statements that will be used by your pipeline plugins:

```
filter {
  #  +----literal----+     +----literal----+
  #  |               |     |               |
  if [@metadata][date] and [@metadata][time] {
    mutate {
      add_field {
        "[@metadata][timestamp]" => "%{[@metadata][date]} %{[@metadata][time]}"
      # |                      |    |  |               |    |               | |
      # +----string-argument---+    |  +--field-ref----+    +--field-ref----+ |
      #                             +-------- sprintf format string ----------+
      }
    }
  }
}
```


### Formal grammar [formal-grammar]

Expand the section below if you would like to explore the formal grammar.

::::{dropdown} Deep Dive: Formal grammar for field references 
:name: formal grammar

#### Field Reference Literal [formal-grammar-field-reference-literal]

A _Field Reference Literal_ is a sequence of one or more _Path Fragments_ that can be used directly in Logstash pipeline [conditionals](#conditionals)  without any additional quoting.
Example: `[request]`, `[response][status]`).

```
fieldReferenceLiteral
  : ( pathFragment )+
  ;
```

#### Field Reference (Event APIs) [formal-grammar-field-reference]

The Event API's methods for manipulating the fields of an event or using the sprintf syntax are more flexible than the pipeline grammar in what they accept as a Field Reference.
Top-level fields can be referenced directly by their _Field Name_ without the square brackets, and there is some support for _Composite Field References_, simplifying use of programmatically-generated Field References.

A _Field Reference_ for use with the Event API is therefore one of:

 - a single _Field Reference Literal_; OR
 - a single _Field Name_ (referencing a top-level field); OR
 - a single _Composite Field Reference_.

```
eventApiFieldReference
  : fieldReferenceLiteral
  | fieldName
  | compositeFieldReference
  ;
```

#### Path Fragment [formal-grammar-path-fragment]

A _Path Fragment_ is a _Field Name_ wrapped in square brackets, such as `[request]`).

```
pathFragment
  : '[' fieldName ']'
  ;
```

#### Field Name [formal-grammar-field-name]

A _Field Name_ is a sequence of characters that are _not_ square brackets (`[` or `]`).

```
fieldName
  : ( ~( '[' | ']' ) )+
  ;
```

#### Composite Field Reference [formal-grammar-event-api-composite-field-reference]

In some cases, you may need to programmatically _compose_ a Field Reference from one or more Field References,
such as when manipulating fields in a plugin or when using the Ruby Filter plugin and the Event API.

```
    fieldReference = "[path][to][deep nested field]"
    compositeFieldReference = "[@metadata][#{fieldReference}][size]"
    # => "[@metadata][[path][to][deep nested field]][size]"
```

##### Canonical Representations of Composite Field References [canonical-representations]

| Acceptable _composite field reference_ | Canonical _field reference_ representation | 
| ------------- | ------------- |
| `[[deep][nesting]][field]`           | `[deep][nesting][field]`
| `[foo][[bar]][bingo]`                | `[foo][bar][bingo]`
| `[[ok]]`                             | `[ok]`


A _Composite Field Reference_ is a sequence of one or more _Path Fragments_ or _Embedded Field References_.

```
compositeFieldReference
  : ( pathFragment | embeddedFieldReference )+
  ;
```

_Composite Field References_ are supported by the Event API, but are _not_ supported as literals in the Pipeline Configuration.


#### Embedded Field Reference [formal-grammar-event-api-embedded-field-reference]

```
embeddedFieldReference
  : '[' fieldReference ']'
  ;
```

An _Embedded Field Reference_ is a _Field Reference_ that is itself wrapped in square brackets (`[` and `]`), and can be a component of a _Composite Field Reference_.
::::

### Escape sequences [formal-grammar-escape-sequences]

For {{ls}} to reference a field whose name contains a character that has special meaning in the field reference grammar, the character must be escaped.
Logstash can be globally configured to use one of two field reference escape modes:

 - `none` (default): no escape sequence processing is done. Fields containing literal square brackets cannot be referenced by the Event API.
 - `percent`: URI-style percent encoding of UTF-8 bytes. The left square bracket (`[`) is expressed as `%5B`, and the right square bracket (`]`) is expressed as `%5D`.
 - `ampersand`: HTML-style ampersand encoding (`&#` + decimal unicode codepoint + `;`). The left square bracket (`[`) is expressed as `&#91;`, and the right square bracket (`]`) is expressed as `&#93;`.


## sprintf format [sprintf]

The field reference format is also used in what Logstash calls *sprintf format*. This format enables you to embed field values in other strings. For example, the statsd output has an *increment* setting that enables you to keep a count of apache logs by status code:

```js
output {
  statsd {
    increment => "apache.%{[response][status]}"
  }
}
```

Similarly, you can convert the UTC timestamp in the `@timestamp` field into a string.

Instead of specifying a field name inside the curly braces, use the `%{{FORMAT}}` syntax where `FORMAT` is a [java time format](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/time/format/DateTimeFormatter.html#patterns).

For example, if you want to use the file output to write logs based on the event’s UTC date and hour and the `type` field:

```
output {
  file {
    path => "/var/log/%{type}.%{{yyyy.MM.dd.HH}}"
  }
}
```

::::{note}
* The sprintf format continues to support [deprecated joda time format](http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html) strings as well using the `%{+FORMAT}` syntax. These formats are not directly interchangeable, and we advise you to begin using the more modern Java Time format.
* A Logstash timestamp represents an instant on the UTC-timeline, so using sprintf formatters will produce results that may not align with your machine-local timezone.
::::

You can generate a fresh timestamp by using `%{{TIME_NOW}}` syntax instead of relying on the value in `@timestamp`. This is particularly useful when you need to estimate the time span of each plugin.

```js
input {
  heartbeat {
    add_field => { "heartbeat_time" => "%{{TIME_NOW}}" }
  }
}
filter {
  mutate {
    add_field => { "mutate_time" => "%{{TIME_NOW}}" }
  }
}
```


## Conditionals [conditionals]

Sometimes you want to filter or output an event only under certain conditions. For that, you can use a conditional.

Conditionals in Logstash look and act the same way they do in programming languages. Conditionals support `if`, `else if` and `else` statements and can be nested.

The conditional syntax is:

```js
if EXPRESSION {
  ...
} else if EXPRESSION {
  ...
} else {
  ...
}
```

What’s an expression? Comparison tests, boolean logic, and so on!

You can use these comparison operators:

* equality: `==`,  `!=`,  `<`,  `>`,  `<=`, `>=`
* regexp: `=~`, `!~` (checks a pattern on the right against a string value on the left)
* inclusion: `in`, `not in`

Supported boolean operators are:

* `and`, `or`, `nand`, `xor`

Supported unary operators are:

* `!`

Expressions can be long and complex. Expressions can contain other expressions, you can negate expressions with `!`, and you can group them with parentheses `(...)`.

For example, this conditional uses the mutate filter to remove the field `secret` if the field `action` has a value of `login`:

```js
filter {
  if [action] == "login" {
    mutate { remove_field => "secret" }
  }
}
```

If an expression generates an error when it is evaluated, event processing stops and a warning message is written to the log. For example, comparing integer value `100` with string value `"100"` cannot be evaluated with certainty, and so processing stops and the error is logged.

To capture the full content of the message at the time the error occurs, set the log level to `debug`. Check out [Logging](/reference/logging.md) for more information about how to configure logging and available log levels.

You can specify multiple expressions in a single condition:

```js
output {
  # Send production errors to pagerduty
  if [loglevel] == "ERROR" and [deployment] == "production" {
    pagerduty {
    ...
    }
  }
}
```

You can use the `in` operator to test whether a field contains a specific string, key, or list element. Note that the semantic meaning of `in` can vary, based on the target type. For example, when applied to a string. `in` means "is a substring of". When applied to a collection type, `in` means "collection contains the exact value".

```js
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
```

You use the `not in` conditional the same way. For example, you could use `not in` to only route events to Elasticsearch when `grok` is successful:

```js
output {
  if "_grokparsefailure" not in [tags] {
    elasticsearch { ... }
  }
}
```

You can check for the existence of a specific field, but there’s currently no way to differentiate between a field that doesn’t exist versus a field that’s simply false. 
The expression `if [foo]` returns `false` when:

* `[foo]` doesn’t exist in the event,
* `[foo]` exists in the event, but is false, or
* `[foo]` exists in the event, but is null

For more complex examples, see [Using Conditionals](/reference/config-examples.md#using-conditionals).

::::{note}
Sprintf date/time format in conditionals is not currently supported. 
A workaround using the `@metadata` field is available. 
See [sprintf date/time format in conditionals](#date-time) for more details and an example.
::::



## The @metadata field [metadata]

In Logstash, there is a special field called `@metadata`.  The contents of `@metadata` are not part of any of your events at output time, which makes it great to use for conditionals, or extending and building event fields with field reference and `sprintf` formatting.

This configuration file yields events from STDIN.  Whatever you type becomes the `message` field in the event.  The `mutate` events in the filter block add a few fields, some nested in the `@metadata` field.

```ruby
input { stdin { } }

filter {
  mutate { add_field => { "show" => "This data will be in the output" } }
  mutate { add_field => { "[@metadata][test]" => "Hello" } }
  mutate { add_field => { "[@metadata][no_show]" => "This data will not be in the output" } }
}

output {
  if [@metadata][test] == "Hello" {
    stdout { codec => rubydebug }
  }
}
```

Let’s see what comes out:

```ruby
$ bin/logstash -f ../test.conf
Pipeline main started
asdf
{
    "@timestamp" => 2016-06-30T02:42:51.496Z,
      "@version" => "1",
          "host" => "example.com",
          "show" => "This data will be in the output",
       "message" => "asdf"
}
```

The "asdf" typed in became the `message` field contents, and the conditional successfully evaluated the contents of the `test` field nested within the `@metadata` field.  But the output did not show a field called `@metadata`, or its contents.

The `rubydebug` codec allows you to reveal the contents of the `@metadata` field if you add a config flag, `metadata => true`:

```ruby
    stdout { codec => rubydebug { metadata => true } }
```

Let’s see what the output looks like with this change:

```ruby
$ bin/logstash -f ../test.conf
Pipeline main started
asdf
{
    "@timestamp" => 2016-06-30T02:46:48.565Z,
     "@metadata" => {
           "test" => "Hello",
        "no_show" => "This data will not be in the output"
    },
      "@version" => "1",
          "host" => "example.com",
          "show" => "This data will be in the output",
       "message" => "asdf"
}
```

Now you can see the `@metadata` field and its sub-fields.

::::{important}
Only the `rubydebug` codec allows you to show the contents of the `@metadata` field.
::::


Make use of the `@metadata` field any time you need a temporary field but do not want it to be in the final output.

Perhaps one of the most common use cases for this new field is with the `date` filter and having a temporary timestamp.

This configuration file has been simplified, but uses the timestamp format common to Apache and Nginx web servers.  In the past, you’d have to delete the timestamp field yourself, after using it to overwrite the `@timestamp` field.  With the `@metadata` field, this is no longer necessary:

```ruby
input { stdin { } }

filter {
  grok { match => [ "message", "%{HTTPDATE:[@metadata][timestamp]}" ] }
  date { match => [ "[@metadata][timestamp]", "dd/MMM/yyyy:HH:mm:ss Z" ] }
}

output {
  stdout { codec => rubydebug }
}
```

Notice that this configuration puts the extracted date into the `[@metadata][timestamp]` field in the `grok` filter.  Let’s feed this configuration a sample date string and see what comes out:

```ruby
$ bin/logstash -f ../test.conf
Pipeline main started
02/Mar/2014:15:36:43 +0100
{
    "@timestamp" => 2014-03-02T14:36:43.000Z,
      "@version" => "1",
          "host" => "example.com",
       "message" => "02/Mar/2014:15:36:43 +0100"
}
```

That’s it!  No extra fields in the output, and a cleaner config file because you do not have to delete a "timestamp" field after conversion in the `date` filter.

Another use case is the [CouchDB Changes input plugin](https://github.com/logstash-plugins/logstash-input-couchdb_changes). This plugin automatically captures CouchDB document field metadata into the `@metadata` field within the input plugin itself.  When the events pass through to be indexed by Elasticsearch, the Elasticsearch output plugin allows you to specify the `action` (delete, update, insert, etc.) and the `document_id`, like this:

```ruby
output {
  elasticsearch {
    action => "%{[@metadata][action]}"
    document_id => "%{[@metadata][_id]}"
    hosts => ["example.com"]
    index => "index_name"
    protocol => "http"
  }
}
```


### sprintf date/time format in conditionals [date-time]

Sprintf date/time format in conditionals is not currently supported, but a workaround is available. Put the date calculation in a field so that you can use the field reference in a conditional.

**Example**

Using sprintf time format directly to add a field based on ingestion time *will not work*:

```
----------
# non-working example
filter{
  if "%{+HH}:%{+mm}" < "16:30" {
    mutate {
      add_field => { "string_compare" => "%{+HH}:%{+mm} is before 16:30" }
    }
  }
}
----------
```

This workaround gives you the intended results:

```js
filter {
  mutate{
     add_field => {
      "[@metadata][time]" => "%{+HH}:%{+mm}"
     }
  }
  if [@metadata][time] < "16:30" {
    mutate {
      add_field => {
        "string_compare" => "%{+HH}:%{+mm} is before 16:30"
      }
    }
  }
}
```
