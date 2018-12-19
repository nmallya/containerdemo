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

# cleanup
kubectl delete pod --all
kubectl delete event --all


# create note payload
cat > ${NOTE_PAYLOAD_PATH} << EOF
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "${NOTE_DESC}"
    }
  }
}
EOF

# send to Bin Auth
curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @${NOTE_PAYLOAD_PATH}  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# verify that it is created
curl -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/${NOTE_ID}"


# generate pgp key pair
gpg --quick-generate-key --yes ${ATTESTOR_EMAIL}

# export public key to file
gpg --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}

# create attestor
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors create "${ATTESTOR}" \
    --attestation-authority-note="${NOTE_ID}" \
    --attestation-authority-note-project="${PROJECT_ID}"

# associate public key to attestor
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors public-keys add \
    --attestor="${ATTESTOR}" \
    --public-key-file="${PGP_PUB_KEY}"

# verify attestor created properly
gcloud --project="${PROJECT_ID}" \
    beta container binauthz attestors list


# get pgp fingerprint for public key
PGP_FINGERPRINT="$(gpg --list-keys ${ATTESTOR_EMAIL} | head -2 | tail -1 | awk '{print $1}')"

# image digest details
IMAGE_PATH="gcr.io/${PROJECT_ID}/containerdemo"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"

# create signature payload
rm ${GENERATED_PAYLOAD}
gcloud beta container binauthz create-signature-payload \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" > ${GENERATED_PAYLOAD}

cat "${GENERATED_PAYLOAD}"

# sign payload with private key
rm ${GENERATED_SIGNATURE}
gpg --local-user "${ATTESTOR_EMAIL}" \
    --armor \
    --output ${GENERATED_SIGNATURE} \
    --sign ${GENERATED_PAYLOAD}

# create attestation with the signed payload
gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}" \
    --signature-file=${GENERATED_SIGNATURE} \
    --pgp-key-fingerprint="${PGP_FINGERPRINT}"

# verify that attestation created properly
gcloud beta container binauthz attestations list \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}"

echo "projects/${PROJECT_ID}/attestors/${ATTESTOR}"

# update Bin Auth policy to allow only images attested by our attestor and in the specified cluster
echo "SLEEPING FOR 40 SECS..."
sleep 40
gcloud beta container binauthz policy import ./sec-policy.yml


echo "SLEEPING FOR 40 SECS..."
sleep 40
echo "DONE DONE DONE"

# deploy the latest version of the image
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
    - containerPort: 3000
EOF

#kubectl rollout status deployment/nginx
kubectl get pods

#curl -vvv -X DELETE  \
#    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
#    "https://containeranalysis.googleapis.com/v1alpha1/projects/${PROJECT_ID}/notes/${NOTE_ID}"