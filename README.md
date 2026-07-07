# WGS analysis with nf-core/sarek

This repository contains a reproducible setup for running paired-end whole genome sequencing data with `nf-core/sarek` on a Slurm cluster.

## Setup

Copy the example environment file and adapt it locally:

```bash
cp .env.example .env
```

The `.env.example` file contains example paths and settings. Update `.env` as needed, for example the Sarek version, container profile, Slurm config path, and optional reference paths.

Copy the example Slurm config and adapt it locally:

```bash
cp config/slurm.example.config config/slurm.local.config
```

Edit `config/slurm.local.config` for the cluster-specific partition, account, queue size, or other Slurm settings.

If FASTQ files should be downloaded from Google Drive, copy and adapt the local FASTQ manifest:

```bash
cp config/fastqs.template.tsv config/fastqs.local.tsv
```

Add the Google Drive file IDs and output filenames to `config/fastqs.local.tsv`.

## Input files

Edit the Sarek samplesheet:

```bash
config/samplesheet.csv
```

Use anonymized sample names and relative paths to the FASTQ files, for example paths under `fastq/`.

Main Sarek settings are stored in:

```bash
config/sarek.params.yaml
```

MultiQC settings are stored in:

```bash
config/multiqc.yaml
```

## Download FASTQ files

After adapting `config/fastqs.local.tsv`, run:

```bash
./scripts/download_gdrive_files.sh
```

Check the downloaded FASTQ files:

```bash
gzip -t fastq/*.fq.gz
```

No output means the gzip check passed.

## Run Sarek

After the FASTQ files are available and the samplesheet is correct, run:

```bash
./scripts/run_sarek.sh
```

The script runs `nf-core/sarek` with the pinned version from `.env`, the local Slurm config, and the Sarek parameter file.

## Git tracking

Local settings, FASTQ files, outputs, and Nextflow work files are ignored by git. In particular, do not commit:

```text
.env
config/fastqs.local.tsv
config/slurm.local.config
fastq/
results/
work/
.nextflow*
.nextflow.log*
```

Before pushing, check:

```bash
git status --short
git status --ignored --short
```
