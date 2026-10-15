#!/bin/bash
# DSYS601 labs - opens a monitoring tool on this VM with kubectl port-forward.
# Usage: bash labs/open.sh prometheus | grafana | alertmanager
case "${1:-}" in
  prometheus)   svc=kube-prometheus-stack-prometheus;   port=9090; target=9090 ;;
  grafana)      svc=kube-prometheus-stack-grafana;      port=3000; target=80 ;;
  alertmanager) svc=kube-prometheus-stack-alertmanager; port=9093; target=9093 ;;
  *) echo "Usage: bash labs/open.sh prometheus | grafana | alertmanager"; exit 1 ;;
esac
echo "Running: kubectl port-forward -n monitoring svc/$svc $port:$target"
echo "Open http://localhost:$port in Firefox. Leave this tab open. Press Ctrl+C to stop."
exec kubectl port-forward -n monitoring "svc/$svc" "$port:$target"
