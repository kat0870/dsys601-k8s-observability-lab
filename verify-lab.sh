#!/bin/bash
# Checks the DSYS601 lab is healthy after a build or reset. Prints PASS/FAIL per check.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_ROOT/versions.env"
fails=0

check() {
  local desc="$1"; shift
  if "$@" > /dev/null 2>&1; then echo "PASS  $desc"; else echo "FAIL  $desc"; fails=$((fails+1)); fi
}

check "Cluster reachable"                  kubectl cluster-info
check "3 nodes Ready"                      bash -c '[ "$(kubectl get nodes --no-headers | grep -cw Ready)" -eq 3 ]'
check "All kube-system pods Running"       bash -c 'out=$(kubectl get pods -n kube-system --no-headers) && [ -n "$out" ] && ! echo "$out" | grep -v Running'
check "Demo app deployments available"     kubectl wait -n demo-app --for=condition=Available deploy --all --timeout=180s
check "Monitoring deployments available"   kubectl wait -n monitoring --for=condition=Available deploy --all --timeout=300s
check "Prometheus ready"                   kubectl rollout status sts/prometheus-kube-prometheus-stack-prometheus -n monitoring --timeout=300s
check "Alertmanager ready"                 kubectl rollout status sts/alertmanager-kube-prometheus-stack-alertmanager -n monitoring --timeout=300s
check "node-exporter on every node"        kubectl rollout status ds/kube-prometheus-stack-prometheus-node-exporter -n monitoring --timeout=300s
check "Helm chart $KUBE_PROMETHEUS_STACK_CHART_VERSION deployed" bash -c "helm list -n monitoring --deployed | grep -q 'kube-prometheus-stack-$KUBE_PROMETHEUS_STACK_CHART_VERSION'"
check "DSYS601 alert rules loaded"         kubectl get prometheusrule dsys601-workload-alerts -n monitoring
check "DSYS601 dashboard loaded"           kubectl get configmap dsys601-workload-health -n monitoring

echo "-----"
if [ "$fails" -eq 0 ]; then echo "LAB READY: all checks passed"; else echo "LAB NOT READY: $fails check(s) failed"; exit 1; fi
