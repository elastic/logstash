---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ls-to-ls.html
---

# Logstash-to-Logstash communications [ls-to-ls]

{{ls}}-to-{{ls}} communication is available if you need to have one {{ls}} instance communicate with another {{ls}} instance. Implementing Logstash-to-Logstash communication can add complexity to your environment, but you may need it if the data path crosses network or firewall boundaries. However, we suggest you don’t implement unless it is strictly required.

::::{note}
If you are looking for information on connecting multiple pipelines within one Logstash instance, see [Pipeline-to-pipeline communication](/reference/pipeline-to-pipeline.md).
::::


Logstash-to-Logstash communication can be achieved in one of two ways:

* [Logstash output to Logstash Input](#native-considerations)
* [Lumberjack output to Beats input](#lumberjack-considerations)

$$$native-considerations$$$**Logstash to Logstash considerations**

This is the preferred method to implement Logstash-to-Logstash. It replaces [Logstash-to-Logstash: HTTP output to HTTP input](/reference/ls-to-ls-http.md) and has these considerations:

* It relies on HTTP as the communication protocol between the Input and Output.
* It supports multiple hosts, providing high availability by load balancing equally amongst the multiple destination hosts.
* No connection information is added to events.

Ready to see more configuration details? See [Logstash-to-Logstash: Output to Input](/reference/ls-to-ls-native.md).

$$$lumberjack-considerations$$$**Lumberjack-Beats considerations**

Lumberjack output to Beats input has been our standard approach for {{ls}}-to-{{ls}} communication, but our recommended approach is now [Logstash-to-Logstash: Output to Input](/reference/ls-to-ls-native.md). Before you implement the Lumberjack to Beats configuration, keep these points in mind:

* Lumberjack to Beats provides high availability, but does not provide load balancing. The Lumberjack output plugin allows defining multiple output hosts for high availability, but instead of load-balancing between all output hosts, it falls back to one host on the list in the case of failure.
* If you need a proxy between the Logstash instances, TCP proxy is the only option.
* There’s no explicit way to exert back pressure back to the beats input.

Ready to see more configuration details? See [Logstash-to-Logstash: Lumberjack output to Beats input](/reference/ls-to-ls-lumberjack.md).




