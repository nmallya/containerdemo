#!/bin/bash

#apt-get install rng-tools -y
#rngd -r /dev/urandom



echo "STARTING GPG STUFF..."
PROJECT_ID="nmallyatestproject"
ATTESTOR_EMAIL="nithdevsecops@gmail.com"
PGP_PUB_KEY="generated-key.pgp"

gpg --quick-generate-key --yes ${ATTESTOR_EMAIL}
gpg --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}
#gcloud --project="${PROJECT_ID}" beta container binauthz attestors public-keys add --attestor="${ATTESTOR}" --public-key-file="${PGP_PUB_KEY}"
#gcloud --project="${PROJECT_ID}" \
#    beta container binauthz attestors list