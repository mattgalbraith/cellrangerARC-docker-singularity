[![Docker Image CI](https://github.com/mattgalbraith/cellrangerARC-docker-singularity/actions/workflows/docker-image.yml/badge.svg)](https://github.com/mattgalbraith/cellrangerARC-docker-singularity/actions/workflows/docker-image.yml)

# cellrangerARC-docker-singularity

## Build Docker container for Cell Ranger ARC and (optionally) convert to Apptainer/Singularity.

A set of analysis pipelines for processing Chromium Single Cell Multiome ATAC + Gene Expression data — barcode processing, ATAC and GEX read alignment and counting, peak calling, and joint analysis linking chromatin accessibility to gene expression from the same cell.

#### Requirements:
You will need to agree to terms and obtain a personal download link for Cell Ranger ARC here:
https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads  
Running Cell Ranger ARC requires at least 8 CPU cores, preferably 16, and at least 64 GB of RAM, preferably 128.  
Global File Limit: 10k per GB RAM. User Limit: 64 times the number of CPUs.  
See also: https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/tutorials/cr-arc-tutorial-in#sitecheck

#### Build platform note:
This image is intended to be built on a MacBook Pro (Apple Silicon, arm64) but run on a Linux HPC (x86_64). Cell Ranger ARC does not ship arm64 binaries, so the image must be built and tagged explicitly for `linux/amd64` — otherwise Docker Desktop will build natively for arm64 and the binaries will fail (or silently fall back to slow emulation) on the HPC. Pass `--platform=linux/amd64` on every `docker build` command below; the Dockerfile itself also pins `--platform=linux/amd64` on its `FROM` lines as a second safeguard.

### Reference data.
See https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads for latest  
https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/release-notes/reference-release-notes for older  
Cell Ranger ARC references bundle the transcriptome (for GEX) and genome/motif annotations (for ATAC) together — this differs from standard Cell Ranger, which uses a transcriptome-only reference.

Human GRCh38 (2024-A):
```
wget https://cf.10xgenomics.com/supp/cell-arc/refdata-cellranger-arc-GRCh38-2024-A.tar.gz
```
Mouse GRCm39 (2024-A):
```
wget https://cf.10xgenomics.com/supp/cell-arc/refdata-cellranger-arc-GRCm39-2024-A.tar.gz
```
Human GRCh38 (2020-A):
```
wget https://cf.10xgenomics.com/supp/cell-arc/refdata-cellranger-arc-GRCh38-2020-A-2.0.0.tar.gz
```
Mouse mm10 (2020-A):
```
wget https://cf.10xgenomics.com/supp/cell-arc/refdata-cellranger-arc-mm10-2020-A-2.0.0.tar.gz
```

**For purposes of reproducibility, the exact build steps are provided here:**  
https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads/cr-arc-ref-build-steps

### A note on `cellranger-arc mkfastq`
`cellranger-arc mkfastq` is deprecated as of recent Cell Ranger ARC releases. Use Illumina's BCL Convert directly to generate FASTQs, then proceed straight to `cellranger-arc count`.

### Library CSV
Unlike standard Cell Ranger, `cellranger-arc count` requires a libraries CSV mapping FASTQ paths to library type (`Gene Expression` or `Chromatin Accessibility`) for each sample — see:
https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/analysis/inputs/cr-arc-feature-bc-matrices#libraries-csv


## Build docker container:

### 1. For Cell Ranger ARC installation instructions:
https://www.10xgenomics.com/support/software/cell-ranger-arc/latest/tutorials/cr-arc-tutorial-in


### 2. Build the Docker Image

#### To build image from the command line:
``` bash
# Assumes current working directory is the top-level cellrangerARC-docker-singularity directory
# --platform=linux/amd64 forces an x86_64 build even when building on Apple Silicon,
# since Cell Ranger ARC has no arm64 binaries and this image needs to run on a Linux HPC
docker build --platform=linux/amd64 \
  --build-arg CRARC_URL="<your signed download URL from 10x>" \
  -t cellranger-arc:2.2.0 . # tag should match software version
```

#### To test this tool from the command line:
``` bash
docker run --platform=linux/amd64 --rm -it cellranger-arc:2.2.0 cellranger-arc --help # should print help information

# Optional: Run a sitecheck and perform a testrun
cellranger-arc sitecheck > cellranger-arc_sitecheck.txt # see Requirements section above
cellranger-arc testrun --id=check_install # Pipestance completed successfully!
```

## Optional: Conversion of Docker image to Singularity

### 3. Build a Docker image to run Singularity
(skip if this image is already on your system)  
https://github.com/mattgalbraith/singularity-docker

### 4. Save Docker image as tar and convert to sif (using singularity run from Docker container)
``` bash
docker images
docker save <Image_ID> -o cellranger-arc_2.2.0-docker.tar && gzip cellranger-arc_2.2.0-docker.tar # = IMAGE_ID of <tool> image
docker run -v "$PWD":/data --rm -it singularity:1.3.4 bash -c "singularity build /data/cellranger-arc_2.2.0.sif docker-archive:///data/cellranger-arc_2.2.0-docker.tar.gz"
```
NB: On Apple M1/M2/M3/M4 machines, always pass `--platform=linux/amd64` (as above) when building and saving the image — otherwise the sif may get built with arm64 and will fail to run on the (x86_64) HPC.

Next, transfer the cellranger-arc_2.2.0.sif file to the system on which you want to run Cell Ranger ARC from the Singularity container

### 5. Test singularity container on (HPC) system with Singularity/Apptainer available
``` bash
# set up path to the Singularity container
CELLRANGER_ARC_SIF=path/to/cellranger-arc_2.2.0.sif

# Test that Cell Ranger ARC can run from Singularity container
singularity run $CELLRANGER_ARC_SIF cellranger-arc --help # depending on system/version, singularity may be called apptainer
```
