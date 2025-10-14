---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/event-api.html
---

# Event API [event-api]

This section is targeted for plugin developers and users of Logstash’s Ruby filter. Below we document recent changes (starting with version 5.0) in the way users have been accessing Logstash’s event based data in custom plugins and in the Ruby filter. Note that [Accessing event data and fields](/reference/event-dependent-configuration.md) data flow in Logstash’s config files — using [Field references](/reference/event-dependent-configuration.md#logstash-config-field-references) — is not affected by this change, and will continue to use existing syntax.


## Event Object [_event_object]

Event is the main object that encapsulates data flow internally in Logstash and provides an API for the plugin developers to interact with the event’s content. Typically, this API is used in plugins and in a Ruby filter to retrieve data and use it for transformations. Event object contains the original data sent to Logstash and any additional fields created during Logstash’s filter stages.

In 5.0, we’ve re-implemented the Event class and its supporting classes in pure Java. Since Event is a critical component in data processing,  a rewrite in Java improves performance and provides efficient serialization when storing data on disk. For the most part, this change aims at keeping backward compatibility and is transparent to the users. To this extent we’ve updated and published most of the plugins in Logstash’s ecosystem to adhere to the new API changes. However, if you are maintaining a custom plugin, or have a Ruby filter, this change will affect you. The aim of this guide is to describe the new API and provide examples to migrate to the new changes.


## Event API [_event_api]

Prior to version 5.0, developers could access and manipulate event data by directly using Ruby hash syntax. For example, `event[field] = foo`. While this is powerful, our goal is to abstract the internal implementation details and provide well-defined getter and setter APIs.

**Get API**

The getter is a read-only access of field-based data in an Event.

**Syntax:** `event.get(field)`

**Returns:** Value for this field or nil if the field does not exist. Returned values could be a string, numeric or timestamp scalar value.

`field` is a structured field sent to Logstash or created after the transformation process. `field` can also be a nested [field reference](https://www.elastic.co/guide/en/logstash/current/field-references-deepdive.html) such as `[field][bar]`.

Examples:

```ruby
event.get("foo" ) # => "baz"
event.get("[foo]") # => "zab"
event.get("[foo][bar]") # => 1
event.get("[foo][bar]") # => 1.0
event.get("[foo][bar]") # =>  [1, 2, 3]
event.get("[foo][bar]") # => {"a" => 1, "b" => 2}
event.get("[foo][bar]") # =>  {"a" => 1, "b" => 2, "c" => [1, 2]}
```

Accessing @metadata

```ruby
event.get("[@metadata][foo]") # => "baz"
```

**Set API**

This API can be used to mutate data in an Event.

**Syntax:** `event.set(field, value)`

**Returns:**  The current Event  after the mutation, which can be used for chainable calls.

Examples:

```ruby
event.set("foo", "baz")
event.set("[foo]", "zab")
event.set("[foo][bar]", 1)
event.set("[foo][bar]", 1.0)
event.set("[foo][bar]", [1, 2, 3])
event.set("[foo][bar]", {"a" => 1, "b" => 2})
event.set("[foo][bar]", {"a" => 1, "b" => 2, "c" => [1, 2]})
event.set("[@metadata][foo]", "baz")
```

Mutating a collection after setting it in the Event has an undefined behaviour and is not allowed.

```ruby
h = {"a" => 1, "b" => 2, "c" => [1, 2]}
event.set("[foo][bar]", h)

h["c"] = [3, 4]
event.get("[foo][bar][c]") # => undefined

Suggested way of mutating collections:

h = {"a" => 1, "b" => 2, "c" => [1, 2]}
event.set("[foo][bar]", h)

h["c"] = [3, 4]
event.set("[foo][bar]", h)

# Alternatively,
event.set("[foo][bar][c]", [3, 4])
```


## Ruby Filter [_ruby_filter]

The [Ruby Filter](logstash-docs-md://lsr/plugins-filters-ruby.md) can be used to execute any ruby code and manipulate event data using the API described above. For example, using the new API:

```ruby
filter {
  ruby {
    code => 'event.set("lowercase_field", event.get("message").downcase)'
  }
}
```

This filter will lowercase the `message` field, and set it to a new field called `lowercase_field`
