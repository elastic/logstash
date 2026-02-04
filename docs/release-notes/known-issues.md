---
navigation_title: "Known issues"
---

# Logstash known issues [logstash-known-issues]

Known issues are significant defects or limitations that may impact your implementation. 
These issues are actively being worked on and will be addressed in a future release. 
Review known issues to help you make informed decisions, such as upgrading to a new version.

<<<<<<< HEAD
## 9.3.0 [logstash-ki-9.3.0]

**Logstash will not start with bundled JDK on aarch64 downloaded artifacts**

Applies to: {{ls}} 9.3.0

::::{dropdown} Details

On `aarch64`, {{ls}} 9.3.0 fails to start when installed from .deb, .rpm, or .tar packages and using the bundled JDK.
=======
## 9.2.5 [logstash-ki-9.2.5]

**Logstash will not start with bundled JDK on aarch64 downloaded artifacts**

Applies to: {{ls}} 9.2.5

::::{dropdown} Details

On `aarch64`,{{ls}} 9.2.5 fails to start when installed from .deb, .rpm, or .tar packages and using the bundled JDK.
>>>>>>> aaf827f2 (Add known issues running 9.2.5 on aarch64 architectures (#18731))
This is due to an incorrect JDK version being included in those packages.

Using a JDK provided via `LS_JAVA_HOME` works as expected. Docker images and non-`aarch64` architectures are not affected.

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
