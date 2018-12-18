#!/bin/bash

sudo apt-get install gnupg2 -y
gpg2 --list-keys
#
#echo "STARTING GPG STUFF..."
#PROJECT_ID="nmallyatestproject"
#ATTESTOR_EMAIL="myemail@gmail.com"
#PGP_PUB_KEY="generated-key.pgp"
#
#export GPG_AGENT_INFO=${HOME}/.gnupg/S.gpg-agent:0:1
#echo "gpg agent is $GPG_AGENT_INFO"
#
#gpg --quick-generate-key --no-tty --batch --yes ${ATTESTOR_EMAIL}
##gpg --quick-generate-key --yes ${ATTESTOR_EMAIL}
#gpg --armor --export "${ATTESTOR_EMAIL}" > ${PGP_PUB_KEY}
#
#
#
#
##gpg --quick-generate-key --no-tty --batch --yes ${ATTESTOR_EMAIL}