---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/configuring-centralized-pipelines.html
---

# Configure Centralized Pipeline Management [configuring-centralized-pipelines]

To configure [centralized pipeline management](/reference/logstash-centralized-pipeline-management.md):

1. Verify that you are using a license that includes the pipeline management feature.

    For more information, see [https://www.elastic.co/subscriptions](https://www.elastic.co/subscriptions) and [License management](docs-content://deploy-manage/license/manage-your-license-in-self-managed-cluster.md).

2. Specify [configuration management settings](#configuration-management-settings) in the `logstash.yml` file. At a minimum, set:

    * `xpack.management.enabled: true` to enable centralized configuration management.
    * `xpack.management.elasticsearch.hosts` to specify the Elasticsearch instance that will store the Logstash pipeline configurations and metadata.
    * `xpack.management.pipeline.id` to register the pipelines that you want to centrally manage.

3. Restart Logstash.
4. If your Elasticsearch cluster is protected with basic authentication, assign the built-in `logstash_admin` role as well as the `logstash_writer` role to any users who will use centralized pipeline management. See [Secure your connection](/reference/secure-connection.md) for more information.

::::{note}
Centralized management is disabled until you configure and enable {{security-features}}.
::::


::::{important}
After you’ve configured Logstash to use centralized pipeline management, you can no longer specify local pipeline configurations. This means that the `pipelines.yml` file and settings like `path.config` and `config.string` are inactive when this feature is enabled.
::::


## Configuration Management Settings in Logstash [configuration-management-settings]


You can set the following `xpack.management` settings in `logstash.yml` to enable [centralized pipeline management](/reference/logstash-centralized-pipeline-management.md). For more information about configuring Logstash, see [logstash.yml](/reference/logstash-settings-file.md).

The following example shows basic settings that assume {{es}} and {{kib}} are installed on the localhost with basic AUTH enabled, but no SSL. If you’re using SSL, you need to specify additional SSL settings.

```shell
xpack.management.enabled: true
xpack.management.elasticsearch.hosts: "http://localhost:9200/"
xpack.management.elasticsearch.username: logstash_admin_user
xpack.management.elasticsearch.password: t0p.s3cr3t
xpack.management.logstash.poll_interval: 5s
xpack.management.pipeline.id: ["apache", "cloudwatch_logs"]
```

`xpack.management.enabled`
:   Set to `true` to enable {{xpack}} centralized configuration management for Logstash.

`xpack.management.logstash.poll_interval`
:   How often the Logstash instance polls for pipeline changes from Elasticsearch. The default is 5s.

`xpack.management.pipeline.id`
:   Specify a comma-separated list of pipeline IDs to register for centralized pipeline management. After changing this setting, you need to restart Logstash to pick up changes. Pipeline IDs support `*` as a [wildcard](#wildcard-in-pipeline-id) for matching multiple IDs

`xpack.management.elasticsearch.hosts`
:   The {{es}} instance that will store the Logstash pipeline configurations and metadata. This might be the same {{es}} instance specified in the `outputs` section in your Logstash configuration, or a different one. Defaults to `http://localhost:9200`.

`xpack.management.elasticsearch.username` and `xpack.management.elasticsearch.password`
:   If your {{es}} cluster is protected with basic authentication, these settings provide the username and password that the Logstash instance uses to authenticate for accessing the configuration data. The username you specify here should have the built-in `logstash_admin` and `logstash_system` roles. These roles provide access to system indices for managing configurations.

::::{note}
Starting with Elasticsearch version 7.10.0, the `logstash_admin` role inherits the `manage_logstash_pipelines` cluster privilege for centralized pipeline management. If a user has created their own roles and granted them access to the .logstash index, those roles will continue to work in 7.x but will need to be updated for 8.0.
::::


`xpack.management.elasticsearch.proxy`
:   Optional setting that allows you to specify a proxy URL if Logstash needs to use a proxy to reach your Elasticsearch cluster.

`xpack.management.elasticsearch.ssl.ca_trusted_fingerprint`
:   Optional setting that enables you to specify the hex-encoded SHA-256 fingerprint of the certificate authority for your {{es}} instance.

::::{note}
A self-secured Elasticsearch cluster will provide the fingerprint of its CA to the console during setup.

You can also get the SHA256 fingerprint of an Elasticsearch’s CA using the `openssl` command-line utility on the Elasticsearch host:

```shell
openssl x509 -fingerprint -sha256 -in $ES_HOME/config/certs/http_ca.crt
```

::::


`xpack.management.elasticsearch.ssl.certificate_authority`
:   Optional setting that enables you to specify a path to the `.pem` file for the certificate authority for your {{es}} instance.

`xpack.management.elasticsearch.ssl.truststore.path`
:   Optional setting that provides the path to the Java keystore (JKS) to validate the server’s certificate.

::::{note}
You cannot use this setting and `xpack.management.elasticsearch.ssl.certificate_authority` at the same time.
::::


`xpack.management.elasticsearch.ssl.truststore.password`
:   Optional setting that provides the password to the truststore.

`xpack.management.elasticsearch.ssl.keystore.path`
:   Optional setting that provides the path to the Java keystore (JKS) to validate the client’s certificate.

::::{note}
You cannot use this setting and `xpack.management.elasticsearch.ssl.keystore.certificate` at the same time.
::::


`xpack.management.elasticsearch.ssl.keystore.password`
:   Optional setting that provides the password to the keystore.

`xpack.management.elasticsearch.ssl.certificate`
:   Optional setting that provides the path to an SSL certificate to use to authenticate the client. This certificate should be an OpenSSL-style X.509 certificate file.

::::{note}
This setting can be used only if `xpack.management.elasticsearch.ssl.key` is set.
::::


`xpack.management.elasticsearch.ssl.key`
:   Optional setting that provides the path to an OpenSSL-style RSA private key that corresponds to the `xpack.management.elasticsearch.ssl.certificate`.

::::{note}
This setting can be used only if `xpack.management.elasticsearch.ssl.certificate` is set.
::::


`xpack.management.elasticsearch.ssl.verification_mode`
:   Option to validate the server’s certificate. Defaults to `full`. To disable, set to `none`. Disabling this severely compromises security.

`xpack.management.elasticsearch.ssl.cipher_suites`
:   Optional setting that provides the list of cipher suites to use, listed by priorities. Supported cipher suites vary depending on the Java and protocol versions.

`xpack.management.elasticsearch.cloud_id`
:   If you’re using {{es}} in {{ecloud}}, you should specify the identifier here. This setting is an alternative to `xpack.management.elasticsearch.hosts`. If `cloud_id` is configured, `xpack.management.elasticsearch.hosts` should not be used. This {{es}} instance will store the Logstash pipeline configurations and metadata.

`xpack.management.elasticsearch.cloud_auth`
:   If you’re using {{es}} in {{ecloud}}, you can set your auth credentials here. This setting is an alternative to both `xpack.management.elasticsearch.username` and `xpack.management.elasticsearch.password`. If `cloud_auth` is configured, those settings should not be used. The credentials you specify here should be for a user with the `logstash_admin` and `logstash_system` roles, which provide access to system indices for managing configurations.

`xpack.management.elasticsearch.api_key`
:   Authenticate using an Elasticsearch API key. Note that this option also requires using SSL. The API key Format is `id:api_key` where `id` and `api_key` are as returned by the Elasticsearch [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key).


## Wildcard support in pipeline ID [wildcard-in-pipeline-id]


Pipeline IDs must begin with a letter or underscore and contain only letters, underscores, dashes, hyphens and numbers. You can use `*` in `xpack.management.pipeline.id` to match any number of letters, underscores, dashes, hyphens, and numbers.

```shell
xpack.management.pipeline.id: ["*logs", "*apache*", "tomcat_log"]
```

In this example, `"*logs"` matches all IDs ending in `logs`. `"*apache*"` matches any IDs with `apache` in the name.

Wildcard in pipeline IDs is available starting with Elasticsearch 7.10. Logstash can pick up new pipeline without a restart if the new pipeline ID matches the wildcard pattern.


