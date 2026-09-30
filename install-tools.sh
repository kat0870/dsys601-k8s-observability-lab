#!/bin/bash
# Installs the tools the DSYS601 lab needs, at the versions in versions.env.
# For a fresh Ubuntu (amd64) host. Safe to re-run: skips tools already at the right version.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_ROOT/versions.env"
[ "$(uname -m)" = "x86_64" ] || { echo "ERROR: only amd64 (x86_64) hosts are supported"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

# Docker (official Docker apt repository, pinned version)
if [ "$(docker --version 2> /dev/null | awk '{print $3}' | tr -d ,)" = "$DOCKER_VERSION" ]; then
  echo "OK    docker $DOCKER_VERSION already installed"
else
  echo "Installing Docker $DOCKER_VERSION ..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  pkg="$(apt-cache madison docker-ce | awk '{print $3}' | grep "^5:${DOCKER_VERSION}-" | head -1)"
  [ -n "$pkg" ] || { echo "ERROR: Docker $DOCKER_VERSION is not available for this Ubuntu release"; exit 1; }
  sudo apt-get install -y "docker-ce=$pkg" "docker-ce-cli=$pkg" containerd.io
  sudo usermod -aG docker "$USER"
  echo "NOTE: log out and back in so $USER can use docker without sudo."
fi

# kubectl (official Kubernetes release, checksum verified)
if [ "$(kubectl version --client 2> /dev/null | awk '/Client Version/{print $3}')" = "$KUBECTL_VERSION" ]; then
  echo "OK    kubectl $KUBECTL_VERSION already installed"
else
  echo "Installing kubectl $KUBECTL_VERSION ..."
  curl -fsSLo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  curl -fsSLo kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  sudo install -m 0755 kubectl /usr/local/bin/kubectl
fi

# Helm (official release, checksum verified)
if [ "$(helm version --short 2> /dev/null | cut -d+ -f1)" = "$HELM_VERSION" ]; then
  echo "OK    helm $HELM_VERSION already installed"
else
  echo "Installing helm $HELM_VERSION ..."
  curl -fsSLo helm.tgz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
  curl -fsSLo helm.sha "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz.sha256sum"
  echo "$(awk '{print $1}' helm.sha)  helm.tgz" | sha256sum --check
  tar -xzf helm.tgz
  sudo install -m 0755 linux-amd64/helm /usr/local/bin/helm
fi

# kind (official release, checksum verified)
if [ "$(kind version 2> /dev/null | awk '{print $2}')" = "$KIND_VERSION" ]; then
  echo "OK    kind $KIND_VERSION already installed"
else
  echo "Installing kind $KIND_VERSION ..."
  curl -fsSLo kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"
  curl -fsSLo kind.sha "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64.sha256sum"
  echo "$(awk '{print $1}' kind.sha)  kind" | sha256sum --check
  sudo install -m 0755 kind /usr/local/bin/kind
fi

# cgroup delegation (Kind needs this on some Ubuntu VMs; see README "Known issue")
ctrl=" $(cat /sys/fs/cgroup/user.slice/cgroup.subtree_control 2> /dev/null || true) "
missing=""
for c in cpu cpuset io memory pids; do
  case "$ctrl" in *" $c "*) ;; *) missing="$missing $c" ;; esac
done
if [ -z "$missing" ]; then
  echo "OK    cgroup delegation already set"
else
  echo "Setting cgroup delegation (missing:$missing) ..."
  sudo mkdir -p /etc/systemd/system/user@.service.d
  printf '[Service]\nDelegate=cpu cpuset io memory pids\n' | sudo tee /etc/systemd/system/user@.service.d/delegate.conf > /dev/null
  sudo systemctl daemon-reload
  echo "NOTE: REBOOT this machine before running reset-lab.sh."
fi

echo "-----"
echo "Tools ready. Next: cp .env.example .env (set the password), then ./reset-lab.sh"
