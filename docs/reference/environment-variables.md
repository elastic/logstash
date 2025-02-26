---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/environment-variables.html
---

# Using environment variables [environment-variables]

## Overview [_overview]

* You can set environment variable references in the configuration for Logstash plugins by using `${var}`.
* At Logstash startup, each reference is replaced by the value of the environment variable.
* The replacement is case-sensitive.
* References to undefined variables raise a Logstash configuration error.
* You can give a default value by using the form `${var:default value}`. Logstash uses the default value if the environment variable is undefined.
* You can add environment variable references in any plugin option type: string, number, boolean, array, or hash.
* Environment variables for list-type URI parameters can support lists of space-delimited values. Currently, other non-URI based options do not support lists of values. See [Cross-plugin concepts and features](/reference/plugin-concepts.md)
* Environment variables are immutable. If you update the environment variable, you’ll have to restart Logstash to pick up the updated value.
* References to environment variables in `config.string` comments are evaluated during configuration parsing, and are therefore discouraged. Remove the `$` sign to avoid pipeline loading failures.


## Examples [_examples]

These examples show you how to use environment variables to set the values of some commonly used configuration options.

### Setting the TCP port [_setting_the_tcp_port]

Here’s an example that uses an environment variable to set the TCP port:

```ruby
input {
  tcp {
    port => "${TCP_PORT}"
  }
}
```

Now let’s set the value of `TCP_PORT`:

```shell
export TCP_PORT=12345
```

At startup, Logstash uses this configuration:

```ruby
input {
  tcp {
    port => 12345
  }
}
```

If the `TCP_PORT` environment variable is not set, Logstash returns a configuration error.

You can fix this problem by specifying a default value:

```ruby
input {
  tcp {
    port => "${TCP_PORT:54321}"
  }
}
```

Now, instead of returning a configuration error if the variable is undefined, Logstash uses the default:

```ruby
input {
  tcp {
    port => 54321
  }
}
```

If the environment variable is defined, Logstash uses the value specified for the variable instead of the default.


### Setting the value of a tag [_setting_the_value_of_a_tag]

Here’s an example that uses an environment variable to set the value of a tag:

```ruby
filter {
  mutate {
    add_tag => [ "tag1", "${ENV_TAG}" ]
  }
}
```

Let’s set the value of `ENV_TAG`:

```shell
export ENV_TAG="tag2"
```

At startup, Logstash uses this configuration:

```ruby
filter {
  mutate {
    add_tag => [ "tag1", "tag2" ]
  }
}
```


### Setting a file path [_setting_a_file_path]

Here’s an example that uses an environment variable to set the path to a log file:

```ruby
filter {
  mutate {
    add_field => {
      "my_path" => "${HOME}/file.log"
    }
  }
}
```

Let’s set the value of `HOME`:

```shell
export HOME="/path"
```

At startup, Logstash uses the following configuration:

```ruby
filter {
  mutate {
    add_field => {
      "my_path" => "/path/file.log"
    }
  }
}
```



