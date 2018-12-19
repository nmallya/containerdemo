#!/usr/bin/env bash

PROJECT_ID=nmallyatestproject
GOOGLE_COMPUTE_ZONE=us-central1-b
GOOGLE_CLUSTER_NAME=cd-cluster


gcloud --quiet config set project ${PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --project ${PROJECT_ID}

ATTESTOR=test-attestor
ATTESTOR_EMAIL=nithdevsecops@gmail.com
NOTE_ID=test-attestor-note

# NOTE CREATION
cat > /tmp/note_payload.json << EOM
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "Attestor Note"
    }
  }
}
EOM

curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @/tmp/note_payload.json  \
    "https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"


curl \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://containeranalysis.googleapis.com/v1beta1/projects/${PROJECT_ID}/notes/${NOTE_ID}"



# GPG KEY CREATION

gpg2 --quick-generate-key --yes ${ATTESTOR_EMAIL}
gpg2 --list-keys ${ATTESTOR_EMAIL}
FINGERPRINT=$(gpg2 --list-keys ${ATTESTOR_EMAIL} | sed -n '2p')
echo "FINGERPRINT IS ${FINGERPRINT}"

# PUBLIC KEY FILE
rm /tmp/generated-key.pgp
gpg2 --armor --export ${FINGERPRINT} > /tmp/generated-key.pgp


# ATTESTOR CREATION
echo "YOU CAN SET UP THE ATTESTOR NOW"

gcloud beta container binauthz attestors create $ATTESTOR \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=$PROJECT_ID

# verify that the attestor was created
gcloud beta container binauthz attestors list

# associate the public key with the attestor
gcloud beta container binauthz attestors public-keys add \
    --attestor=$ATTESTOR  --public-key-file=/tmp/generated-key.pgp


sleep 10

# CHANGE BIN AUTH POLICY TO ONLY ALLOW SIGNED IMAGES FROM THIS ATTESTOR
gcloud beta container binauthz policy import ./sec-policy.yml

sleep 40

# SIGN IMAGE METADATA
IMAGE_PATH="gcr.io/google-samples/hello-app"
IMAGE_DIGEST="sha256:c62ead5b8c15c231f9e786250b07909daf6c266d0fcddd93fea882eb722c3be4"

rm /tmp/generated_payload.json

gcloud beta container binauthz create-signature-payload \
--artifact-url=${IMAGE_PATH}@${IMAGE_DIGEST} > /tmp/generated_payload.json

rm /tmp/generated_signature.pgp

gpg2 \
    --local-user ${ATTESTOR_EMAIL} \
    --armor \
    --output /tmp/generated_signature.pgp \
    --sign /tmp/generated_payload.json


gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR}" \
    --signature-file=/tmp/generated_signature.pgp \
    --pgp-key-fingerprint="${FINGERPRINT}"

gcloud beta container binauthz attestations list \
    --attestor=$ATTESTOR --attestor-project=$PROJECT_ID

gcloud beta container binauthz attestations list \
    --attestor=$ATTESTOR --attestor-project=$PROJECT_ID

# wait for the policy changes to take effect
sleep 40

kubectl run hello-server --image ${IMAGE_PATH}@${IMAGE_DIGEST} --port 8080

kubectl get pods

