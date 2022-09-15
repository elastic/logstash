Initialize cluster on GCP
```bash
# login GCP
export GOOGLE_PROJECT=elastic-logstash
gcloud auth login
# create GKE cluster
terraform init
terraform apply
# fetch credentials for a running cluster lsdev
gcloud container clusters get-credentials lsdev --zone=europe-north1-a
# check kubectl is working
kubectl get nodes
```

Deploy example
```bash
kubectl apply -f ../example/beats_ls_es
```

Delete GKE cluster
```bash
terraform destroy
```
