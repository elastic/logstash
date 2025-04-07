---
navigation_title: "Breaking changes"
---

# Logstash breaking changes [logstash-breaking-changes]
Breaking changes can impact your Elastic applications, potentially disrupting normal operations. 
Before you upgrade, carefully review the Logstash breaking changes and take the necessary steps to mitigate any issues. 

% ## Next version [logstash-nextversion-breaking-changes]

% ::::{dropdown} Title of breaking change
% Description of the breaking change.
% For more information, check [PR #](PR link).
% **Impact**<br> Impact of the breaking change.
% **Action**<br> Steps for mitigating deprecation impact.
% ::::

## 9.0.0 [logstash-900-breaking-changes]

::::{dropdown} Pipeline buffer type defaults to `heap`
:name: pipeline-buffer-type]

We've improved memory configuration for certain {{ls}} plugins.
Input plugins such as `elastic_agent`, `beats`, `tcp`, and `http` allocate buffers in Java memory to read events from the network.
The default allocation method is `direct` memory rather than `heap` memory to simplify configuration, and to help facilitate debugging memory usage problems through the analysis of heap dumps.
If you need to re-enable the previous behavior, change the `pipeline.buffer.type` setting in [logstash.yml](/reference/logstash-settings-file.md).
Check out [off-heap-buffers-allocation](/reference/jvm-settings.md#off-heap-buffers-allocation) for details. [#16500](https://github.com/elastic/logstash/pull/16500)
::::

::::{dropdown} JDK11 not supported
:name: jdk-11-support-drop

JDK17 is the minimum version of the JDK required to run Logstash.
For the best experience, we still recommend running {{ls}} using the bundled-jdk. 
See [Logstash JVM requirements](/reference/getting-started-with-logstash.md#ls-jvm)
for details. [#16443](https://github.com/elastic/logstash/pull/16443)
::::

::::{dropdown} Docker base image now UBI9 based
:name: docker-base-image-change

The base image for {{ls}} on Docker has been changed from Ubuntu to UBI9.
If you create a Docker image based on the {{ls}} image and rely on it being Ubuntu based, you need to change your derived image to take account of this change. 
For example, if your derived docker image installs additional packages using a package manager, UBI9 uses `microdnf`, rather than `apt`.
[#16599](https://github.com/elastic/logstash/pull/16599)
::::

::::{dropdown} Cannot run {{ls}} as `superuser` by default
:name: [disallow-superuser

We've changed the default behavior to prevent users from accidentally running {{ls}} as a superuser.
If you try to run {{ls}} as a superuser, it logs an error and fails to start, ensuring that users cannot run Logstash with elevated privileges by accident.

You can change the value of the `allow_superuser` setting to `true` in [logstash.yml](/reference/logstash-settings-file.md) if you want to restore the previous behavior and allow {{ls}} to run with superuser privileges. [#16558](https://github.com/elastic/logstash/pull/16558)
::::

::::{dropdown}New setting required to continue using legacy internal monitoring
:name: allow-legacy-monitoring

To continue using deprecated internal collection to monitor {{ls}}, set `xpack.monitoring.allow_legacy_collection` to `true` in [logstash.yml](/reference/logstash-settings-file.md).
We encourage you to move to [agent-driven monitoring](/reference/monitoring-logstash-with-elastic-agent.md), the latest, supported way to monitor Logstash [#16586](https://github.com/elastic/logstash/pull/16586)
::::

::::{dropdown} Avoiding JSON log lines collision
:name: avoid-collision-on-json-fields

We've improved the way we deal with duplicate `message` fields in `json` documents.
Some code paths that log in `json` produce log events that include multiple instances of the  `message` field. (The JSON codec plugin is one example.)
While this approach produces JSON that is technically valid, many clients do not parse this data correctly, and either crash or discard one of the fields.

We recently introduced the option to fix duplicates, and made it the default behavior for `9.0` and later.
To re-enable the previous behavior, change the `log.format.json.fix_duplicate_message_fields` setting in [logstash.yml](/reference/logstash-settings-file.md) to `false`.

Check out [Logging in json format can write duplicate message fields](docs-content://troubleshoot/ingest/logstash.md) for more details about the issue. [#16578](https://github.com/elastic/logstash/pull/16578)
::::

