---
navigation_title: "Deprecations"
---

# Logstash deprecations [logstash-deprecations]
Over time, certain Elastic functionality becomes outdated and is replaced or removed. To help with the transition, Elastic deprecates functionality for a period before removal, giving you time to update your applications. 

Review the deprecated functionality for Logstash. While deprecations have no immediate impact, we strongly encourage you update your implementation after you upgrade.

% ## Next version [logstash-versionnext-deprecations]

% ::::{dropdown} Deprecation title
% Description of the deprecation.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of deprecation. 
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

% ## 9.0.0 [logstash-900-deprecations]

% ::::{dropdown} Deprecation title
% Description of the deprecation.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of deprecation. 
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

::::{dropdown} Enterprise_search integration plugin is deprecated
:name: enterprise_search-deprecated-9.0

We’ve deprecated the {{ls}} Enterprise_search integration plugin, and its component App Search and Workplace Search plugins. These plugins will receive only security updates and critical fixes moving forward.

We recommend using our native {{es}} tools for your Search use cases. For more details, please visit the [Search solution and use case documentation](docs-content://solutions/search.md).
::::

