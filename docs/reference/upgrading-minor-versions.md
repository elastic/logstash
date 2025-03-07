---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/upgrading-minor-versions.html
---

# Upgrading between minor versions [upgrading-minor-versions]

As a general rule, you can upgrade between minor versions (for example, 9.x to 9.y, where x < y) by simply installing the new release and restarting {{ls}}. {{ls}} typically maintains backwards compatibility for configuration settings and exported fields. Please review the [release notes](/release-notes/index.md) for potential exceptions.

Upgrading between non-consecutive major versions (7.x to 9.x, for example) is not supported.

