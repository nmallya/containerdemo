gcloud config set project nmallyatestproject
gcloud container clusters get-credentials cd-cluster --zone us-central1-a --project nmallyatestproject
kubectl apply -f ../kube/web-deployment.yml