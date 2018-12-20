#!/usr/bin/env bash
PROJECT_ID=nmallyatestproject
GOOGLE_COMPUTE_ZONE=us-central1-b
GOOGLE_CLUSTER_NAME=cd-cluster



gcloud --quiet config set project ${PROJECT_ID}
gcloud --quiet config set compute/zone ${GOOGLE_COMPUTE_ZONE}
gcloud --quiet container clusters get-credentials ${GOOGLE_CLUSTER_NAME} --zone ${GOOGLE_COMPUTE_ZONE} --project ${PROJECT_ID}


ATTESTOR="binauth-attestor"
ATTESTOR_EMAIL=nithdevsecops@gmail.com #the email associated with the project
NOTE_ID="BinAuth-Note"
NOTE_DESCRIPTION="Bin Auth Note"
NOTE_PAYLOAD_PATH="note_payload.json"
PGP_PUB_KEY="generated-key.pgp" #the public key file from the PGP key pair
GENERATED_PAYLOAD="generated_payload.json"
GENERATED_SIGNATURE="generated_signature.pgp"

# cleanup before the action begins - USE WITH CARE
kubectl delete pod --all
kubectl delete event --all


# create note payload
cat > ${NOTE_PAYLOAD_PATH} << EOF
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "${NOTE_DESCRIPTION}"
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


# CHANGE BIN AUTH POLICY TO ONLY ALLOW SIGNED IMAGES FROM THIS ATTESTOR
gcloud beta container binauthz policy import ./sec-policy.yml
