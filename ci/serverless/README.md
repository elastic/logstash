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
   - save the credentials of superuser
4. [Create API key](#create-api-key)
   - save the api keys for metricbeat and elasticsearch
   - get the elasticsearch and kibana endpoint from UI or [API](https://docs.elastic.dev/serverless/create-project#get-project)
5. [Save credentials to Vault](#save-credentials-to-vault)


### Create API key

#### Logstash

Plugin user
```
POST /_security/api_key
{
  "name": "plugin_user",
  "expiration": "365d",   
  "role_descriptors": { 
    "plugin_user_role": {
      "cluster": ["manage_index_templates", "monitor"], 
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

Integration User
```
POST /_security/api_key
{
  "name": "integration_user",
  "expiration": "365d",   
  "role_descriptors": { 
    "integration_user_role": {
      "cluster": ["manage_index_templates", "read_pipeline", "monitor"]
    }
  }
}
```

CPM User
```
POST /_security/api_key
{
  "name": "cpm_user",
  "expiration": "365d",   
  "role_descriptors": { 
    "cpm_user_role": {
      "cluster": ["manage_logstash_pipelines", "monitor"]
    }
  }
}
```

Tester 
```
POST /_security/api_key
{
  "name": "tester_user",
  "expiration": "365d",   
  "role_descriptors": { 
    "tester_user_role": {
      "cluster": ["manage_index_templates", "manage_logstash_pipelines","manage_ingest_pipelines"], 
      "indices": [
        {
          "names": [ "logstash", "logstash-*", "ecs-logstash", "ecs-logstash-*", "serverless*", "logs-*", "metrics-*", "synthetics-*", "traces-*", "*test*" ], 
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

[Setup Vault](https://github.com/elastic/infra/tree/master/docs/vault) if you haven't.

The username, password, API key and hosts are stored in `secret/ci/elastic-logstash/serverless-test`.

| Vault field                 |                                                         |
|-----------------------------|---------------------------------------------------------|
| es_host                     | Elasticsearch endpoint with port                        |
| es_superuser                | username of superuser                                   |
| es_superuser_pw             | password of superuser                                   |
| kb_host                     | Kibana endpoint with port                               |
| mb_api_key                  | id:api_key for for beats                                |  
| plugin_api_key              | id:api_key for es-output/filter/input                   |
| integration_api_key_encoded | base64 of api_key for elastic integration               |
| tester_api_key_encoded      | base64 of api_key for the script to update testing data |
| cpm_api_key                 | id:api_key for central pipeline management              |


```bash
vault write secret/ci/elastic-logstash/serverless-test es_host="REDACTED" es_superuser="REDACTED" es_superuser_pw="REDACTED" " kb_host="REDACTED" mb_api_key="REDACTED" plugin_api_key="REDACTED" integration_api_key_encoded="REDACTED" tester_api_key_encoded="REDACTED" cpm_api_key="REDACTED"
```