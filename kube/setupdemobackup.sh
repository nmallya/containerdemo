#!/usr/bin/env bash
PROJECT_ID=nmallyatestproject
GOOGLE_COMPUTE_ZONE=us-central1-b
GOOGLE_CLUSTER_NAME=cd-cluster



gcloud --quiet config set project ${PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --project ${PROJECT_ID}


ATTESTOR="manually-verified" # No spaces allowed
ATTESTOR_NAME="Manual Attestor"
ATTESTOR_EMAIL="$(gcloud config get-value core/account)" # This uses your current user/email
NOTE_ID="Human-Attestor-Note" # No spaces
NOTE_DESC="Human Attestation Note Demo"
NOTE_PAYLOAD_PATH="note_payload.json"
IAM_REQUEST_JSON="iam_request.json"
PGP_PUB_KEY="generated-key.pgp"
GENERATED_PAYLOAD="generated_payload.json"
GENERATED_SIGNATURE="generated_signature.pgp"


#curl -vvv -X DELETE  \
#    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
#    "https://containeranalysis.googleapis.com/v1alpha1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

#docker build -t containerdemo -f ../Dockerfile .
#docker tag containerdemo gcr.io/${PROJECT_ID}/containerdemo:v2
#gcloud docker -- push "gcr.io/${PROJECT_ID}/containerdemo:v2"

#docker pull gcr.io/google-containers/nginx:latest
#docker tag gcr.io/google-containers/nginx "gcr.io/${PROJECT_ID}/nginx:v2"
#gcloud docker -- push "gcr.io/${PROJECT_ID}/nginx:v2"
#gcloud container images list-tags "gcr.io/${PROJECT_ID}/nginx"

#cat << EOF | kubectl create -f -
#apiVersion: v1
#kind: Pod
#metadata:
#  name: nginx
#spec:
#  containers:
#  - name: nginx
#    image: "gcr.io/${PROJECT_ID}/nginx:v2"
#    ports:
#    - containerPort: 80
#EOF
#kubectl rollout status deployment/nginx
#kubectl get pods
kubectl delete pod --all
kubectl delete event --all



#cat > ${NOTE_PAYLOAD_PATH} << EOF
#{
#  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
#  "attestation_authority": {
#    "hint": {
#      "human_readable_name": "${NOTE_DESC}"
#    }
#  }
#}
#EOF
#
#curl -X POST \
#    -H "Content-Type: application/json" \
#    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
#    --data-binary @${NOTE_PAYLOAD_PATH}  \
#    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"
#
#curl -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
#    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/${NOTE_ID}"
#
#
#gpg --quick-generate-key --yes ${ATTESTOR_EMAIL}
#
#gpg --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}
#
#gcloud --project="${PROJECT_ID}" \
#    beta container binauthz attestors create "${ATTESTOR}" \
#    --attestation-authority-note="${NOTE_ID}" \
#    --attestation-authority-note-project="${PROJECT_ID}"
#
#gcloud --project="${PROJECT_ID}" \
#    beta container binauthz attestors public-keys add \
#    --attestor="${ATTESTOR}" \
#    --public-key-file="${PGP_PUB_KEY}"

gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors list


PGP_FINGERPRINT="$(gpg --list-keys ${ATTESTOR_EMAIL} | head -2 | tail -1 | awk '{print $1}')"
IMAGE_PATH="gcr.io/${PROJECT_ID}/containerdemo"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"

rm ${GENERATED_PAYLOAD}
gcloud beta container binauthz create-signature-payload \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" > ${GENERATED_PAYLOAD}

cat "${GENERATED_PAYLOAD}"

rm ${GENERATED_SIGNATURE}
gpg --local-user "${ATTESTOR_EMAIL}" \
    --armor \
    --output ${GENERATED_SIGNATURE} \
    --sign ${GENERATED_PAYLOAD}

gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}" \
    --signature-file=${GENERATED_SIGNATURE} \
    --pgp-key-fingerprint="${PGP_FINGERPRINT}"

gcloud beta container binauthz attestations list \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}"

echo "projects/${PROJECT_ID}/attestors/${ATTESTOR}"

#echo "SLEEPING FOR 40 SECS..."
#sleep 40
#gcloud beta container binauthz policy import ./sec-policy.yml


echo "SLEEPING FOR 40 SECS..."
sleep 40
echo "DONE DONE DONE"

cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: containerdemo
spec:
  containers:
  - name: containerdemo
    image: "${IMAGE_PATH}@${IMAGE_DIGEST}"
    ports:
    - containerPort: 80
EOF

#kubectl rollout status deployment/nginx
kubectl get pods

