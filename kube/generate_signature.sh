#!/bin/bash

signature_file="./kube/signature.pgp"
private_key_file="./kube/my-private-key.asc"
payload_file="./kube/generated_payload.json"

echo -n $BINAUTH_PRIVATE_KEY | base64 -d > $private_key_file

export GNUPGHOME="$(mktemp -d)"
gpg2 --import "$private_key_file"
gpg2 --list-secret-keys


gpg2 \
    --local-user  attestor@example.com \
    --armor \
    --output $signature_file \
    --sign $payload_file

cat "$signature_file"

#cat >foo <<EOF
#     %echo Generating a basic OpenPGP key
#     Key-Type: DSA
#     Key-Length: 1024
#     Subkey-Type: ELG-E
#     Subkey-Length: 1024
#     Name-Real: Joe Tester
#     Name-Comment: with stupid passphrase
#     Name-Email: joe@foo.bar
#     Expire-Date: 0
#     Passphrase: abc
#     # Do a commit here, so that we can later print "done" :-)
#     %commit
#     %echo done
#EOF
#gpg2 --quick-generate-key --yes "myemail@gmail.com"
#
#
#echo "STARTING GPG STUFF..."
#PROJECT_ID="nmallyatestproject"
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