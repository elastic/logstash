---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/filebeat-modules.html
---

# Working with Filebeat modules [filebeat-modules]

{{filebeat}} comes packaged with pre-built [modules](beats://reference/filebeat/filebeat-modules.md) that contain the configurations needed to collect, parse, enrich, and visualize data from various log file formats. Each {{filebeat}} module consists of one or more filesets that contain ingest node pipelines, {{es}} templates, {{filebeat}} input configurations, and {{kib}} dashboards.

You can use {{filebeat}} modules with {{ls}}, but you need to do some extra setup. The simplest approach is to [set up and use the ingest pipelines](/reference/use-ingest-pipelines.md) provided by {{filebeat}}.



