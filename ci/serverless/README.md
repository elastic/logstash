The test cases against serverless Elasticsearch covers the following scenarios

- es-output
- es-input
- es-filter
- elastic-integration-filter (Logstash run ingest pipeline)
- DLQ
- central pipeline management
- Kibana API for pipeline management (CPM)
- Metricbeat monitoring 
- ~~Logstash legacy monitoring~~

### Credentials

The username, password, API key and hosts are stored in Vault. 

Generate API key for Logstash with limited privileges instead of using superuser `elastic`.

```
POST /_security/api_key
{
  "name": "logstash_serverless_apikey",
  "expiration": "365d",   
  "role_descriptors": { 
    "logstash_serverless_role": {
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