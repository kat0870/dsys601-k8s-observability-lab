#!/bin/bash
# DSYS601 Lab 0: download the images Lab 1 needs, once, before class.
# Later, cluster/setup-cluster.sh copies them into the cluster, so Lab 1
# does not download from Docker Hub during class.
set -euo pipefail
cd "$(dirname "$0")/.."
source versions.env
for img in "$KIND_NODE_IMAGE" $LAB1_IMAGES; do
  echo "Downloading ${img%%@*}"
  docker pull -q --platform linux/amd64 "$img" > /dev/null
done
echo "DONE: Lab 1 images are saved on this VM"
