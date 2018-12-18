#!/bin/bash


ATTESTOR_EMAIL="myemail@gmail.com"

export GNUPGHOME="$(mktemp -d)"
cat >foo <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: DSA
     Key-Length: 1024
     Subkey-Type: ELG-E
     Subkey-Length: 1024
     Name-Real: Joe Tester
     Name-Comment: with stupid passphrase
     Name-Email: joe@foo.bar
     Expire-Date: 0
     Passphrase: abc
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
EOF
gpg2 --batch --quick-generate-key --yes "myemail@gmail.com"

gpg2 --list-secret-keys
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