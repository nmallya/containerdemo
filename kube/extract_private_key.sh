#!/usr/bin/env bash

ATTESTOR_EMAIL=nithdevsecops@gmail.com

# RUN THIS ON THE MACHINE WHERE YOU GENERATED THE PGP KEY PAIR
# show secret key
gpg --list-secret-keys

PGP_FINGERPRINT="$(gpg --list-keys ${ATTESTOR_EMAIL} | head -2 | tail -1 | awk '{print $1}')"
echo $PGP_FINGERPRINT
# copy the id from the above command and use it extract the key into a file
gpg --export-secret-keys ${PGP_FINGERPRINT} > /tmp/my-private-key.asc

# base64 encode the key value
base64 -i /tmp/my-private-key.asc -o /tmp/my-base64-private-key.asc

cat /tmp/my-base64-private-key.asc
#copy the above value into your Circleci env variable BINAUTH_PRIVATE_KEY