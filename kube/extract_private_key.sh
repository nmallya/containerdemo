#!/usr/bin/env bash

ATTESTOR_EMAIL=nithdevsecops@gmail.com

# RUN THIS ON THE MACHINE WHERE YOU GENERATED THE PGP KEY PAIR
# show secret key
gpg --list-secret-keys
#sample output below
#/Users/nithinmallya/.gnupg/pubring.kbx
#--------------------------------------
#sec   rsa2048 2018-12-19 [SC] [expires: 2020-12-18]
#      2F9B955A09D31711F5EA77A7095551B4B03789FB
#uid           [ultimate] nithindevsecops@gmail.com
#ssb   rsa2048 2018-12-19 [E]

PGP_FINGERPRINT="$(gpg --list-keys ${ATTESTOR_EMAIL} | head -2 | tail -1 | awk '{print $1}')"
echo $PGP_FINGERPRINT
# copy the id from the above command and use it extract the key into a file
gpg --export-secret-keys ${PGP_FINGERPRINT} > my-private-key.asc

# base64 encode the key value
base64 -i ./my-private-key.asc -o ./my-base64-private-key.asc

cat ./my-base64-private-key.asc
#copy the above value into your Circleci env variable BINAUTH_PRIVATE_KEY