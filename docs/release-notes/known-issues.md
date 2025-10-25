---
navigation_title: "Known issues"
---

# Logstash known issues [logstash-known-issues]

Known issues are significant defects or limitations that may impact your implementation. 
These issues are actively being worked on and will be addressed in a future release. 
Review known issues to help you make informed decisions, such as upgrading to a new version.

## 9.2.0

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