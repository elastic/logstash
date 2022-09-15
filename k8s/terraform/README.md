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
# install CRD
kubectl create -f https://download.elastic.co/downloads/eck/2.4.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.4.0/operator.yaml
kubectl apply -f ../example/beats_ls_es
```

Delete GKE cluster
```bash
terraform destroy
```
