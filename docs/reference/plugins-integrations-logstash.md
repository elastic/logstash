---
navigation_title: "logstash"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-integrations-logstash.html
---

# Logstash Integration Plugin [plugins-integrations-logstash]


* Plugin version: v1.0.4
* Released on: 2024-12-10
* [Changelog](https://github.com/logstash-plugins/logstash-integration-logstash/blob/v1.0.4/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/integration-logstash-index.md).

## Getting help [_getting_help_5]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-integration-logstash). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_6]

The Logstash Integration Plugin provides integrated plugins for sending events from one Logstash to another instance(s):

* [Logstash output plugin](/reference/plugins-outputs-logstash.md)
* [Logstash input plugin](/reference/plugins-inputs-logstash.md)

### High-level concepts [plugins-integrations-logstash-concepts]

You can configure a `logstash` output to send events to one or more `logstash` inputs, which are each in another pipeline that is running in different processes or on a different host.

To do so, you should first configure the downstream pipeline with a `logstash` input plugin, bound to an available port so that it can listen for inbound connections. Security is enabled by default, so you will need to either provide identity material or disable SSL.

::::{note}
You will need a TCP route from the upstream pipeline to the interface that the downstream pipeline is bound to.
::::


```
input {
  logstash {
    port => 9800

    # SSL IDENTITY <1>
    ssl_keystore_path      => "/path/to/identity.p12"
    ssl_keystore_password  => "${SSL_IDENTITY_PASSWORD}"
  }
}
```

1. Identity material typically should include identity claims about the hostnames and ip addresses that will be used by upstream output plugins.


Once the downstream pipeline is configured and running, you may send events from any number of upstream pipelines by adding a `logstash` output plugin that points to the downstream input. You may need to configure SSL to trust the certificates presented by the downstream input plugin.

```
output {
  logstash {
    hosts => ["10.0.0.123:9800", "10.0.0.125:9801"]

    # SSL TRUST <1>
    ssl_truststore_path => "/path/to/truststore.p12"
    ssl_truststore_password => "${SSL_TRUST_PASSWORD}"
  }
}
```

1. Unless SSL is disabled or the downstream input is expected to present certificates signed by globally-trusted authorities, you will likely need to provide a source-of-trust.




## Load Balancing [plugins-integrations-logstash-load-balancing]

When a `logstash` output is configured to send to multiple `hosts`, it distributes events in batches to *all* of those downstream hosts fairly, favoring those without recent errors. This increases the likelihood of each batch being routed to a downstream that is up and has capacity to receive events.


