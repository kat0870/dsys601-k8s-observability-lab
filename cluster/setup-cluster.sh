#!/bin/bash
# Get the directory this script lives in, so it works regardless of where it's called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kind create cluster --name dsys601-lab --config "$SCRIPT_DIR/kind-config.yaml"
kubectl cluster-info --context kind-dsys601-lab
