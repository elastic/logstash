---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugin-concepts.html
---

# Cross-plugin concepts and features [plugin-concepts]

New section for concepts, features, and behaviours that apply to multiple plugins.

## Space-deliminated URIs in list-type params [space-delimited-uris-in-list-params]

List-type URI parameters will automatically expand strings that contain multiple whitespace-delimited URIs into separate entries. This behaviour enables the expansion of an arbitrary list of URIs from a single Environment- or Keystore-variable.

These plugins and options support this functionality:

* [Elasticsearch input plugin - `hosts`](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md#plugins-inputs-elasticsearch-hosts)
* [Elasticsearch output plugin - `hosts`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-hosts)
* [Elasticsearch filter plugin - `hosts`](logstash-docs-md://lsr/plugins-filters-elasticsearch.md#plugins-filters-elasticsearch-hosts)

You can use this functionality to define an environment variable with multiple whitespace-delimited URIs and use it for the options above.

**Example**

```
ES_HOSTS="es1.example.com es2.example.com:9201 es3.example.com:9201"
```
