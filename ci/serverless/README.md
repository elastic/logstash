The test cases against serverless Elasticsearch cover the following scenarios

- es-output
- es-input
- es-filter
- elastic-integration-filter (Logstash run ingest pipeline)
- DLQ
- central pipeline management
- Kibana API for pipeline management (CPM)
- Metricbeat monitoring
- ~~Logstash legacy monitoring~~

### Setup testing endpoint
1. Go to https://console.qa.cld.elstc.co
2. Create deployment. Choose AWS as cloud provider.
3. [Create fully-managed project](https://docs.elastic.dev/serverless/create-project)
4. [Create API key](#create-api-key)
5. [Save credentials to Vault](#save-credentials-to-vault). [Setup Vault](https://github.com/elastic/infra/tree/master/docs/vault) if you haven't.
   - vault write secret/ci/elastic-logstash/serverless-test es_host="REDACTED" es_superuser="REDACTED" es_superuser_pw="REDACTED" " kb_host="REDACTED" ls_role_api_key_encoded="REDACTED" ls_plugin_api_key="REDACTED"

### Create API key

#### Logstash
Use limited privileges instead of using superuser `elastic`.

```
POST /_security/api_key
{
  "name": "logstash_user",
  "expiration": "365d",   
  "role_descriptors": { 
    "logstash_user_role": {
      "cluster": ["monitor", "manage_index_templates", "manage_logstash_pipelines", "cluster:admin/ingest/pipeline/get", "read_pipeline"], 
      "indices": [
        {
          "names": [ "logstash", "logstash-*", "ecs-logstash", "ecs-logstash-*", "serverless*", "logs-*", "metrics-*", "synthetics-*", "traces-*" ], 
          "privileges": ["manage", "write", "create_index", "read", "view_index_metadata"]  
        }
      ]
    }
  }
}
```

#### MetricBeat
Grant metricbeat write permission.

```
POST /_security/api_key
{
  "name": "metricbeat_user", 
  "role_descriptors": {
    "metricbeat_user_role": { 
      "cluster": ["monitor", "read_ilm", "read_pipeline"],
      "index": [
        {
          "names": ["metricbeat-*"],
          "privileges": ["view_index_metadata", "create_doc"]
        }
      ]
    }
  }
}
```

### Save credentials to Vault

The username, password, API key and hosts are stored in Vault `secret/ci/elastic-logstash/serverless-test`.

| Vault field             |                                       |
|-------------------------|---------------------------------------|
| es_host                 | Elasticsearch endpoint with port      |
| es_superuser            | username of superuser                 |
| es_superuser_pw         | password of superuser                 |
| kb_host                 | Kibana endpoint with port             |
| ls_role_api_key_encoded | base64 api_key for integration-filter |
| ls_plugin_api_key       | id:api_key for Logstash plugins       |
| mb_api_key              | api key for beats to elasticsearch    |  

