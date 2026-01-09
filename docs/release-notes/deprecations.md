---
navigation_title: "Deprecations"
---

# Logstash deprecations [logstash-deprecations]
Over time, certain Elastic functionality becomes outdated and is replaced or removed. To help with the transition, Elastic deprecates functionality for a period before removal, giving you time to update your applications. 

Review the deprecated functionality for Logstash. 
While deprecations have no immediate impact, we strongly encourage you update your implementation after you upgrade.

% ## Next version [logstash-versionnext-deprecations]

% ::::{dropdown} Deprecation title
% Description of the deprecation.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of deprecation. 
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

## 9.1.10 [logstash-910-deprecations]

::::{dropdown} Deprecation of settings in the Kafka Integration

* An upcoming release of the Kafka Integration plugin will update the Kafka Client version to `4.x`. This version of
Kafka Client removes the `DefaultPartitioner` and `UniformStickyPartitioner` partitioner implementations, and
includes a new default partitioner which is an
[improved](https://cwiki.apache.org/confluence/display/KAFKA/KIP-794%3A+Strictly+Uniform+Sticky+Partitioner) 
uniform sticky partitioner. 
* For this reason, the `default` and `uniform_sticky` options for the `partitioner` configuration option for
the Kafka Output have been deprecated. While these options will work correctly for this version of the plugin, they
be removed in a future version of this plugin.
* For more information, check [PR 206](https://github.com/logstash-plugins/logstash-integration-kafka/pull/206).


% ## 9.0.0 [logstash-900-deprecations]

% ::::{dropdown} Deprecation title
% Description of the deprecation.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of deprecation. 
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

None at this time