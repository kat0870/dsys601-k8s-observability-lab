#!/bin/bash
# Creates the DSYS601 Kind cluster (1 control-plane, 2 workers) from version-controlled config.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="dsys601-lab"
source "$REPO_ROOT/versions.env"

# 1. Required tools must be installed
for tool in docker kind kubectl helm; do
  command -v "$tool" > /dev/null || { echo "ERROR: $tool is not installed"; exit 1; }
done

# 2. Warn if installed versions differ from the tested versions
check_version() {
  if [ "$2" = "$3" ]; then echo "OK    $1 $3"; else echo "WARN  $1 is $3 (lab tested with $2)"; fi
}
check_version kind    "$KIND_VERSION"    "$(kind version | awk '{print $2}')"
check_version kubectl "$KUBECTL_VERSION" "$(kubectl version --client | awk '/Client Version/{print $3}')"
check_version helm    "$HELM_VERSION"    "$(helm version --short | cut -d+ -f1)"
check_version docker  "$DOCKER_VERSION"  "$(docker version --format '{{.Server.Version}}')"

# 3. kind-config.yaml must use the pinned node image from versions.env
if ! grep -qF "$KIND_NODE_IMAGE" "$SCRIPT_DIR/kind-config.yaml"; then
  echo "ERROR: node image in kind-config.yaml does not match KIND_NODE_IMAGE in versions.env"; exit 1
fi

# 4. Don't try to create a cluster that already exists
if kind get clusters 2> /dev/null | grep -x "$CLUSTER_NAME" > /dev/null; then
  echo "ERROR: cluster '$CLUSTER_NAME' already exists. Run ./cluster/teardown-cluster.sh first."; exit 1
fi

kind create cluster --name "$CLUSTER_NAME" --config "$SCRIPT_DIR/kind-config.yaml"
kubectl cluster-info --context "kind-$CLUSTER_NAME"
