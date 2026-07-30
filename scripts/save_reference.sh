#!/bin/bash


mkdir -p results/sarek/reference/genome

REF=$(find work -name "Homo_sapiens_assembly38.fasta" | head -n 1)
REF_REAL=$(readlink -f "$REF")

cp -L "$REF_REAL" results/sarek/reference/genome/

find work cache results -type f \( \
  -name "Homo_sapiens_assembly38.fasta.fai" -o \
  -name "Homo_sapiens_assembly38.dict" -o \
  -name "Homo_sapiens_assembly38.fasta.dict" \
\) -exec cp -n {} results/sarek/reference/genome/ \;

