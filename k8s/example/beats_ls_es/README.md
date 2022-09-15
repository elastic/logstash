In this example, Filebeat collect the container log of kube-apiserver and output to Logstash, and then Logstash send events to Elasticsearch

For the moment, it includes
- Filebeat <> Logstash tls mutual verification
- Logstash <> Elasticsearch tls setup
- Logstash with memory queue scale with hpa
- Metricbeat collects metrics of Logstash and Elasticsearch
- Kibana stack monitoring

## Deploy the example
```
# prepare cert/key for filebeat <> logstash
./cert/generate_cert.sh

kubectl apply -f .
```

## Access Kibana

Port forwarding kibana port 5601 and open https://localhost:5601/ 
```
kubectl port-forward service/demo-kb-http 5601
```

Login as the elastic user. The password can be obtained with the following command
```
kubectl get secret demo-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

## Configuration

### Secret setting
`generate_cert.sh` generates ca.crt, client.key, client.crt, server.key and server.pkcs8.key to secure connection between filebeat and logstash.

`001-secret.yaml` contains all certs and keys for filebeat and logstash.
Filebeat uses ca.crt, client.key and client.crt.
Logstash uses ca.crt, server.key and server.pkcs8.key.

### Filebeat config
Filebeat mounts the secret `logstash-beats-tls` and config logstash output as following.
```
    output.logstash:
      hosts:
        - "logstash:5044"
      ssl.certificate_authorities: ["/usr/share/filebeat/ca.crt"]
      ssl.certificate: "/usr/share/filebeat/client.crt"
      ssl.key: "/usr/share/filebeat/client.key"
```

### Logstash config

Logstash setting and pipeline are in `001-configmap.yaml`

```
  logstash.conf: |
    input {
      beats {
        port => "5044"
        ssl => true
        ssl_certificate_authorities => ["/usr/share/logstash/config/ca.crt"]
        ssl_certificate => "/usr/share/logstash/config/server.crt"
        ssl_key => "/usr/share/logstash/config/server.pkcs8.key"
        ssl_verify_mode => "force_peer"
      }
    }
    output {
      elasticsearch { 
        hosts => ["https://demo-es-http:9200"]
        index => "kube-apiserver-%{+YYYY.MM.dd}"
        cacert => "/usr/share/logstash/config/es_ca.crt"
        user => 'elastic'
        password => '${ELASTICSEARCH_PASSWORD}'
      }
    }
```

Deployment mounts a couple of secrets for secure setup.

```
      volumes:
        - name: es-certs
          secret:
            secretName: demo-es-http-certs-public
        - name: es-user
          secret:
            secretName: demo-es-elastic-user
        - name: logstash-beats-tls
          secret:
            secretName: logstash-beats-tls
```

`logstash-beats-tls` is for beats input ca.crt, server.crt and server.pkcs8.key

`demo-es-http-certs-public` contains CA cert for elasticsearch output, checkout [TLS certificates](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-tls-certificates.html)

The elasticsearch password is taken from `demo-es-elastic-user` and pass to pipeline as environment variable `ELASTICSEARCH_PASSWORD` , checkout [access the Elasticsearch endpoint](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-request-elasticsearch-endpoint.html)

### Metricbeat config
Metricbeat enable logstash module and collect metric from `logstash:9600`.
```
      - module: logstash
        metricsets:
          - node
          - node_stats
        period: 10s
        hosts:
          - logstash:9600
        xpack.enabled: true
```

## Clean up the example
```
kubectl delete service,pods,deployment,hpa,configmap,secret,beat,elasticsearch,kibana -l app=logstash-demo
```

## Install plugin

Add install command in `Deployment`
```
  image: "docker.elastic.co/logstash/logstash:8.3.2"
  command: ["/bin/bash", "-c"]
  args:
    - |
      set -e
      bin/logstash-plugin install logstash-output-google_bigquery
      /usr/local/bin/docker-entrypoint
```

## Connect to local Elasticsearch 

In test environment, you can connect the host's Elasticsearch from Logstash in kubernetes.
- Set Logstash Deployment `spec.template.spec.hostNetwork` to `true`
- Add Elasticsearch CA cert to Secret. `kubectl create secret generic es-certs --from-file=ca.crt=/YOUR/ELASTICSEARCH/PATH/config/certs/http_ca.crt`
- Mount the Secret `es-certs` to Logstash Deployment
  ```
          volumeMounts:
            - name: es-certs
              mountPath: /usr/share/logstash/config/ca.crt
              subPath: ca.crt
    volumes:
      - name: es-certs
        secret:
          secretName: es-certs
  ```
- Connect Elasticsearch with IP
  ```
  elasticsearch { 
    hosts => ["https://192.168.1.70:9200"]
    cacert => "/usr/share/logstash/config/ca.crt"
    user => 'elastic'
    password => 'ELASTICSEARCH_PASSWORD'
  }
  ```

## Connect to Elastic Cloud Elasticsearch

Config cloud endpoint and username and password to `elasticsearch { }` 

## Autoscaling

To scale Logstash with memory queue, tune the target CPU and memory of `HorizontalPodAutoscaler`.