# Whole genome sequencing (WGS) analysis using nf-core/sarek pipeline and verifybamid

Whole-genome sequencing analysis with [nf-core/sarek](https://nf-co.re/sarek) and VerifyBamID2 contamination QC on a Slurm cluster.

All scripts and commands should be run from the repository root because paths are relative.

## Project structure

```text
config/
  nextflow.example.config
  nextflow.local.config
  sarek.params.yaml
  verifybamid.params.yaml
  samplesheet.csv

scripts/
  run_sarek.sbatch
  submit_sarek.sh
  setup_verifybamid.sh
  verifybamid.nf
  run_verifybamid.sbatch
  submit_verifybamid.sh
  calculate_checksums.sh
  box_upload.sh
  download_gdrive_files.sh

results/
  sarek/
  verifybamid/
```

## Requirements

* Nextflow, loaded through the cluster module system
* Slurm
* Singularity available inside submitted jobs
* `curl` for downloading VerifyBamID2 reference files

## Configuration

Create a local Nextflow configuration:

```bash
cp config/nextflow.example.config config/nextflow.local.config
```

Edit `config/nextflow.local.config` for the local Slurm environment.

Optional `.env` settings:

```bash
SAREK_VERSION="3.9.0"
PROFILE="singularity"
NEXTFLOW_CONFIG="config/nextflow.local.config"
NXF_SINGULARITY_CACHEDIR="/path/to/singularity/cache"
```

Edit pipeline parameters in:

* `config/sarek.params.yaml`
* `config/verifybamid.params.yaml`

All paths in these files are relative to the repository root.

## Run Sarek

```bash
./scripts/submit_sarek.sh
```

Outputs are written to:

```text
results/sarek/
```

## Run VerifyBamID2

VerifyBamID2 estimates human-to-human contamination from the final Sarek CRAM.

Edit the variables at the top of `scripts/setup_verifybamid.sh`, then prepare the input and reference files:

```bash
./scripts/setup_verifybamid.sh
```

Submit the workflow:

```bash
./scripts/submit_verifybamid.sh
```

Do not run the VerifyBamID2 Nextflow command directly on the login node when Singularity is only available inside submitted jobs.

Main outputs:

```text
results/verifybamid/S001.selfSM
results/verifybamid/S001.Ancestry
results/verifybamid/S001.log
```

Inspect the contamination estimate:

```bash
column -t results/verifybamid/S001.selfSM
```

The relevant field is `FREEMIX`.

## Helper scripts

* `scripts/download_gdrive_files.sh`: download FASTQ files from Google Drive
* `scripts/calculate_checksums.sh`: calculate checksums for files
* `scripts/box_upload.sh`: upload files to Box.com

Run each helper script from the repository root.

## Monitor jobs

```bash
squeue -u "${USER}"
sacct -S today -u "${USER}" --format=JobID,JobName,State,ExitCode,Elapsed,Reason
```

Logs are stored under `logs/`.
