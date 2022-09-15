In this example, Logstash enable persistent queue and dead letter queue. There are two pipelines `main` and `dlq`.
`main` generates uptime event to index `uptime-%{+YYYY.MM.dd}`.
`dlq` takes the fail events of `main` to index `dlq-%{+YYYY.MM.dd}`.

Besides PQ and DLQ, there are a few plugins require persistent volume to store the state of work in sincedb.
- logstash-input-s3
- logstash-input-jdbc
- logstash-input-file
- logstash-input-dead_letter_queue

## Deploy the example
```
kubectl apply -f .
```

## Check PQ status
```
kubectl exec logstash-pq-0 -it -- /usr/share/logstash/bin/pqcheck /usr/share/logstash/data/queue/main
```

## Generate DLQ event
Using the [_close](https://www.elastic.co/guide/en/elasticsearch/reference/8.3/indices-close.html) API to manually close the index will generate event in DLQ
```
PASSWORD=$(kubectl get secret demo2-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
curl -u "elastic:$PASSWORD" -X POST -k "https://demo2-es-http:9200/uptime-YYYY.MM.dd/_close"
```

Index can be reopened with [_open](https://www.elastic.co/guide/en/elasticsearch/reference/8.3/indices-open-close.html) API

## Configuration

### pipeline config
`001-configmap.yaml` customize `logstash.yml` and `pipelines.yml`, and define two pipelines in `logstash.conf` and `dlq.conf`.

```
  logstash.yml: |
    api.http.host: "0.0.0.0"
    queue.type: persisted
    dead_letter_queue.enable: true
    dead_letter_queue.flush_interval: 1000
  pipelines.yml: |
    - pipeline.id: main
      path.config: "/usr/share/logstash/pipeline/logstash.conf"
    - pipeline.id: dlq
      path.config: "/usr/share/logstash/pipeline/dlq.conf"
```

`queue.type: persisted` enable persisted queue.

`dead_letter_queue.enable: true` enable DLQ of elasticsearch output.

### persist data

Logstash with PQ enabled should persist data with `PersistentVolumeClaim` to prevent data loss

```
  volumeClaimTemplates:
    - metadata:
        name: logstash-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 2Gi
```

Persistent volume expansion feature depends on the storage class and the cloud provider.
Checkout [google cloud doc](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/volume-expansion)

## Clean up the example
```
kubectl delete service,configmap,secret,elasticsearch,statefulset,pvc -l app=logstash-pq-demo
```

## Autoscaling

Scaling out Logstash with PQ should be fine, but when it scales down, events may be leftover in the queue. 
Setting `queue.drain: true` can make Logstash to wait until the persistent queue is drained before shutting down. 
The default `terminationGracePeriodSeconds` is 30 seconds which is likely not enough to drain all events.
A workaround is to set a very long period like 1 year in `terminationGracePeriodSeconds` to make sure Logstash get enough time.

DLQ?

other plugin?


