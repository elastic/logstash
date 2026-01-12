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

## 9.1.10 [logstash-deprecations-9.1.10]

::::{dropdown} Deprecation of partitioner settings in the Kafka Integration

The `partitioner` configuration options `default` and `uniform_sticky` have been deprecated in the Kafka output. [#206](https://github.com/logstash-plugins/logstash-integration-kafka/pull/206)

These options will work correctly for the Kafka plugin version bundled with Logstash 9.1.x, but will be removed in a future release.

The deprecations in the Kafka output were made to align with changes in the Kafka Client. 
At version 4.x, the Kafka Client removes the `DefaultPartitioner` and `UniformStickyPartitioner` partitioner implementations. 
It adds an improved [uniform sticky partitioner](https://cwiki.apache.org/confluence/display/KAFKA/KIP-794%3A+Strictly+Uniform+Sticky+Partitioner), which is the default. 
::::


% ## 9.0.0 [logstash-900-deprecations]

% ::::{dropdown} Deprecation title
% Description of the deprecation.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of deprecation. 
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

None at this time