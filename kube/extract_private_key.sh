#!/usr/bin/env bash

# RUN THIS ON THE MACHINE WHERE YOU GENERATED THE PGP KEY PAIR
# show secret key
gpg2 --list-secret-keys
#sample output below
#/Users/nithinmallya/.gnupg/pubring.kbx
#--------------------------------------
#sec   rsa2048 2018-12-19 [SC] [expires: 2020-12-18]
#      2F9B955A09D31711F5EA77A7095551B4B03789FB
#uid           [ultimate] nithindevsecops@gmail.com
#ssb   rsa2048 2018-12-19 [E]

# copy the id from the above command and use it extract the key into a file
gpg2 --export-secret-keys 2F9B955A09D31711F5EA77A7095551B4B03789FB > my-private-key.asc

# base64 encode the key value
base64 -i ./my-private-key.asc -o ./my-base64-private-key.asc

cat ./my-base64-private-key.asc
#copy the above value into your Circleci env variable BINAUTH_PRIVATE_KEY