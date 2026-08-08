################# BASE IMAGE ######################
FROM --platform=linux/amd64 ubuntu:24.04 AS base

################## METADATA ######################
LABEL base_image="ubuntu:24.04"
LABEL version="1.0.0"
LABEL software="Cell Ranger ARC"
LABEL software.version="2.2.0"
LABEL about.summary="Cell Ranger ARC is a set of analysis pipelines for processing Chromium Single Cell Multiome ATAC + Gene Expression data, jointly analyzing gene expression and chromatin accessibility from the same cell."
LABEL about.home="https://www.10xgenomics.com/support/software/cell-ranger-arc/latest"
LABEL about.documentation="https://www.10xgenomics.com/support/software/cell-ranger-arc"
LABEL about.license_file="https://github.com/10XGenomics/cellranger/blob/main/LICENSE"
LABEL about.license="support.10xgenomics.com/license"
LABEL about.maintainer="Matthew Galbraith <matthew.galbraith@cuanschutz.edu>"

################## INSTALLATION ######################
ENV DEBIAN_FRONTEND="noninteractive"
ENV PACKAGES="tar wget ca-certificates"

RUN apt-get update && \
    apt-get install -y --no-install-recommends ${PACKAGES} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Signed download URL expires (see Expires=/Signature= params) and is tied to
# accepting the 10x EULA. Get a fresh link from:
# https://www.10xgenomics.com/support/software/cell-ranger-arc/downloads
# then pass it at build time, e.g.:
#   docker build --build-arg CRARC_URL="https://cf.10xgenomics.com/releases/cell-arc/cellranger-arc-2.2.0.tar.gz?Expires=...&Signature=..." .
ARG CRARC_URL

# NOT USED:
# Copy from parent dir and unpack downloaded Cell Ranger ARC archive:
# COPY cellranger-arc-2.2.0.tar.gz /
# RUN tar -xzvf cellranger-arc-2.2.0.tar.gz

RUN wget -O cellranger-arc-2.2.0.tar.gz "${CRARC_URL}"

RUN tar -xzvf cellranger-arc-2.2.0.tar.gz


################## 2ND STAGE ######################
FROM --platform=linux/amd64 ubuntu:24.04
ENV DEBIAN_FRONTEND="noninteractive"

# RUN apt-get update && \
#     apt-get install -y --no-install-recommends ${PACKAGES} && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=base /cellranger-arc-2.2.0/ /opt/cellranger-arc-2.2.0

ENV PATH=/opt/cellranger-arc-2.2.0:$PATH
