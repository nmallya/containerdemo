#!/usr/bin/env bash

# Project housekeeping - enable APIs
echo "Enabling Container API"
gcloud services enable container.googleapis.com
echo "Enabling Bin Auth API"
gcloud services enable binaryauthorization.googleapis.com


# CREATE AND PERSIST NOTE ---------------------------------------------------  BEGIN
PROJECT_ID=nmallyatestproject
NOTE_ID=cd-attestor-note

cat > ./create_note_request.json << EOM
{
  "name": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "This note represents an attestation authority"
    }
  }
}
EOM

curl -vvv -X POST \
    -H "Content-Type: application/json"  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @./create_note_request.json  \
    "https://containeranalysis.googleapis.com/v1alpha1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# verify that the note was saved
curl -vvv  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://containeranalysis.googleapis.com/v1alpha1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

# CREATE AND PERSIST NOTE ---------------------------------------------------  END


# CREATE AND PERSIST ATTESTOR ---------------------------------------------------  BEGIN
ATTESTOR_ID=cd-attestor
ATTESTOR_EMAIL=nithdevsecops@gmail.com

gcloud beta container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=$PROJECT_ID

# verify that the attestor was created
gcloud beta container binauthz attestors list

# CREATE AND PERSIST ATTESTOR ---------------------------------------------------  END

# GENERATE PGP KEY ---------------------------- BEGIN
gpg2 --quick-generate-key --yes ${ATTESTOR_EMAIL}

# extract the public key into a file
gpg2 --armor --export ${ATTESTOR_EMAIL} > ./public.pgp

# associate the public key with the attestor
gcloud beta container binauthz attestors public-keys add \
    --attestor=$ATTESTOR_ID  --public-key-file=./public.pgp
# GENERATE PGP KEY ---------------------------- END