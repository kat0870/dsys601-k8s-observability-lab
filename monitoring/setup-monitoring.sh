#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --version 91.5.3 \
  --values "$SCRIPT_DIR/values.yaml"

# Load the Grafana dashboard automatically (picked up by Grafana's dashboard sidecar)
kubectl create configmap dsys601-workload-health \
  --namespace monitoring \
  --from-file="$SCRIPT_DIR/dashboards/dsys601-workload-health.json" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap dsys601-workload-health \
  --namespace monitoring grafana_dashboard=1 --overwrite
