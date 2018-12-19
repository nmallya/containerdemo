#!/bin/bash

SIGNATURE_FILE="./kube/signature.pgp"
PRIVATE_KEY_FILE="./kube/my-private-key.asc"
PAYLOAD_FILE="./kube/generated_payload.json"
PUBLIC_KEY_FILE="./kube/public.pgp"

# GET THE IMAGE DIGEST FOR THE LATEST IMAGE DEPLOYED TO GCR
IMAGE_PATH="gcr.io/${GOOGLE_PROJECT_ID}/containerdemo"
IMAGE_DIGEST="$(gcloud container images list-tags --format='get(digest)' $IMAGE_PATH | head -1)"
ATTESTOR_EMAIL=nithdevsecops@gmail.com


# CREATE THE SIGNATURE PAYLOAD JSON FILE
gcloud beta container binauthz create-signature-payload \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" > ${PAYLOAD_FILE}

# BASE64 DECRYPT THE PRIVATE KEY - NEEDED FOR SIGNING THE IMAGE DIGEST
echo -n $BINAUTH_PRIVATE_KEY | base64 -d > $PRIVATE_KEY_FILE

export GNUPGHOME="$(mktemp -d)"
gpg2 --import "$PUBLIC_KEY_FILE"
gpg2 --import "$PRIVATE_KEY_FILE"

echo "PUBLIC KEYS"
gpg2 --list-keys

echo "PRIVATE KEYS"
gpg2 --list-secret-keys


echo "GET THE PGP FINGERPRINT"
PGP_FINGERPRINT="2F9B955A09D31711F5EA77A7095551B4B03789FB"
#"$(gpg2 --list-keys ${ATTESTOR_EMAIL} | sed -n '2p')"
echo "PGP FINGERPRINT IS $PGP_FINGERPRINT"

# SIGN THE PAYLOAD JSON FILE
gpg2 \
    --local-user  $ATTESTOR_EMAIL \
    --armor \
    --output $SIGNATURE_FILE \
    --sign $PAYLOAD_FILE

cat "$SIGNATURE_FILE"

# SUBMIT THE ATTESTATION TO BIN AUTH

gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}@${IMAGE_DIGEST}" \
    --attestor="projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}" \
    --signature-file=${SIGNATURE_FILE} \
    --pgp-key-fingerprint="${PGP_FINGERPRINT}"