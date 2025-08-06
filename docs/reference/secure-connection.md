---
navigation_title: "Secure your connection"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/ls-security.html
---

# Secure your connection to {{es}} [ls-security]


The Logstash {{es}} [output](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md), [input](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md), and [filter](logstash-docs-md://lsr/plugins-filters-elasticsearch.md) plugins,  as well as [monitoring](monitoring-logstash.md) and central management, support authentication and encryption over HTTPS.

{{es}} clusters are secured by default (starting in 8.0). You need to configure authentication credentials for Logstash in order to establish communication. Logstash throws an exception and the processing pipeline is halted if authentication fails.

In addition to configuring authentication credentials for Logstash, you need to grant authorized users permission to access the Logstash indices.

Security is enabled by default on the {{es}} cluster (starting in 8.0). You must enable TLS/SSL in the {{es}} output section of the Logstash configuration in order to allow Logstash to communicate with the {{es}} cluster.


## {{es}} security on by default [es-security-on]

{{es}} generates its own default self-signed Secure Sockets Layer (SSL) certificates at startup.

{{ls}} must establish a Secure Sockets Layer (SSL) connection before it can transfer data to a secured {{es}} cluster. {{ls}} must have a copy of the certificate authority (CA) that signed the {{es}} cluster’s certificates. When a new {{es}} cluster is started up *without* dedicated certificates, it generates its own default self-signed Certificate Authority at startup. See [Starting the Elastic Stack with security enabled](docs-content://deploy-manage/deploy/self-managed/installing-elasticsearch.md) for more info.

{{ess}} uses certificates signed by standard publicly trusted certificate authorities, and therefore setting a cacert is not necessary.

$$$serverless$$$

::::{admonition} Security to {{serverless-full}}
:class: note

{{es-serverless}} simplifies safe, secure communication between {{ls}} and {{es}}.

Configure the [{{ls}} {{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) to use [`cloud_id`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id) and an [`api_key`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key) to establish safe, secure communication between {{ls}} and {{es-serverless}}. No additional SSL configuration steps are needed.

Configuration example:

* `output {elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" } }`

For more details, check out [Grant access using API keys](#ls-api-keys).

::::

$$$hosted-ess$$$

::::{admonition} Security to hosted {{ess}}
:class: note

Our hosted {{ess}} on Elastic Cloud simplifies safe, secure communication between {{ls}} and {{es}}. When you configure the [{{ls}} {{es}} output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) to use [`cloud_id`](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_id) with either the [`cloud_auth` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-cloud_auth) or the [`api_key` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-api_key), no additional SSL configuration steps are needed. {{ess-leadin-short}}

Configuration example:

* `output {elasticsearch { cloud_id => "<cloud id>" cloud_auth => "<cloud auth>" } }`
* `output {elasticsearch { cloud_id => "<cloud id>" api_key => "<api key>" } }`

For more details, check out [Grant access using API keys](#ls-api-keys) or [Sending data to {{ech}}](/reference/connecting-to-cloud.md).

::::


### Secure communication with an on-premise {{es}} cluster [es-security-onprem]

If you are running {{es}} on your own hardware and using the Elasticsearch cluster’s default self-signed certificates, you need to complete a few more steps to establish secure communication between {{ls}} and {{es}}.

You need to:

* Copy the self-signed CA certificate from {{es}} and save it to {{ls}}.
* Configure the elasticsearch-output plugin to use the certificate.

These steps are not necessary if your cluster is using public trusted certificates.


#### Copy and save the certificate [es-sec-copy-cert]

By default an on-premise {{es}} cluster generates a self-signed CA and creates its own SSL certificates when it starts. Therefore {{ls}} needs its own copy of the self-signed CA from the {{es}} cluster in order for {{ls}} to validate the certificate presented by {{es}}.

Copy the [self-signed CA certificate](docs-content://deploy-manage/deploy/self-managed/installing-elasticsearch.md#stack-security-certificates) from the {{es}} `config/certs` directory.

Save it to a location that Logstash can access, such as `config/certs` on the {{ls}} instance.


#### Configure the elasticsearch output [es-sec-plugin]

Use the [`elasticsearch output`'s](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) [`ssl_certificate_authorities` option](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md#plugins-outputs-elasticsearch-ssl_certificate_authorities) to point to the certificate’s location.

**Example**

```ruby
output {
  elasticsearch {
    hosts => ["https://...] <1>
    ssl_certificate_authorities => ['/etc/logstash/config/certs/ca.crt'] <2>
  }
}
```

1. Note that the `hosts` url must begin with `https`
2. Path to the {{ls}} copy of the {{es}} certificate


For more information about establishing secure communication with {{es}}, see [security is on by default](docs-content://deploy-manage/deploy/self-managed/installing-elasticsearch.md).


### Configuring Logstash to use basic authentication [ls-http-auth-basic]

Logstash needs to be able to manage index templates, create indices, and write and delete documents in the indices it creates.

To set up authentication credentials for Logstash:

1. Use the **Management > Roles** UI in {{kib}} or the `role` API to create a `logstash_writer` role. For **cluster** privileges, add `manage_index_templates` and `monitor`. For **indices** privileges, add `write`, `create`, and `create_index`.

    Add `manage_ilm` for cluster and `manage` and `manage_ilm` for indices if you plan to use [index lifecycle management](docs-content://manage-data/lifecycle/index-lifecycle-management/tutorial-automate-rollover.md).

    ```sh
    POST _security/role/logstash_writer
    {
      "cluster": ["manage_index_templates", "monitor", "manage_ilm"], <1>
      "indices": [
        {
          "names": [ "logstash-*" ], <2>
          "privileges": ["write","create","create_index","manage","manage_ilm"]  <3>
        }
      ]
    }
    ```

    1. The cluster needs the `manage_ilm` privilege if [index lifecycle management](docs-content://manage-data/lifecycle/index-lifecycle-management/tutorial-automate-rollover.md) is enabled.
    2. If you use a custom Logstash index pattern, specify your custom pattern instead of the default `logstash-*` pattern.
    3. If [index lifecycle management](docs-content://manage-data/lifecycle/index-lifecycle-management/tutorial-automate-rollover.md) is enabled, the role requires the `manage` and `manage_ilm` privileges to load index lifecycle policies, create rollover aliases, and create and manage rollover indices.

2. Create a `logstash_internal` user and assign it the `logstash_writer` role. You can create users from the **Management > Users** UI in {{kib}} or through the `user` API:

    ```sh
    POST _security/user/logstash_internal
    {
      "password" : "x-pack-test-password",
      "roles" : [ "logstash_writer"],
      "full_name" : "Internal Logstash User"
    }
    ```

3. Configure Logstash to authenticate as the `logstash_internal` user you just created. You configure credentials separately for each of the {{es}} plugins in your Logstash `.conf` file. For example:

    ```js
    input {
      elasticsearch {
        ...
        user => logstash_internal
        password => x-pack-test-password
      }
    }
    filter {
      elasticsearch {
        ...
        user => logstash_internal
        password => x-pack-test-password
      }
    }
    output {
      elasticsearch {
        ...
        user => logstash_internal
        password => x-pack-test-password
      }
    }
    ```



### Granting access to the indices Logstash creates [ls-user-access]

To access the indices Logstash creates, users need the `read` and `view_index_metadata` privileges:

1. Create a `logstash_reader` role that has the `read` and `view_index_metadata` privileges  for the Logstash indices. You can create roles from the **Management > Roles** UI in {{kib}} or through the `role` API:

    ```sh
    POST _security/role/logstash_reader
    {
      "cluster": ["manage_logstash_pipelines"],
      "indices": [
        {
          "names": [ "logstash-*" ],
          "privileges": ["read","view_index_metadata"]
        }
      ]
    }
    ```

2. Assign your Logstash users the `logstash_reader` role. If the Logstash user will be using [centralized pipeline management](/reference/logstash-centralized-pipeline-management.md), also assign the `logstash_system` role. You can create and manage users from the **Management > Users** UI in {{kib}} or through the `user` API:

    ```sh
    POST _security/user/logstash_user
    {
      "password" : "x-pack-test-password",
      "roles" : [ "logstash_reader", "logstash_system"], <1>
      "full_name" : "Kibana User for Logstash"
    }
    ```

    1. `logstash_system` is a built-in role that provides the necessary permissions to check the availability of the supported features of {{es}} cluster.



### Configuring Logstash to use TLS/SSL encryption [ls-http-ssl]

If TLS encryption is enabled on an on premise {{es}} cluster, you need to configure the `ssl` and `cacert` options in your Logstash `.conf` file:

```js
output {
  elasticsearch {
    ...
    ssl_enabled => true
    ssl_certificate_authorities => '/path/to/cert.pem' <1>
  }
}
```

1. The path to the local `.pem` file that contains the Certificate Authority’s certificate.


::::{note}
Hosted {{ess}} simplifies security. This configuration step is not necessary for hosted Elasticsearch Service on Elastic Cloud. {{ess-leadin-short}}
::::



### Configuring the {{es}} output to use PKI authentication [ls-http-auth-pki]

The `elasticsearch` output supports PKI authentication. To use an X.509 client-certificate for authentication, you configure the `keystore` and `keystore_password` options in your Logstash `.conf` file:

```js
output {
  elasticsearch {
    ...
    ssl_keystore_path => /path/to/keystore.jks
    ssl_keystore_password => realpassword
    ssl_truststore_path =>  /path/to/truststore.jks <1>
    ssl_truststore_password =>  realpassword
  }
}
```

1. If you use a separate truststore, the truststore path and password are also required.



### Configuring credentials for {{ls}} monitoring [ls-monitoring-user]

If you want to monitor your Logstash instance with {{stack-monitor-features}}, and store the monitoring data in a secured {{es}} cluster, you must configure Logstash with a username and password for a user with the appropriate permissions.

The {{security-features}} come preconfigured with a [`logstash_system` built-in user](docs-content://deploy-manage/users-roles/cluster-or-deployment-auth/built-in-users.md) for this purpose. This user has the minimum permissions necessary for the monitoring function, and *should not* be used for any other purpose - it is specifically *not intended* for use within a Logstash pipeline.

By default, the `logstash_system` user does not have a password. The user will not be enabled until you set a password. See [Setting built-in user passwords](docs-content://deploy-manage/users-roles/cluster-or-deployment-auth/built-in-users.md#set-built-in-user-passwords).

Then configure the user and password in the `logstash.yml` configuration file:

```yaml
xpack.monitoring.elasticsearch.username: logstash_system
xpack.monitoring.elasticsearch.password: t0p.s3cr3t
```

If you initially installed an older version of {{xpack}} and then upgraded, the `logstash_system` user may have defaulted to `disabled` for security reasons. You can enable the user through the `user` API:

```console
PUT _security/user/logstash_system/_enable
```


### Configuring credentials for Centralized Pipeline Management [ls-pipeline-management-user]

If you plan to use Logstash [centralized pipeline management](/reference/logstash-centralized-pipeline-management.md), you need to configure the username and password that Logstash uses for managing configurations.

You configure the user and password in the `logstash.yml` configuration file:

```yaml
xpack.management.elasticsearch.username: logstash_admin_user <1>
xpack.management.elasticsearch.password: t0p.s3cr3t
```

1. The user you specify here must have the built-in `logstash_admin` role as well as the `logstash_writer` role that you created earlier.



### Grant access using API keys [ls-api-keys]

Instead of using usernames and passwords, you can use API keys to grant access to {{es}} resources. You can set API keys to expire at a certain time, and you can explicitly invalidate them. Any user with the `manage_api_key` or `manage_own_api_key` cluster privilege can create API keys.

Tips for creating API keys:

* API keys are tied to the cluster they are created in. If you are sending output to different clusters, be sure to create the correct kind of API key.
* {{ls}} can send both collected data and monitoring information to {{es}}. If you are sending both to the same cluster, you can use the same API key. For different clusters, you need an API key per cluster.
* A single cluster can share a key for ingestion and monitoring purposes.
* A production cluster and a monitoring cluster require separate keys.
* When you create an API key for {{ls}}, select **Logstash** from the **API key format** dropdown.
  This option formats the API key in the correct `id:api_key` format required by {{ls}}.

  :::{image} images/logstash_api_key_format.png
  :alt: API key format dropdown set to {{ls}}:
  :screenshot:
  :width: 400px
  :::

  The UI for API keys may look different depending on the deployment type.

::::{note}
For security reasons, we recommend using a unique API key per {{ls}} instance. You can create as many API keys per user as necessary.
::::


#### Create an API key [ls-create-api-key]

You can create API keys using either the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key) or the [Kibana UI](docs-content://deploy-manage/api-keys/elasticsearch-api-keys.md). This section walks you through creating an API key using the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key). The privileges needed are the same for either approach.

Here is an example that shows how to create an API key for publishing to {{es}} using the [Elasticsearch output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md).

```console
POST /_security/api_key
{
  "name": "logstash_host001", <1>
  "role_descriptors": {
    "logstash_writer": { <2>
      "cluster": ["monitor", "manage_ilm", "read_ilm"],
      "index": [
        {
          "names": ["logstash-*"],
          "privileges": ["view_index_metadata", "create_doc"]
        }
      ]
    }
  }
}
```

1. Name of the API key
2. Granted privileges


The return value should look similar to this:

```console-result
{
  "id":"TiNAGG4BaaMdaH1tRfuU", <1>
  "name":"logstash_host001",
  "api_key":"KnR6yE41RrSowb0kQ0HWoA" <2>
}
```

1. Unique id for this API key
2. Generated API key



##### Create an API key for publishing [ls-api-key-publish]

You’re in luck! The example we used in the [Create an API key](#ls-create-api-key) section creates an API key for publishing to {{es}} using the [Elasticsearch output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md).

Here’s an example using the API key in your [Elasticsearch output plugin](logstash-docs-md://lsr/plugins-outputs-elasticsearch.md) configuration.

```ruby
output {
  elasticsearch {
    api_key => "TiNAGG4BaaMdaH1tRfuU:KnR6yE41RrSowb0kQ0HWoA" <1>
  }
}
```

1. The format of the value is `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)



##### Create an API key for reading [ls-api-key-input]

Creating an API key to use for reading data from {{es}} is similar to creating an API key for publishing described earlier. You can use the example in the [Create an API key](#ls-create-api-key) section, granting the appropriate privileges.

Here’s an example using the API key in your [Elasticsearch inputs plugin](logstash-docs-md://lsr/plugins-inputs-elasticsearch.md) configuration.

```ruby
input {
  elasticsearch {
    "api_key" => "TiNAGG4BaaMdaH1tRfuU:KnR6yE41RrSowb0kQ0HWoA" <1>
  }
}
```

1. The format of the value is `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)



##### Create an API key for filtering [ls-api-key-filter]

Creating an API key to use for processing data from {{es}} is similar to creating an API key for publishing described earlier. You can use the example in the [Create an API key](#ls-create-api-key) section, granting the appropriate privileges.

Here’s an example using the API key in your [Elasticsearch filter plugin](logstash-docs-md://lsr/plugins-filters-elasticsearch.md) configuration.

```ruby
filter {
  elasticsearch {
    api_key => "TiNAGG4BaaMdaH1tRfuU:KnR6yE41RrSowb0kQ0HWoA" <1>
  }
}
```

1. The format of the value is `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)



##### Create an API key for monitoring [ls-api-key-monitor]

To create an API key to use for sending monitoring data to {{es}}, use the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key). For example:

```console
POST /_security/api_key
{
  "name": "logstash_host001", <1>
  "role_descriptors": {
    "logstash_monitoring": { <2>
      "cluster": ["monitor"],
      "index": [
        {
          "names": [".monitoring-ls-*"],
          "privileges": ["create_index", "create"]
        }
      ]
    }
  }
}
```

1. Name of the API key
2. Granted privileges


The return value should look similar to this:

```console-result
{
  "id":"TiNAGG4BaaMdaH1tRfuU", <1>
  "name":"logstash_host001",
  "api_key":"KnR6yE41RrSowb0kQ0HWoA" <2>
}
```

1. Unique id for this API key
2. Generated API key


Now you can use this API key in your logstash.yml configuration file:

```yaml
xpack.monitoring.elasticsearch.api_key: TiNAGG4BaaMdaH1tRfuU:KnR6yE41RrSowb0kQ0HWoA <1>
```

1. The format of the value is `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)



##### Create an API key for central management [ls-api-key-man]

To create an API key to use for central management, use the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key). For example:

```console
POST /_security/api_key
{
  "name": "logstash_host001", <1>
  "role_descriptors": {
    "logstash_monitoring": { <2>
      "cluster": ["monitor", "manage_logstash_pipelines"]
    }
  }
}
```

1. Name of the API key
2. Granted privileges


The return value should look similar to this:

```console-result
{
  "id":"TiNAGG4BaaMdaH1tRfuU", <1>
  "name":"logstash_host001",
  "api_key":"KnR6yE41RrSowb0kQ0HWoA" <2>
}
```

1. Unique id for this API key
2. Generated API key


Now you can use this API key in your logstash.yml configuration file:

```yaml
xpack.management.elasticsearch.api_key: TiNAGG4BaaMdaH1tRfuU:KnR6yE41RrSowb0kQ0HWoA <1>
```

1. The format of the value is `id:api_key`, where `id` and `api_key` are the values returned by the [Create API key API](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)



#### Learn more about API keys [learn-more-api-keys]

See the {{es}} API key documentation for more information:

* [Create API key](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-create-api-key)
* [Get API key information](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-get-api-key)
* [Invalidate API key](https://www.elastic.co/docs/api/doc/elasticsearch/operation/operation-security-invalidate-api-key)

See [API Keys](docs-content://deploy-manage/api-keys/elasticsearch-api-keys.md) for info on managing API keys through {{kib}}.
