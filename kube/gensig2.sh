#!/bin/bash


gpg2 --batch --gen-key <(
    cat <<- EOF
      Key-Type: RSA
      Key-Length: 2048
      Name-Real: Demo Signing Role
      Name-Email: attestor@example.com
      %commit
EOF
)

gpg2 --export-secret-keys 90D50FBE9C9FB7624B00ED6818B2A7A8528DE3A6 > my-private-key.asc
gpg2 --armor --export attestor@example.com> ./public.pgp
PGP_FINGERPRINT="$(gpg --list-keys attestor@example.com | head -2 | tail -1 | awk '{print $1}')"
# 90D50FBE9C9FB7624B00ED6818B2A7A8528DE3A6
gpg2 --import my-private-key.asc
