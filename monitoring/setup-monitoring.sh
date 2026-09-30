#!/bin/bash
# Installs the DSYS601 monitoring stack (kube-prometheus-stack) from pinned, version-controlled config.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Grafana admin password comes from .env (not committed to git). See .env.example.
if [ -f "$REPO_ROOT/.env" ]; then
  source "$REPO_ROOT/.env"
fi
: "${GRAFANA_ADMIN_PASSWORD:?Set GRAFANA_ADMIN_PASSWORD in .env (copy .env.example to .env)}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# upgrade --install works for both first install and re-runs; chart version is pinned.
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --version 91.5.3 \
  --values "$SCRIPT_DIR/values.yaml" \
  --set grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD"

# Load the Grafana dashboard automatically (picked up by Grafana's dashboard sidecar)
kubectl create configmap dsys601-workload-health \
  --namespace monitoring \
  --from-file="$SCRIPT_DIR/dashboards/dsys601-workload-health.json" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap dsys601-workload-health \
  --namespace monitoring grafana_dashboard=1 --overwrite

# Load the DSYS601 alerting rules (PrometheusRule objects). The Prometheus operator
# picks them up because they carry the label release=kube-prometheus-stack.
kubectl apply -f "$SCRIPT_DIR/alerts/"
