#!/bin/bash

IMAGE_PATH="gcr.io/nmallyatestproject/containerdemo"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"
FINAL_IMAGE=$IMAGE_PATH@$IMAGE_DIGEST
echo $FINAL_IMAGE
pwd
ls
sed -i '' "s|MY_IMAGE|$FINAL_IMAGE|g" "./kube/web-deployment.yml"

