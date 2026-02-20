---
navigation_title: "Known issues"
---

# Logstash known issues [logstash-known-issues]

Known issues are significant defects or limitations that may impact your implementation. 
These issues are actively being worked on and will be addressed in a future release. 
Review known issues to help you make informed decisions, such as upgrading to a new version.

## 9.3.0 [logstash-ki-9.3.0]

**Logstash will not start with bundled JDK on aarch64 Linux/MacOs and x86_64 Windows**

Applies to: {{ls}} 9.3.0

::::{dropdown} Details

All {{ls}} 9.3.0 artifacts were bundled with Linux x86_64 JDK due to a bug in artifact generation.
Starting {{ls}} on Windows or aarch64 Linux/MacOS with 9.3.0 artifacts results in an fatal error as the bundled JDK is not compatible with those platforms.

This issue affects:
* logstash-9.3.0-linux-aarch64.tar.gz
* logstash-9.3.0-darwin-aarch64.tar.gz
* logstash-9.3.0-windows-x86_64.zip
* logstash-9.3.0-arm64.deb
* logstash-9.3.0-aarch64.rpm
* logstash-oss-9.3.0-linux-aarch64.tar.gz
* logstash-oss-9.3.0-darwin-aarch64.tar.gz
* logstash-oss-9.3.0-windows-x86_64.zip
* logstash-oss-9.3.0-arm64.deb
* logstash-oss-9.3.0-aarch64.rpm

This issue does NOT affect:
* logstash-9.3.0-linux-x86_64.tar.gz
* logstash-9.3.0-x86_64.deb
* logstash-9.3.0-x86_64.rpm
* logstash-oss-9.3.0-linux-x86_64.tar.gz
* logstash-oss-9.3.0-x86_64.deb
* logstash-oss-9.3.0-x86_64.rpm
* Docker images

For this reason the download links to the affected artifacts have been removed from the [{{ls}} Download page](https://www.elastic.co/downloads/logstash) for version 9.3.0.

As a workaround, users can provide an external and compatible JDK via the `LS_JAVA_HOME` environment variable.

::::

## 9.2.5 [logstash-ki-9.2.5]

**Logstash will not start with bundled JDK on aarch64 Linux and x86_64 Windows**

Applies to: {{ls}} 9.2.5

::::{dropdown} Details

All {{ls}} 9.2.5 artifacts were bundled with Linux x86_64 JDK due to a bug in artifact generation.
Starting {{ls}} on Windows or aarch64 Linux/MacOS with 9.2.5 artifacts results in an fatal error as the bundled JDK is not compatible with those platforms.

This issue affects:
* logstash-9.2.5-linux-aarch64.tar.gz
* logstash-9.2.5-darwin-aarch64.tar.gz
* logstash-9.2.5-windows-x86_64.zip
* logstash-9.2.5-arm64.deb
* logstash-9.2.5-aarch64.rpm
* logstash-oss-9.2.5-linux-aarch64.tar.gz
* logstash-oss-9.2.5-darwin-aarch64.tar.gz
* logstash-oss-9.2.5-windows-x86_64.zip
* logstash-oss-9.2.5-arm64.deb
* logstash-oss-9.2.5-aarch64.rpm

This issue does NOT affect:
* logstash-9.2.5-linux-x86_64.tar.gz
* logstash-9.2.5-x86_64.deb
* logstash-9.2.5-x86_64.rpm
* logstash-oss-9.2.5-linux-x86_64.tar.gz
* logstash-oss-9.2.5-x86_64.deb
* logstash-oss-9.2.5-x86_64.rpm
* Docker images

For this reason the download links to the affected artifacts have been removed from the [{{ls}} Download page](https://www.elastic.co/downloads/logstash) for version 9.2.5.

As a workaround, users can provide an external and compatible JDK using the `LS_JAVA_HOME` environment variable.

::::

## 9.2.0 [logstash-ki-9.2.0]

**Logstash will not start if a Persistent Queue has been defined with a size greater than 2 GiB**

Applies to: {{ls}} 9.2.0

::::{dropdown} Details

Attempts to start Logstash when `queue.max_bytes` has been set to `2147483648` bytes or greater will fail. There is currently no workaround for this issue other than downgrading to a previous version of Logstash. Therefore we recommend that any Logstash users with a Persistent Queue greater than size not upgrade to Logstash `9.2.0`.

Details of the bug are included in [this PR fixing the issue](https://github.com/elastic/logstash/pull/18366), which will be included in a future version of Logstash.
::::

**BufferedTokenizer may silently drop data when oversize input has no delimiters**

Applies to: {{ls}} 9.2.0

::::{dropdown} Details

The `decode_size_limit_bytes` setting for {{ls}} plugins that use the `json_lines` codec is behaving differently than expected. When the size limit exceeds the specified limit without a separator in the data, the size grows beyond the limit. 
This occurs because size validation happens after the token is fully accumulated, which does not occur if no trailing separator is detected.

{{ls}} plugins that use the `json_lines` codec include `input-stdin` `input-http`, `input-tcp` `integration-logstash` and `input-elastic_serverless_forwarder`. 

Best practice: Do not set `decode_size_limit_bytes` manually.

Details for this issue and the details for future behavior are being tracked in [#18321](https://github.com/elastic/logstash/issues/18321)
::::


## 9.0.0

None at this time
