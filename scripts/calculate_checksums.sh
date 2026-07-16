#!/bin/bash

#find results/sarek -type f -print0 \
#  | sort -z \
#  | xargs -0 sha256sum \
#  > results/sarek/checksums.sha256


find results/verifybamid -type f -print0 \
  | sort -z \
  | xargs -0 sha256sum \
  > results/verifybamid/checksums.sha256
