# Deploy logstash to Kubernetes

This repository used for demo purpose. It includes a collection of Logstash setup connecting to Elastic stack in Kubernetes.

- filebeat -> logstash -> elasticsearch
- logstash with PQ, DLQ -> elasticsearch

# Prerequisite

Install Elastic CRD
```
helm repo add elastic https://helm.elastic.co && helm repo update
helm install elastic-operator elastic/eck-operator
```

# How to run

Please check the readme in the folder

The demo is tested in minikube kubernetes 1.23

# Troubleshoot

### Unhealthy Logstash pod

Logstash restarts several times and the readiness probe failed
```
NAMESPACE     NAME                                  READY   STATUS    RESTARTS      AGE
default       logstash-f7768c66d-grzbj              0/1     Running   3 (55s ago)   6m32s
```

Possible solutions
- In logstash.yml, set `api.http.host: 0.0.0.0` to enable health check connection.
- Review CPU and memory if they are enough to start Logstash within `initialDelaySeconds` of readiness probe.
- Logstash takes longer time to verify persistent queue at startup depending on the size of the queue, hence might be unresponsive to readiness probe. Adjust `initialDelaySeconds` of readinessProbe if needed.

### Pod is killed 

Logstash is ready but restarts
```
NAMESPACE     NAME                               READY   STATUS    RESTARTS      AGE
default       logstash-f7768c66d-grzbj           1/1     Running   2 (22s ago)   2m3s
```

Possible solutions
- Run `kubectl get event --watch` or `kubectl describe pod logstash-f7768c66d-grzbj` to check kubernetes event, which might show the reason.
- A common case is the status shows `OOMKilled`. If the memory of Logstash use more than the declared resource limit, kubernetes kill the pod immediately and the log of Logstash does not show any shutdown related message.

### Persistent queue does not drain before shutdown

Logstash is set to drain `queue.drain: true` but the pod is gone in 30 seconds after getting SIGTERM 

Possible solutions
- Set a long enough `terminationGracePeriodSeconds`. The drain process may take longer depending on the size of the queue. If the process cannot shutdown within `terminationGracePeriodSeconds`, kubernetes will kill the pod. 