#!/bin/bash
# Tears down the DSYS601 Kind cluster and checks nothing is left behind.
# Usage: ./cluster/teardown-cluster.sh          (asks for confirmation)
#        ./cluster/teardown-cluster.sh --yes    (no prompt, used by reset-lab.sh)
set -euo pipefail
CLUSTER_NAME="dsys601-lab"

# 1. Nothing to do if the cluster doesn't exist
if ! kind get clusters 2> /dev/null | grep -x "$CLUSTER_NAME" > /dev/null; then
  echo "Nothing to delete: cluster '$CLUSTER_NAME' does not exist."
  exit 0
fi

# 2. Ask for confirmation unless --yes was given
if [ "${1:-}" != "--yes" ]; then
  echo "This will DELETE cluster '$CLUSTER_NAME', including the demo app, monitoring stack and all their data."
  read -r -p "Type the cluster name to confirm: " answer
  [ "$answer" = "$CLUSTER_NAME" ] || { echo "Cancelled."; exit 1; }
fi

# 3. Delete
kind delete cluster --name "$CLUSTER_NAME"

# 4. Check nothing was left behind
problems=0
if docker ps -a --format '{{.Names}}' | grep "^${CLUSTER_NAME}-" > /dev/null; then
  echo "LEFTOVER: node containers still exist"; problems=1
fi
if kubectl config get-contexts -o name | grep -x "kind-${CLUSTER_NAME}" > /dev/null; then
  echo "LEFTOVER: kubectl context kind-${CLUSTER_NAME} still exists"; problems=1
fi
[ "$problems" -eq 0 ] || exit 1
echo "CLEAN: cluster, node containers and kubectl context removed."
echo "Note: the 'kind' Docker network is kept on purpose; Kind reuses it."
