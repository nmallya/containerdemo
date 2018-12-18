#!/bin/bash

apt-get install rng-tools -y
rngd -r /dev/urandom

apt-get install gnupg2 -y

echo "INSTALLED GNUPG2"
echo "STOPPING AGENT GNUPG2"
gpg-connect-agent /bye

echo "STARTING GPG STUFF..."
PROJECT_ID="nmallyatestproject"
ATTESTOR_EMAIL="nithdevsecops@gmail.com"
PGP_PUB_KEY="generated-key.pgp"

gpg2 --quick-generate-key --yes ${ATTESTOR_EMAIL}
gpg2 --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}
#gcloud --project="${PROJECT_ID}" beta container binauthz attestors public-keys add --attestor="${ATTESTOR}" --public-key-file="${PGP_PUB_KEY}"
#gcloud --project="${PROJECT_ID}" \
#    beta container binauthz attestors list